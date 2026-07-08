import { EVENT, PLAYBACK_START_REASON, STATE } from "./constants";

function createTransition({
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
}) {
  return function transition(currentState, event, payload = {}) {
    switch (event) {
      case EVENT.INIT_REQUESTED:
        if (currentState === STATE.COLD) {
          if (preload || poster?.type == "npt") {
            return { nextState: STATE.LOADING, action: () => loadPromise() };
          }

          if (poster?.type == "text") {
            return { nextState: currentState, action: () => renderTextPoster() };
          }
        }

        return { nextState: currentState };

      case EVENT.LOAD_SUCCEEDED:
        if (currentState !== STATE.LOADING) {
          return { nextState: currentState };
        }

        return {
          nextState: STATE.READY_INITIAL,
          action: () => {
            dispatch("metadata", {
              duration: ctx.duration / 1000,
              markers: ctx.markers.map(([t, label]) => [t / 1000, label]),
              hasAudio: payload.hasAudio,
            });

            resetTerminalFromSnapshot(ctx.segment);

            renderPoster();
          },
        };

      case EVENT.LOAD_FAILED:
        if (currentState !== STATE.LOADING) {
          return { nextState: currentState };
        }

        return {
          nextState: STATE.FAILED,
          action: () => {
            ctx.failureError = payload.error;
            dispatch("error", payload.errorPayload);
          },
        };

      case EVENT.PLAY_REQUESTED:
        if (currentState === STATE.COLD) {
          return {
            nextState: STATE.LOADING,
            action: () => {
              clearPoster();
              dispatch("play");
              return loadPromise().then(() => sendDriverEvent(EVENT.DEFERRED_PLAY_READY));
            },
          };
        }

        if (
          currentState === STATE.READY_INITIAL ||
          currentState === STATE.READY_PAUSED ||
          currentState === STATE.READY_ENDED
        ) {
          return {
            nextState: STATE.READY_STARTING,
            action: () => {
              dispatch("play");
              clearPoster();
              return startPlayback(PLAYBACK_START_REASON.PLAY);
            },
          };
        }

        if (currentState === STATE.READY_BUFFERING_WHILE_PAUSED) {
          return {
            nextState: STATE.READY_BUFFERING_TO_RESUME,
            action: () => {
              dispatch("play");

              if (ctx.segmentWaiting) return true;

              if (ctx.audioElement) {
                return ctx.audioElement.play().catch((error) => {
                  sendDriverEvent(EVENT.PLAYBACK_START_REJECTED);
                  throw error;
                });
              }

              return true;
            },
          };
        }

        if (
          currentState === STATE.READY_BUFFERING_TO_RESUME ||
          currentState === STATE.READY_PLAYING
        ) {
          return {
            nextState: currentState,
            action: () => {
              dispatch("play");
              return true;
            },
          };
        }

        return { nextState: currentState };

      case EVENT.DEFERRED_PLAY_READY:
        if (currentState === STATE.READY_INITIAL) {
          return {
            nextState: STATE.READY_STARTING,
            action: () => {
              clearPoster();
              return startPlayback(PLAYBACK_START_REASON.PLAY);
            },
          };
        }

        return { nextState: currentState };

      case EVENT.PLAYBACK_START_CONFIRMED:
        if (currentState !== STATE.READY_STARTING) {
          return { nextState: currentState };
        }

        return {
          nextState: STATE.READY_PLAYING,
          action: () => {
            payload.confirmPlaybackClockStart();

            if (payload.reason === PLAYBACK_START_REASON.SEEK) {
              dispatch("seeked");
            } else {
              dispatch("playing");
            }

            return true;
          },
        };

      case EVENT.PLAYBACK_START_REJECTED:
        if (currentState === STATE.READY_STARTING) {
          return {
            nextState: STATE.READY_PAUSED,
          };
        }

        if (currentState === STATE.READY_BUFFERING_TO_RESUME) {
          return {
            nextState: STATE.READY_BUFFERING_WHILE_PAUSED,
          };
        }

        return { nextState: currentState };

      case EVENT.PLAYBACK_ENDED:
        if (currentState !== STATE.READY_PLAYING) {
          return { nextState: currentState };
        }

        if (canLoopPlayback()) {
          return {
            nextState: STATE.READY_PLAYING,
            action: restartLoop,
          };
        }

        return {
          nextState: STATE.READY_ENDED,
          action: finishPlayback,
        };

      case EVENT.AUDIO_WAITING:
        if (currentState === STATE.READY_PLAYING) {
          return {
            nextState: STATE.READY_BUFFERING_TO_RESUME,
            action: () => {
              logger.debug("pausing session playback");
              pausePlaybackClock();
              restartWaitingTimeout();
            },
          };
        }

        if (
          currentState === STATE.READY_BUFFERING_WHILE_PAUSED ||
          currentState === STATE.READY_BUFFERING_TO_RESUME
        ) {
          return {
            nextState: currentState,
            action: restartWaitingTimeout,
          };
        }

        return { nextState: currentState };

      case EVENT.AUDIO_PLAYING:
        if (ctx.segmentWaiting) {
          return { nextState: currentState };
        }

        if (currentState === STATE.READY_BUFFERING_TO_RESUME) {
          return {
            nextState: STATE.READY_PLAYING,
            action: () => {
              logger.debug("resuming session playback");
              clearWaitingTimeout();
              payload.confirmPlaybackClockStart();
              dispatch("playing");
            },
          };
        }

        if (currentState === STATE.READY_BUFFERING_WHILE_PAUSED) {
          return {
            nextState: STATE.READY_PAUSED,
            action: () => {
              clearWaitingTimeout();
            },
          };
        }

        return { nextState: currentState };

      case EVENT.SEGMENT_WAITING:
        if (currentState === STATE.READY_PLAYING) {
          return {
            nextState: STATE.READY_BUFFERING_TO_RESUME,
            action: () => {
              ctx.segmentWaiting = true;
              pausePlaybackAt(payload.time);
              restartWaitingTimeout();

              if (ctx.audioElement) {
                ctx.audioElement.pause();
              }
            },
          };
        }

        return { nextState: currentState };

      case EVENT.SEGMENT_READY:
        ctx.segmentWaiting = false;

        if (currentState === STATE.READY_BUFFERING_TO_RESUME) {
          return {
            nextState: currentState,
            action: resumeAfterSegmentWait,
          };
        }

        if (currentState === STATE.READY_BUFFERING_WHILE_PAUSED) {
          return {
            nextState: STATE.READY_PAUSED,
            action: clearWaitingTimeout,
          };
        }

        return { nextState: currentState };

      case EVENT.PAUSE_REQUESTED:
        if (currentState === STATE.READY_PLAYING) {
          return { nextState: STATE.READY_PAUSED, action: performPause };
        }

        if (currentState === STATE.READY_BUFFERING_TO_RESUME) {
          return {
            nextState: STATE.READY_BUFFERING_WHILE_PAUSED,
            action: () => {
              if (ctx.audioElement) {
                ctx.audioElement.pause();
              }

              return true;
            },
          };
        }

        return { nextState: currentState, action: () => true };

      case EVENT.SEEK_REQUESTED: {
        if (currentState === STATE.COLD) {
          return {
            nextState: STATE.LOADING,
            action: () =>
              loadPromise(
                typeof payload.where === "number" ? payload.where * 1000 : undefined,
              ).then(() => seek(payload.where)),
          };
        }

        if (isBufferingState(currentState) && !ctx.segmentWaiting) {
          return { nextState: currentState, action: () => false };
        }

        if (
          currentState !== STATE.READY_INITIAL &&
          currentState !== STATE.READY_PAUSED &&
          currentState !== STATE.READY_ENDED &&
          currentState !== STATE.READY_PLAYING &&
          currentState !== STATE.READY_BUFFERING_WHILE_PAUSED &&
          currentState !== STATE.READY_BUFFERING_TO_RESUME
        ) {
          return { nextState: currentState };
        }

        const seekOperation = payload.seekOperation;

        if (seekOperation.noOp) {
          return { nextState: currentState, action: () => false };
        }

        return {
          nextState: seekOperation.reachedEnd
            ? STATE.READY_ENDED
            : currentState === STATE.READY_PLAYING ||
                currentState === STATE.READY_BUFFERING_TO_RESUME
              ? STATE.READY_STARTING
              : STATE.READY_PAUSED,
          action: () => {
            clearPoster();
            return performSeek(seekOperation, currentState);
          },
        };
      }

      case EVENT.STEP_REQUESTED: {
        if (currentState === STATE.COLD) {
          return {
            nextState: STATE.LOADING,
            action: () => loadPromise().then(() => sendCommand(EVENT.STEP_REQUESTED, payload)),
          };
        }

        if (currentState === STATE.READY_PLAYING || isBufferingState(currentState)) {
          return { nextState: currentState };
        }

        if (
          currentState !== STATE.READY_INITIAL &&
          currentState !== STATE.READY_PAUSED &&
          currentState !== STATE.READY_ENDED
        ) {
          return { nextState: currentState };
        }

        return {
          nextState: currentState,
          action: () => performStep(payload.n),
        };
      }

      case EVENT.MARKER_REACHED:
        if (currentState !== STATE.READY_PLAYING) {
          return { nextState: currentState };
        }

        if (pauseOnMarkers) {
          return {
            nextState: STATE.READY_PAUSED,
            action: () => {
              dispatchMarker(payload.data);
              return performPause(payload.time);
            },
          };
        }

        return {
          nextState: currentState,
          action: () => dispatchMarker(payload.data),
        };

      case EVENT.STOP_REQUESTED:
        return { nextState: STATE.STOPPED, action: teardown };

      default:
        return { nextState: currentState };
    }
  };
}

export { createTransition };
