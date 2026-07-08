# popcorn server

__popcorn server__ is a server-side component of the popcorn ecosystem.

It implements a hosting platform for terminal session recordings and live
streaming. It offers a familiar web interface for viewing, browsing, sharing
and managing recordings and streams. This includes [HTTP
API](https://docs.popcorn.local/manual/server/api/), which is used by the
[popcorn CLI](https://docs.popcorn.local/manual/cli/index.md).

The server is built with [Elixir language](https://elixir-lang.org/) and
[Phoenix framework](https://www.phoenixframework.org/). It embeds popcorn's
virtual terminal, [avt](https://github.com/dotbrains/popcorn/tree/main/crates/avt), which is utilized by
tasks such as preview generation, recording analysis and live stream state
bookkeeping.

[popcorn.local](https://popcorn.local) is a public popcorn server instance
managed by the popcorn project team, providing free hosting for terminal
recordings and streams, available to everyone. Check
[popcorn.local/about](https://popcorn.local/about) to learn more about this
instance.

You can easily [self-host popcorn
server](https://docs.popcorn.local/manual/server/self-hosting) and use
the [popcorn CLI](https://docs.popcorn.local/manual/cli) with your
own instance. If you're not comfortable with hosting your data at
popcorn.local, if your company policy prevents you from doing so, or if you
simply prefer self-hosting everything, then popcorn has you covered.

Notable features:

- hosting of terminal session recordings in
  [popcast](https://docs.popcorn.local/manual/popcast/v3/) format,
- [live streaming](https://docs.popcorn.local/manual/server/streaming/) of
  terminal sessions,
- perfectly integrated [popcorn
  player](https://docs.popcorn.local/manual/player/) for best viewing experience,
- full-text search using recording titles, descriptions, and _full terminal
  session content_,
- easy [sharing](https://docs.popcorn.local/manual/server/sharing/) of
  recordings via secret links,
- easy [embedding](https://docs.popcorn.local/manual/server/embedding/) of the
  player, or linking via preview images (SVG),
- privacy friendly - no tracking, no ads,
- visibility control for recordings and streams: private, unlisted, or public,
- editable recording/stream metadata like title or long description (Markdown),
- configurable terminal themes and font families,
- download of plain text transcripts (`.txt`) of a recordings.

Refer to [popcorn server docs](https://docs.popcorn.local/manual/server/) for
further details.

## Donations

Sustainability of popcorn development relies on donations and sponsorships.

Please help the software project you use and love. Become a
[supporter](https://docs.popcorn.local/donations/#individuals) or a [corporate
sponsor](https://docs.popcorn.local/donations/#corporate-sponsorship).

popcorn is sponsored by:

- [Brightbox](https://www.brightbox.com/)

## Consulting

If you're interested in hosting, maintenance or customization of popcorn
server, check [popcorn consulting
services](https://docs.popcorn.local/consulting/).

## Copyright

© 2011 Marcin Kulik.

All code is licensed under the Apache License, Version 2.0. See LICENSE file for
details.
