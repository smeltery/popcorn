export function validateSeekInput(where) {
  if (typeof where === "number") {
    if (Number.isFinite(where)) return;
  } else if (typeof where === "string") {
    if (isRelativeSeek(where) || parseSeekPercentage(where) !== undefined) return;
  } else if (typeof where === "object" && where !== null) {
    if (
      where.marker === "prev" ||
      where.marker === "next" ||
      (Number.isInteger(where.marker) && where.marker >= 0)
    ) {
      return;
    }
  }

  throw new Error(`invalid seek target: ${JSON.stringify(where)}`);
}

export function resolveSeekTarget({
  where,
  currentTime,
  duration,
  markers,
  pauseElapsedTime,
  isPlaying,
}) {
  let target = where;

  if (typeof target === "number") {
    target = target * 1000;
  } else if (typeof target === "string") {
    if (target === "<<") {
      target = currentTime - 5000;
    } else if (target === ">>") {
      target = currentTime + 5000;
    } else if (target === "<<<") {
      target = currentTime - 0.1 * duration;
    } else if (target === ">>>") {
      target = currentTime + 0.1 * duration;
    } else if (target[target.length - 1] === "%") {
      target = (parseSeekPercentage(target) / 100) * duration;
    }
  } else if (typeof target === "object") {
    if (target.marker === "prev") {
      target = findMarkerTimeBefore(markers, currentTime) ?? 0;

      if (isPlaying && currentTime - target < 1000) {
        target = findMarkerTimeBefore(markers, target) ?? 0;
      }
    } else if (target.marker === "next") {
      target = findMarkerTimeAfter(markers, currentTime) ?? duration;
    } else if (typeof target.marker === "number") {
      const marker = markers[target.marker];

      if (marker === undefined) {
        throw new Error(`invalid marker index: ${target.marker}`);
      }

      target = marker[0];
    }
  }

  const targetTime = Math.min(Math.max(target, 0), duration);

  return {
    targetTime,
    reachedEnd: targetTime >= duration,
    noOp: targetTime === pauseElapsedTime,
  };
}

function isRelativeSeek(where) {
  return where === "<<" || where === ">>" || where === "<<<" || where === ">>>";
}

function parseSeekPercentage(where) {
  if (!where.endsWith("%")) return;

  const percentage = Number(where.slice(0, -1));

  if (Number.isFinite(percentage)) {
    return percentage;
  }
}

function findMarkerTimeBefore(markers, time) {
  if (markers.length == 0) return;

  let i = 0;
  let marker = markers[i];
  let lastMarkerTimeBefore;

  while (marker && marker[0] < time) {
    lastMarkerTimeBefore = marker[0];
    marker = markers[++i];
  }

  return lastMarkerTimeBefore;
}

function findMarkerTimeAfter(markers, time) {
  if (markers.length == 0) return;

  let i = markers.length - 1;
  let marker = markers[i];
  let firstMarkerTimeAfter;

  while (marker && marker[0] > time) {
    firstMarkerTimeAfter = marker[0];
    marker = markers[--i];
  }

  return firstMarkerTimeAfter;
}
