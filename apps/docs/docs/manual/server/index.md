---
hide:
  - toc
---

# popcorn server

__popcorn server__ is a server-side component of the popcorn ecosystem.

It implements a hosting platform for terminal session recordings and live
streaming. It offers a familiar web interface for viewing, browsing, sharing
and managing recordings and streams. This includes [HTTP API](api.md), which is
used by the [popcorn CLI](../cli/index.md).

The server is built with [Elixir language](https://elixir-lang.org/) and
[Phoenix framework](https://www.phoenixframework.org/). It embeds Popcorn's
virtual terminal library, [popcorn-terminal](https://github.com/smeltery/popcorn/tree/main/crates/avt),
which is used for preview generation, recording analysis, and live stream state
bookkeeping.

Popcorn is self-hosted by default. You can run a personal, team, or public
instance and point the [Popcorn CLI](../cli/index.md) at it with
`POPCORN_SERVER_URL=https://popcorn.example.com`.

---

Notable features:

- hosting of terminal session recordings in [popcast](../popcast/v3.md)
  format,
- [live streaming](streaming.md) of terminal sessions,
- perfectly integrated [popcorn player](../player/index.md) for best viewing
  experience,
- full-text search using recording titles, descriptions, and _full terminal
  session content_,
- easy [sharing](sharing.md) of recordings via secret links,
- easy [embedding](embedding.md) of the player, or linking via preview images
  (SVG),
- privacy friendly - no tracking, no ads,
- visibility control for recordings: private, unlisted, public,
- editable recording metadata like title or long description (Markdown),
- configurable terminal themes and font families (including Nerd Font
  variants),
- download of plain text transcripts (`.txt`) of recordings.

---

popcorn server is licensed under the PolyForm Shield License 1.0.0. Source code
and license are available at
[github.com/smeltery/popcorn](https://github.com/smeltery/popcorn).
