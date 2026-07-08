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

// --- segmented recordings ---

test("segmented init loads only the initial segment and playback prefetches the next", async () => {
  const requests = [];
  const restoreFetch = stubSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();

    expect(requests).toEqual(["/recording/index.json", "http://localhost/recording/0.json"]);

    expect(recorder.eventsNamed("metadata")[0].payload).toEqual({
      duration: 0.06,
      markers: [
        [0.02, "chapter"],
        [0.04, "summary"],
      ],
      hasAudio: false,
    });

    expect(recorder.eventsNamed("reset")[0].payload.init).toBe("first snapshot");

    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(requests).toEqual([
      "/recording/index.json",
      "http://localhost/recording/0.json",
      "http://localhost/recording/1.json",
    ]);

    expect(recorder.outputs).toEqual([["first"], ["last"]]);
    expect(recorder.eventsNamed("reset")).toHaveLength(1);
  } finally {
    restoreFetch();
  }
});

test("cold segmented seek loads the target segment directly and restores its snapshot", async () => {
  const requests = [];
  const restoreFetch = stubSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1 },
    );

    await driver.seek(0.04);

    expect(requests).toEqual(["/recording/index.json", "http://localhost/recording/1.json"]);
    expect(recorder.eventsNamed("reset")[0].payload.init).toBe("second snapshot");
    expect(recorder.outputs).toEqual([["last"]]);
    expect(driver.getCurrentTime()).toBeCloseTo(0.04);
  } finally {
    restoreFetch();
  }
});

test("segmented NPT poster loads only its containing segment", async () => {
  const requests = [];
  const restoreFetch = stubSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, poster: { type: "npt", value: 0.04 } },
    );

    await driver.init();

    expect(requests).toEqual(["/recording/index.json", "http://localhost/recording/1.json"]);
    expect(recorder.eventsNamed("reset")[0].payload.init).toBe("second snapshot");
    expect(recorder.outputs).toEqual([["last"]]);
  } finally {
    restoreFetch();
  }
});

test("segmented marker metadata and playback use global marker indexes", async () => {
  const requests = [];
  const restoreFetch = stubSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(recorder.eventsNamed("marker")).toEqual([
      {
        name: "marker",
        payload: { index: 0, time: 0.02, label: "chapter" },
      },
      {
        name: "marker",
        payload: { index: 1, time: 0.04, label: "summary" },
      },
    ]);
  } finally {
    restoreFetch();
  }
});

test("segmented recordings reject unsupported options", async () => {
  const requests = [];
  const restoreFetch = stubSegmentedFetch(requests);

  try {
    for (const [sourceOption, playerOption] of [
      ["parser", undefined],
      ["encoding", undefined],
      ["inputOffset", undefined],
      [undefined, "idleTimeLimit"],
      [undefined, "markers"],
    ]) {
      const src = { url: "/recording/index.json", format: "segmented" };
      const options = { speed: 1, preload: true };

      if (sourceOption) src[sourceOption] = sourceOption === "parser" ? () => {} : "value";
      if (playerOption) options[playerOption] = playerOption === "markers" ? [1] : 1;

      const driver = recording(src, { logger: stubLogger(), dispatch() {} }, options);
      await expect(driver.init()).rejects.toThrow("segmented recordings do not support option");
    }

    expect(requests).toEqual([]);
  } finally {
    restoreFetch();
  }
});

test("invalid segmented options do not start audio loading", async () => {
  const restoreAudio = installFakeAudio();

  const driver = recording(
    { url: "/recording/index.json", format: "segmented" },
    { logger: stubLogger(), dispatch() {} },
    {
      speed: 1,
      preload: true,
      idleTimeLimit: 1,
      audioUrl: "/audio.mp3",
    },
  );

  try {
    await expect(driver.init()).rejects.toThrow(
      "segmented recordings do not support option: idleTimeLimit",
    );

    expect(fakeAudioState.lastAudio).toBeUndefined();
  } finally {
    restoreAudio();
  }
});

test("pausing during a pending segment transition prevents automatic resume", async () => {
  const requests = [];
  const gate = createGate();
  const restoreFetch = stubSegmentedFetch(requests, { segmentOneGate: gate });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    await driver.play();
    await wait(40);

    expect(driver.getCurrentTime()).toBeCloseTo(0.03, 2);
    await driver.pause();
    gate.resolve();
    await wait(0);
    await wait(0);

    expect(recorder.eventsNamed("playing")).toHaveLength(1);
    expect(recorder.eventsNamed("loading")).toHaveLength(0);
    expect(recorder.outputs).toEqual([["first"]]);

    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(recorder.outputs).toEqual([["first"], ["last"]]);
  } finally {
    restoreFetch();
  }
});

