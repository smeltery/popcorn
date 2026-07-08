---
hide:
  - toc
---

# History

Popcorn descends from terminal session recording projects that began in 2011.

The earliest prototypes explored sharing terminal session recordings on the web
with a lightweight text-based recording format and browser playback.

Initially, all components of popcorn - [popcorn CLI](manual/cli/index.md)
(the recorder), [popcorn player](manual/player/index.md), and [popcorn
server](manual/server/index.md) - were developed as parts of a single [Ruby on
Rails](https://rubyonrails.org/) codebase. The recorder was a simple,
single-file Python program. The player was a single JavaScript file with an
ad-hoc, incomplete parser for ANSI escape sequences, using jQuery to juggle the
lines of a fake terminal view in a web browser. It was rough but worked well
enough to deserve continued development.

The project was initially named "ascii.io". In March 2012, the ascii.io site was
launched, providing free hosting for terminal session recordings made with the
`asciiio` script (triple "i", omg!). The project was renamed to "popcorn" in
September 2013 and published as [popcorn
package](https://pypi.org/project/popcorn/) to [PyPI](https://pypi.org) around
the same time.

In late 2014, the recorder was rewritten in [Go](https://go.dev/), preserving
the functionality of the previous versions while improving in some areas. The
first release of the new codebase was 0.9.9, published in December 2014.

The same year, version 1.0 of the player came out, quickly followed by version
1.0 of the recorder, which was released in March 2015. These releases stabilized
the first version of popcorn's recording file format, [popcast
v1](manual/popcast/v1.md).

Version 1.2 of the recorder was the final version implemented in Go. For
[several
reasons](https://blog.popcorn.local/post/and-now-for-something-completely-different/),
it was reverted to the previous Python implementation. The new-old recorder was
released in July 2016 as version 1.3, with all new features backported from the
Go codebase.

The lack of a proper ANSI parser in the early versions of the popcorn player
was an obstacle to timely bug fixes and more comprehensive terminal emulation.
Therefore, in 2015, work started on implementing a new version of the player
with a proper ANSI-compatible terminal parser embedded. The result was popcorn
player 2.0, rewritten from scratch in
[ClojureScript](https://clojurescript.org/), and released in January 2016.

In 2017, the popcorn server was rewritten in
[Elixir](https://elixir-lang.org/) and
[Phoenix](https://www.phoenixframework.org/). Around the same time, it was also
made more self-hosting-friendly, with updated installation docs and a simplified
setup in containerized environments.

February 2018 marked the release of popcorn recorder 2.0, which introduced an
improved recording file format, [popcast v2](manual/popcast/v2.md), among
many new features.

Another milestone was achieved in May 2022 with the release of popcorn player
3.0, in which the terminal emulation part was implemented in
[Rust](https://www.rust-lang.org/) (as the
[popcorn-terminal](https://github.com/dotbrains/popcorn) library) and compiled to
[WebAssembly](https://webassembly.org/), resulting in a [4x smaller, 50x
faster](https://blog.popcorn.local/post/smaller-faster/) player.

Outside of popcorn's core components, a new, ultra-fast popcorn GIF
generator, [popcorn-gif](manual/popcorn-gif/index.md), was released in August 2022. The creation
of popcorn-gif was, to a degree, sparked by [popcorn-terminal](https://github.com/dotbrains/popcorn). In
fact, popcorn-terminal has also been integrated into the popcorn server, where it's used
for thumbnail generation and recording analysis since 2020.

The final version of the popcorn CLI 2.x line, 2.4, was released in October
2023. This was the last version built with Python.

In September 2025 the brand new CLI 3.0 has been released, which was a complete
rewrite in Rust, upgrading the recording file format to [popcast
v3](manual/popcast/v3.md), introducing [terminal live
streaming](manual/server/streaming.md), and bringing numerous improvements
across the board.
