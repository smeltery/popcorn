---
hide:
  - toc
---

# popcorn CLI

__popcorn CLI__ (also known as popcorn "client" or "recorder") is a
command-line tool for recording and live streaming terminal sessions.

Unlike typical _screen_ recording software, which records visual output of a
screen into a heavyweight video files (`.mp4`, `.mov`), popcorn CLI runs
_inside a terminal_, capturing terminal session output into lightweight
recording files in the [popcast](../popcast/v3.md) format (`.pop`), or
streaming it live to viewers in real-time.

Recordings can be replayed in a terminal, embedded on a web page with the
[popcorn player](../player/index.md), or published to an [popcorn
server](../server/index.md), such as [popcorn.example.com](https://popcorn.example.com), for further
sharing. Live streams allow viewers to watch terminal sessions as they happen.
Existing ttyrec recordings can be imported into `.pop` files with the
`convert` command.

<div class="player" id="player-manual-cli-intro"></div>

Recording a terminal with popcast is just:

```sh
popcorn rec demo.pop
```

Similarly, live terminal streaming is as simple as:

```sh
popcorn stream -r
```

Check out the [quick start guide](quick-start.md) for installation and usage
overview, or the [conversion guide](converting.md) for importing ttyrec files
and generating transcripts.

---

Notable features:

- recording and replaying of sessions inside a terminal,
- conversion from popcast and ttyrec inputs into `.pop`, text, or raw terminal
  output,
- local and remote [live streaming](quick-start.md#stream-a-terminal-session)
  of terminal sessions to multiple viewers in real-time,
- [lightweight recording format](../popcast/v3.md), which is highly
  compressible (8% of the original size with `gzip` on average),
- integration with [popcorn server](../server/index.md), e.g.
  [popcorn.example.com](https://popcorn.example.com), for easy recording hosting and live
  streaming.

---

popcorn CLI is licensed under the PolyForm Shield License 1.0.0. Source code
and license are available at
[github.com/dotbrains/popcorn](https://github.com/dotbrains/popcorn).
