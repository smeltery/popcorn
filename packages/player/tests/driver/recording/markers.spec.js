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

// --- pause & markers ---

test("pauseOnMarkers pauses playback and resumes on play", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [10, "o", "start\r\n"],
      [20, "m", "chapter"],
      [40, "o", "end\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1, pauseOnMarkers: true },
  );

  const paused = recorder.waitFor("pause");
  await driver.play();
  await paused;

  expect(recorder.eventsNamed("marker")).toEqual([
    { name: "marker", payload: { index: 0, time: 0.02, label: "chapter" } },
  ]);

  expect(recorder.eventsNamed("pause")).toHaveLength(1);
  expect(driver.getCurrentTime()).toBeCloseTo(0.02, 2);
  expect(recorder.outputs).toEqual([["start\r\n"]]);

  const ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  expect(recorder.outputs).toEqual([["start\r\n"], ["end\r\n"]]);
  expect(recorder.eventsNamed("ended")).toHaveLength(1);
});
