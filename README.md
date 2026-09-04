# El Descubrimiento de America (Gema / OMK, 1987) — a commented disassembly

A complete, commented disassembly of the MSX1 tape **El Descubrimiento de
America** (Gema Software / OMK Software, 1987), reproducible byte for byte.

**Web: <https://antxiko.github.io/Descubrimiento-disassembly/>** · [En castellano](README.es.md)

|  |  |
|---|---|
| Of the tape explained | **100%** — 0 bytes unaccounted for, of 66,016 |
| Reassembles | **byte for byte**, to the same sha256 |
| Listings commented | **26.7%** — 1,782 comments over 6,665 instructions |
| Routines below the 10% bar | **0** of 733 |

## Five listings, not one

The tape carries **two programs that occupy the same addresses** at different
times, so there is no single memory map to disassemble:

    src/descubrimiento_carga.asm    0xC000-0xD3DF  the loader
    src/descubrimiento_p1bajo.asm   0x4000-0x63FF  first half, the program
    src/descubrimiento_p1alto.asm   0x8000-0xD2FF  first half, the graphics
    src/descubrimiento_p2bajo.asm   0x4000-0x63FF  second half, the program
    src/descubrimiento_p2alto.asm   0x8000-0xD2FF  second half, the graphics

Each listing has its own `.notes` beside it. The tracer's inputs are per half,
because the two halves are traced as two different 64 KB memory images:

    src/*.notes              what is understood: data blocks and comments
    src/carga.entries        the loader's entry point, with its reason
    src/p1.entries           the first half's entry points, seven of them
    src/p2.entries           the second half's entry points, five of them
    src/comun.nocode         the parts of the 64 KB image the tape never loads
    src/p1.datos p2.datos    zones the tracer must not walk into
    tools/                   the tracer, the generator and the drawing tools
    docs/                    the website, in English and Spanish

## Running it

The tape is **not** distributed here. Put it in the root as
`descubrimiento.cas` (66,371 bytes, sha256 `ac7b780000c2b92f0cbbd89f9ee36e741beb88a41261920680235e84b1c53077`)
and run:

    make                # extract, trace, build, reassemble, verify, test

It ends with `OK: la cinta entera se reproduce byte a byte`, which means the
five listings give back the tape exactly.

## Some of what turned up

- **0xD300 is not code, it is a pointer.** It holds the address of the loop
  that reads a tape block, which is how the first half asks for the second
  without carrying the address in its own code — and why the `CARGA` file
  starts at 0xD302.
- **The BIOS never reads the two big blocks**: the loader reads them by hand,
  byte by byte, with TAPION and TAPIN, and splits each into 0x2400 bytes at
  0x4000 and 0x5300 at 0x8000.
- **The second half plays out inside the caravel** — a 128 x 52 tile cutaway of
  the ship, with a 32x24 window scrolling both ways.
- **What you buy is drawn stowed in the hold**: one pile per commodity, as many
  pieces as units remain.
- **7,564 bytes nobody reads** (11.5% of the tape), because the tape records
  fixed-size blocks no matter what. One stretch of them is the loading screen,
  still sat in memory when the block was recorded.
- **The publisher's signature has a typo on the tape**: OMIKRON *Softwarwe*.

The full list is in [Findings](https://antxiko.github.io/Descubrimiento-disassembly/FINDINGS.html),
and what is still **not** known in
[Open questions](https://antxiko.github.io/Descubrimiento-disassembly/OPEN-QUESTIONS.html).

## Legal

This is preservation, study and documentation work. The game and its artwork
remain the property of their rights holders; the tape image is not distributed.
See [LEGAL-NOTICE.md](LEGAL-NOTICE.md) and [LICENSE](LICENSE).
