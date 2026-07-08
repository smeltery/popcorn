import { batch, createEffect, createMemo, createSignal, onCleanup, onMount } from "solid-js";
import { hexToOklab, lerpOklab, normalizeHexColor, oklabToHex, rgbToHex } from "../colors.js";
import { Vt } from "../vt";
import {
  BLOCK_H_RES,
  BLOCK_V_RES,
  POWERLINE_SYMBOL_NUDGE,
  POWERLINE_SYMBOLS,
  drawBlockGlyph,
  getVectorSymbolDef,
} from "./terminal/glyphs.js";

const SVG_NS = "http://www.w3.org/2000/svg";

const BOLD_MASK = 1;
const FAINT_MASK = 1 << 1;
const ITALIC_MASK = 1 << 2;
const UNDERLINE_MASK = 1 << 3;
const STRIKETHROUGH_MASK = 1 << 4;
const BLINK_MASK = 1 << 5;

export default (props) => {
  const core = props.core;
  const textRowPool = [];
  const vectorSymbolRowPool = [];
  const vectorSymbolUsePool = [];
  const vectorSymbolDefCache = new Set();
  const colorsCache = new Map();
  const attrClassCache = new Map();
  const vtReady = Vt.build(props.cols, props.rows, props.boldIsBright, props.logger);
  let vt;

  const [size, setSize] = createSignal(
    { cols: props.cols, rows: props.rows },
    { equals: (newVal, oldVal) => newVal.cols === oldVal.cols && newVal.rows === oldVal.rows },
  );

  const [theme, setTheme] = createSignal(buildTheme(FALLBACK_THEME, props.adaptivePalette));
  const lineHeight = () => props.lineHeight ?? 1.3333333333;
  const [blinkOn, setBlinkOn] = createSignal(true);

  const cursorOn = createMemo(() => {
    if (props.cursorMode === "hidden") return false;
    if (props.cursorMode === "steady") return true;
    return blinkOn() || cursorHold;
  });

  const style = createMemo(() => {
    return {
      width: `${size().cols}ch`,
      height: `${lineHeight() * size().rows}em`,
      "font-size": `${(props.scale || 1.0) * 100}%`,
      "--term-line-height": `${lineHeight()}em`,
      "--term-cols": size().cols,
      "--term-rows": size().rows,
    };
  });

  let cursor = {
    col: 0,
    row: 0,
    visible: false,
  };

  let pendingChanges = {
    size: undefined,
    theme: undefined,
    rows: new Set(),
  };

  let el;
  let canvasEl;
  let canvasCtx;
  let textEl;
  let vectorSymbolsEl;
  let vectorSymbolDefsEl;
  let vectorSymbolRowsEl;
  let frameRequestId;
  let blinkIntervalId;
  let cssTheme;
  let cursorHold = false;

  onMount(() => {
    setupCanvas();
    setInitialTheme();
    adjustTextRowNodeCount(size().rows);
    adjustSymbolRowNodeCount(size().rows);

    vtReady.then((vt_) => {
      vt = vt_;
      core.addEventListener("reset", onVtReset);
      core.addEventListener("resize", onVtResize);
      core.addEventListener("output", onVtOutput);
      props.onReady?.();
    });
  });

  onCleanup(() => {
    core.removeEventListener("reset", onVtReset);
    core.removeEventListener("resize", onVtResize);
    core.removeEventListener("output", onVtOutput);
    clearInterval(blinkIntervalId);
    cancelAnimationFrame(frameRequestId);
  });

  createEffect(() => {
    if (props.blinking && blinkIntervalId === undefined) {
      blinkIntervalId = setInterval(toggleBlink, 600);
    } else {
      clearInterval(blinkIntervalId);
      blinkIntervalId = undefined;
      setBlinkOn(true);
    }
  });

  createEffect(() => {
    cursorOn();

    if (cursor.visible) {
      pendingChanges.rows.add(cursor.row);
      scheduleRender();
    }
  });

  function setupCanvas() {
    canvasCtx = canvasEl.getContext("2d");
    if (!canvasCtx) throw new Error("2D ctx not available");
    const { cols, rows } = size();
    canvasEl.width = cols * BLOCK_H_RES;
    canvasEl.height = rows * BLOCK_V_RES;
    canvasEl.style.imageRendering = "pixelated";
    canvasCtx.imageSmoothingEnabled = false;
  }

  function resizeCanvas({ cols, rows }) {
    canvasEl.width = cols * BLOCK_H_RES;
    canvasEl.height = rows * BLOCK_V_RES;
    canvasCtx.imageSmoothingEnabled = false;
  }

  function setInitialTheme() {
    cssTheme = getCssTheme(el);
    pendingChanges.theme = cssTheme;
  }

  function onVtReset({ size, theme, init }) {
    const changedRows = vt.reset(size.cols, size.rows, init);
    onVtUpdate({ size, theme, changedRows });
  }

  function onVtResize(size) {
    const changedRows = vt.resize(size.cols, size.rows);
    if (changedRows === undefined) return;
    onVtUpdate({ size, changedRows });
  }

  function onVtOutput(data) {
    let changedRows;

    if (Array.isArray(data)) {
      changedRows = new Set();

      for (const d of data) {
        for (const row of vt.feed(d)) {
          changedRows.add(row);
        }
      }
    } else {
      changedRows = vt.feed(data);
    }

    onVtUpdate({ changedRows });
  }

  function onVtUpdate({ size: newSize, theme, changedRows }) {
    let activity = false;

    if (changedRows !== undefined) {
      for (const row of changedRows) {
        pendingChanges.rows.add(row);
        cursorHold = true;
        activity = true;
      }
    }

    if (theme !== undefined && props.preferEmbeddedTheme) {
      pendingChanges.theme = theme;

      for (let row = 0; row < size().rows; row++) {
        pendingChanges.rows.add(row);
      }
    }

    const newCursor = vt.getCursor();

    if (
      newCursor.visible != cursor.visible ||
      newCursor.col != cursor.col ||
      newCursor.row != cursor.row
    ) {
      if (cursor.visible) {
        pendingChanges.rows.add(cursor.row);
      }

      if (newCursor.visible) {
        pendingChanges.rows.add(newCursor.row);
      }

      cursor = newCursor;
      cursorHold = true;
      activity = true;
    }

    if (newSize !== undefined) {
      pendingChanges.size = newSize;

      for (const row of pendingChanges.rows) {
        if (row >= newSize.rows) {
          pendingChanges.rows.delete(row);
        }
      }
    }

    if (activity && cursor.visible) {
      pendingChanges.rows.add(cursor.row);
    }

    scheduleRender();
  }

  function toggleBlink() {
    setBlinkOn((blink) => {
      if (!blink) cursorHold = false;
      return !blink;
    });
  }

  function scheduleRender() {
    if (frameRequestId === undefined) {
      frameRequestId = requestAnimationFrame(render);
    }
  }

  function render() {
    frameRequestId = undefined;
    const { size: newSize, theme: newTheme, rows } = pendingChanges;

    batch(function () {
      if (newSize !== undefined) {
        resizeCanvas(newSize);
        adjustTextRowNodeCount(newSize.rows);
        adjustSymbolRowNodeCount(newSize.rows);
        setSize(newSize);
      }

      if (newTheme !== undefined) {
        if (newTheme === null) {
          setTheme(buildTheme(cssTheme, props.adaptivePalette));
        } else {
          setTheme(buildTheme(newTheme, props.adaptivePalette));
        }

        colorsCache.clear();
      }

      const theme_ = theme();
      const cursorOn_ = cursorOn();

      for (const r of rows) {
        renderRow(r, theme_, cursorOn_);
      }
    });

    pendingChanges.size = undefined;
    pendingChanges.theme = undefined;
    pendingChanges.rows.clear();

    props.stats.renders += 1;
  }

  function renderRow(rowIndex, theme, cursorOn) {
    const line = vt.getLine(rowIndex, cursorOn);

    clearCanvasRow(rowIndex);
    renderRowBg(rowIndex, line.bg, theme);
    renderRowRasterSymbols(rowIndex, line.raster_symbols, theme);
    renderRowVectorSymbols(rowIndex, line.vector_symbols, theme);
    renderRowText(rowIndex, line.text, line.codepoints, theme);
  }

  function clearCanvasRow(rowIndex) {
    canvasCtx.clearRect(0, rowIndex * BLOCK_V_RES, size().cols * BLOCK_H_RES, BLOCK_V_RES);
  }

  function renderRowBg(rowIndex, spans, theme) {
    // The memory layout of a BgSpan must follow one defined in lib.rs (see the assertions at the bottom)
    const view = vt.getDataView(spans, 8);

    const y = rowIndex * BLOCK_V_RES;
    let i = 0;

    while (i < view.byteLength) {
      const column = view.getUint16(i + 0, true);
      const width = view.getUint16(i + 2, true);
      const color = getColor(view, i + 4, theme);
      i += 8;

      canvasCtx.fillStyle = color;
      canvasCtx.fillRect(column * BLOCK_H_RES, y, width * BLOCK_H_RES, BLOCK_V_RES);
    }
  }

  function renderRowRasterSymbols(rowIndex, symbols, theme) {
    // The memory layout of a RasterSymbol must follow one defined in lib.rs (see the assertions at the bottom)
    const view = vt.getDataView(symbols, 12);

    const y = rowIndex * BLOCK_V_RES;
    let i = 0;

    while (i < view.byteLength) {
      const column = view.getUint16(i + 0, true);
      const codepoint = view.getUint32(i + 4, true);
      const color = getColor(view, i + 8, theme) || theme.fg;
      i += 12;

      canvasCtx.fillStyle = color;
      drawBlockGlyph(canvasCtx, codepoint, column * BLOCK_H_RES, y);
    }
  }

  function renderRowVectorSymbols(rowIndex, symbols, theme) {
    // The memory layout of a VectorSymbol must follow one defined in lib.rs (see the assertions at the bottom)
    const view = vt.getDataView(symbols, 16);

    const frag = document.createDocumentFragment();
    const symbolRow = vectorSymbolRowsEl.children[rowIndex];
    let i = 0;

    while (i < view.byteLength) {
      const column = view.getUint16(i + 0, true);
      const codepoint = view.getUint32(i + 4, true);
      const color = getColor(view, i + 8, theme);
      const attrs = view.getUint8(i + 12);
      i += 16;

      const blink = (attrs & BLINK_MASK) !== 0;
      const el = createVectorSymbolNode(codepoint, column, color, blink);

      if (el) {
        frag.appendChild(el);
      }
    }

    recycleVectorSymbolUses(symbolRow);
    symbolRow.replaceChildren(frag);
  }

  function renderRowText(rowIndex, spans, codepoints, theme) {
    // The memory layout of a TextSpan must follow one defined in lib.rs (see the assertions at the bottom)
    const spansView = vt.getDataView(spans, 12);

    const codepointsView = vt.getUint32Array(codepoints);
    const frag = document.createDocumentFragment();
    let i = 0;

    while (i < spansView.byteLength) {
      const column = spansView.getUint16(i + 0, true);
      const codepointsStart = spansView.getUint16(i + 2, true);
      const len = spansView.getUint16(i + 4, true);
      const color = getColor(spansView, i + 6, theme);
      const attrs = spansView.getUint8(i + 10);
      const text = String.fromCodePoint(
        ...codepointsView.subarray(codepointsStart, codepointsStart + len),
      );
      i += 12;

      const el = document.createElement("span");
      const style = el.style;
      style.setProperty("--offset", column);
      el.textContent = text;

      if (color) {
        style.color = color;
      }

      const cls = getAttrClass(attrs);

      if (cls !== null) {
        el.className = cls;
      }

      frag.appendChild(el);
    }

    textEl.children[rowIndex].replaceChildren(frag);
  }

  function getAttrClass(attrs) {
    let c = attrClassCache.get(attrs);

    if (c === undefined) {
      c = buildAttrClass(attrs);
      attrClassCache.set(attrs, c);
    }

    return c;
  }

  function buildAttrClass(attrs) {
    let cls = "";

    if ((attrs & BOLD_MASK) !== 0) {
      cls += "ap-bold ";
    } else if ((attrs & FAINT_MASK) !== 0) {
      cls += "ap-faint ";
    }

    if ((attrs & ITALIC_MASK) !== 0) {
      cls += "ap-italic ";
    }

    if ((attrs & UNDERLINE_MASK) !== 0) {
      cls += "ap-underline ";
    }

    if ((attrs & STRIKETHROUGH_MASK) !== 0) {
      cls += "ap-strike ";
    }

    if ((attrs & BLINK_MASK) !== 0) {
      cls += "ap-blink ";
    }

    return cls === "" ? null : cls;
  }

  function getColor(view, offset, theme) {
    const tag = view.getUint8(offset);

    if (tag === 0) {
      return null;
    } else if (tag === 1) {
      return theme.fg;
    } else if (tag === 2) {
      return theme.bg;
    } else if (tag === 3) {
      return theme.palette[view.getUint8(offset + 1)];
    } else if (tag === 4) {
      const key = view.getUint32(offset, true);
      let c = colorsCache.get(key);

      if (c === undefined) {
        const r = view.getUint8(offset + 1);
        const g = view.getUint8(offset + 2);
        const b = view.getUint8(offset + 3);
        c = "rgb(" + r + "," + g + "," + b + ")";
        colorsCache.set(key, c);
      }

      return c;
    } else {
      throw new Error(`invalid color tag: ${tag}`);
    }
  }

  function adjustTextRowNodeCount(rows) {
    let r = textEl.children.length;

    if (r < rows) {
      const frag = document.createDocumentFragment();

      while (r < rows) {
        const row = getNewRow();
        row.style.setProperty("--row", r);
        frag.appendChild(row);
        r += 1;
      }

      textEl.appendChild(frag);
    }

    while (textEl.children.length > rows) {
      const row = textEl.lastElementChild;
      textEl.removeChild(row);
      textRowPool.push(row);
    }
  }

  function adjustSymbolRowNodeCount(rows) {
    let r = vectorSymbolRowsEl.children.length;

    if (r < rows) {
      const frag = document.createDocumentFragment();

      while (r < rows) {
        const row = getNewSymbolRow();
        row.setAttribute("transform", `translate(0 ${r})`);
        frag.appendChild(row);
        r += 1;
      }

      vectorSymbolRowsEl.appendChild(frag);
    }

    while (vectorSymbolRowsEl.children.length > rows) {
      const row = vectorSymbolRowsEl.lastElementChild;
      vectorSymbolRowsEl.removeChild(row);
      vectorSymbolRowPool.push(row);
    }
  }

  function getNewRow() {
    let row = textRowPool.pop();

    if (row === undefined) {
      row = document.createElement("span");
      row.className = "ap-line";
    }

    return row;
  }

  function getNewSymbolRow() {
    let row = vectorSymbolRowPool.pop();

    if (row === undefined) {
      row = document.createElementNS(SVG_NS, "g");
      row.setAttribute("class", "ap-symbol-line");
    }

    return row;
  }

  function createVectorSymbolNode(codepoint, column, fg, blink) {
    if (!ensureVectorSymbolDef(codepoint)) {
      return null;
    }

    const isPowerline = POWERLINE_SYMBOLS.has(codepoint);
    const symbolX = isPowerline ? column - POWERLINE_SYMBOL_NUDGE : column;
    const symbolWidth = isPowerline ? 1 + POWERLINE_SYMBOL_NUDGE * 2 : 1;

    const node = getVectorSymbolUse();
    node.setAttribute("href", `#sym-${codepoint}`);
    node.setAttribute("x", symbolX);
    node.setAttribute("y", 0);
    node.setAttribute("width", symbolWidth);
    node.setAttribute("height", "1");

    if (fg) {
      node.style.setProperty("color", fg);
    } else {
      node.style.removeProperty("color");
    }

    if (blink) {
      node.classList.add("ap-blink");
    } else {
      node.classList.remove("ap-blink");
    }

    return node;
  }

  function recycleVectorSymbolUses(row) {
    while (row.firstChild) {
      const child = row.firstChild;
      row.removeChild(child);
      vectorSymbolUsePool.push(child);
    }
  }

  function getVectorSymbolUse() {
    let node = vectorSymbolUsePool.pop();

    if (node === undefined) {
      node = document.createElementNS(SVG_NS, "use");
    }

    return node;
  }

  function ensureVectorSymbolDef(codepoint) {
    const content = getVectorSymbolDef(codepoint);

    if (!content) {
      return false;
    }

    if (vectorSymbolDefCache.has(codepoint)) {
      return true;
    }

    const id = `sym-${codepoint}`;
    const symbol = document.createElementNS(SVG_NS, "symbol");
    symbol.setAttribute("id", id);
    symbol.setAttribute("viewBox", "0 0 1 1");
    symbol.setAttribute("preserveAspectRatio", "none");
    symbol.setAttribute("overflow", "visible");
    symbol.innerHTML = content;
    vectorSymbolDefsEl.appendChild(symbol);
    vectorSymbolDefCache.add(codepoint);
    return true;
  }

  return (
    <div class="ap-term" style={style()} ref={el}>
      <canvas ref={canvasEl} />
      <svg
        class="ap-term-symbols"
        xmlns="http://www.w3.org/2000/svg"
        viewBox={`0 0 ${size().cols} ${size().rows}`}
        preserveAspectRatio="none"
        width="100%"
        height="100%"
        aria-hidden="true"
        classList={{ "ap-blink": blinkOn() }}
        ref={vectorSymbolsEl}
      >
        <defs ref={vectorSymbolDefsEl}></defs>
        <g ref={vectorSymbolRowsEl}></g>
      </svg>
      <pre
        class="ap-term-text"
        classList={{ "ap-blink": blinkOn() }}
        ref={textEl}
        aria-live="off"
        tabindex="0"
      ></pre>
    </div>
  );
};

