import { expect } from "@playwright/test";

const PLAYER_EVENTS = ["play", "playing", "pause", "ended", "error", "input", "marker"];

export async function createPlayer(page, src, opts = {}) {
  await page.goto("/index.html");

  await page.evaluate(
    ({ src, opts, eventNames }) => {
      window.__events = [];
      window.__eventIndex = 0;
      window.__eventWaiter = null;

      window.__pushEvent = (event) => {
        window.__events.push(event);

        if (window.__eventWaiter) {
          const resolve = window.__eventWaiter;
          window.__eventWaiter = null;
          resolve(window.__events[window.__eventIndex]);
          window.__eventIndex += 1;
        }
      };

      window.__nextEvent = () => {
        if (window.__events.length > window.__eventIndex) {
          const event = window.__events[window.__eventIndex];
          window.__eventIndex += 1;
          return Promise.resolve(event);
        }

        return new Promise((resolve) => {
          window.__eventWaiter = resolve;
        });
      };

      window.player = PopcornPlayer.create(src, document.getElementById("player"), opts);

      eventNames.forEach((name) => {
        window.player.addEventListener(name, (payload) => {
          window.__pushEvent({ name, payload: payload ?? null });
        });
      });
    },
    { src, opts, eventNames: PLAYER_EVENTS },
  );

  const events = createEventStream(page);

  return {
    events,
    play: () => page.evaluate(() => window.player.play()),
    pause: () => page.evaluate(() => window.player.pause()),
    seek: (where) => page.evaluate((where) => window.player.seek(where), where),
    getCurrentTime: () => page.evaluate(() => window.player.getCurrentTime()),
    getDuration: () => page.evaluate(() => window.player.getDuration()),
  };
}

export function createEventStream(page) {
  return {
    async next() {
      return await page.evaluate(() => window.__nextEvent());
    },

    async expectNext(name) {
      const event = await this.next();
      expect(event.name).toBe(name);
      return event;
    },

    async collect(predicate) {
      const shouldStop =
        typeof predicate === "function" ? predicate : (event) => event.name === "ended";

      const collected = [];

      while (true) {
        const event = await this.next();
        collected.push(event);
        if (shouldStop(event)) {
          return collected;
        }
      }
    },

    async waitFor(name) {
      while (true) {
        const event = await this.next();

        if (!name || event.name === name) {
          return event;
        }
      }
    },
  };
}

export function expectCurrentTime(player, timeout = 1000) {
  return expect.poll(() => player.getCurrentTime(), { timeout });
}

export function expectDuration(player) {
  return expect.poll(() => player.getDuration(), { timeout: 1000 });
}

export function expectTermSize(terminal, cols, rows) {
  return expect
    .poll(async () => {
      return await terminal.evaluate((node) => {
        const style = getComputedStyle(node);
        const cols = Number.parseInt(style.getPropertyValue("--term-cols"), 10);
        const rows = Number.parseInt(style.getPropertyValue("--term-rows"), 10);
        return { cols, rows };
      });
    })
    .toEqual({ cols, rows });
}

export async function expectTermText(page, fragments, timeout = 1000) {
  const termText = page.locator(".ap-term-text");
  await termText.waitFor();
  const expected = Array.isArray(fragments) ? fragments : [fragments];

  await expect
    .poll(
      async () => {
        const text = await termText.innerText();
        return expected.every((fragment) => text.includes(fragment));
      },
      { timeout },
    )
    .toBe(true);
}

export async function clickProgressBar(page, position) {
  const bar = page.locator(".ap-bar");
  await bar.waitFor();
  const box = await bar.boundingBox();
  expect(box).not.toBeNull();

  await bar.click({ position: { x: box.width * position, y: box.height / 2 } });
}

export async function focusPlayer(page) {
  await page.evaluate(() => {
    document.querySelector(".ap-wrapper")?.focus();
  });
}

export async function waitForInputEvents(playerApi, count) {
  for (let i = 0; i < count; i += 1) {
    await playerApi.events.waitFor("input");
  }
}

export async function setPlayerContainerSize(page, width, height) {
  await page.evaluate(
    ({ width, height }) => {
      const container = document.getElementById("player");
      container.style.width = `${width}px`;
      container.style.height = `${height}px`;
    },
    { width, height },
  );
}

