import { test, expect } from "@playwright/test";

import {
  createPlayer,
  failOnPageError,
  sampleTerminalPixels,
  waitForCellColor,
  expectTermText,
  buildThemeSamples,
} from "./helpers.js";

test.beforeEach(async ({ page }) => {
  await failOnPageError(page);
});

test("bold+inverse brightens indexed fg when boldIsBright=true", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/bold-inverse-indexed.pop", {
    autoPlay: true,
    boldIsBright: true,
    theme: "tango",
  });

  await playerApi.events.waitFor("ended");

  const { cells } = await sampleTerminalPixels(page, { cells: [[0, 0, 0.5, 0.5]] });

  expect(cells[0]).toBe("#8ae234");
});

test("bold+inverse keeps indexed fg when boldIsBright=false", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/bold-inverse-indexed.pop", {
    autoPlay: true,
    boldIsBright: false,
    theme: "tango",
  });

  await playerApi.events.waitFor("ended");

  const { cells } = await sampleTerminalPixels(page, { cells: [[0, 0, 0.5, 0.5]] });

  expect(cells[0]).toBe("#4e9a06");
});

test("cursorMode=blinking toggles cursor visibility during playback", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/cursor.pop", {
    autoPlay: true,
    theme: "tango",
  });

  await playerApi.events.waitFor("playing");

  const visible = await waitForCellColor(page, [0, 1, 0.5, 0.5], "#cccccc");
  const hidden = await waitForCellColor(page, [0, 1, 0.5, 0.5], "#121314");

  expect(visible).toBe(true);
  expect(hidden).toBe(true);
});

test("cursorMode=steady keeps cursor visible during playback", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/cursor.pop", {
    autoPlay: true,
    cursorMode: "steady",
    theme: "tango",
  });

  await playerApi.events.waitFor("playing");
  await page.waitForTimeout(800);

  const { cells } = await sampleTerminalPixels(page, { cells: [[0, 1, 0.5, 0.5]] });

  expect(cells[0]).toBe("#cccccc");
});

test("cursorMode=hidden hides cursor", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/cursor.pop", {
    autoPlay: true,
    cursorMode: "hidden",
    theme: "tango",
  });

  await playerApi.events.waitFor("playing");

  const { cells } = await sampleTerminalPixels(page, { cells: [[0, 1, 0.5, 0.5]] });

  expect(cells[0]).toBe("#121314");
});

test("RGB colors apply across text, raster, and SVG layers", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/rgb.pop", {
    autoPlay: true,
  });

  await playerApi.events.waitFor("ended");

  const { cells } = await sampleTerminalPixels(page, {
    cells: [
      [0, 0, 0.9, 0.1],
      [0, 0, 0.5, 0.5],
      [0, 1, 0.9, 0.1],
      [0, 1, 0.5, 0.5],
      [0, 2, 0.9, 0.1],
      [0, 2, 0.5, 0.5],
    ],
  });

  expect(cells[0]).toBe("#123456");
  expect(cells[1]).toBe("#fedcba");
  expect(cells[2]).toBe("#123456");
  expect(cells[3]).toBe("#fedcba");
  expect(cells[4]).toBe("#123456");
  expect(cells[5]).toBe("#fedcba");
});

test("text layer renders text with foreground and background colors", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/text-layer.pop", {
    autoPlay: true,
  });

  await playerApi.events.waitFor("ended");
  await expectTermText(page, "H");

  const fg = "#123456";
  const bg = "#fedcba";

  const { cells } = await sampleTerminalPixels(page, {
    cells: [
      [0, 0, 0.2, 0.5], // H stem: foreground text
      [0, 0, 0.5, 0.35], // H counter: background
      [0, 1, 0.5, 0.5], // styled space: background
    ],
  });

  expect(cells[0]).toBe(fg);
  expect(cells[1]).toBe(bg);
  expect(cells[2]).toBe(bg);
});

