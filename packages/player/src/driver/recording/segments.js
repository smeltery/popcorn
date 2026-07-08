import { STATE } from "./constants";

function createSegmentLoader({ ctx, logger, getState, failDriver }) {
  function activateSegment(index, segment) {
    ctx.segmentIndex = index;
    ctx.segment = segment;
    ctx.nextEventIndex = 0;
    ctx.lastEventTime = ctx.recording.segments[index].start;
  }

  function getSegment(index, required = false) {
    let entry = ctx.segmentCache.get(index);

    if (entry === undefined) {
      entry = {};

      entry.promise = ctx.recording.loadSegment(index).then(
        (data) => {
          if (ctx.segmentCache.get(index) === entry) {
            entry.data = data;
          }

          return data;
        },

        (error) => {
          if (ctx.segmentCache.get(index) === entry) {
            ctx.segmentCache.delete(index);
          }

          if (!required) {
            logger.warn(`segment prefetch failed: ${error.message}`);
          }

          throw error;
        },
      );

      ctx.segmentCache.set(index, entry);

      if (!required) {
        void entry.promise.catch(() => {});
      }
    }

    return entry.promise;
  }

  async function getRequiredSegment(index, generation, onWaiting) {
    if (ctx.segmentCache.get(index)?.data === undefined) {
      onWaiting?.();
    }

    try {
      return await getSegment(index, true);
    } catch (error) {
      if (generation === ctx.positionGeneration && getState() !== STATE.STOPPED) {
        failDriver(error);
      }

      throw error;
    }
  }

  function retainSegments(indexes) {
    const retained = new Set(indexes.filter((index) => index >= 0));

    for (const index of ctx.segmentCache.keys()) {
      if (!retained.has(index)) {
        ctx.segmentCache.delete(index);
      }
    }
  }

  return {
    activateSegment,
    getSegment,
    getRequiredSegment,
    retainSegments,
  };
}

export { createSegmentLoader };
