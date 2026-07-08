# Installation

Popcorn is currently source-first. Use a release binary when one is published
for your platform, or build from source with Rust.

## Release Binary

Release artifacts are published from the repository release workflow when a
version tag is cut:

- `popcorn-x86_64-unknown-linux-gnu`
- `popcorn-x86_64-unknown-linux-musl`
- `popcorn-aarch64-unknown-linux-gnu`
- `popcorn-x86_64-apple-darwin`
- `popcorn-aarch64-apple-darwin`

Download the binary for your platform, make it executable, and place it on your
`PATH`:

```bash
chmod +x popcorn-aarch64-apple-darwin
sudo mv popcorn-aarch64-apple-darwin /usr/local/bin/popcorn
```

## Build From Source

Install Rust 1.85 or newer, then build from the repository root:

```bash
git clone https://github.com/dotbrains/popcorn.git
cd popcorn
cargo build -p popcorn --release --locked
```

The binary is written to `target/release/popcorn`.

## Flox Development Environment

For repository development, use the checked-in Flox environment:

```bash
git clone https://github.com/dotbrains/popcorn.git
cd popcorn
flox activate
cargo build -p popcorn --locked
```

The Flox environment installs the shared development tools and prepares the docs
Python environment.

## Container Builds

The CLI package includes a Dockerfile for image builds. Container publishing is
not yet a stable public installation channel; prefer release binaries or source
builds for now.