export async function sampleTerminalPixels(page, options = {}) {
  const { cells = [], border = false } = options;

  const term = page.locator(".ap-term");
  await term.waitFor();
  const buffer = await term.screenshot({ type: "png" });
  const dataUrl = `data:image/png;base64,${buffer.toString("base64")}`;

  return await term.evaluate(
    async (node, { dataUrl, cells, border }) => {
      const style = getComputedStyle(node);
      const rect = node.getBoundingClientRect();
      const img = new Image();

      const loaded = new Promise((resolve, reject) => {
        img.onload = () => resolve();
        img.onerror = () => reject(new Error("Failed to decode screenshot"));
      });

      img.src = dataUrl;
      await loaded;

      const canvas = document.createElement("canvas");
      canvas.width = img.width;
      canvas.height = img.height;

      const ctx = canvas.getContext("2d");
      if (!ctx) throw new Error("2D ctx not available");
      ctx.drawImage(img, 0, 0);

      const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
      const scaleX = img.width / rect.width;
      const scaleY = img.height / rect.height;
      const borderLeft = (Number.parseFloat(style.borderLeftWidth) || 0) * scaleX;
      const borderTop = (Number.parseFloat(style.borderTopWidth) || 0) * scaleY;

      const toHex = (value) => value.toString(16).padStart(2, "0");
      const rgbToHex = (r, g, b) => `#${toHex(r)}${toHex(g)}${toHex(b)}`;

      const samplePixel = (px, py) => {
        const ix = Math.max(0, Math.min(canvas.width - 1, Math.floor(px)));
        const iy = Math.max(0, Math.min(canvas.height - 1, Math.floor(py)));
        const idx = (iy * canvas.width + ix) * 4;
        const r = imgData[idx];
        const g = imgData[idx + 1];
        const b = imgData[idx + 2];
        return rgbToHex(r, g, b);
      };

      let sampledCells = [];

      if (cells.length > 0) {
        const cols = Number.parseInt(style.getPropertyValue("--term-cols"), 10);
        const rows = Number.parseInt(style.getPropertyValue("--term-rows"), 10);
        const borderRight = (Number.parseFloat(style.borderRightWidth) || 0) * scaleX;
        const borderBottom = (Number.parseFloat(style.borderBottomWidth) || 0) * scaleY;
        const contentWidth = img.width - borderLeft - borderRight;
        const contentHeight = img.height - borderTop - borderBottom;
        const cellWidth = contentWidth / cols;
        const cellHeight = contentHeight / rows;

        sampledCells = cells.map((sample) => {
          const [row, col, x, y] = sample;
          const px = borderLeft + (col + x) * cellWidth;
          const py = borderTop + (row + y) * cellHeight;
          return samplePixel(px, py);
        });
      }

      let borderColor = null;

      if (border) {
        const px = Math.max(0, borderLeft / 2);
        const py = img.height / 2;
        borderColor = samplePixel(px, py);
      }

      return { cells: sampledCells, border: borderColor };
    },
    { dataUrl, cells, border },
  );
}

export async function waitForCellColor(page, cell, color) {
  for (let i = 0; i < 15; i += 1) {
    const { cells } = await sampleTerminalPixels(page, { cells: [cell] });

    if (cells[0] === color) {
      return true;
    }

    await page.waitForTimeout(200);
  }

  return false;
}

export function buildThemeSamples(theme) {
  const samples = [];

  for (let color = 0; color < 16; color += 1) {
    for (let offset = 0; offset < 3; offset += 1) {
      const col = color * 3 + offset;
      samples.push([0, col, 0.8, 0.1, theme.bg]);
      samples.push([0, col, 0.5, 0.5, theme.palette[color]]);
      samples.push([1, col, 0.8, 0.1, theme.palette[color]]);
      samples.push([1, col, 0.5, 0.5, theme.fg]);
    }
  }

  return samples;
}

export async function failOnPageError(page) {
  await page.addInitScript(() => {
    window.addEventListener("unhandledrejection", (event) => {
      setTimeout(() => {
        // Re-throw asynchronously so Firefox reports it via pageerror with a browser stack.
        throw event.reason;
      });
    });
  });

  page.on("pageerror", (error) => {
    throw error;
  });

  page.on("crash", () => {
    throw new Error("Page crashed.");
  });
}