function buildTheme(theme, adaptivePalette = false) {
  return {
    fg: theme.foreground,
    bg: theme.background,
    palette: adaptivePalette
      ? generate256Palette(theme.palette, theme.background, theme.foreground)
      : generateFixed256Palette(theme.palette),
  };
}

function getCssTheme(el) {
  const style = getComputedStyle(el);

  const foreground = normalizeHexColor(
    style.getPropertyValue("--term-color-foreground"),
    FALLBACK_THEME.foreground,
  );

  const background = normalizeHexColor(
    style.getPropertyValue("--term-color-background"),
    FALLBACK_THEME.background,
  );

  const palette = [];

  for (let i = 0; i < 16; i++) {
    const fallback = i >= 8 ? palette[i - 8] : FALLBACK_THEME.palette[i];
    palette[i] = normalizeHexColor(style.getPropertyValue(`--term-color-${i}`), fallback);
  }

  return { foreground, background, palette };
}

function generate256Palette(base16, bg, fg) {
  const bgLab = hexToOklab(bg);
  const fgLab = hexToOklab(fg);
  const c100 = hexToOklab(base16[1]);
  const c010 = hexToOklab(base16[2]);
  const c110 = hexToOklab(base16[3]);
  const c001 = hexToOklab(base16[4]);
  const c101 = hexToOklab(base16[5]);
  const c011 = hexToOklab(base16[6]);
  const palette = [...base16];

  // 216 color cube range

  for (let r = 0; r < 6; r += 1) {
    const tR = r / 5;
    const c0 = lerpOklab(tR, bgLab, c100);
    const c1 = lerpOklab(tR, c010, c110);
    const c2 = lerpOklab(tR, c001, c101);
    const c3 = lerpOklab(tR, c011, fgLab);

    for (let g = 0; g < 6; g += 1) {
      const tG = g / 5;
      const c4 = lerpOklab(tG, c0, c1);
      const c5 = lerpOklab(tG, c2, c3);

      for (let b = 0; b < 6; b += 1) {
        const tB = b / 5;
        const c6 = lerpOklab(tB, c4, c5);
        palette.push(oklabToHex(c6));
      }
    }
  }

  // grayscale range

  for (let i = 0; i < 24; i += 1) {
    const t = (i + 1) / 25;
    palette.push(oklabToHex(lerpOklab(t, bgLab, fgLab)));
  }

  return palette;
}

function generateFixed256Palette(base16) {
  const palette = [...base16];
  const levels = [0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff];

  // 216 color cube range

  for (let r = 0; r < 6; r += 1) {
    for (let g = 0; g < 6; g += 1) {
      for (let b = 0; b < 6; b += 1) {
        palette.push(rgbToHex(levels[r], levels[g], levels[b]));
      }
    }
  }

  // grayscale range

  for (let i = 0; i < 24; i += 1) {
    const level = 8 + i * 10;
    palette.push(rgbToHex(level, level, level));
  }

  return palette;
}

const FALLBACK_THEME = {
  foreground: "#000000",
  background: "#000000",
  palette: [
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
    "#000000",
  ],
};
