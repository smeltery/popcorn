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

// --- audio buffering ---

test("audio waiting during playback emits loading and resumes on playing", async () => {
  const restoreAudio = installFakeAudio();
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      source([
        [10, "m", "start"],
        [200, "m", "later"],
      ]),
      {
        logger: stubLogger(),
        dispatch: recorder.dispatch,
      },
      { speed: 1, audioUrl: "/assets/fake.mp3" },
    );

    const marker = recorder.waitFor("marker");
    await driver.play();
    await marker;

    const loading = recorder.waitFor("loading");
    fakeAudioState.lastAudio.dispatch("waiting");
    await loading;
    const ended = recorder.waitFor("ended");
    fakeAudioState.lastAudio.dispatch("playing");
    await ended;

    expect(recorder.eventsNamed("loading")).toHaveLength(1);
    expect(recorder.eventsNamed("playing")).toHaveLength(2);

    expect(recorder.eventsNamed("marker")).toEqual([
      { name: "marker", payload: { index: 0, time: 0.01, label: "start" } },
      { name: "marker", payload: { index: 1, time: 0.2, label: "later" } },
    ]);
  } finally {
    restoreAudio();
  }
});

test("seek while buffering returns false and does not emit seeked", async () => {
  const restoreAudio = installFakeAudio();
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      source([
        [10, "m", "start"],
        [200, "m", "later"],
      ]),
      {
        logger: stubLogger(),
        dispatch: recorder.dispatch,
      },
      { speed: 1, audioUrl: "/assets/fake.mp3" },
    );

    await driver.play();
    await recorder.waitFor("marker");

    const loading = recorder.waitFor("loading");
    fakeAudioState.lastAudio.dispatch("waiting");
    await loading;

    const bufferedTime = driver.getCurrentTime();
    const seekedCount = recorder.eventsNamed("seeked").length;
    const result = await driver.seek(0.15);

    expect(result).toBe(false);
    expect(recorder.eventsNamed("seeked")).toHaveLength(seekedCount);
    expect(driver.getCurrentTime()).toBeCloseTo(bufferedTime, 2);
  } finally {
    restoreAudio();
  }
});

test("pause while buffering prevents automatic resume", async () => {
  const restoreAudio = installFakeAudio();
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      source([
        [10, "m", "start"],
        [200, "m", "later"],
      ]),
      {
        logger: stubLogger(),
        dispatch: recorder.dispatch,
      },
      { speed: 1, audioUrl: "/assets/fake.mp3" },
    );

    const marker = recorder.waitFor("marker");
    await driver.play();
    await marker;

    const loading = recorder.waitFor("loading");
    fakeAudioState.lastAudio.dispatch("waiting");
    await loading;

    const pausedTime = driver.getCurrentTime();
    const playingCount = recorder.eventsNamed("playing").length;
    driver.pause();
    fakeAudioState.lastAudio.dispatch("playing");

    expect(recorder.eventsNamed("playing")).toHaveLength(playingCount);

    expect(recorder.eventsNamed("marker")).toEqual([
      { name: "marker", payload: { index: 0, time: 0.01, label: "start" } },
    ]);

    expect(driver.getCurrentTime()).toBeCloseTo(pausedTime, 2);

    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(recorder.eventsNamed("marker")).toEqual([
      { name: "marker", payload: { index: 0, time: 0.01, label: "start" } },
      { name: "marker", payload: { index: 1, time: 0.2, label: "later" } },
    ]);
  } finally {
    restoreAudio();
  }
});

test("play during buffering keeps recovery event and clears waiting timeout", async () => {
  const restoreAudio = installFakeAudio();
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      source([
        [10, "m", "start"],
        [200, "m", "later"],
      ]),
      {
        logger: stubLogger(),
        dispatch: recorder.dispatch,
      },
      { speed: 1, audioUrl: "/assets/fake.mp3" },
    );

    const marker = recorder.waitFor("marker");
    await driver.play();
    await marker;
    fakeAudioState.lastAudio.dispatch("waiting");

    driver.pause();
    await driver.play();
    const playing = recorder.waitFor("playing");
    fakeAudioState.lastAudio.dispatch("playing");
    await playing;
    await wait(1100);

    expect(recorder.eventsNamed("play")).toHaveLength(2);
    expect(recorder.eventsNamed("playing")).toHaveLength(2);
    expect(recorder.eventsNamed("loading")).toHaveLength(0);
  } finally {
    restoreAudio();
  }
});
