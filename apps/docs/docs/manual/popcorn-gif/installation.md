# Installation

## Install with Flox

The repository includes a Flox environment with the Rust toolchain, Node.js,
Elixir, documentation tools, and CI helpers used by the project.

```bash
git clone https://github.com/smeltery/popcorn
cd popcorn
flox activate
cargo build -p popcorn-gif --release --locked
export PATH="$PWD/target/release:$PATH"
```

Run `popcorn-gif --help` to confirm the binary is available.

## Install with Cargo

You can install the GIF renderer directly from the monorepo:

```bash
cargo install --locked --git https://github.com/smeltery/popcorn --package popcorn-gif
```

Make sure `$HOME/.cargo/bin` is in your shell's `$PATH`.

## Release artifacts

When release artifacts are published, download the archive for your operating
system from [GitHub releases](https://github.com/smeltery/popcorn/releases),
extract `popcorn-gif`, make it executable, and move it somewhere in `$PATH`.

## Building from source

Building from source requires [Rust](https://www.rust-lang.org/) compiler
(1.85.0 or later) and [Cargo package manager](https://doc.rust-lang.org/cargo/).
You can install both with [rustup](https://rustup.rs/).

To download source code, build popcorn-gif binary and install it in `$HOME/.cargo/bin`
run:

```bash
cargo install --locked --git https://github.com/smeltery/popcorn --package popcorn-gif
```

You need to ensure `$HOME/.cargo/bin` is in your shell's `$PATH`.

Alternatively, you can manually download source code and build popcorn-gif binary with:

```bash
git clone https://github.com/smeltery/popcorn
cd popcorn
cargo build -p popcorn-gif --release --locked
```

This produces an executable file in _release mode_ (`--release`) at
`target/release/popcorn-gif`. There are no other build artifacts so you can copy the
binary to a directory in your `$PATH`.

## Building with Docker

If you would rather build a local container image, use Docker, Podman, or
another Docker-compatible tool. This does not require a Rust toolchain on your
machine.

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
