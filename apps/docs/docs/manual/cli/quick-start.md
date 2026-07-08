# Quick start

This guide shows how to use popcorn CLI for recording, replaying, publishing,
and live streaming terminal sessions.

For a broader overview of what's possible with popcorn check out the [intro
guide](../../getting-started.md).

## Install popcorn CLI

popcorn CLI is available in most package repositories on Linux, macOS, and
FreeBSD. Search for a package named `popcorn`.

=== "apt (Debian, Ubuntu)"

    ```bash
    sudo apt install popcorn
    ```

=== "pacman (Arch, Manjaro)"

    ```bash
    sudo pacman -S popcorn
    ```

=== "homebrew (macOS)"

    ```bash
    brew install popcorn
    ```

=== "Cargo"

    You can install latest development version with `cargo`:

    ```bash
    cargo install --locked --git https://github.com/dotbrains/popcorn
    ```

=== "Other"

    Check the [Installation](installation.md) section for all installation
    options.

You can also download a pre-built, static binary of the latest version from the
[releases](https://github.com/dotbrains/popcorn/releases) page.

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

## Share via popcorn.local

If you want to watch and share it on the web, upload it:

```sh
popcorn upload demo.pop
```

The above command uploads it to [popcorn.local](https://popcorn.local), which is
a default [popcorn server](../server/index.md) instance, and prints a secret
link you can use to watch your recording in a web browser.

Run `popcorn upload --help` for all upload options.

!!! note

    This step is completely optional. You can embed your recordings on a web
    page with [popcorn player](../player/index.md), or publish them to a
    self-hosted [popcorn server](../server/index.md) instance.

## Stream a terminal session

To stream your terminal live to popcorn.local:

```sh
popcorn stream -r
```

Similarly to the `upload` command, this one also lets you stream to a
self-hosted [popcorn server](../server/index.md) instance.

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
