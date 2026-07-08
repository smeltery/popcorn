import { test, expect } from "@playwright/test";

import { createPlayer, failOnPageError, waitForInputEvents } from "./helpers.js";

test.beforeEach(async ({ page }) => {
  await failOnPageError(page);
});

test("hides keystroke overlay by default", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/input.pop");

  await playerApi.play();
  await playerApi.events.collect();

  await expect(page.locator(".ap-overlay-keystrokes")).toHaveCount(0);
});

test("shows keystroke overlay when enabled", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/input.pop", { keystrokeOverlay: true });

  await playerApi.play();
  await playerApi.events.waitFor("input");

  await expect(page.locator(".ap-overlay-keystrokes kbd")).toHaveText(/^(a|Ret)$/);
});

test("positions keystroke overlay near lower right", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/input.pop", { keystrokeOverlay: true });

  await playerApi.play();
  await playerApi.events.waitFor("input");

  const playerBox = await page.locator(".ap-player").boundingBox();
  const overlayBox = await page.locator(".ap-overlay-keystrokes").boundingBox();

  expect(playerBox).not.toBeNull();
  expect(overlayBox).not.toBeNull();
  expect(overlayBox.width).toBeLessThan(playerBox.width / 2);
  expect(overlayBox.x).toBeGreaterThan(playerBox.x + playerBox.width * 0.6);
  expect(overlayBox.y).toBeGreaterThan(playerBox.y + playerBox.height * 0.5);
});

test("shows last four keystrokes in a right-anchored reel", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/keystroke-reel.pop", {
    keystrokeOverlay: true,
  });

  await playerApi.play();
  await waitForInputEvents(playerApi, 6);

  await expect(page.locator(".ap-overlay-keystrokes kbd")).toHaveText(["Ret", "c", "Esc", "d"]);

  const playerBox = await page.locator(".ap-player").boundingBox();
  const latestBox = await page.locator(".ap-overlay-keystrokes kbd").last().boundingBox();

  expect(playerBox).not.toBeNull();
  expect(latestBox).not.toBeNull();
  expect(latestBox.x + latestBox.width).toBeGreaterThan(playerBox.x + playerBox.width - 24);
});

test("groups text keystrokes into one pill", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/text-group-input.pop", {
    keystrokeOverlay: true,
  });

  await playerApi.play();
  await waitForInputEvents(playerApi, 13);

  await expect(page.locator(".ap-overlay-keystrokes kbd")).toHaveText(["cdefghijkl"]);
});

test("counts repeated special keystrokes in one pill", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/special-group-input.pop", {
    keystrokeOverlay: true,
  });

  await playerApi.play();
  await waitForInputEvents(playerApi, 3);

  await expect(page.locator(".ap-overlay-keystrokes kbd")).toHaveText(["Ret × 3"]);
});

test("keeps keystroke fade timers independent", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/repeated-input.pop", {
    keystrokeOverlay: true,
  });

  await playerApi.play();
  await playerApi.events.waitFor("input");

  const pills = page.locator(".ap-keystroke-pill");

  await expect(pills.first()).not.toHaveClass(/fading/);

  await playerApi.events.waitFor("input");

  await expect(pills).toHaveCount(2);
  await expect(pills.first()).not.toHaveClass(/fading/);
  await expect(pills.last()).not.toHaveClass(/fading/);
  await expect(page.locator(".ap-overlay-keystrokes kbd")).toHaveText(["a", "Ret"]);

  await expect(pills).toHaveCount(2);
  await expect(pills.first()).toHaveClass(/fading/, { timeout: 5000 });
  await expect(pills.last()).not.toHaveClass(/fading/);
});
