import { test, expect } from "@playwright/test";

import {
  createPlayer,
  failOnPageError,
  expectCurrentTime,
  expectDuration,
  expectTermText,
  clickProgressBar,
  focusPlayer,
  setPlayerContainerSize,
  expectTermSize,
} from "./helpers.js";

test.beforeEach(async ({ page }) => {
  await failOnPageError(page);
});

test("initializes successfully and mounts in DOM", async ({ page }) => {
  await createPlayer(page, "/assets/simple.pop");

  const created = await page.evaluate(() => window.player !== null);
  expect(created).toBe(true);

  const player = page.locator(".ap-player");
  await expect(player).toBeVisible();

  const terminal = page.locator(".ap-term");
  await expect(terminal).toBeVisible();

  const controlBar = page.locator(".ap-control-bar");
  await expect(controlBar).toBeVisible();

  const hasApiMethods = await page.evaluate(() => {
    const player = window.player;

    return (
      typeof player.play === "function" &&
      typeof player.pause === "function" &&
      typeof player.seek === "function" &&
      typeof player.getCurrentTime === "function" &&
      typeof player.getDuration === "function" &&
      typeof player.dispose === "function"
    );
  });

  expect(hasApiMethods).toBe(true);
});

test("starts playback when start overlay is clicked", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/simple.pop");

  const startOverlay = page.locator(".ap-overlay-start");
  await expect(startOverlay).toBeVisible();

  await startOverlay.click();
  await playerApi.events.waitFor("playing");

  await expect(startOverlay).toBeHidden();
});

test("API play/pause emits play, playing, and pause events", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/simple.pop");

  await playerApi.play();
  await playerApi.events.expectNext("play");
  await playerApi.events.expectNext("playing");

  await playerApi.pause();
  await playerApi.events.expectNext("pause");
});

test("API seek jumps to a marker index", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/markers.pop");

  await playerApi.seek({ marker: 1 });

  await expectCurrentTime(playerApi).toBeCloseTo(1.1);
});

test("playback button toggles play/pause", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/simple.pop");

  const playbackButton = page.locator(".ap-playback-button");
  await expect(playbackButton).toBeVisible();

  await playbackButton.click();
  await playerApi.events.waitFor("playing");

  await playbackButton.click();
  await playerApi.events.waitFor("pause");
});

test("progress bar click seeks to a new position", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/simple.pop");

  await clickProgressBar(page, 0.75);
  await expectCurrentTime(playerApi).toBeCloseTo(9, 1);
});

test("autoplay starts playback without user interaction", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/simple.pop", { autoPlay: true });
  await playerApi.events.waitFor("playing");
});

test("segmented source loads through Core and fetches segments on demand", async ({ page }) => {
  const requests = [];

  const payloads = {
    "/recording/index.json": {
      version: 1,
      duration: 0.04,
      term: { cols: 80, rows: 24 },
      segments: [
        { url: "0.json", start: 0 },
        { url: "1.json", start: 0.02 },
      ],
    },

    "/recording/0.json": {
      snapshot: { cols: 80, rows: 24, init: "" },
      events: [[0.01, "o", "first"]],
    },

    "/recording/1.json": {
      snapshot: { cols: 80, rows: 24, init: "first" },
      events: [
        [0.02, "o", "last"],
        [0.04, "r", "80x24"],
      ],
    },
  };

  await page.route("**/recording/*.json", async (route) => {
    const path = new URL(route.request().url()).pathname;
    requests.push(path);
    await route.fulfill({ json: payloads[path] });
  });

  const playerApi = await createPlayer(
    page,
    { url: "/recording/index.json", format: "segmented" },
    { preload: true },
  );

  await expectDuration(playerApi).toBe(0.04);
  expect(requests).toEqual(["/recording/index.json", "/recording/0.json"]);

  await playerApi.play();
  await playerApi.events.waitFor("ended");

  expect(requests).toEqual(["/recording/index.json", "/recording/0.json", "/recording/1.json"]);
  await expectTermText(page, ["first", "last"]);
});

test("invalid preload data emits error without an unhandled rejection", async ({ page }) => {
  const playerApi = await createPlayer(page, { data: {} }, { preload: true });

  const event = await playerApi.events.waitFor("error");

  expect(event.payload).toEqual({
    name: "Error",
    message: "invalid data",
  });
});

test("resizes terminal view when the container changes size", async ({ page }) => {
  await createPlayer(page, "/assets/simple.pop");

  await setPlayerContainerSize(page, 800, 500);
  const terminal = page.locator(".ap-term");
  await terminal.waitFor();
  const initialBox = await terminal.boundingBox();
  expect(initialBox).not.toBeNull();

  await setPlayerContainerSize(page, 420, 320);

  await expect
    .poll(async () => (await terminal.boundingBox())?.width ?? 0)
    .toBeLessThan(initialBox.width - 20);

  await expect
    .poll(async () => (await terminal.boundingBox())?.height ?? 0)
    .toBeLessThan(initialBox.height - 20);
});

test("resizes terminal grid when the session window changes size", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/resizing.pop");
  const terminal = page.locator(".ap-term");
  await terminal.waitFor();

  await expectTermSize(terminal, 80, 24);

  await playerApi.play();
  await expectTermSize(terminal, 100, 30);
  await expectTermSize(terminal, 50, 10);
});

test("keyboard space toggles play/pause", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/simple.pop");
  await focusPlayer(page);

  await page.keyboard.press("Space");
  await playerApi.events.waitFor("playing");

  await page.keyboard.press("Space");
  await playerApi.events.waitFor("pause");
});

test("arrow key shortcuts seek by seconds and percentages", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/long.pop");
  await focusPlayer(page);

  await page.keyboard.press("ArrowRight");
  await expectCurrentTime(playerApi).toBeGreaterThanOrEqual(4.5);

  await page.keyboard.press("Shift+ArrowRight");
  await expectCurrentTime(playerApi).toBeGreaterThanOrEqual(5.5);

  await page.keyboard.press("ArrowLeft");
  await expectCurrentTime(playerApi).toBeLessThanOrEqual(1.5);

  await page.keyboard.press("Shift+ArrowLeft");
  await expectCurrentTime(playerApi).toBeLessThanOrEqual(0.5);
});

test("keyboard seek shortcuts jump to markers and percentages", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/markers.pop");
  await focusPlayer(page);

  await page.keyboard.press("]");
  await expectCurrentTime(playerApi).toBeCloseTo(0.5);

  await page.keyboard.press("]");
  await expectCurrentTime(playerApi).toBeCloseTo(1.1);

  await page.keyboard.press("[");
  await expectCurrentTime(playerApi).toBeCloseTo(0.5);

  await page.keyboard.press("5");
  await expectCurrentTime(playerApi).toBeCloseTo(1.0);
});

test("help overlay toggles with keyboard shortcuts", async ({ page }) => {
  await createPlayer(page, "/assets/simple.pop");
  await focusPlayer(page);
  const helpOverlay = page.locator(".ap-overlay-help");

  await page.keyboard.press("?");
  await expect(helpOverlay).toBeVisible();

  await page.keyboard.press("Escape");
  await expect(helpOverlay).toBeHidden();

  await page.keyboard.press("?");
  await expect(helpOverlay).toBeVisible();

  await page.keyboard.press("?");
  await expect(helpOverlay).toBeHidden();
});
