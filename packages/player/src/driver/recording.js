import { toErrorPayload } from "../error";
import { createAudioElement } from "./recording/audio";
import { createRecordingContext } from "./recording/context";
import { EVENT, PLAYBACK_START_REASON, STATE } from "./recording/constants";
import { validateSeekInput, resolveSeekTarget } from "./recording/seek";
import { createSegmentLoader } from "./recording/segments";
import { findSegmentIndex, loadRecordingSource } from "./recording/source";
import { createTransition } from "./recording/transition";

function recording(
  src,
  { dispatch, logger },
  {
    speed,
    idleTimeLimit,
    startAt,
    preload,
    loop,
    poster,
    markers: markers_,
    pauseOnMarkers,
    cols: optionCols,
    rows: optionRows,
    audioUrl,
  },
) {
  const outputBatchWindow = (src.minFrameTime ?? 1 / 60) * 1000;
  let now = () => performance.now() * speed;
  let state = STATE.COLD;
  let queuedDriverEvents = [];
  let processingDriverEvents = false;

  const ctx = createRecordingContext({ poster });

  function isBufferingState(value = state) {
    return (
      value === STATE.READY_BUFFERING_WHILE_PAUSED || value === STATE.READY_BUFFERING_TO_RESUME
    );
  }

  function canLoopPlayback() {
    return loop === true || (typeof loop === "number" && ctx.playCount < loop);
  }

  function loadPromise(initialTime) {
    if (ctx.loaded === undefined) {
      ctx.loaded = load(initialTime);
      void ctx.loaded.catch(() => {});
    }

    return ctx.loaded;
  }

  const { activateSegment, getSegment, getRequiredSegment, retainSegments } = createSegmentLoader({
    ctx,
    logger,
    getState: () => state,
    failDriver,
  });

  const transition = createTransition({
    ctx,
    preload,
    poster,
    pauseOnMarkers,
    isBufferingState,
    canLoopPlayback,
    loadPromise,
    renderTextPoster,
    dispatch,
    resetTerminalFromSnapshot,
    renderPoster,
    clearPoster,
    startPlayback,
    logger,
    pausePlaybackClock,
    restartWaitingTimeout,
    clearWaitingTimeout,
    pausePlaybackAt,
    resumeAfterSegmentWait,
    performPause,
    seek,
    sendDriverEvent,
    sendCommand,
    performSeek,
    performStep,
    dispatchMarker,
    restartLoop,
    finishPlayback,
    teardown,
  });
  function enqueueDriverEvent(event, payload = {}) {
    queuedDriverEvents.push({ event, payload });
  }

  function processDriverEvent(event, payload = {}) {
    const previousState = state;
    const { nextState, action } = transition(previousState, event, payload);

    if (nextState !== state) {
      state = nextState;
    }

    return action?.();
  }

  function failDriver(error) {
    if (ctx.failureError || state === STATE.STOPPED) return;

    queuedDriverEvents.length = 0;
    ctx.segmentWaiting = false;
    cancelPendingTimers();

    if (ctx.audioElement) {
      ctx.audioElement.pause();
    }

    ctx.failureError = error;
    state = STATE.FAILED;
    dispatch("error", toErrorPayload(error));
  }

  function assertCommandAllowed() {
    if (ctx.failureError) {
      throw ctx.failureError;
    }

    if (state === STATE.STOPPED) {
      throw new Error("driver has been stopped");
    }
  }

  function sendCommand(event, payload = {}) {
    assertCommandAllowed();

    return sendDriverEvent(event, payload);
  }

  function sendDriverEvent(event, payload = {}) {
    if (ctx.failureError || state === STATE.STOPPED) {
      // Terminal states reject public commands via sendCommand(); late async
      // facts from timers/media callbacks are ignored here.
      return;
    }

    if (processingDriverEvents) {
      // Core serializes public commands, so re-entry here means the driver was
      // called directly in an unsupported way.
      throw new Error("re-entrant sendDriverEvent() is not allowed during queue processing");
    }

    processingDriverEvents = true;

    try {
      const result = processDriverEvent(event, payload);

      while (queuedDriverEvents.length > 0) {
        const queuedEvent = queuedDriverEvents.shift();
        processDriverEvent(queuedEvent.event, queuedEvent.payload);
      }

      return result;
    } catch (error) {
      failDriver(error);
      throw error;
    } finally {
      processingDriverEvents = false;
      queuedDriverEvents.length = 0;
    }
  }

  // Emit a follow-up event when the call site's framing is runtime-dependent:
  // defer to the active queue while one is processing (a direct sendDriverEvent() would
  // re-enter and throw), otherwise process immediately. Where the framing is
  // statically known, call sendDriverEvent()/enqueueDriverEvent() directly instead.
  function raiseDriverEvent(event, payload = {}) {
    if (processingDriverEvents) {
      enqueueDriverEvent(event, payload);
      return true;
    }

    return sendDriverEvent(event, payload);
  }

  function init() {
    return sendCommand(EVENT.INIT_REQUESTED);
  }

  async function load(requestedInitialTime) {
    const generation = ctx.positionGeneration;

    ctx.loadingTimeout = setTimeout(() => {
      dispatch("loading");
    }, 3000);

    try {
      const loadedRecording = loadRecordingSource(src, {
        idleTimeLimit,
        startAt,
        markers: markers_,
        inputOffset: src.inputOffset,
      });

      const audioLoaded = loadAudio(audioUrl).catch((error) => {
        logger.warn(`audio load failed: ${error.message}`);
        return false;
      });

      const recording = await loadedRecording;

      if (generation !== ctx.positionGeneration) return false;

      ctx.recording = recording;
      ctx.duration = recording.duration;
      ctx.effectiveStartAt = recording.effectiveStartAt;
      ctx.markers = recording.markers;

      const initialTime =
        requestedInitialTime ??
        (poster?.type === "npt" ? poster.value * 1000 : ctx.effectiveStartAt);

      const segmentIndex = findSegmentIndex(recording, initialTime ?? 0);
      const segment = await getSegment(segmentIndex, true);

      if (generation !== ctx.positionGeneration) return false;

      activateSegment(segmentIndex, segment);

      const hasAudio = await audioLoaded;

      if (generation !== ctx.positionGeneration) return false;

      sendDriverEvent(EVENT.LOAD_SUCCEEDED, { hasAudio });
    } catch (e) {
      // Segmented option validation may fail synchronously in-frame, while
      // fetch and parser failures arrive asynchronously out-of-frame.
      raiseDriverEvent(EVENT.LOAD_FAILED, { error: e, errorPayload: toErrorPayload(e) });

      throw e;
    } finally {
      clearLoadingTimeout();
    }
  }

  async function loadAudio(audioUrl) {
    if (!audioUrl) return false;

    ctx.audioElement = await createAudioElement(audioUrl);

    ctx.audioSeekable =
      !Number.isNaN(ctx.audioElement.duration) &&
      ctx.audioElement.duration !== Infinity &&
      ctx.audioElement.seekable.length > 0 &&
      ctx.audioElement.seekable.end(ctx.audioElement.seekable.length - 1) ===
        ctx.audioElement.duration;

    if (ctx.audioSeekable) {
      ctx.audioElement.addEventListener("playing", onAudioPlaying);
      ctx.audioElement.addEventListener("waiting", onAudioWaiting);
    } else {
      logger.warn(
        `audio is not seekable - you must enable range request support on the server providing ${ctx.audioElement.src} for audio seeking to work`,
      );
    }

    return true;
  }

  function renderPoster() {
    if (!ctx.posterRenderableAfterLoad) return;

    if (poster.type == "npt") {
      syncActiveSegmentToTime(poster.value * 1000, false, false);
    } else if (poster.type == "text") {
      feed(poster.value);
    }

    ctx.posterVisible = true;
  }

  function clearPoster() {
    if (ctx.posterVisible) {
      feed("\x1bc");
    }

    ctx.posterVisible = false;
    ctx.posterRenderableAfterLoad = false;
  }

  function prefetchNextSegment() {
    const lastIndex = ctx.recording.segments.length - 1;

    const nextIndex =
      ctx.segmentIndex < lastIndex ? ctx.segmentIndex + 1 : canLoopPlayback() ? 0 : undefined;

    retainSegments([ctx.segmentIndex - 1, ctx.segmentIndex, nextIndex]);

    if (nextIndex !== undefined) getSegment(nextIndex);
  }

  async function advanceSegment() {
    const nextIndex = ctx.segmentIndex + 1;
    const boundary = ctx.recording.segments[nextIndex].start;
    const generation = ++ctx.positionGeneration;

    try {
      const segment = await getRequiredSegment(nextIndex, generation, () => {
        sendDriverEvent(EVENT.SEGMENT_WAITING, { time: boundary });
      });

      if (generation !== ctx.positionGeneration || state === STATE.STOPPED) return;

      activateSegment(nextIndex, segment);
      prefetchNextSegment();

      if (
        state === STATE.READY_BUFFERING_TO_RESUME ||
        state === STATE.READY_BUFFERING_WHILE_PAUSED
      ) {
        await sendDriverEvent(EVENT.SEGMENT_READY);
      } else if (state === STATE.READY_PLAYING) {
        scheduleNextRecordingEvent();
      }
    } catch {
      // Required segment failures have already failed the driver.
    }
  }

  function pausePlaybackAt(time) {
    cancelScheduledRecordingEvent();
    ctx.pauseElapsedTime = time;
  }

  function resumeAfterSegmentWait() {
    clearWaitingTimeout();

    if (ctx.audioElement) {
      return ctx.audioElement.play().then(
        () => sendDriverEvent(EVENT.AUDIO_PLAYING, { confirmPlaybackClockStart }),
        (error) => {
          sendDriverEvent(EVENT.PLAYBACK_START_REJECTED);
          logger.warn(`audio resume failed: ${error.message}`);
          return false;
        },
      );
    }

    enqueueDriverEvent(EVENT.AUDIO_PLAYING, { confirmPlaybackClockStart });
  }

  function scheduleNextRecordingEvent() {
    const nextEvent = ctx.segment.events[ctx.nextEventIndex];

    if (nextEvent) {
      ctx.recordingEventTimeoutId = scheduleAt(runDueRecordingEvents, nextEvent[0]);
    } else {
      if (ctx.segmentIndex < ctx.recording.segments.length - 1) {
        const boundary = ctx.recording.segments[ctx.segmentIndex + 1].start;
        ctx.recordingEventTimeoutId = scheduleAt(advanceSegment, boundary);
      } else {
        raiseDriverEvent(EVENT.PLAYBACK_ENDED);
      }
    }
  }

  function scheduleAt(f, targetTime) {
    let timeout = (targetTime - (now() - ctx.startTime)) / speed;

    if (timeout < 0) {
      timeout = 0;
    }

    return setTimeout(f, timeout);
  }

  function runDueRecordingEvents() {
    while (ctx.segment.events[ctx.nextEventIndex] !== undefined) {
      if (applyNextRecordingEvents()) {
        return;
      }

      const nextEvent = ctx.segment.events[ctx.nextEventIndex];

      if (nextEvent === undefined) {
        break;
      }

      const elapsedWallTime = now() - ctx.startTime;

      if (elapsedWallTime <= nextEvent[0]) {
        break;
      }
    }

    scheduleNextRecordingEvent();
  }

  function applyNextRecordingEvents() {
    const event = ctx.segment.events[ctx.nextEventIndex];

    if (event[1] === "o") {
      applyOutputGroup();
      return false;
    }

    ctx.lastEventTime = event[0];
    ctx.nextEventIndex++;

    return applyRecordingEvent(event);
  }

  function applyOutputGroup() {
    const firstEvent = ctx.segment.events[ctx.nextEventIndex];
    const batchDeadline = firstEvent[0] + outputBatchWindow;
    const output = [];
    let event = firstEvent;

    while (event !== undefined && event[1] === "o" && event[0] < batchDeadline) {
      output.push(event[2]);
      ctx.lastEventTime = event[0];
      ctx.nextEventIndex++;
      event = ctx.segment.events[ctx.nextEventIndex];
    }

    feed(output);
  }

  function cancelScheduledRecordingEvent() {
    clearTimeout(ctx.recordingEventTimeoutId);
    ctx.recordingEventTimeoutId = null;
  }

  async function teardownAudio() {
    clearTimeout(ctx.waitingTimeout);

    if (ctx.audioElement) {
      ctx.audioElement.removeEventListener("playing", onAudioPlaying);
      ctx.audioElement.removeEventListener("waiting", onAudioWaiting);
      ctx.audioElement.pause();
      ctx.audioElement.src = "";
      ctx.audioElement.load();
      ctx.audioElement = undefined;
    }

    if (ctx.audioCtx) {
      await ctx.audioCtx.close();
      ctx.audioCtx = undefined;
    }
  }

  function applyRecordingEvent(event) {
    const [time, type, data] = event;

    if (type === "o") {
      feed(data);
    } else if (type === "i") {
      dispatch("input", { data });
    } else if (type === "r") {
      const [cols, rows] = data.split("x").map((n) => Number.parseInt(n, 10));
      dispatch("resize", effectiveSize(cols, rows));
    } else if (type === "m") {
      return sendDriverEvent(EVENT.MARKER_REACHED, { data, time }) === true;
    }

    return false;
  }

  function play() {
    return sendCommand(EVENT.PLAY_REQUESTED);
  }

  function pause() {
    return sendCommand(EVENT.PAUSE_REQUESTED);
  }

  function pausePlaybackClock() {
    cancelScheduledRecordingEvent();
    ctx.pauseElapsedTime = now() - ctx.startTime;
  }

  function preparePlaybackClock() {
    if (ctx.audioElement && !ctx.audioCtx) setupAudioCtx();
  }

  function confirmPlaybackClockStart() {
    ctx.startTime = now() - ctx.pauseElapsedTime;
    ctx.pauseElapsedTime = null;
    scheduleNextRecordingEvent();
  }

  function seek(where) {
    assertCommandAllowed();
    validateSeekInput(where);

    if (state === STATE.COLD) {
      return sendDriverEvent(EVENT.SEEK_REQUESTED, { where });
    }

    return sendDriverEvent(EVENT.SEEK_REQUESTED, { seekOperation: resolveSeek(state, where) });
  }

  function step(n) {
    return sendCommand(EVENT.STEP_REQUESTED, { n });
  }

  function getDuration() {
    return ctx.duration === undefined ? undefined : ctx.duration / 1000;
  }

  function getCurrentTimeMs() {
    if (state === STATE.READY_PLAYING) {
      return now() - ctx.startTime;
    } else {
      return ctx.pauseElapsedTime ?? 0;
    }
  }

  function getCurrentTime() {
    return getCurrentTimeMs() / 1000;
  }

  function setupAudioCtx() {
    ctx.audioCtx = new AudioContext({ latencyHint: "interactive" });
    const src = ctx.audioCtx.createMediaElementSource(ctx.audioElement);
    src.connect(ctx.audioCtx.destination);
    now = audioNow;
  }

  function audioNow() {
    if (!ctx.audioCtx) throw new Error("audio context not started - can't tell time!");

    const { contextTime, performanceTime } = ctx.audioCtx.getOutputTimestamp();

    // The check below is needed for Chrome,
    // which returns 0 for first several dozen millis,
    // completely ruining the timing (the clock jumps backwards once),
    // therefore we initially ignore performanceTime in our calculation.

    return performanceTime === 0
      ? contextTime * 1000
      : contextTime * 1000 + (performance.now() - performanceTime);
  }

  function onAudioWaiting() {
    logger.debug("audio buffering");
    sendDriverEvent(EVENT.AUDIO_WAITING);
  }

  function onAudioPlaying() {
    logger.debug("audio resumed");
    sendDriverEvent(EVENT.AUDIO_PLAYING, { confirmPlaybackClockStart });
  }

  function mute() {
    if (ctx.audioElement) {
      ctx.audioElement.muted = true;
      dispatch("muted", true);
      return true;
    }
  }

  function unmute() {
    if (ctx.audioElement) {
      ctx.audioElement.muted = false;
      dispatch("muted", false);
      return true;
    }
  }

  function stop() {
    return sendCommand(EVENT.STOP_REQUESTED);
  }

  function feed(data) {
    dispatch("output", data);
  }

  function dispatchMarker(data) {
    dispatch("marker", { ...data, time: data.time / 1000 });
  }

  function renderTextPoster() {
    renderPoster();
    ctx.posterRenderableAfterLoad = false;
  }

  function resolveSeek(currentState, where) {
    return resolveSeekTarget({
      where,
      currentTime: getCurrentTimeMs(),
      duration: ctx.duration,
      markers: ctx.markers,
      pauseElapsedTime: ctx.pauseElapsedTime,
      isPlaying: currentState === STATE.READY_PLAYING,
    });
  }

  function effectiveSize(cols, rows) {
    return { cols: optionCols ?? cols, rows: optionRows ?? rows };
  }

  function resetTerminalFromSnapshot(segment, emitClear = false) {
    if (emitClear) {
      // Preserve the existing observable RIS output even though reset replaces the VT state.
      feed("\x1bc");
    }

    dispatch("reset", {
      size: effectiveSize(segment.snapshot.cols, segment.snapshot.rows),
      init: segment.snapshot.init,
      theme: ctx.recording.theme ?? null,
    });
  }

  function syncActiveSegmentToTime(targetTime, clearStartAt = true, inclusive = true) {
    let event = ctx.segment.events[ctx.nextEventIndex];
    let output = [];

    while (event && (inclusive ? event[0] <= targetTime : event[0] < targetTime)) {
      if (event[1] === "o") {
        output.push(event[2]);
      } else if (event[1] === "r") {
        if (output.length > 0) {
          feed(output);
          output = [];
        }

        applyRecordingEvent(event);
      }

      ctx.lastEventTime = event[0];
      event = ctx.segment.events[++ctx.nextEventIndex];
    }

    if (output.length > 0) {
      feed(output);
    }

    ctx.pauseElapsedTime = targetTime;

    if (clearStartAt) {
      ctx.effectiveStartAt = null;
    }

    if (ctx.audioElement && ctx.audioSeekable) {
      ctx.audioElement.currentTime = targetTime / 1000 / speed;
    }
  }

  async function positionAt(targetTime, generation, forceReset = false) {
    const targetIndex = findSegmentIndex(ctx.recording, targetTime);

    if (generation !== ctx.positionGeneration) return false;

    if (!forceReset && targetIndex === ctx.segmentIndex && targetTime >= ctx.lastEventTime) {
      syncActiveSegmentToTime(targetTime);
      return true;
    }

    retainSegments([targetIndex - 1, targetIndex, targetIndex + 1]);
    const segment = await getRequiredSegment(targetIndex, generation);

    if (generation !== ctx.positionGeneration) return false;

    activateSegment(targetIndex, segment);
    resetTerminalFromSnapshot(segment, true);
    syncActiveSegmentToTime(targetTime);

    return true;
  }

  async function startPlayback(reason) {
    const generation = ctx.positionGeneration;

    if (
      ctx.segmentIndex === ctx.recording.segments.length - 1 &&
      ctx.segment.events[ctx.nextEventIndex] === undefined
    ) {
      if (!(await positionAt(0, generation, true))) return false;
    } else if (ctx.effectiveStartAt !== null) {
      if (!(await positionAt(ctx.effectiveStartAt, generation))) return false;
    }

    if (generation !== ctx.positionGeneration) return false;

    prefetchNextSegment();
    preparePlaybackClock();

    if (ctx.audioElement) {
      try {
        await ctx.audioElement.play();
        return sendDriverEvent(EVENT.PLAYBACK_START_CONFIRMED, {
          reason,
          confirmPlaybackClockStart,
        });
      } catch (error) {
        sendDriverEvent(EVENT.PLAYBACK_START_REJECTED);
        throw error;
      }
    }

    return raiseDriverEvent(EVENT.PLAYBACK_START_CONFIRMED, {
      reason,
      confirmPlaybackClockStart,
    });
  }

  function performPause(time) {
    if (ctx.audioElement) {
      ctx.audioElement.pause();
    }

    pausePlaybackClock();

    if (time !== undefined) {
      ctx.pauseElapsedTime = time;
    }

    dispatch("pause");

    return true;
  }

  async function performSeek(seekOperation, stateBeforeSeek) {
    const resumeAfterSeek =
      stateBeforeSeek === STATE.READY_PLAYING ||
      stateBeforeSeek === STATE.READY_BUFFERING_TO_RESUME;

    const generation = ++ctx.positionGeneration;

    if (stateBeforeSeek === STATE.READY_PLAYING) {
      pausePlaybackClock();
    }

    ctx.segmentWaiting = false;
    clearWaitingTimeout();

    if (ctx.audioElement) {
      ctx.audioElement.pause();
    }

    if (!(await positionAt(seekOperation.targetTime, generation))) return false;

    if (generation !== ctx.positionGeneration) return false;

    if (seekOperation.reachedEnd) {
      dispatch("seeked");
      dispatch("ended");
      return true;
    }

    if (resumeAfterSeek) {
      return await startPlayback(PLAYBACK_START_REASON.SEEK);
    }

    dispatch("seeked");

    return true;
  }

  async function performStep(n = 1) {
    const generation = ++ctx.positionGeneration;
    const target = await findStepTarget(n, generation);

    if (target === undefined || generation !== ctx.positionGeneration) return;

    clearPoster();

    if (!(await positionAt(target.time, generation, n < 0))) return;

    if (ctx.audioElement && ctx.audioSeekable) {
      ctx.audioElement.currentTime = target.time / 1000 / speed;
    }

    if (target.reachedEnd) {
      state = STATE.READY_ENDED;
      dispatch("ended");
    } else {
      state = STATE.READY_PAUSED;
    }
  }

  async function findStepTarget(n, generation) {
    let remaining = Math.abs(n);
    let segmentIndex = ctx.segmentIndex;
    let eventIndex = n > 0 ? ctx.nextEventIndex : ctx.nextEventIndex - 2;
    let target;

    while (segmentIndex >= 0 && segmentIndex < ctx.recording.segments.length) {
      if (generation !== ctx.positionGeneration) return;

      retainSegments([segmentIndex - 1, segmentIndex, segmentIndex + 1]);
      const segment = await getRequiredSegment(segmentIndex, generation);

      if (generation !== ctx.positionGeneration) return;

      if (n > 0) {
        for (let i = Math.max(eventIndex, 0); i < segment.events.length; i++) {
          if (segment.events[i][1] === "o" && --remaining === 0) {
            target = { time: segment.events[i][0] };
            break;
          }
        }

        if (target) break;
        segmentIndex++;
        eventIndex = 0;
      } else {
        for (let i = Math.min(eventIndex, segment.events.length - 1); i >= 0; i--) {
          if (segment.events[i][1] === "o" && --remaining === 0) {
            target = { time: segment.events[i][0] };
            break;
          }
        }

        if (target) break;
        segmentIndex--;
        eventIndex = Number.MAX_SAFE_INTEGER;
      }
    }

    if (target) {
      target.reachedEnd = target.time >= ctx.duration;
    }

    return target;
  }

  function restartWaitingTimeout() {
    clearTimeout(ctx.waitingTimeout);

    ctx.waitingTimeout = setTimeout(() => {
      dispatch("loading");
    }, 1000);
  }

  function clearWaitingTimeout() {
    clearTimeout(ctx.waitingTimeout);
    ctx.waitingTimeout = null;
  }

  function clearLoadingTimeout() {
    clearTimeout(ctx.loadingTimeout);
    ctx.loadingTimeout = null;
  }

  function cancelPendingTimers() {
    clearLoadingTimeout();
    clearWaitingTimeout();
    cancelScheduledRecordingEvent();
  }

  async function restartLoop() {
    cancelScheduledRecordingEvent();
    ctx.playCount++;
    const generation = ++ctx.positionGeneration;

    try {
      const segment = await getRequiredSegment(0, generation, () => {
        enqueueDriverEvent(EVENT.SEGMENT_WAITING, { time: ctx.duration });
      });

      if (generation !== ctx.positionGeneration) return;

      activateSegment(0, segment);
      resetTerminalFromSnapshot(segment, true);
      ctx.pauseElapsedTime = 0;
      ctx.startTime = now();
      prefetchNextSegment();

      if (ctx.audioElement && ctx.audioSeekable) {
        ctx.audioElement.currentTime = 0;
      }

      if (
        state === STATE.READY_BUFFERING_TO_RESUME ||
        state === STATE.READY_BUFFERING_WHILE_PAUSED
      ) {
        await sendDriverEvent(EVENT.SEGMENT_READY);
      } else {
        ctx.pauseElapsedTime = null;
        scheduleNextRecordingEvent();
      }
    } catch {
      // Required segment failures have already failed the driver.
    }
  }

  function finishPlayback() {
    cancelScheduledRecordingEvent();
    ctx.playCount++;
    ctx.pauseElapsedTime = ctx.duration;

    if (ctx.audioElement) {
      ctx.audioElement.pause();
    }

    retainSegments([ctx.segmentIndex - 1, ctx.segmentIndex]);

    dispatch("ended");
  }

  function teardown() {
    ctx.positionGeneration++;
    ctx.segmentCache.clear();
    cancelPendingTimers();

    return teardownAudio();
  }

  return {
    init,
    stop,
    getDuration,
    getCurrentTime,
    play,
    pause,
    seek,
    step,
    mute,
    unmute,
  };
}

export default recording;
