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
[Phoenix framework](https://www.phoenixframework.org/). It embeds popcorn's
virtual terminal, [popcorn-terminal](https://github.com/dotbrains/popcorn), which is utilized by
tasks such as preview generation, recording analysis and live stream state
bookkeeping.

[popcorn.local](https://popcorn.local) is a public popcorn server instance
managed by the popcorn project team, providing free hosting for terminal
recordings and streams, available to everyone. Check
[popcorn.local/about](https://popcorn.local/about) to learn more about this
instance.

You can easily [self-host popcorn server](self-hosting/index.md) and use the
[popcorn CLI](../cli/index.md) with your own instance. If you're not
comfortable with hosting your data at popcorn.local, if your company policy
prevents you from doing so, or if you simply prefer self-hosting everything,
then popcorn has you covered.

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

popcorn server is free and open-source software (FOSS). Source code and
license available at
[github.com/dotbrains/popcorn](https://github.com/dotbrains/popcorn).
