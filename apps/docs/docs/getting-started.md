---
hide:
  - navigation
---

# Getting started

This guide serves as your introduction to popcorn, starting with the basics
of recording a terminal with [popcorn CLI](manual/cli/index.md). We'll cover
how to share recordings via [popcorn.local](https://popcorn.local), live stream
terminal sessions, embed [popcorn player](manual/player/index.md) on a
website, and conclude with instructions for self-hosting [popcorn
server](manual/server/index.md).

## Recording

Install the popcorn CLI first. There are several installation options to
choose from:

=== "Download static binary"

    You can download a pre-built, static binary of the latest version from the
    [releases](https://github.com/dotbrains/popcorn/releases) page.

=== "apt (Debian, Ubuntu)"

    ``` bash
    sudo apt install popcorn
    ```

=== "pacman (Arch, Manjaro)"

    ``` bash
    sudo pacman -S popcorn
    ```

=== "homebrew (macOS)"

    ``` bash
    brew install popcorn
    ```

=== "pipx (popcorn 2.4 only)"

    ``` bash
    pipx install popcorn
    ```

=== "Other"

    Check the [Installation](manual/cli/installation.md) section for all
    installation options.

Now record your terminal with:

```sh
popcorn rec demo.pop
```

This starts a new recording session, where everything printed to a terminal
gets captured and saved to the `demo.pop` file in
[popcast](manual/popcast/v3.md) format.

To end the recording session simply exit the shell. This can be done by pressing
<kbd>ctrl+d</kbd> or entering <code>exit</code>.

Replay your recording with:

```sh
popcorn play demo.pop
```

You can pause/resume by pressing <kbd>space</kbd>, or end the playback early by
pressing <kbd>ctrl+c</kbd>.

See [popcorn CLI quick-start guide](manual/cli/quick-start.md) for more
examples.

## Sharing

Replaying a recording in your terminal is handy but not as useful as sharing it
with the wider audience on the internet.

You can host your recordings at [popcorn.local](https://popcorn.local), which
is a public popcorn server instance that provides free hosting for terminal
recordings. _Hosting your recordings on popcorn.local is completely optional_
but has many benefits, e.g. easy sharing and embedding.

Upload your recording to popcorn.local with:

```sh
popcorn upload demo.pop
```

The command prints a secret link to the recording page, where you can view it.
Feel free to share the link with anyone.

The player component on the recording page is not a typical video player. It's
[popcorn player](manual/player/index.md), built from the ground up to play
terminal sessions. It lets you copy the contents of its terminal view, just like
in a regular terminal. Try it: pause the playback, select some lines, copy,
paste elsewhere. It's just text after all!

If you'd like to manage your recordings on popcorn.local (set a title, change
terminal color theme) you need to link your uploads to your popcorn.local user
account. To do it run:

```sh
popcorn auth
```

This command displays a URL, which, when opened in a web browser, authenticates
the CLI with your popcorn.local account, ensuring you have access to your uploads.

You can skip this step now, and do it later. However, all recordings not
assigned to an account are automatically deleted after 7 days. Run `popcorn
upload --help` and `popcorn auth --help` for detailed information.

## Live streaming

In addition to recording terminal sessions to a file, popcorn also supports
terminal live streaming. This is useful for live coding sessions, visual
monitoring of servers (e.g. with `htop`), etc.

To start a live stream to popcorn.local:

```sh
popcorn stream -r
```

This provides you with a URL that viewers can visit to watch your terminal
session in real-time. The stream begins immediately and continues until you end
the session by pressing <kbd>ctrl+d</kbd> or entering `exit`.

This mode of streaming is called "remote streaming", as it sends the stream to
a remote popcorn server, which acts as a (public) relay. Remote streaming
works with any self-hosted popcorn server, not just popcorn.local.

There's also local streaming mode:

```sh
popcorn stream -l
```

This starts a local web server that lets you access the live stream from your
local machine or over LAN. This is purely local, "no-cloud" mode, and no data
is sent anywhere.

Run `popcorn stream --help` for more streaming options. Check out the [server
streaming guide](manual/server/streaming.md) for technical details about the
streaming protocols.

!!! note

    Live streaming requires popcorn CLI 3.0 or newer.

## Embedding

[popcorn player](manual/player/index.md) can be embedded on any website by
using HTML `<script>` tag. Embedded player is commonly used on blogs, in project
documentation, and in conference talk slides.

All recordings uploaded to popcorn.local can be embedded on a website by using a
script snippet provided on the recording's page. It looks like this:

```html
<script async id="popcast-569727" src="https://popcorn.local/a/569727.js"></script>
```

To get it, go to a recording page, click on the "Share" button and copy the
script from the "Embed the player" section.

The above `<script>` tag is included right below this very paragraph, resulting
in the following player:

<script async id="popcast-569727" src="https://popcorn.local/a/569727.js"></script>

If you prefer not to rely on popcorn.local for your embedded demos, you can use
the standalone player on your website like this:

```html
<!DOCTYPE html>
<html>
<head>
  ...
  <link rel="stylesheet" type="text/css" href="/popcorn-player.css" />
  ...
</head>
<body>
  ...
  <div id="demo"></div>
  ...
  <script src="/popcorn-player.min.js"></script>
  <script>
    // @license magnet:?xt=urn:btih:8e4f440f4c65981c5bf93c76d35135ba5064d8b7&dn=apache-2.0.txt Apache-2.0
    PopcornPlayer.create('/demo.pop', document.getElementById('demo'));
    // @license-end
  </script>
</body>
</html>
```

See [popcorn player quick-start guide](manual/player/quick-start.md) for full
setup details.

## Self-hosting the server

While [popcorn.local](https://popcorn.local) is the default [popcorn
server](manual/server/index.md) used by the CLI for uploading recordings, you
can self-host your own instance if you want full ownership and control over the
recordings.

popcorn server is packaged as OCI container image and is available at
[ghcr.io/dotbrains/popcorn-server](https://github.com/dotbrains/popcorn/pkgs/container/popcorn-server).

Here's a minimal docker-compose example:

```yaml title="docker-compose.yml"
services:
  popcorn:
    image: ghcr.io/dotbrains/popcorn-server:latest
    ports:
      - '4000:4000'
    volumes:
      - popcorn_data:/var/lib/popcorn
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: docker.io/library/postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_HOST_AUTH_METHOD=trust
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 2s
      timeout: 5s
      retries: 10

volumes:
  popcorn_data:
  postgres_data:
```

Start it with:

```sh
docker compose up
```

Then point popcorn CLI to it by setting `POPCORN_API_URL` environment
variable:

```sh
export POPCORN_API_URL=http://localhost:4000

popcorn rec demo.pop
popcorn upload demo.pop
```

Note that the above configuration should be used only for testing the server
locally. See full [server self-hosting
guide](manual/server/self-hosting/index.md) to learn how to set it up properly
in a full-featured and secure way.

## Generating a GIF

On websites where `<script>` tags are not allowed but `<img>` tags are, you can
use animated GIF files for embedding your demos.

Use [popcorn-gif](manual/popcorn-gif/index.md) to create a GIF file from your recording:

```sh
popcorn-gif demo.pop first.gif
```

See [popcorn-gif usage manual](manual/popcorn-gif/usage.md) for GIF generation details.

Using popcorn player to present a recording is usually a better choice than a
GIF file if you have the option of using `<script>` tags. Contrary to GIF, the
player provides the ability to pause, rewind, copy text, and it always renders
the terminal content as sharp as possible on a given display.

## Next steps

Thank you for taking the first steps with popcorn through this introductory
guide. Our goal was to provide you with a clear, high-level overview of the
popcorn tools and their usage.

For additional insights and answers, feel free to explore our [FAQ](faq.md)
section and join the conversation in the `#popcorn` room on the Matrix
network, `#popcorn:matrix.org` ([web
client](https://matrix.to/#/#popcorn:matrix.org)), or `#popcorn` IRC channel
on [Libera.Chat](https://libera.chat/) ([web
client](https://web.libera.chat/#popcorn)).

To stay updated on the latest developments and get useful tips, follow
[@popcorn@fosstodon.org](https://fosstodon.org/@popcorn) on Mastodon.

Happy recording!
