# Legal notice and attribution

*(Tambien disponible [en castellano](AVISO-LEGAL.md).)*

## Who owns what

**The game is not ours.** *El Descubrimiento de America* was published by **Gema
Software / OMK Software** for the MSX in 1987, on tape. All rights over the game
remain with their holders.

**What is ours** are the tools in this repository, the comments in the listings,
the analysis and the documentation. Those are published under the licence in
`LICENSE`.

## What is in this repository

The five `src/descubrimiento_*.asm` files are the commented disassembly of the
tape. They are published for the **preservation, study and documentation** of a
title that is part of the history of Spanish MSX software.

There are five and not one because the tape carries **two programs that occupy
the same addresses** at different times: `carga` is the loader, `p1bajo` and
`p1alto` the first half, and `p2bajo` and `p2alto` the second.

The tape image (`.cas`) is **not** distributed here. Anyone who wants to rebuild
the listings has to supply their own, and the `Makefile` checks its sha256
before doing anything.

The pictures in `docs/imagenes/` are not artwork brought in from elsewhere, nor
emulator captures: `tools/dibuja.py` draws them by reading the tape's own
blocks, at the addresses the listings give. They are part of the proof that the
reading of the binary is correct: if it were wrong, they would come out as
noise.

## What it rests on

On nobody else's work. Everything asserted here comes from reading this binary
or from measuring it running, and every claim carries its evidence beside it:
the instruction that reads a piece of data, the table that ends exactly where it
has to end, or the measurement taken in the emulator. What is not settled is
said not to be, and it is collected in
[Open questions](docs/OPEN-QUESTIONS.md).

## If you are one of the authors

If you worked on *El Descubrimiento de America* or hold rights over the game,
and you would rather this material were not published, **say so and it comes
down, no argument**. The intent of this work is the opposite of harming you: it
is to leave a record of how it was made.

And if you know **who programmed it**, we would like to hear: there is not one
credit nor a set of initials across the five pieces on the tape, and the only
name that shows up is the publisher's, drawn on the loading screen.