test("basic Powerline symbols render as SVG shapes", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/powerline-basic-symbols.pop", {
    autoPlay: true,
  });

  await playerApi.events.waitFor("ended");

  const fg = "#123456";
  const bg = "#fedcba";

  const { cells } = await sampleTerminalPixels(page, {
    cells: [
      [0, 0, 0.25, 0.5], // U+E0B0 right triangle: fill
      [0, 0, 0.75, 0.1], // U+E0B0 right triangle: background
      [0, 1, 0.5, 0.25], // U+E0B1 right bracket: stroke
      [0, 1, 0.5, 0.5], // U+E0B1 right bracket: background
      [0, 2, 0.75, 0.5], // U+E0B2 left triangle: fill
      [0, 2, 0.25, 0.1], // U+E0B2 left triangle: background
      [0, 3, 0.5, 0.25], // U+E0B3 left bracket: stroke
      [0, 3, 0.5, 0.5], // U+E0B3 left bracket: background
    ],
  });

  expect(cells[0]).toBe(fg);
  expect(cells[1]).toBe(bg);
  expect(cells[2]).not.toBe(bg);
  expect(cells[3]).toBe(bg);
  expect(cells[4]).toBe(fg);
  expect(cells[5]).toBe(bg);
  expect(cells[6]).not.toBe(bg);
  expect(cells[7]).toBe(bg);
});

test("powerline rounded symbols render as SVG shapes", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/powerline-rounded-symbols.pop", {
    autoPlay: true,
  });

  await playerApi.events.waitFor("ended");

  const expectedCodepoints = [0xe0b4, 0xe0b5, 0xe0b6, 0xe0b7];

  const renderedSymbols = await page.locator(".ap-term-symbols").evaluate((node) => {
    return {
      defs: [...node.querySelectorAll("symbol")].map((symbol) => symbol.id),
      uses: [...node.querySelectorAll("use")].map((use) => use.getAttribute("href")),
    };
  });

  for (const codepoint of expectedCodepoints) {
    expect(renderedSymbols.defs).toContain(`sym-${codepoint}`);
    expect(renderedSymbols.uses).toContain(`#sym-${codepoint}`);
  }

  const fg = "#123456";
  const bg = "#fedcba";

  const { cells } = await sampleTerminalPixels(page, {
    cells: [
      [0, 0, 0.75, 0.5], // U+E0B4 right rounded cap: fill
      [0, 0, 0.9, 0.05], // U+E0B4 right rounded cap: background
      [0, 1, 0.99, 0.5], // U+E0B5 right rounded cap: stroke
      [0, 1, 0.5, 0.5], // U+E0B5 right rounded cap: background
      [0, 2, 0.25, 0.5], // U+E0B6 left rounded cap: fill
      [0, 2, 0.1, 0.05], // U+E0B6 left rounded cap: background
      [0, 3, 0.5, 0.5], // U+E0B7 left rounded cap: background
    ],
  });

  expect(cells[0]).toBe(fg);
  expect(cells[1]).toBe(bg);
  expect(cells[2]).not.toBe(bg);
  expect(cells[3]).toBe(bg);
  expect(cells[4]).toBe(fg);
  expect(cells[5]).toBe(bg);
  expect(cells[6]).toBe(bg);
});

