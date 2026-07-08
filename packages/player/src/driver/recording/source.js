import { loadFullRecording } from "./full";
import { loadSegmentedRecording } from "./segmented";

export function loadRecordingSource(src, options) {
  if (src.format === "segmented") {
    return loadSegmentedRecording(src, options);
  }

  return loadFullRecording(src, options);
}

export function findSegmentIndex(recording, time) {
  let low = 0;
  let high = recording.segments.length;

  while (low + 1 < high) {
    const middle = Math.floor((low + high) / 2);

    if (recording.segments[middle].start <= time) {
      low = middle;
    } else {
      high = middle;
    }
  }

  return low;
}
