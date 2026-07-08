export async function createAudioElement(src) {
  const audio = new Audio();
  audio.preload = "metadata";
  audio.loop = false;
  audio.crossOrigin = "anonymous";

  let resolve;
  let reject;

  const canPlay = new Promise((resolve_, reject_) => {
    resolve = resolve_;
    reject = reject_;
  });

  function cleanup() {
    audio.removeEventListener("canplay", onCanPlay);
    audio.removeEventListener("error", onError);
    audio.removeEventListener("abort", onAbort);
  }

  function onCanPlay() {
    cleanup();
    resolve();
  }

  function onError() {
    cleanup();
    reject(new Error(`failed loading audio from ${src}`));
  }

  function onAbort() {
    cleanup();
    reject(new Error(`audio loading aborted for ${src}`));
  }

  audio.addEventListener("canplay", onCanPlay);
  audio.addEventListener("error", onError);
  audio.addEventListener("abort", onAbort);
  audio.src = src;
  audio.load();
  await canPlay;

  return audio;
}
