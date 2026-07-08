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

// --- resize ---

test("resize events dispatch numeric terminal dimensions", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([[100, "r", "100x30"]]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  await driver.seek(1);

  expect(recorder.events).toContainEqual({
    name: "resize",
    payload: { cols: 100, rows: 30 },
  });
});

test("size overrides pin terminal dimensions over in-stream resizes", async () => {
  const bothRecorder = createDispatchRecorder();

  const bothDriver = recording(
    source([[100, "r", "100x30"]]),
    { logger: stubLogger(), dispatch: bothRecorder.dispatch },
    { speed: 1, cols: 120, rows: 40 },
  );

  await bothDriver.seek(1);

  // Both overrides set: the override wins over the recording's in-stream resize.
  expect(bothRecorder.eventsNamed("resize").at(-1).payload).toEqual({ cols: 120, rows: 40 });

  const colsRecorder = createDispatchRecorder();

  const colsDriver = recording(
    source([[100, "r", "100x30"]]),
    { logger: stubLogger(), dispatch: colsRecorder.dispatch },
    { speed: 1, cols: 120 },
  );

  await colsDriver.seek(1);

  // Only cols overridden: cols stays pinned while rows still follows the recording.
  expect(colsRecorder.eventsNamed("resize").at(-1).payload).toEqual({ cols: 120, rows: 30 });

  const rowsRecorder = createDispatchRecorder();

  const rowsDriver = recording(
    source([[100, "r", "100x30"]]),
    { logger: stubLogger(), dispatch: rowsRecorder.dispatch },
    { speed: 1, rows: 40 },
  );

  await rowsDriver.seek(1);

  // Only rows overridden: rows stays pinned while cols still follows the recording.
  expect(rowsRecorder.eventsNamed("resize").at(-1).payload).toEqual({ cols: 100, rows: 40 });
});
