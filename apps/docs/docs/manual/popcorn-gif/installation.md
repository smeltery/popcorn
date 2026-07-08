# Installation

## Native package

popcorn-gif may be available in your operating system's packager manager repository.
Search for `popcorn-gif` or `popcorn-popcorn-gif`.

If it's not there then you can [download prebuilt popcorn-gif
binary](#prebuilt-binaries), [use the container
image](#oci-container-image), or [build from source](#building-from-source).

## Prebuilt binaries

popcorn-gif is written in Rust, and Rust compiler produces standalone binaries that can
run without extra dependencies. There's [Github Actions Release
workflow](https://github.com/dotbrains/popcorn/blob/main/.github/workflows/release.yml)
for popcorn-gif which builds binaries for multiple OSes and CPU architectures, attaching
the binaries to every new release on Github.

Visit [latest release](https://github.com/dotbrains/popcorn/releases/latest) page,
and download a binary appropriate for your system.

For 64-bit x86 system choose a file with `x86_64` in the name. For ARMv8
(64-bit, e.g. Apple Silicon) choose a file with `aarch64`. For ARMv7 (32-bit,
e.g. Raspberry Pi) choose a file with `arm`.

Make it executable and put it somewhere in `$PATH`:

```bash
chmod a+x popcorn-gif
sudo mv popcorn-gif /usr/local/bin
```

## OCI container image

Official container images are published to the GitHub Container Registry at
[`ghcr.io/popcorn/popcorn-gif`](https://github.com/dotbrains/popcorn/pkgs/container/popcorn-gif).
The image bundles popcorn-gif with a broad set of monospace fonts, so recordings render
out of the box.

With Docker:

```sh
docker run --rm -u $(id -u):$(id -g) -v $PWD:/data ghcr.io/popcorn/popcorn-gif demo.pop demo.gif
```

With Podman in root-less mode:

```sh
podman run --rm -v $PWD:/data ghcr.io/popcorn/popcorn-gif demo.pop demo.gif
```

Under Docker, `-u $(id -u):$(id -g)` makes the output files owned by you instead
of root; rootless Podman maps the container user to your account automatically,
so it's not needed there.

Besides `latest`, each release is tagged with its version, e.g.
`ghcr.io/popcorn/popcorn-gif:1.9.0`.

## Building from source

Building from source requires [Rust](https://www.rust-lang.org/) compiler
(1.85.0 or later) and [Cargo package manager](https://doc.rust-lang.org/cargo/).
You can install both with [rustup](https://rustup.rs/).

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

If you'd rather build the container image yourself from the latest source —
instead of using the [official image](#oci-container-image) — you can do so with
Docker, Podman, or another Docker-compatible tool. This doesn't require a Rust
toolchain on your machine.

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
