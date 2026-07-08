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

// --- stop ---

test("stop during playback cancels scheduled progression", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [10, "m", "start"],
      [200, "m", "later"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  const marker = recorder.waitFor("marker");
  await driver.play();
  await marker;
  await driver.stop();

  await wait(250);

  expect(recorder.eventsNamed("marker")).toEqual([
    { name: "marker", payload: { index: 0, time: 0.01, label: "start" } },
  ]);

  expect(recorder.eventsNamed("ended")).toHaveLength(0);
});

test("stop tears down audio resources and pending waiting state", async () => {
  const restoreAudio = installFakeAudio();
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      source([[100, "o", "start\r\n"]]),
      {
        logger: stubLogger(),
        dispatch: recorder.dispatch,
      },
      { speed: 1, audioUrl: "/assets/fake.mp3" },
    );

    await driver.play();
    expect(recorder.eventsNamed("playing")).toHaveLength(1);

    fakeAudioState.lastAudio.dispatch("waiting");
    await driver.stop();
    await wait(1100);

    expect(recorder.eventsNamed("loading")).toHaveLength(0);
    expect(fakeAudioState.lastAudio.pauseCalls).toBeGreaterThan(0);
    expect(fakeAudioState.lastAudio.listeners.get("playing") ?? []).toHaveLength(0);
    expect(fakeAudioState.lastAudio.listeners.get("waiting") ?? []).toHaveLength(0);
    expect(fakeAudioState.closedContexts).toBe(1);
    expect(fakeAudioState.lastAudio.src).toBe("");
  } finally {
    restoreAudio();
  }
});
