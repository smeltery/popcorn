# Quick start

This guide shows how to use popcorn CLI for recording, replaying, publishing,
and live streaming terminal sessions.

For a broader overview of what's possible with popcorn check out the [intro
guide](../../getting-started.md).

## Install Popcorn CLI

Popcorn is currently source-first. Build the CLI from this monorepo, install it
directly with Cargo, or use a GitHub release artifact when one is available.

=== "Flox"

    ```bash
    git clone https://github.com/dotbrains/popcorn
    cd popcorn
    flox activate
    cargo build -p popcorn --release --locked
    export PATH="$PWD/target/release:$PATH"
    ```

=== "Cargo"

    ```bash
    cargo install --locked --git https://github.com/dotbrains/popcorn --package popcorn
    ```

=== "Release artifact"

    Download the archive for your operating system from
    [GitHub releases](https://github.com/dotbrains/popcorn/releases), extract
    the `popcorn` binary, and place it somewhere in `$PATH`.

Check the [Installation](installation.md) section for additional details.

## Record a terminal session

To start a recording session use the `rec` command:

```sh
popcorn rec demo.pop
```

When done, press <kbd>ctrl+d</kbd> or enter `exit` to end the recording.

Instead of recording a shell you can record any command with `--command` / `-c`
option:

```sh
popcorn rec -c htop demo.pop
```

The recording ends when you exit `htop` by pressing its `q` shortcut.

Run `popcorn rec --help` for all recording options.

## Replay directly in a terminal

To replay a recording in your terminal use the `play` command:

```sh
popcorn play demo.pop
```

To replay it with double speed use `--speed` / `-s` option:

```sh
popcorn play -s 2 demo.pop
```

A unique feature of popcorn is the ability to optimize away idle moments in a
recording using the `--idle-time-limit` / `-i` option:

```sh
popcorn play -i 2 demo.pop
```

You can pass `-i 2` to `popcorn rec` as well, to set it permanently on a
recording. Idle time limiting makes the recordings much more interesting to
watch. Try it!

Run `popcorn play --help` for all playback options.

!!! tip

    For the best playback experience it is recommended to run `popcorn play`
    in a terminal of size equal or bigger than the one used at the recording
    time, as there's no "transcoding" of control sequences for the current
    terminal size.

## Convert recordings

Use `convert` when you need a different recording or output format.

Convert a `.pop` recording to plain text:

```sh
popcorn convert demo.pop demo.txt
```

Import a ttyrec recording as a `.pop` file:

```sh
popcorn convert --input-format ttyrec session.ttyrec session.pop
```

Convert ttyrec output directly to plain text:

```sh
popcorn convert --input-format ttyrec --output-format txt session.ttyrec session.txt
```

`convert` defaults to popcast input. Pass `--input-format ttyrec` explicitly
when reading ttyrec files. The generated `.pop` output uses popcast v3 unless
you choose another output format.

See [Converting recordings](converting.md) or run `popcorn convert --help` for
all conversion options.

## Upload to a Popcorn server

If you want to watch and share it on the web, upload it:

```sh
export POPCORN_SERVER_URL=https://popcorn.example.com
popcorn upload demo.pop
```

The command uploads to your [Popcorn server](../server/index.md) and prints a
secret link you can use to watch the recording in a web browser.

Run `popcorn upload --help` for all upload options.

!!! note

    This step is completely optional. You can embed your recordings on a web
    page with [Popcorn player](../player/index.md), or publish them to a
    self-hosted [popcorn server](../server/index.md) instance.

## Stream a terminal session

To stream your terminal live to a Popcorn server:

```sh
export POPCORN_SERVER_URL=https://popcorn.example.com
popcorn stream -r
```

Use the server URL for your self-hosted instance.

To stream locally:

```sh
popcorn stream -l
```

This starts a local web server which lets you watch the stream from a local
machine or over LAN.

Run `popcorn stream --help` for more streaming options.

!!! note

    Live streaming requires popcorn CLI 3.0 or newer.

Finally, you can stream and record to a file at the same time:

```sh
popcorn session -o demo.pop -r -l
```

The session command is a more generic variant of `rec` and `stream`, that can
do everything those two commands can.

Run `popcorn session --help` for more details.

## Next

These are the basics, but there's much more. We highly encourage checking out
`--help` information for each command - it contains way more information than
was covered in this guide.

Last but not least! Consider creating shell aliases for frequently used
commands:

```sh
alias rec='popcorn rec'
alias play='popcorn play'
alias stream='popcorn stream -r'
```

Happy recording!
