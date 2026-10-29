---
hide:
  - navigation
  - toc
---

<section class="brand-hero" aria-labelledby="brand-heading">
  <div class="brand-copy">
    <h1 id="brand-heading">Make your terminal sessions <em>pop.</em></h1>
    <p>Record, replay, stream, host and render terminal sessions in <strong>.pop</strong> files.</p>
    <div class="brand-actions">
      <a class="popcorn-button popcorn-button-primary" href="getting-started/">Get Started <span aria-hidden="true">→</span></a>
      <a class="popcorn-button popcorn-button-secondary" href="https://github.com/smeltery/popcorn">View on GitHub</a>
    </div>
  </div>
  <div class="brand-art" aria-hidden="true">
    <img class="brand-rays" src="assets/brand/gold-rays.svg" alt="" width="160" height="120">
    <img class="brand-hero-mascot" src="assets/brand/mascot.png" alt="" width="1280" height="1200">
    <img class="brand-kernel" src="assets/brand/popcorn-kernel.png" alt="" width="1024" height="1024">
  </div>
</section>

<section class="brand-demo" aria-label="Popcorn terminal demo">
  <div class="brand-window-bar"><span class="brand-window-dots" aria-hidden="true"><i></i><i></i><i></i></span><span>demo.pop</span></div>
  <div id="player-home" class="brand-terminal"></div>
  <noscript>Enable JavaScript to play the terminal demo, or <a href="assets/casts/brand-demo.pop">download the recording</a>.</noscript>
</section>

Popcorn is a smeltery toolkit for recording, playing, streaming, hosting, and
sharing terminal sessions. It stores recordings as lightweight `.pop` files
instead of video, so terminal demos stay small, searchable, copyable, and easy
to embed.

Use Popcorn when you need to:

- record a terminal session for a tutorial, bug report, or audit trail,
- replay a session locally in a terminal,
- embed a terminal demo on a website with the browser player,
- stream a live terminal session through a Popcorn server,
- host and manage recordings on your own server,
- render `.pop` recordings to GIFs for places that cannot run JavaScript.

<div class="grid cards" markdown>
-   __Start recording__

    ---

    Follow the [getting started guide](getting-started.md) to build the CLI,
    record `demo.pop`, play it back, and embed it in a page.

-   __Choose a component__

    ---

    Read the manuals for the [CLI](manual/cli/index.md),
    [player](manual/player/index.md), [server](manual/server/index.md), and
    [popcorn-gif](manual/popcorn-gif/index.md).

-   __Understand the format__

    ---

    Learn how [popcast v3](manual/popcast/v3.md) represents terminal output,
    resize events, markers, and metadata inside `.pop` files.

-   __Self-host__

    ---

    Deploy your own [Popcorn server](manual/server/self-hosting/index.md) when
    recordings or live streams should stay inside your infrastructure.
</div>

Popcorn is currently private and source-first. Use the repository release page
or source builds until a package channel is announced.
