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

// --- step ---

test("step advances across multiple output frames", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [100, "o", "start\r\n"],
      [1000, "o", "one\r\n"],
      [2000, "o", "two\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  await driver.step(2);

  expect(driver.getCurrentTime()).toBeCloseTo(1.0);
  expect(recorder.outputs.join("")).toContain("start");
  expect(recorder.outputs.join("")).toContain("one");
  expect(recorder.outputs.join("")).not.toContain("two");
});

test("step reverses across multiple output frames", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [100, "o", "start\r\n"],
      [1000, "o", "one\r\n"],
      [2000, "o", "two\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  await driver.step(3);
  recorder.outputs.length = 0;

  await driver.step(-2);

  expect(driver.getCurrentTime()).toBeCloseTo(0.1);
  expect(recorder.outputs).toEqual(["\x1bc", ["start\r\n"]]);
});

test("step to the last frame with loop emits ended and pins current time", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [10, "o", "start\r\n"],
      [200, "o", "end\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1, loop: true },
  );

  await driver.step(2);

  expect(driver.getCurrentTime()).toBe(driver.getDuration());
  expect(recorder.eventsNamed("ended")).toHaveLength(1);
});

test("step from cold state loads recording and steps", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [100, "o", "start\r\n"],
      [1000, "o", "one\r\n"],
      [2000, "o", "two\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  await driver.step(2);

  expect(recorder.outputs).toEqual([["start\r\n", "one\r\n"]]);
  expect(driver.getCurrentTime()).toBeCloseTo(1.0);
});