test("powerline extra symbols render as SVG shapes", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/powerline-extra-symbols.pop", {
    autoPlay: true,
  });

  await playerApi.events.waitFor("ended");

  const expectedCodepoints = [0xe0b8, 0xe0b9, 0xe0ba, 0xe0bb, 0xe0bc, 0xe0bd, 0xe0be, 0xe0bf];
  await expect(page.locator(".ap-term-symbols symbol")).toHaveCount(expectedCodepoints.length);

  const renderedSymbols = await page.locator(".ap-term-symbols").evaluate((node) => {
    return {
      defs: [...node.querySelectorAll("symbol")].map((symbol) => symbol.id),
      uses: [...node.querySelectorAll("use")].map((use) => use.getAttribute("href")),
    };
  });

  for (const codepoint of expectedCodepoints) {
    expect(renderedSymbols.defs).toContain(`sym-${codepoint}`);
    expect(renderedSymbols.uses).toContain(`#sym-${codepoint}`);
  }

  const fg = "#123456";
  const bg = "#fedcba";

  const { cells } = await sampleTerminalPixels(page, {
    cells: [
      [0, 0, 0.25, 0.75], // U+E0B8 lower-left triangle: fill
      [0, 0, 0.75, 0.25], // U+E0B8 lower-left triangle: background
      [0, 1, 0.5, 0.5], // U+E0B9 backslash separator: stroke
      [0, 2, 0.75, 0.75], // U+E0BA lower-right triangle: fill
      [0, 2, 0.25, 0.25], // U+E0BA lower-right triangle: background
      [0, 3, 0.5, 0.5], // U+E0BB forwardslash separator: stroke
      [0, 4, 0.25, 0.25], // U+E0BC upper-left triangle: fill
      [0, 4, 0.75, 0.75], // U+E0BC upper-left triangle: background
      [0, 5, 0.5, 0.5], // U+E0BD forwardslash separator: stroke
      [0, 6, 0.75, 0.25], // U+E0BE upper-right triangle: fill
      [0, 6, 0.25, 0.75], // U+E0BE upper-right triangle: background
      [0, 7, 0.5, 0.5], // U+E0BF backslash separator: stroke
    ],
  });

  expect(cells[0]).toBe(fg);
  expect(cells[1]).toBe(bg);
  expect(cells[2]).not.toBe(bg);
  expect(cells[3]).toBe(fg);
  expect(cells[4]).toBe(bg);
  expect(cells[5]).not.toBe(bg);
  expect(cells[6]).toBe(fg);
  expect(cells[7]).toBe(bg);
  expect(cells[8]).not.toBe(bg);
  expect(cells[9]).toBe(fg);
  expect(cells[10]).toBe(bg);
  expect(cells[11]).not.toBe(bg);
});

test("raster symbol groups render representative glyphs with expected pixels", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/raster-symbol-groups.pop", {
    autoPlay: true,
    theme: "dracula",
  });

  await playerApi.events.waitFor("ended");

  const fg = "#f8f8f2";
  const bg = "#282a36";
  const topY = 5.5 / 24;
  const bottomY = 18.5 / 24;

  const { cells } = await sampleTerminalPixels(page, {
    cells: [
      [0, 0, 0.5625, 0.5], // U+2503 heavy vertical: right stroke
      [0, 0, 0.4375, 0.5], // U+2503 heavy vertical: left stroke
      [0, 0, 0.3125, 0.5], // U+2503 heavy vertical: side background
      [0, 1, 0.4375, topY], // U+2579 heavy up: left top stroke
      [0, 1, 0.5625, topY], // U+2579 heavy up: right top stroke
      [0, 1, 0.5625, bottomY], // U+2579 heavy up: bottom background
      [0, 2, 0.5625, topY], // U+257B heavy down: top background
      [0, 2, 0.4375, bottomY], // U+257B heavy down: left bottom stroke
      [0, 2, 0.5625, bottomY], // U+257B heavy down: right bottom stroke
      [0, 3, 0.5, topY], // U+2580 upper half block: top fill
      [0, 3, 0.5, bottomY], // U+2580 upper half block: bottom background
      [0, 4, 0.25, 0.25], // U+259A quadrant: upper-left fill
      [0, 4, 0.75, 0.25], // U+259A quadrant: upper-right background
      [0, 4, 0.25, 0.75], // U+259A quadrant: lower-left background
      [0, 4, 0.75, 0.75], // U+259A quadrant: lower-right fill
      [0, 5, 0.5, 2.5 / 24], // U+25A0 black square: top background
      [0, 5, 0.5, 11.5 / 24], // U+25A0 black square: middle fill
      [0, 5, 0.5, 21.5 / 24], // U+25A0 black square: bottom background
      [0, 6, 0.25, 4.5 / 24], // U+1FB00 sextant-1: top-left fill
      [0, 6, 0.75, 4.5 / 24], // U+1FB00 sextant-1: top-right background
      [0, 6, 0.25, 12.5 / 24], // U+1FB00 sextant-1: middle-left background
    ],
  });

  expect(cells).toEqual([
    fg,
    fg,
    bg,
    fg,
    fg,
    bg,
    bg,
    fg,
    fg,
    fg,
    bg,
    fg,
    bg,
    bg,
    fg,
    bg,
    fg,
    bg,
    fg,
    bg,
    bg,
  ]);
});