test("required segment failures fail seek, step, and playback positioning", async () => {
  for (const operation of ["seek", "step", "play"]) {
    const requests = [];

    const restoreFetch = stubSegmentedFetch(requests, {
      failSegmentZero: operation === "play" ? 1 : 0,
      failSegmentOne: operation === "play" ? 0 : 1,
    });

    const recorder = createDispatchRecorder();

    try {
      const driver = recording(
        { url: "/recording/index.json", format: "segmented" },
        { logger: stubLogger(), dispatch: recorder.dispatch },
        operation === "play"
          ? { speed: 1, poster: { type: "npt", value: 0.04 } }
          : { speed: 1, preload: true },
      );

      await driver.init();

      const result =
        operation === "seek"
          ? driver.seek(0.04)
          : operation === "step"
            ? driver.step(2)
            : driver.play();

      await expect(result).rejects.toThrow("503 Unavailable");
      expect(recorder.eventsNamed("error")).toHaveLength(1);
      expect(() => driver.play()).toThrow("503 Unavailable");
    } finally {
      restoreFetch();
    }
  }
});

test("fatal boundary failure clears the delayed loading notification", async () => {
  const requests = [];
  const gate = createGate();

  const restoreFetch = stubSegmentedFetch(requests, {
    failSegmentOne: 1,
    segmentOneGate: gate,
  });

  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    await driver.play();
    await wait(40);
    gate.resolve();
    await wait(0);
    await wait(1100);

    expect(recorder.eventsNamed("error")).toHaveLength(1);
    expect(recorder.eventsNamed("loading")).toHaveLength(0);
  } finally {
    gate.resolve();
    restoreFetch();
  }
});

test("stale audio recovery does not resume a pending segment wait", async () => {
  const restoreAudio = installFakeAudio();
  const requests = [];
  const gate = createGate();
  const restoreFetch = stubSegmentedFetch(requests, { segmentOneGate: gate });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true, audioUrl: "/assets/fake.mp3" },
    );

    await driver.init();
    await driver.play();
    await wait(40);

    fakeAudioState.lastAudio.dispatch("playing");
    await wait(20);

    expect(driver.getCurrentTime()).toBeCloseTo(0.03, 2);
    expect(recorder.eventsNamed("playing")).toHaveLength(1);

    const ended = recorder.waitFor("ended");
    gate.resolve();
    await ended;

    expect(recorder.eventsNamed("playing")).toHaveLength(2);
  } finally {
    restoreFetch();
    restoreAudio();
  }
});

test("segment wait longer than one second dispatches loading once", async () => {
  const requests = [];
  const gate = createGate();
  const restoreFetch = stubSegmentedFetch(requests, { segmentOneGate: gate });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    await driver.play();
    await wait(1100);

    expect(recorder.eventsNamed("loading")).toHaveLength(1);

    const ended = recorder.waitFor("ended");
    gate.resolve();
    await ended;
  } finally {
    gate.resolve();
    restoreFetch();
  }
});

test("ready segment boundaries advance without loading or resetting", async () => {
  const requests = [];
  const restoreFetch = stubLinearSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/linear/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(recorder.eventsNamed("loading")).toHaveLength(0);
    expect(recorder.eventsNamed("reset")).toHaveLength(1);
    expect(recordingOutputs(recorder)).toEqual(["zero", "one", "two", "three"]);
  } finally {
    restoreFetch();
  }
});

test("segmented rewind reuses the previous segment and refetches an evicted one", async () => {
  const requests = [];
  const restoreFetch = stubLinearSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/linear/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    await driver.seek(0.035);
    expect(requestCount(requests, "2.json")).toBe(1);

    await driver.seek(0.015);
    expect(requestCount(requests, "0.json")).toBe(2);
  } finally {
    restoreFetch();
  }
});

test("finite segmented loop reloads and later evicts segment zero", async () => {
  const requests = [];
  const restoreFetch = stubLinearSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/linear/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true, loop: 1 },
    );

    await driver.init();
    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(recordingOutputs(recorder).filter((output) => output === "zero")).toHaveLength(2);
    expect(requestCount(requests, "0.json")).toBe(2);

    await driver.seek(0.015);
    expect(requestCount(requests, "0.json")).toBe(3);
  } finally {
    restoreFetch();
  }
});

