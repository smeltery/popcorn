---
hide:
  - toc
---

# popcorn player

__popcorn player__ is a web player for terminal session recordings.

Unlike typical web _video_ players, which play heavyweight video files (`.mp4`,
`.mov`), popcorn player plays lightweight terminal session recordings in the
text-based [popcast](../popcast/v3.md) format (`.pop`), such as those
produced by [popcorn recorder](../cli/index.md).

<div class="player" id="player-manual-player-intro"></div>

The player is built from the ground up with JavaScript and
[Rust](https://www.rust-lang.org/) ([WASM](https://webassembly.org/)), and is
available as [npm package](https://www.npmjs.com/package/popcorn-player) and a
[standalone JS
bundle](https://github.com/smeltery/popcorn/releases/latest).

You can use it on any HTML page - in a project documentation, on a blog, or in a
conference talk presentation.

It's as easy as adding a single line of Javascript code to your web page:

```javascript
PopcornPlayer.create('demo.pop', document.getElementById('demo'));
```

Check out the [quick start guide](quick-start.md) for basic setup overview.

---

Notable features:

- playback of [static recordings](../popcast/v3.md) and [live terminal streams](loading.md#playing-live-streams),
- ability to copy-paste terminal content - it's just text after all!
- smooth, timing-accurate playback,
- [idle time optimization](options.md#idletimelimit) to skip periods of
  inactivity,
- [posters](options.md#poster),
- [markers](markers.md) for navigation or auto-pause,
- configurable [font families](options.md#terminalfontfamily) and [line
  height](options.md#terminallineheight),
- [automatic terminal scaling](options.md#fit) to fit into container element in
  most efficient way,
- full-screen mode,
- [keystroke overlay](options.md#keystrokeoverlay) showing keys typed during the
  recording,
- [multiple color themes for standard 16 colors](options.md#theme) + support for
  256 color palette and 24-bit true color (ISO-8613-3),
- [adjustable playback speed](options.md#speed),
- [looped playback](options.md#loop), infinite or finite,
- [starting playback at specific time](options.md#startat),
- [API for programmatic control](api.md),
- [keyboard shortcuts](shortcuts.md),
- [support for other recording
  formats](loading.md#playing-other-recording-formats) like ttyrec, typescript.

---

popcorn player is licensed under the Apache-2.0. Source code
and license are available at
[github.com/smeltery/popcorn](https://github.com/smeltery/popcorn).
