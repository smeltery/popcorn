# Quick start

This guide shows how to add popcorn player to your own website.

It assumes you have obtained terminal session recording file by either recording
a terminal with [popcorn CLI](../cli/index.md) (`popcorn rec demo.pop`), or
downloading a `.pop ` file from [popcorn.local](https://popcorn.local) or a
[self-hosted popcorn server](../server/self-hosting/index.md).

For a broader overview of what's possible with popcorn check out the [intro
guide](../../getting-started.md).

## Installation

There are two ways of installing popcorn player on your website.

You can just copy standalone ("bundle") version of player's JS and CSS files
into your site assets directory and reference those in HTML via `<script
src="...">` and `<link rel="stylesheet" href="...">` tags.

If you use a JavaScript bundler you can use [popcorn-player npm
package](https://www.npmjs.com/package/popcorn-player).

### Standalone player bundle

Download latest version of the player bundle from
[releases page](https://github.com/dotbrains/popcorn/releases/latest). You
only need `popcorn-player.min.js` and `popcorn-player.css` files.

First, add `popcorn-player.min.js`, `popcorn-player.css` and the `.pop` file of
your recording to your site's assets. The HTML snippet below assumes they're in
the web server's root directory.

Then add necessary includes to your HTML document and initialize the player
inside an empty container `<div>` element:

```html
<!DOCTYPE html>
<html>
<head>
  ...
  <link rel="stylesheet" type="text/css" href="/popcorn-player.css" />
  ...
</head>
<body>
  ...
  <div id="demo"></div>
  ...
  <script src="/popcorn-player.min.js"></script>
  <script>
    PopcornPlayer.create('/demo.pop', document.getElementById('demo'));
  </script>
</body>
</html>
```

### npm package

Add [`popcorn-player`](https://www.npmjs.com/package/popcorn-player) to your
`devDependencies`:

```bash
npm install --save-dev popcorn-player@3.6.3
```

Add empty `<div id="demo"></div>` element to your page to contain the player.

Import `PopcornPlayer` from `popcorn-player` module and initialize the
player inside an empty container `<div>` element:

```javascript
import * as PopcornPlayer from 'popcorn-player';
PopcornPlayer.create('/demo.pop', document.getElementById('demo'));
```

Finally, include player's CSS file in your site CSS bundle. It's at `dist/bundle/popcorn-player.css` in the npm package.

If you need LibreJS compatibility when using a JavaScript bundler, add LibreJS
license metadata to your final application bundle and any inline JavaScript on
the page.

## Basic usage

In the code snippets above we initialized the player by calling `create` with 2
arguments. This function can in fact be called with 3 arguments:

```javascript
PopcornPlayer.create(src, containerElement, opts);
```

The arguments are:

- `src` - recording source, typically a recording URL,
- `containerElement` - container DOM element, to mount the player in,
- `opts` - configuration options (optional).

In the most common case, `src` is a URL pointing to an
[popcast](../popcast/v3.md) file. You can pass it as a full URL, e.g.
`"https://example.com/demo.pop"`, an absolute path, e.g. `"/demo.pop"`, or a
relative path, e.g. `"../casts/demo.pop"`.

!!! note

    A recording can be loaded from other sources, e.g. by inlining it in HTML or
    providing it through a function. See [Loading a recording](loading.md) for
    available ways of getting a recording into the player.

The third argument, `opts`, can be used to configure player's look and feel.
For example, to enable looping and select Solarized Dark theme we pass `loop`
and `theme` options like this:

```javascript
PopcornPlayer.create('/demo.pop', document.getElementById('demo'), {
  loop: true,
  theme: 'dracula'
});
```

See [Options](options.md) for a complete list of available options.

Finally, if you'd like to control the player programmatically, you can use the
methods of the player object, which is returned from the `create` function:

```javascript
const player = PopcornPlayer.create(src, containerElement);

document.getElementById('my-play-button').addEventListener('click', e => {
  e.preventDefault();
  player.play();
});
```

See [API](api.md) for full overview of programmatic control.

Before we conclude this guide here's an example of a player with a
[poster](options.md#poster) and a couple of [markers](markers.md), additionally
controlled with external buttons.

```javascript
const player = PopcornPlayer.create('/demo.pop', document.getElementById('demo'), {
  poster: 'npt:1:17',
  markers: [
    [3, 'Intro'],
    [5, 'Foo'],
    [9, 'Bar'],
    [15, 'Baz'],
    [30, 'Qux'],
  ]
});

document.getElementById('play-button').addEventListener('click', e => {
  e.preventDefault();
  player.play();
});

document.getElementById('prev-marker-button').addEventListener('click', e => {
  e.preventDefault();
  player.seek({ marker: 'prev' });
});
```

Below is the result. Go ahead and use the big buttons below the player.

<div class="player" id="player-manual-player-quickstart-1"></div>

[Play](#){ .md-button #play-button } &nbsp; [Pause](#){ .md-button #pause-button } &nbsp; [Prev marker](#){ .md-button #prev-marker-button } &nbsp; [Next marker](#){ .md-button #next-marker-button }

That wraps up our quick start guide. There's way more to the player than we
covered here though. Check out the rest of the documentation for further
configuration and customization options.