test("automatic embedded theme", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/theme.pop", {
    autoPlay: true,
  });

  await playerApi.events.waitFor("ended");

  const embeddedTheme = {
    fg: "#fafafa",
    bg: "#bababa",
    palette: [
      "#000000",
      "#111111",
      "#222222",
      "#333333",
      "#444444",
      "#555555",
      "#666666",
      "#777777",
      "#888888",
      "#999999",
      "#aaaaaa",
      "#bbbbbb",
      "#cccccc",
      "#dddddd",
      "#eeeeee",
      "#ffffff",
    ],
  };

  const expectedColors = buildThemeSamples(embeddedTheme);

  const { cells, border } = await sampleTerminalPixels(page, {
    cells: expectedColors,
    border: true,
  });

  expect(border).toBe("#bababa");

  for (let i = 0; i < expectedColors.length; i += 1) {
    expect(cells[i]).toBe(expectedColors[i][4]);
  }
});

test("fixed 256 color palette by default", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/theme-256.pop", {
    autoPlay: true,
  });

  await playerApi.events.waitFor("ended");

  const expectedColors = [
    "#000000", // 16
    "#0000ff", // 21
    "#00ff00", // 46
    "#00ffff", // 51
    "#ff0000", // 196
    "#ff00ff", // 201
    "#ffff00", // 226
    "#ffffff", // 231
    "#878787", // 102
    "#afafaf", // 145
    "#080808", // 232
    "#767676", // 243
    "#eeeeee", // 255
  ];

  const samples = [];

  for (let col = 0; col < expectedColors.length; col += 1) {
    samples.push([0, col, 0.5, 0.5, expectedColors[col]]);
    samples.push([1, col, 0.5, 0.5, expectedColors[col]]);
  }

  const { cells } = await sampleTerminalPixels(page, { cells: samples });

  for (let i = 0; i < samples.length; i += 1) {
    expect(cells[i]).toBe(samples[i][4]);
  }
});

test("generated 256 color palette with adaptivePalette enabled", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/theme-256.pop", {
    autoPlay: true,
    adaptivePalette: true,
  });

  await playerApi.events.waitFor("ended");

  const expectedColors = [
    "#282a36", // 16
    "#bd93f9", // 21
    "#50fa7b", // 46
    "#8be9fd", // 51
    "#ff5555", // 196
    "#ff79c6", // 201
    "#f1fa8c", // 226
    "#f8f8f2", // 231
    "#ab9c99", // 102
    "#d1c1bc", // 145
    "#2f313d", // 232
    "#84868b", // 243
    "#efefea", // 255
  ];

  const samples = [];

  for (let col = 0; col < expectedColors.length; col += 1) {
    samples.push([0, col, 0.5, 0.5, expectedColors[col]]);
    samples.push([1, col, 0.5, 0.5, expectedColors[col]]);
  }

  const { cells } = await sampleTerminalPixels(page, { cells: samples });

  for (let i = 0; i < samples.length; i += 1) {
    expect(cells[i]).toBe(samples[i][4]);
  }
});

test("explicit theme", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/theme.pop", {
    autoPlay: true,
    theme: "dracula",
  });

  await playerApi.events.waitFor("ended");

  const draculaTheme = {
    fg: "#f8f8f2",
    bg: "#282a36",
    palette: [
      "#21222c",
      "#ff5555",
      "#50fa7b",
      "#f1fa8c",
      "#bd93f9",
      "#ff79c6",
      "#8be9fd",
      "#f8f8f2",
      "#6272a4",
      "#ff6e6e",
      "#69ff94",
      "#ffffa5",
      "#d6acff",
      "#ff92df",
      "#a4ffff",
      "#ffffff",
    ],
  };

  const expectedColors = buildThemeSamples(draculaTheme);

  const { cells, border } = await sampleTerminalPixels(page, {
    cells: expectedColors,
    border: true,
  });

  expect(border).toBe("#282a36");

  for (let i = 0; i < expectedColors.length; i += 1) {
    expect(cells[i]).toBe(expectedColors[i][4]);
  }
});
