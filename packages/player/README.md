# popcorn player

[![Build status](https://github.com/dotbrains/popcorn/actions/workflows/build.yml/badge.svg)](https://github.com/dotbrains/popcorn/actions/workflows/build.yml)

__popcorn player__ is a web player for terminal sessions recordings.

Unlike typical web _video_ players, which play heavyweight video files (`.mp4`,
`.mov`), popcorn player plays lightweight terminal session recordings in the
text-based [popcast](https://github.com/dotbrains/popcorn/tree/main/docs/v3/) format
(`.pop`), such as those produced by the [popcorn
recorder](https://github.com/dotbrains/popcorn/tree/main/crates/cli).

The player is built from the ground up with JavaScript and
[Rust](https://www.rust-lang.org/) ([WASM](https://webassembly.org/)), and is
available as [npm package](https://www.npmjs.com/package/popcorn-player) and a
[standalone JS
bundle](https://github.com/dotbrains/popcorn/releases/latest).

You can use it on any HTML page - in a project documentation, on a blog, or in a
conference talk presentation.

It's as easy as adding a single line of Javascript code to your web page:

```javascript
PopcornPlayer.create('demo.pop', document.getElementById('demo'));
```

Check out the [quick start
guide](https://github.com/dotbrains/popcorn/tree/main/packages/player/quick-start/) for basic setup
overview.

You can see the player in action in [Popcorn
documentation](https://github.com/dotbrains/popcorn/tree/main/packages/player/).

Notable features:

* ability to copy-paste terminal content - it's just text after all!
* smooth, timing-accurate playback,
* [idle time optimization](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#idletimelimit) to skip periods of inactivity,
* [posters](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#poster),
* [markers](https://github.com/dotbrains/popcorn/tree/main/packages/player/markers/) for navigation or auto-pause,
* configurable [font families](https://github.com/dotbrains/popcorn/tree/main/packages/player/fonts/) and [line height](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#terminallineheight),
* [automatic terminal scaling](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#fit) to fit into container element in most efficient way,
* full-screen mode,
* [keystroke overlay](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#keystrokeoverlay) showing keys typed during the recording,
* [multiple color themes for standard 16 colors](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#theme) + support for 256 color palette and 24-bit true color (ISO-8613-3),
* [adjustable playback speed](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#speed),
* [looped playback](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#loop), infinite or finite,
* [starting playback at specific time](https://github.com/dotbrains/popcorn/tree/main/packages/player/options/#startat),
* [API for programmatic control](https://github.com/dotbrains/popcorn/tree/main/packages/player/api/),
* [keyboard shortcuts](https://github.com/dotbrains/popcorn/tree/main/packages/player/shortcuts/),
* [support for other recording formats](https://github.com/dotbrains/popcorn/tree/main/packages/player/parsers/) like ttyrec, typescript.

## Building

Building popcorn player from source requires:

- [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/),
- [Rust](https://www.rust-lang.org/) compiler (1.77 or later) and [Cargo package
  manager](https://doc.rust-lang.org/cargo/).

To build the project run:

    git clone https://github.com/dotbrains/popcorn
    cd popcorn-player
    rustup target add wasm32-unknown-unknown
    npm install
    npm run build

This produces following output files:

- `dist/index.js` - monolithic ES module, to be `import`-ed in your JS bundle
- `dist/bundle/popcorn-player.js` - standalone monolithic player script (IIFE), to be linked directly from a website
- `dist/bundle/popcorn-player.min.js` - minimized version of the above
- `dist/bundle/popcorn-player.css` - stylesheet, to be linked directly from a website or included in a CSS bundle

The monolithic version of the player covers majority of use cases, and it's all
you need to use the player.

In addition, the split version of the player is built with `npm run build`,
producing the following files:

- `dist/ui.js` - UI ES module, to be `import`-ed in your JS bundle
- `dist/bundle/popcorn-player-ui.js` - standalone UI script (IIFE), to be linked directly from a website
- `dist/bundle/popcorn-player-ui.min.js` - minimized version of the above
- `dist/bundle/popcorn-player-worker.js` - standalone web worker script (IIFE), to be linked directly from a website
- `dist/bundle/popcorn-player-worker.min.js` - minimized version of the above

The split version runs the UI and data crunching (parsing, terminal emulation)
in separate OS threads, which improves UI's responsiveness during playback. In
this setup the UI code runs in the window context, while the processing code
runs in a
[WebWorker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API).
The benefit of this configuration is typically observed only for high
frame-rate / high bandwidth recordings. For typical demos/sessions it's
not worth the setup hassle.

## Donations



Popcorn is maintained by dotbrains.

- [Brightbox](https://www.brightbox.com/)

## Consulting

If you're interested in integration or customization of popcorn player to suit
your needs, contact dotbrains.

## License

© 2011 Marcin Kulik.

All code is licensed under the Apache License, Version 2.0. See
[LICENSE](./LICENSE) file for details.
