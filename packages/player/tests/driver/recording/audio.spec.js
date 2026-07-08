import { test, expect } from "@playwright/test";
import recording from "../../../src/driver/recording.js";
import {
  createDispatchRecorder,
  fakeAudioState,
  installFakeAudio,
  recordingOutputs,
  requestCount,
  resolveFakeAudioPlay,
  source,
  stubEffectiveTimeFetch,
  stubFetch,
  stubLinearSegmentedFetch,
  stubLogger,
  stubSegmentedFetch,
  wait,
  waitForCondition,
  createGate,
} from "./helpers.js";

// --- mute ---

test("mute and unmute toggle audio and dispatch events", async () => {
  const restoreAudio = installFakeAudio();
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      source([[100, "o", "start\r\n"]]),
      {
        logger: stubLogger(),
        dispatch: recorder.dispatch,
      },
      { speed: 1, preload: true, audioUrl: "/assets/fake.mp3" },
    );

    await driver.init();

    expect(driver.mute()).toBe(true);
    expect(driver.unmute()).toBe(true);

    expect(recorder.eventsNamed("muted")).toEqual([
      { name: "muted", payload: true },
      { name: "muted", payload: false },
    ]);
  } finally {
    restoreAudio();
  }
});

test("mute and unmute are no-ops without audio", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([[100, "o", "start\r\n"]]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  await driver.init();

  expect(driver.mute()).toBeUndefined();
  expect(driver.unmute()).toBeUndefined();
  expect(recorder.eventsNamed("muted")).toHaveLength(0);
});

test("audio load failure falls back to playback without audio", async () => {
  const restoreAudio = installFakeAudio({ failLoad: true });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      source([[10, "o", "done"]]),
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true, audioUrl: "/missing.mp3" },
    );

    await driver.init();

    expect(recorder.eventsNamed("metadata")[0].payload.hasAudio).toBe(false);

    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(recorder.eventsNamed("playing")).toHaveLength(1);
    expect(recorder.eventsNamed("error")).toHaveLength(0);
  } finally {
    restoreAudio();
  }
});
