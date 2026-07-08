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

// --- init ---

test("init with text poster renders poster without loading recording", async () => {
  const recorder = createDispatchRecorder();
  let parserCalls = 0;

  const driver = recording(
    {
      data: { cols: 80, rows: 24, events: [[100, "o", "start\r\n"]] },
      parser: async (data) => {
        parserCalls++;
        return data;
      },
    },
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    {
      speed: 1,
      preload: false,
      poster: { type: "text", value: "hello world" },
    },
  );

  await driver.init();

  expect(parserCalls).toBe(0);
  expect(recorder.outputs).toEqual(["hello world"]);
  expect(recorder.eventsNamed("metadata")).toHaveLength(0);
  expect(recorder.eventsNamed("reset")).toHaveLength(0);
});

test("init with npt poster loads recording and renders poster frame", async () => {
  const recorder = createDispatchRecorder();
  let parserCalls = 0;

  const driver = recording(
    {
      data: {
        cols: 80,
        rows: 24,
        events: [
          [100, "o", "start\r\n"],
          [1000, "o", "one\r\n"],
        ],
      },
      parser: async (data) => {
        parserCalls++;
        return data;
      },
    },
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    {
      speed: 1,
      preload: false,
      poster: { type: "npt", value: 0.5 },
    },
  );

  await driver.init();

  expect(parserCalls).toBe(1);
  expect(recorder.eventNames()).toEqual(["metadata", "reset", "output"]);
  expect(recorder.outputs).toEqual([["start\r\n"]]);
});

test("step without a target frame preserves the initial poster", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [100, "o", "start\r\n"],
      [1000, "o", "one\r\n"],
    ]),
    { logger: stubLogger(), dispatch: recorder.dispatch },
    { speed: 1, poster: { type: "npt", value: 0.5 } },
  );

  await driver.init();
  await driver.step(-1);

  expect(recorder.outputs).toEqual([["start\r\n"]]);
  expect(driver.getCurrentTime()).toBeCloseTo(0.5);
});

test("init with preload and text poster loads immediately and still renders poster", async () => {
  const recorder = createDispatchRecorder();
  let parserCalls = 0;

  const driver = recording(
    {
      data: { cols: 80, rows: 24, events: [[100, "o", "start\r\n"]] },
      parser: async (data) => {
        parserCalls++;
        return data;
      },
    },
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    {
      speed: 1,
      preload: true,
      poster: { type: "text", value: "hello world" },
    },
  );

  await driver.init();

  expect(parserCalls).toBe(1);
  expect(recorder.eventNames()).toEqual(["metadata", "reset", "output"]);
  expect(recorder.outputs).toEqual(["hello world"]);
});

test("preload exposes duration before playback", async () => {
  const driver = recording(
    source([
      [100, "o", "start"],
      [500, "o", "end"],
    ]),
    { logger: stubLogger(), dispatch() {} },
    { speed: 1, preload: true },
  );

  await driver.init();

  expect(driver.getDuration()).toBe(0.5);
});
