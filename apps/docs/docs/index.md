---
hide:
  - navigation
  - toc
---

# Popcorn

<div class="brand-hero" markdown>
<div markdown>
<p class="brand-tagline">Make your terminal sessions pop.</p>

Record, replay, and share terminal sessions.

```sh
popcorn rec demo.pop
popcorn play demo.pop
```

</div>
<div class="brand-art">
<img src="assets/brand/mascot.png" alt="Popcorn mascot recording a terminal session on a laptop" width="1280" height="1200">
</div>
</div>

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
