# The tape

66,371 bytes, sha256 `ac7b7800...`. Inside there is not one program: there are
four files, and two of them are whole programs that occupy the same addresses.

## The four files

`tools/cas_parse.py` splits the `.cas` on the eight-byte sentinel and finds
this:

| # | type | name | contents |
|---|---|---|---|
| 00 | ASCII | `DSCRMT` | 256 bytes: one line of BASIC |
| 02 | BIN | `CARGA ` | 5,088 bytes, 0xC000-0xD3DF, runs from 0xD302 |
| 04 | headerless | — | 30,472 bytes: the FIRST half |
| 05 | headerless | — | 30,467 bytes: the SECOND half |

The ASCII file is literally one line:

    1 CLEAR 0,57107!:POKE 65535!,168:BLOAD "CAS:",R

`CLEAR 0,57107` puts HIMEM at 0xDF13, and the `POKE 65535,168` writes 0xA8 into
the page 3 subslot register, which only has any effect on machines with an
expanded slot.

## The BIOS never reads the two big blocks

Files 04 and 05 have **no header**, so `BLOAD` would not know what to do with
them. The loader's loop at 0xD369 reads them by hand, with TAPION and TAPIN,
byte by byte, and splits each into three pieces:

- three sync bytes, `03 02 01`;
- **0x2400 bytes (9,216) at 0x4000-0x63FF**: the program;
- **0x5300 bytes (21,248) at 0x8000-0xD2FF**: graphics, screens and tables.

3 + 9,216 + 21,248 = **30,467**, which is exactly block 05. Block 04 is five
bytes longer, and they are `.cas` alignment padding: zeros, checked.

## The memory map, of which there are three

    0x0000-0x3FFF   BASIC ROM (the font comes from here, CGTABL 0x1BBF)
    0x4000-0x63FF   the program of whichever half is loaded
    0x6400-0x7FFF   not used by the tape
    0x8000-0xD2FF   the graphics of whichever half is loaded
    0xD300-0xD3DF   the loader, which survives both halves
    0xD3E0-0xFFFF   game and system variables

That **no tape block reaches past 0xD2FF** is what makes the whole arrangement
possible: the loader stays alive at 0xD300-0xD3DF from beginning to end, and
above it there is room for the six bytes the two halves hand over.

Since the program loads at 0x4000, the machine needs **RAM in page 1**, that is,
64 KB.

## The five listings

That split is where the project's five listings come from:

| listing | org | bytes | code | data |
|---|---|---|---|---|
| `carga` | 0xC000 | 5,088 | 210 | 4,878 |
| `p1bajo` | 0x4000 | 9,216 | 8,079 | 1,137 |
| `p1alto` | 0x8000 | 21,248 | 0 | 21,248 |
| `p2bajo` | 0x4000 | 9,216 | 7,215 | 2,001 |
| `p2alto` | 0x8000 | 21,248 | 0 | 21,248 |
| **total** | | **66,016** | **15,504** | **50,512** |

Three quarters of the tape is data. The two `alto` listings have not a single
instruction.

## Where the data boundaries fall

The 103 declared data ranges are **not eyeballed**. In the first half they come
out of the game's own three upload routines, which say how many bytes of tape
each block consumes:

| routine | consumes |
|---|---|
| `vuelca_patrones` (0x4497) | BC bytes |
| `vuelca_comprimido` (0x44CB) | BC of artwork + BC/8 of colour, one byte per tile stretched over its eight rows with FILVRM |
| `vuelca_con_color` (0x446D) | 2*BC |

Chaining those sums, the end of each block falls **exactly** on the start of the
next, from 0xAB60 to 0xC012, with not one gap. A test checks the whole chain.

## What is left over at the end of each block

The tape records 0x2400 and 0x5300 bytes **no matter what**, but the first
half's program ends at 0x5F9F and the second's at 0x5C3F. Whatever was in memory
got recorded behind them.

Altogether that is **7,564 bytes out of 66,016 (11.5%)** that are identified and
accounted for but that no instruction reads. `make sin_leer` counts them from
the notes themselves:

| listing | region | range | bytes |
|---|---|---|---|
| `carga` | assembly leftover | D3D8-D3DF | 8 |
| `p1bajo` | assembly leftovers | 5F9F-5FF7 | 89 |
| `p1bajo` | block filler | 5FF8-63FF | 1,032 |
| `p1alto` | sprite gap | A66D-AAFC | 1,168 |
| `p1alto` | loading-screen colour tail | CC56-CFFF | 938 |
| `p1alto` | copy of the loading screen | D000-D2FF | 768 |
| `p2bajo` | assembly leftovers | 5C3F-5C79 | 59 |
| `p2bajo` | block filler | 5C7A-63FF | 1,926 |
| `p2alto` | block filler | CCD8-D2FF | 1,576 |
| | | **TOTAL** | **7,564** |

The three "assembly leftovers" -one per program, loader included- are a
**truncated copy of the program's own code**, always cut mid-instruction:

| program | leftover | copy of |
|---|---|---|
| `carga` | 0xD3D8-0xD3DF | 0xD358-0xD35F |
| first half | 0x5F9F-0x5FF7 | 0x5F1F-0x5F77, 0x80 higher up |
| second half | 0x5C42-0x5C79 | 0x5BC2-0x5BF9 |

All three checked byte for byte. Nobody executes them, and they look like a slip
of whatever tool the blocks were built with.

What is in the fillers, and what is not known about them, is in
[Open questions](OPEN-QUESTIONS.md).
