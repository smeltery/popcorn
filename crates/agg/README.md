# popcorn-gif - popcorn gif generator

__agg__ is a command-line tool for generating animated GIF files from terminal
session recordings.

It supports conversion from
[popcast](https://github.com/popcorn/popcorn/blob/master/doc/popcast-v3.md)
files produced by [popcorn recorder](https://github.com/popcorn/popcorn).
It uses Kornel Lesiński's excellent
[gifski](https://github.com/ImageOptim/gifski) library to produce optimized,
high quality GIF output with accurate frame timing.

Example GIF file generated with popcorn-gif:

![Example GIF file generated with popcorn-gif](demo.gif)

Notable features:

- conversion of [popcast](https://docs.popcorn.org/manual/popcast/v3/)
  recordings (v1, v2, v3) to animated GIF files,
- input from local files, stdin, or HTTP(S) URLs (e.g.
  [popcorn.org](https://popcorn.org) recording links),
- high-quality, optimized GIF output with accurate frame timing via the
  [gifski](https://github.com/ImageOptim/gifski) encoder,
- multiple built-in color themes (popcorn, dracula, monokai, github-dark,
  github-light, kanagawa, nord, solarized-dark, solarized-light, gruvbox-dark,
  and more),
- custom ad-hoc themes specified as hex color triplets,
- automatic use of the recording's embedded theme when present,
- configurable [font families](https://popcorn.dotbrains.local/docs/manual/popcorn-gif/usage/#fonts)
  with sensible cross-platform defaults and implicit fallbacks for symbols,
  including automatic Nerd Font symbols rendering,
- configurable font size and line height,
- additional font directory support via `--font-dir` for fonts outside standard
  system locations,
- color emoji rendering with support for Apple Color Emoji, Noto Color Emoji,
  and other common emoji fonts,
- two selectable rendering backends: `swash` (default) and `resvg`,
- adjustable playback speed,
- idle time limiting to skip periods of inactivity,
- frame selection by time ranges, discrete positions, markers, percentages, and
  event indexes,
- looped or single-pass playback,
- configurable FPS cap and last-frame duration,
- terminal size override (cols/rows) for re-rendering at a different geometry.

Check out the [popcorn-gif docs](https://popcorn.dotbrains.local/docs/manual/popcorn-gif/) for
installation and usage overview.

## Building

Building from source requires [Rust](https://www.rust-lang.org/) compiler
(1.85.0 or later) and [Cargo package
manager](https://doc.rust-lang.org/cargo/). You can install both with
[rustup](https://rustup.rs/).

To download source code, build popcorn-gif binary and install it in `$HOME/.cargo/bin`
run:

```bash
cargo install --git https://github.com/dotbrains/popcorn
```

You need to ensure `$HOME/.cargo/bin` is in your shell's `$PATH`.

Alternatively, you can manually download source code and build popcorn-gif binary with:

```bash
git clone https://github.com/dotbrains/popcorn
cd popcorn-gif
cargo build --release
```

This produces an executable file in _release mode_ (`--release`) at
`target/release/popcorn-gif`. There are no other build artifacts so you can copy the
binary to a directory in your `$PATH`.

### Building with Docker

Alternatively, if you have Docker, Podman or another Docker-compatible tool
installed you can use it to build popcorn-gif container image. This doesn't require Rust
toolchain installed on your machine.

Build the image with the following command:

```sh
docker build -t popcorn-gif .
```

Then run popcorn-gif like this:

```sh
docker run --rm -u $(id -u):$(id -g) -v $PWD:/data popcorn-gif demo.pop demo.gif
```

If you use Podman in root-less mode:

```sh
podman run --rm -v $PWD:/data popcorn-gif demo.pop demo.gif
```

## Consulting

If you're interested in customization of popcorn-gif or any other popcorn component to
for your corporate needs, check [popcorn consulting
services](https://docs.popcorn.org/consulting/).

## License

© 2022 Marcin Kulik.


All code is licensed under the GPL, v3 or later. See [LICENSE](./LICENSE) file
for details.
