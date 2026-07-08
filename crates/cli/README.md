# popcorn CLI

`popcorn` records, plays, converts, concatenates, and streams terminal sessions.

This package is the Rust CLI member of the Popcorn monorepo. It writes Popcorn
recordings with the `.pop` extension and exposes the recording format as
`popcast`.

## Usage

Record a session:

```sh
popcorn rec demo.pop
```

Play a recording:

```sh
popcorn play demo.pop
```

Convert a recording:

```sh
popcorn convert demo.pop demo.txt
```

Stream locally:

```sh
popcorn stream --local
```

## Build

From the repository root:

```sh
cargo build -p popcorn --locked
```

The binary is written to `target/debug/popcorn`.

## Test

```sh
cargo test -p popcorn --locked
crates/cli/tests/integration.sh
```

## Generated Artifacts

Set `POPCORN_GEN_DIR` when building to generate man pages and shell
completions:

```sh
POPCORN_GEN_DIR=/tmp/popcorn-gen cargo build -p popcorn --release
```
