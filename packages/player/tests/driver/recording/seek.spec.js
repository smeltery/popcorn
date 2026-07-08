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

// --- seek ---

test("seek to duration emits ended and pins current time", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [100, "o", "start\r\n"],
      [200, "o", "end\r\n"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  await driver.seek(999);

  expect(driver.getCurrentTime()).toBe(driver.getDuration());
  expect(recorder.eventsNamed("ended")).toHaveLength(1);
  expect(recorder.eventsNamed("seeked")).toHaveLength(1);
});

test("seek to duration with loop emits ended and pins current time", async () => {
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

  await driver.seek(999);

  expect(driver.getCurrentTime()).toBe(driver.getDuration());
  expect(recorder.eventsNamed("ended")).toHaveLength(1);
  expect(recorder.eventsNamed("seeked")).toHaveLength(1);
});

test("seek to duration during playback emits ended and pins current time", async () => {
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
    { speed: 1 },
  );

  const playing = recorder.waitFor("playing");
  await driver.play();
  await playing;
  await driver.seek(999);

  expect(driver.getCurrentTime()).toBe(driver.getDuration());
  expect(recorder.eventsNamed("ended")).toHaveLength(1);
  expect(recorder.eventsNamed("seeked")).toHaveLength(1);
});

test("seek from cold state loads recording and seeks", async () => {
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

  await driver.seek(0.5);

  expect(recorder.eventsNamed("seeked")).toHaveLength(1);
  expect(recorder.outputs).toEqual([["start\r\n"]]);
  expect(driver.getCurrentTime()).toBeCloseTo(0.5);
});

test("invalid seek target throws without failing the driver", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([[10, "o", "start\r\n"]]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  expect(() => driver.seek("wat")).toThrow('invalid seek target: "wat"');

  const ended = recorder.waitFor("ended");
  await driver.play();
  await ended;

  expect(recorder.eventsNamed("error")).toHaveLength(0);
  expect(recorder.eventsNamed("ended")).toHaveLength(1);
});

test("invalid marker seek rejects without failing the driver", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [100, "o", "start\r\n"],
      [200, "m", "chapter"],
    ]),
    {
      logger: stubLogger(),
      dispatch: recorder.dispatch,
    },
    { speed: 1 },
  );

  await expect(driver.seek({ marker: 1 })).rejects.toThrow("invalid marker index: 1");

  await driver.seek({ marker: 0 });

  expect(recorder.eventsNamed("error")).toHaveLength(0);
  expect(recorder.eventsNamed("seeked")).toHaveLength(1);
  expect(driver.getCurrentTime()).toBeCloseTo(0.2);
});
