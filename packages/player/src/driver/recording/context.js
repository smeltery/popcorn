function createRecordingContext({ poster }) {
  return {
    recording: undefined,
    segmentIndex: undefined,
    segment: undefined,
    segmentCache: new Map(),
    positionGeneration: 0,
    markers: undefined,
    duration: undefined,
    effectiveStartAt: undefined,
    recordingEventTimeoutId: undefined,
    nextEventIndex: 0,
    lastEventTime: 0,
    startTime: undefined,
    pauseElapsedTime: undefined,
    playCount: 0,
    waitingTimeout: undefined,
    loadingTimeout: undefined,
    audioCtx: undefined,
    audioElement: undefined,
    audioSeekable: false,
    loaded: undefined,
    posterVisible: false,
    posterRenderableAfterLoad: poster !== undefined,
    failureError: null,
    segmentWaiting: false,
  };
}

export { createRecordingContext };
