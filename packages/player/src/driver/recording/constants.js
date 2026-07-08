export const STATE = {
  COLD: "cold", // Recording has not been loaded yet.
  LOADING: "loading", // Recording/audio load is in progress.
  READY_INITIAL: "ready.initial", // Loaded, not yet played or navigated.
  READY_PAUSED: "ready.paused", // Loaded and positioned while playback clock is stopped.
  READY_STARTING: "ready.starting", // Playback start/resume requested; waiting for clock readiness.
  READY_PLAYING: "ready.playing", // Playback clock is running and events are scheduled.
  READY_BUFFERING_WHILE_PAUSED: "ready.buffering.whilePaused", // Buffering while remaining paused.
  READY_BUFFERING_TO_RESUME: "ready.buffering.toResume", // Buffering before resuming playback.
  READY_ENDED: "ready.ended", // Playback or navigation reached recording duration.
  FAILED: "failed", // Fatal driver error; public commands reject.
  STOPPED: "stopped", // Terminal state after stop().
};

export const EVENT = {
  INIT_REQUESTED: "initRequested", // Public init/preload command.
  PLAY_REQUESTED: "playRequested", // Public play command.
  DEFERRED_PLAY_READY: "deferredPlayReady", // Cold play() can continue after load.
  PAUSE_REQUESTED: "pauseRequested", // Public pause command.
  SEEK_REQUESTED: "seekRequested", // Public seek command.
  STEP_REQUESTED: "stepRequested", // Public frame-step command.
  STOP_REQUESTED: "stopRequested", // Public teardown command.
  LOAD_SUCCEEDED: "loadSucceeded", // Recording load completed.
  LOAD_FAILED: "loadFailed", // Recording load failed fatally.
  PLAYBACK_START_CONFIRMED: "playbackStartConfirmed", // Playback clock can start.
  PLAYBACK_START_REJECTED: "playbackStartRejected", // Audio/media play() rejected.
  PLAYBACK_ENDED: "playbackEnded", // Scheduled playback reached natural end.
  AUDIO_WAITING: "audioWaiting", // Audio element entered buffering.
  AUDIO_PLAYING: "audioPlaying", // Audio element resumed from buffering.
  SEGMENT_WAITING: "segmentWaiting", // Required segment is loading at a boundary.
  SEGMENT_READY: "segmentReady", // Required segment loaded and playback may continue.
  MARKER_REACHED: "markerReached", // Playback crossed a marker event.
};

export const PLAYBACK_START_REASON = {
  PLAY: "play",
  SEEK: "seek",
};