test("segmented playback preserves server-provided effective boundary times", async () => {
  const requests = [];
  const restoreFetch = stubEffectiveTimeFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/effective/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 100, preload: true },
    );

    await driver.init();
    expect(driver.getDuration()).toBe(0.51);

    await driver.seek(0.5);
    expect(driver.getCurrentTime()).toBe(0.5);
    expect(requestCount(requests, "1.json")).toBe(1);
  } finally {
    restoreFetch();
  }
});

test("terminal size overrides apply to full and segmented snapshot restoration", async () => {
  const fullRecorder = createDispatchRecorder();

  const fullDriver = recording(
    source([
      [10, "o", "first"],
      [20, "o", "last"],
    ]),
    { logger: stubLogger(), dispatch: fullRecorder.dispatch },
    { speed: 1, preload: true, cols: 120, rows: 40 },
  );

  await fullDriver.init();
  await fullDriver.seek(0.02);
  await fullDriver.seek(0.005);
  expect(fullRecorder.eventsNamed("reset").at(-1).payload.size).toEqual({ cols: 120, rows: 40 });

  const requests = [];
  const restoreFetch = stubSegmentedFetch(requests);
  const segmentedRecorder = createDispatchRecorder();

  try {
    const segmentedDriver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: segmentedRecorder.dispatch },
      { speed: 1, preload: true, cols: 120, rows: 40 },
    );

    await segmentedDriver.init();
    await segmentedDriver.seek(0.04);

    expect(segmentedRecorder.eventsNamed("reset").at(-1).payload.size).toEqual({
      cols: 120,
      rows: 40,
    });
  } finally {
    restoreFetch();
  }
});

test("NPT poster applies resize events before the poster time", async () => {
  const recorder = createDispatchRecorder();

  const driver = recording(
    source([
      [10, "r", "100x30"],
      [20, "o", "poster"],
    ]),
    { logger: stubLogger(), dispatch: recorder.dispatch },
    { speed: 1, poster: { type: "npt", value: 0.015 } },
  );

  await driver.init();

  expect(recorder.eventsNamed("resize")).toEqual([
    { name: "resize", payload: { cols: 100, rows: 30 } },
  ]);
});

test("seeking away from a pending segment transition clears its loading timeout", async () => {
  const requests = [];
  const gate = createGate();
  const restoreFetch = stubSegmentedFetch(requests, { segmentOneGate: gate });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    await driver.play();
    await wait(40);
    await driver.pause();
    await driver.seek(0.01);
    await wait(1100);

    expect(recorder.eventsNamed("loading")).toHaveLength(0);

    await driver.stop();
    gate.resolve();
  } finally {
    restoreFetch();
  }
});

test("stop prevents pending playback positioning from restoring or fetching segments", async () => {
  const requests = [];
  const gate = createGate();
  const restoreFetch = stubSegmentedFetch(requests, { segmentZeroGate: gate });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, poster: { type: "npt", value: 0.04 } },
    );

    await driver.init();
    const play = driver.play();
    await wait(0);
    await driver.stop();
    const eventCountAfterStop = recorder.events.length;
    const requestCountAfterStop = requests.length;

    gate.resolve();
    await play;
    await wait(0);

    expect(recorder.events).toHaveLength(eventCountAfterStop);
    expect(requests).toHaveLength(requestCountAfterStop);
  } finally {
    restoreFetch();
  }
});

test("stop prevents pending initial segment loading from activating the recording", async () => {
  const requests = [];
  const gate = createGate();
  const restoreFetch = stubSegmentedFetch(requests, { segmentZeroGate: gate });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    const init = driver.init();
    await wait(0);
    await driver.stop();
    const eventCountAfterStop = recorder.events.length;

    gate.resolve();
    await init;

    expect(recorder.events).toHaveLength(eventCountAfterStop);
    expect(recorder.eventsNamed("metadata")).toHaveLength(0);
    expect(recorder.eventsNamed("reset")).toHaveLength(0);
  } finally {
    restoreFetch();
  }
});

