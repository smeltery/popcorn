import { test, expect } from "@playwright/test";

import { createPlayer, failOnPageError, expectTermText } from "./helpers.js";

test.beforeEach(async ({ page }) => {
  await failOnPageError(page);
});

test("poster - npt", async ({ page }) => {
  await createPlayer(page, "/assets/long.pop", {
    poster: "npt:7",
  });

  await page.waitForTimeout(500);

  await expectTermText(page, ["start", "one", "six"]);
});

test("poster - data:text/plain - clears when playback starts", async ({ page }) => {
  const playerApi = await createPlayer(page, "/assets/long.pop", {
    poster: "data:text/plain,hello world",
  });

  await expectTermText(page, "hello world");

  await playerApi.play();
  await playerApi.events.waitFor("playing");
  await expectTermText(page, "start");

  await expect
    .poll(async () => {
      const text = await page.locator(".ap-term-text").innerText();
      return text.includes("hello world");
    })
    .toBe(false);
});
