---
hide:
  - toc
---

# How it works

Unlike traditional screen recording tools that capture video, popcorn
captures the textual output, making the recording files and terminal live
streams very lightweight and easy to share.

popcorn's recording process is deeply rooted in the Unix pseudo-terminal (PTY)
concept, a mechanism shared by commands like `ssh`, `screen`, and `script`. A
PTY is essentially a pair of pseudo-devices: the slave, which emulates a real
text terminal, and the master, which a terminal emulator process uses to control
the slave.

Whether you record with `popcorn rec <filename>` or stream with `popcorn
stream`, popcorn acts as the master, interfacing between the user and the
shell. This setup allows popcorn to transparently capture all terminal
outputs, including text and invisible escape/control sequences, in their raw,
unfiltered form. Additionally, the use of PTY lets popcorn capture terminal
window resize events, and when enabled, also keyboard input.

When recording with `popcorn rec`, the recordings are saved in
[popcast](manual/popcast/v3.md) format, designed for simplicity and
interoperability. Every detail of the terminal session is encoded as a sequence
of time-stamped events, preserving not only the content but also the rhythm and
flow of the session. Similarly, when streaming with `popcorn stream`, the
session live stream is transmitted to the viewers in real-time using
lightweight, WebSocket-based [streaming protocol](manual/server/streaming.md),
which ensures minimal latency and perfect fidelity.

Displaying a captured session involves more than just displaying text; it
requires interpreting a complex series of ANSI escape code sequences to
accurately render what was captured. When you replay in a terminal, with
`popcorn play <filename>`, your terminal does the job of interpreting and
rendering the recorded content. popcorn simply leverages the terminal to do
the heavy lifting.

However, playback in a web browser is another story. To do that we need
something that can interpret ANSI sequences and produce visual representation of
a terminal window. Therefore, [popcorn player](manual/player/index.md) is
powered by a bespoke terminal emulator, [popcorn-terminal](https://github.com/smeltery/popcorn),
based on [Paul Williams' parser for ANSI-compatible video
terminals](https://vt100.net/emu/dec_ansi_parser). This emulator is specifically
tailored to replicate the display aspect of terminal emulation, handling color
changes, cursor movements, and accurate placement of text on the screen. It
ensures that all text attributes, including color, and styles like bold,
underline, inverse, are perfectly rendered, creating a faithful viewing
experience.

For implementation details check out [popcorn CLI source
code](https://github.com/smeltery/popcorn), [popcorn server source
code](https://github.com/smeltery/popcorn) and [popcorn player
source code](https://github.com/smeltery/popcorn).