test("stop prevents pending step positioning from restoring a segment", async () => {
  const requests = [];
  const gate = createGate();
  const restoreFetch = stubSegmentedFetch(requests, { segmentOneGate: gate });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    const step = driver.step(2);
    await wait(0);
    await driver.stop();
    const eventCountAfterStop = recorder.events.length;

    gate.resolve();
    await step;
    await wait(0);

    expect(recorder.events).toHaveLength(eventCountAfterStop);
  } finally {
    restoreFetch();
  }
});

test("loop waits safely when the evicted first segment is still reloading", async () => {
  const gate = createGate();
  const reloadStarted = createGate();
  const recorder = createDispatchRecorder();
  let segmentZeroLoads = 0;

  const index = {
    version: 1,
    duration: 0.05,
    term: { cols: 80, rows: 24 },
    segments: [
      { url: "0.json", start: 0 },
      { url: "1.json", start: 0.02 },
      { url: "2.json", start: 0.03 },
      { url: "3.json", start: 0.04 },
    ],
  };

  const payloads = {
    "0.json": {
      snapshot: { cols: 80, rows: 24, init: "" },
      events: [[0.01, "o", "zero"]],
    },
    "1.json": {
      snapshot: { cols: 80, rows: 24, init: "zero" },
      events: [[0.02, "o", "one"]],
    },
    "2.json": {
      snapshot: { cols: 80, rows: 24, init: "zero one" },
      events: [[0.03, "o", "two"]],
    },
    "3.json": {
      snapshot: { cols: 80, rows: 24, init: "zero one two" },
      events: [
        [0.04, "o", "three"],
        [0.05, "r", "80x24"],
      ],
    },
  };

  const restoreFetch = stubFetch(async (url) => {
    if (url === "/loop/index.json") return Response.json(index);

    const name = url.split("/").at(-1);

    if (name === "0.json" && segmentZeroLoads++ > 0) {
      reloadStarted.resolve();
      await gate.promise;
    }

    return Response.json(payloads[name]);
  });

  try {
    const driver = recording(
      { url: "/loop/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true, loop: true },
    );

    await driver.init();
    await driver.play();
    await reloadStarted.promise;
    await waitForCondition(() => driver.getCurrentTime() >= 0.049);

    expect(driver.getCurrentTime()).toBeCloseTo(0.05, 2);
    expect(recorder.eventsNamed("error")).toHaveLength(0);

    gate.resolve();

    await waitForCondition(
      () =>
        recorder.outputs.filter((output) => Array.isArray(output) && output[0] === "zero").length >=
        2,
    );

    await driver.stop();

    expect(
      recorder.outputs.filter((output) => Array.isArray(output) && output[0] === "zero"),
    ).toHaveLength(2);
  } finally {
    gate.resolve();
    restoreFetch();
  }
});

test("failed segmented prefetch is logged and retried when required", async () => {
  const requests = [];
  const warnings = [];
  const restoreFetch = stubSegmentedFetch(requests, { failSegmentOne: 1 });
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      {
        logger: {
          debug() {},
          warn(message) {
            warnings.push(message);
          },
        },
        dispatch: recorder.dispatch,
      },
      { speed: 1, preload: true },
    );

    await driver.init();
    const ended = recorder.waitFor("ended");
    await driver.play();
    await ended;

    expect(requests.filter((url) => url.endsWith("/1.json"))).toHaveLength(2);
    expect(warnings).toHaveLength(1);
    expect(warnings[0]).toContain("503 Unavailable");
    expect(recorder.eventsNamed("error")).toHaveLength(0);
  } finally {
    restoreFetch();
  }
});

test("stepping crosses segmented boundaries in both directions", async () => {
  const requests = [];
  const restoreFetch = stubSegmentedFetch(requests);
  const recorder = createDispatchRecorder();

  try {
    const driver = recording(
      { url: "/recording/index.json", format: "segmented" },
      { logger: stubLogger(), dispatch: recorder.dispatch },
      { speed: 1, preload: true },
    );

    await driver.init();
    await driver.step(2);

    expect(recorder.eventsNamed("reset").at(-1).payload.init).toBe("second snapshot");
    expect(driver.getCurrentTime()).toBeCloseTo(0.03);

    await driver.step(-1);

    expect(recorder.eventsNamed("reset").at(-1).payload.init).toBe("first snapshot");
    expect(driver.getCurrentTime()).toBeCloseTo(0.01);
    expect(requests.filter((url) => url.endsWith("/0.json"))).toHaveLength(1);
  } finally {
    restoreFetch();
  }
});
