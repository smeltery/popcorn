export const fakeAudioState = {
  closedContexts: 0,
  lastAudio: undefined,
  pendingPlay: null,
};

export function installFakeAudio({ manualPlay = false, failLoad = false } = {}) {
  const originalAudio = globalThis.Audio;
  const originalAudioContext = globalThis.AudioContext;
  fakeAudioState.closedContexts = 0;
  fakeAudioState.lastAudio = undefined;
  fakeAudioState.pendingPlay = null;

  class FakeAudio {
    constructor() {
      this.currentTime = 0;
      this.duration = 10;
      this.loop = false;
      this.preload = "metadata";
      this.crossOrigin = "anonymous";
      this.muted = false;
      this.seekable = { length: 1, end: () => this.duration };
      this.listeners = new Map();
      this.pauseCalls = 0;
      this.src = "";
      fakeAudioState.lastAudio = this;
    }

    addEventListener(name, handler) {
      const handlers = this.listeners.get(name) ?? [];
      handlers.push(handler);
      this.listeners.set(name, handlers);
    }

    removeEventListener(name, handler) {
      const handlers = this.listeners.get(name) ?? [];
      this.listeners.set(
        name,
        handlers.filter((h) => h !== handler),
      );
    }

    dispatch(name) {
      for (const handler of this.listeners.get(name) ?? []) {
        handler();
      }
    }

    load() {
      setTimeout(() => {
        if (this.src !== "") {
          this.dispatch(failLoad ? "error" : "canplay");
        }
      }, 0);
    }

    play() {
      if (manualPlay) {
        const gate = createGate();
        fakeAudioState.pendingPlay = gate;

        return gate.promise.then(() => {
          fakeAudioState.pendingPlay = null;
          this.dispatch("playing");
        });
      }

      setTimeout(() => this.dispatch("playing"), 0);
      return Promise.resolve();
    }

    pause() {
      this.pauseCalls++;
    }
  }

  class FakeAudioContext {
    constructor() {
      this.destination = {};
    }

    createMediaElementSource() {
      return { connect() {} };
    }

    getOutputTimestamp() {
      const time = performance.now();

      return { contextTime: time / 1000, performanceTime: time };
    }

    close() {
      fakeAudioState.closedContexts++;
      return Promise.resolve();
    }
  }

  globalThis.Audio = FakeAudio;
  globalThis.AudioContext = FakeAudioContext;

  return () => {
    globalThis.Audio = originalAudio;
    globalThis.AudioContext = originalAudioContext;
  };
}

export async function resolveFakeAudioPlay() {
  for (let i = 0; i < 20; i++) {
    if (fakeAudioState.pendingPlay) {
      fakeAudioState.pendingPlay.resolve();
      return;
    }

    await wait(0);
  }

  throw new Error("timed out waiting for fake audio play");
}

export function source(events) {
  return {
    data: { cols: 80, rows: 24, events },
    parser: (data) => data,
  };
}

export function createDispatchRecorder() {
  const events = [];
  const outputs = [];
  let waiter = null;

  return {
    events,
    outputs,

    dispatch(name, payload) {
      events.push({ name, payload });

      if (name === "output") {
        outputs.push(payload);
      }

      if (waiter?.name === name) {
        waiter.resolve({ name, payload });
        waiter = null;
      }
    },

    eventNames() {
      return events.map((event) => event.name);
    },

    eventsNamed(name) {
      return events.filter((event) => event.name === name);
    },

    waitFor(name) {
      if (waiter) {
        throw new Error(`already waiting for ${waiter.name}`);
      }

      return new Promise((resolve) => {
        waiter = { name, resolve };
      });
    },
  };
}

export function stubLogger() {
  return {
    debug() {},
    warn() {},
  };
}

export function stubFetch(fn) {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, opts) => await fn(url, opts);

  return () => {
    globalThis.fetch = originalFetch;
  };
}

export function stubSegmentedFetch(
  requests,
  { segmentZeroGate, segmentOneGate, failSegmentZero = 0, failSegmentOne = 0 } = {},
) {
  const index = {
    version: 1,
    duration: 0.06,
    term: { cols: 100, rows: 30 },
    markers: [
      [0.02, "chapter"],
      [0.04, "summary"],
    ],
    segments: [
      { url: "0.json", start: 0 },
      { url: "1.json", start: 0.03 },
    ],
  };

  const segments = {
    "http://localhost/recording/0.json": {
      snapshot: { cols: 100, rows: 30, init: "first snapshot" },
      events: [
        [0.01, "o", "first"],
        [0.02, "m", "chapter"],
      ],
    },
    "http://localhost/recording/1.json": {
      snapshot: { cols: 100, rows: 30, init: "second snapshot" },
      events: [
        [0.03, "o", "last"],
        [0.04, "m", "summary"],
        [0.06, "r", "100x30"],
      ],
    },
  };

  return stubFetch(async (url) => {
    requests.push(url);

    if (url === "/recording/index.json") {
      return Response.json(index);
    }

    if (segments[url]) {
      if (url.endsWith("/0.json")) {
        await segmentZeroGate?.promise;

        if (failSegmentZero > 0) {
          failSegmentZero--;
          return new Response("unavailable", { status: 503, statusText: "Unavailable" });
        }
      }

      if (url.endsWith("/1.json")) {
        await segmentOneGate?.promise;

        if (failSegmentOne > 0) {
          failSegmentOne--;
          return new Response("unavailable", { status: 503, statusText: "Unavailable" });
        }
      }

      return Response.json(segments[url]);
    }

    return new Response("missing", { status: 404, statusText: "Not Found" });
  });
}

export function stubLinearSegmentedFetch(requests) {
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

  const segments = {
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

  return stubFetch((url) => {
    requests.push(url);

    if (url === "/linear/index.json") return Response.json(index);

    return Response.json(segments[url.split("/").at(-1)]);
  });
}

export function stubEffectiveTimeFetch(requests) {
  const index = {
    version: 1,
    duration: 0.51,
    term: { cols: 80, rows: 24 },
    segments: [
      { url: "0.json", start: 0 },
      { url: "1.json", start: 0.5 },
    ],
  };

  const segments = {
    "0.json": {
      snapshot: { cols: 80, rows: 24, init: "" },
      events: [[0.01, "o", "before limited gap"]],
    },

    "1.json": {
      snapshot: { cols: 80, rows: 24, init: "before limited gap" },
      events: [
        [0.5, "o", "after limited gap"],
        [0.51, "r", "80x24"],
      ],
    },
  };

  return stubFetch((url) => {
    requests.push(url);

    if (url === "/effective/index.json") return Response.json(index);

    return Response.json(segments[url.split("/").at(-1)]);
  });
}

export function requestCount(requests, name) {
  return requests.filter((url) => url.endsWith(`/${name}`)).length;
}

export function recordingOutputs(recorder) {
  return recorder.outputs.flatMap((output) => (Array.isArray(output) ? output : []));
}

export function wait(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

export async function waitForCondition(condition, timeout = 1000) {
  const deadline = performance.now() + timeout;

  while (!condition()) {
    if (performance.now() >= deadline) {
      throw new Error("timed out waiting for condition");
    }

    await wait(1);
  }
}

export function createGate() {
  let resolve;

  const promise = new Promise((resolve_) => {
    resolve = resolve_;
  });

  return { promise, resolve };
}
