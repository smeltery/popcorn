---
hide:
  - navigation
---

# Getting Started

This guide walks through the core Popcorn loop: build the CLI, record a `.pop`
file, play it back, render it for the web, and decide whether to self-host a
server.

## Install The Toolchain

The recommended development setup is Flox:

```bash
git clone https://github.com/dotbrains/popcorn.git
cd popcorn
flox activate
```

Flox provides the project toolchain and prepares the docs Python environment.
Without Flox, install these tools directly:

- Rust 1.85 or newer with `rustfmt` and `clippy`
- Node.js 24 or newer with npm
- Python 3.12 or newer
- Erlang/OTP 28.1 or newer and Elixir for the server
- PostgreSQL for server tests and local server development

## Build Popcorn

Build the CLI from the workspace root:

```bash
cargo build -p popcorn --locked
```

The debug binary is created at `target/debug/popcorn`. For a release binary:

```bash
cargo build -p popcorn --release --locked
```

## Record A Session

Record a terminal session to a local `.pop` file:

```bash
target/debug/popcorn rec demo.pop
```

Run a few commands in the child shell, then exit the shell with `exit` or
<kbd>ctrl+d</kbd>. Popcorn writes the captured terminal output, resize events,
timing, markers, and metadata to `demo.pop`.

## Play It Back

Replay the file in your terminal:

```bash
target/debug/popcorn play demo.pop
```

During playback, press <kbd>space</kbd> to pause or resume and <kbd>ctrl+c</kbd>
to stop early.

## Convert Recordings

Create a text transcript from a `.pop` recording:

```bash
target/debug/popcorn convert demo.pop demo.txt
```

Import a ttyrec recording into Popcorn's `.pop` format:

```bash
target/debug/popcorn convert --input-format ttyrec session.ttyrec session.pop
```

Use `--output-format txt` when you want terminal text instead of another
recording file.

## Use The Browser Player

Build the browser player:

```bash
cd packages/player
npm ci
npm run build
```

Add the built CSS and JavaScript bundle to a page, then create a player:

```html
<link rel="stylesheet" href="/popcorn-player.css">
<div id="demo"></div>
<script src="/popcorn-player.min.js"></script>
<script>
  PopcornPlayer.create('/demo.pop', document.getElementById('demo'));
</script>
```

See the [player quick start](manual/player/quick-start.md) for module imports,
standalone bundles, options, and API details.

## Render A GIF

Use `popcorn-gif` when the destination cannot run JavaScript:

```bash
cargo run -p popcorn-gif -- demo.pop demo.gif
```

The GIF renderer uses the same `.pop` input format and supports themes, font
selection, playback speed, frame selection, and terminal size overrides.

## Stream Or Host Recordings

Popcorn can upload recordings and live stream terminal sessions to a Popcorn
server. Use a self-hosted server URL until a public hosted service is announced:

```bash
export POPCORN_API_URL=https://popcorn.example.com
target/debug/popcorn upload demo.pop
target/debug/popcorn stream
```

For deployment details, see [self-hosting](manual/server/self-hosting/index.md).

## Next Steps

- Read [how Popcorn works](how-it-works.md) for the PTY, `.pop`, and player
  model.
- Configure the [CLI](manual/cli/configuration/index.md) for your server URL,
  notifications, and recording defaults.
- Explore the [server API](manual/server/api.md) for automation.
- Review [security notes](support.md#security-and-private-data) before sharing
  recordings outside your team.
