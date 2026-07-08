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

// --- play ---

test("play after text poster init loads recording and starts playback", async () => {
  const recorder = createDispatchRecorder();
  let parserCalls = 0;

  const driver = recording(
    {
      data: { cols: 80, rows: 24, events: [[10, "o", "start\r\n"]] },
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

  const ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  expect(parserCalls).toBe(1);

  expect(recorder.eventNames()).toEqual([
    "output",
    "output",
    "play",
    "metadata",
    "reset",
    "playing",
    "output",
    "ended",
  ]);

  expect(recorder.outputs[0]).toBe("hello world");
  expect(recorder.outputs[1]).toBe("\x1bc");
  expect(recorder.outputs[2]).toEqual(["start\r\n"]);
});

test("first play applies startAt before playback starts", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [100, "o", "zero\r\n"],
      [200, "o", "one\r\n"],
      [400, "o", "two\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    {
      speed: 1,
      startAt: 0.25,
    },
  );

  await driver.play();

  expect(recorder.outputs).toEqual([["zero\r\n", "one\r\n"]]);
  expect(driver.getCurrentTime()).toBeGreaterThanOrEqual(0.25);
  expect(driver.getCurrentTime()).toBeLessThan(0.4);
});

test("play after ended restarts from beginning", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [10, "o", "start\r\n"],
      [30, "o", "end\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  let ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  const firstRunOutputCount = recorder.outputs.length;
  expect(recorder.eventsNamed("ended")).toHaveLength(1);

  ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  expect(recorder.eventsNamed("play")).toHaveLength(2);
  expect(recorder.eventsNamed("playing")).toHaveLength(2);
  expect(recorder.eventsNamed("ended")).toHaveLength(2);

  expect(recorder.outputs.slice(firstRunOutputCount)).toEqual([
    "\x1bc",
    ["start\r\n"],
    ["end\r\n"],
  ]);
});

test("numeric loop plays exactly N times then ends", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [10, "o", "start\r\n"],
      [20, "o", "end\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1, loop: 2 },
  );

  const ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  expect(recorder.eventsNamed("ended")).toHaveLength(1);
  expect(recorder.outputs.filter((o) => o === "\x1bc")).toHaveLength(2);
});

test("play batches adjacent output events at runtime", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [1, "o", "hel"],
      [6, "o", "lo"],
      [11, "o", "!"],
      [30, "o", "?"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  const ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  expect(recorder.outputs).toEqual([["hel", "lo", "!"], ["?"]]);
});

test("playback dispatches input events", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [10, "i", "a"],
      [20, "i", "\r"],
      [30, "o", "done"],
    ]),
    { logger: stubLogger(), dispatch: recorder.dispatch },
    { speed: 1 },
  );

  const ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  expect(recorder.eventsNamed("input")).toEqual([
    { name: "input", payload: { data: "a" } },
    { name: "input", payload: { data: "\r" } },
  ]);
});
