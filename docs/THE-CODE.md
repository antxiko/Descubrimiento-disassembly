# The code

15,504 bytes of code spread over **733 named routines**, none of them below the
comment bar. But the code sits in three places, not one, and the three are
independent.

| listing | instructions | routines | commented |
|---|---|---|---|
| `carga` | 88 | 9 | 26.1% |
| `p1bajo` | 3,451 | 371 | 27.2% |
| `p2bajo` | 3,126 | 353 | 26.3% |
| **total** | **6,665** | **733** | **26.7%** |

The two `alto` listings do not appear because they have not a single
instruction.

## The loader: 88 instructions that outlive everything

`carga` is the smallest program and the most important one. Of its 5,088 bytes
only **210 are code**; the rest is the loading screen and its font.

Its job is the loop at 0xD369: it starts the motor with TAPION, takes the sync,
and then reads **byte by byte with TAPIN**, with no header and no file BIOS,
splitting what arrives between 0x4000 and 0x8000. When it is done it jumps into
the code it has just loaded.

It lives at 0xD300-0xD3DF, which is **above anything a tape block reaches**, and
that is why it is still standing once the game is running. The two bytes at
0xD300 are not code but the address of that loop, and the first half uses them
to come back:

    5CC2  ld hl,(0xD300)
    5CC5  push hl
    5CC6  ret

## The three routines that upload graphics

Everything you see goes through one of these three, and each consumes tape at a
different rate:

| routine | consumes | what it does |
|---|---|---|
| `vuelca_patrones` (0x4497) | BC | uploads artwork, leaving colour alone |
| `vuelca_comprimido` (0x44CB) | BC + BC/8 | uploads artwork and then **one colour byte per tile**, stretched over its eight rows with FILVRM |
| `vuelca_con_color` (0x446D) | 2*BC | uploads artwork and the full colour table |

That `BC/8` in the middle one is the game's colour compression: one byte per
tile instead of eight. It is also what makes it possible to close the data
boundaries without eyeballing them — see [The tape](THE-CARTRIDGE.md).

## The music hangs off the keyboard hook, and only in the first half

The first half installs a `JP` at H.KEYI (0xFD9F) pointing to 0x4046: the music
plays on every scan interrupt, **before the BIOS reads the keyboard**.

The state is fourteen consecutive bytes, 0xF8CB-0xF8D8, with **three bytes per
channel** -score pointer and duration-. That is why the cursor at 0x4181 steps
by three and the same routine serves all three channels without a single table.
There are sixteen tunes indexed at 0xCB95.

The second half **installs nothing**: it writes the PSG straight from the main
loop, at 0x5213. Checked by searching for writes to 0xFD9A and 0xFD9F across all
traced code: there are none.

## A flag hidden inside the artwork itself

The first half's start-up does:

    420A  ld a,(0xC103)
    420D  cp 8
    420F  call nz, voltea_los_patrones

0xC103 is **not a variable**: it is a byte of the pattern table, used as a flag
so the same artwork is not flipped twice. The routine at 0x561D reverses the bit
order of every byte between 0xC102 and 0xC138, which is how the game gets its
mirrored artwork without spending any more tape.

The same trick is in the sprites: the routine at 0x4B1E flips them **in memory**
to draw the figure facing the other way. You can see it on the machine: of the
21,248 bytes of the first half's high block, openMSX finds only 45 written over,
and they are exactly those sprites (0x9E05-0x9E53) plus one tile the start-up
touches up (0x915B).

## How the wide screen is drawn

Screen 7 of the first half and the whole ship of the second come out of the same
kind of loop: a map wider than the screen, out of which a window is cut.

What says how wide it is **is not a constant in any table**: it is the loop's own
step between rows. In the ship map, the loop at 0x4285 adds **0x80** per row, and
that is what fixes the width at 128 tiles. If it had been misread, cross-checking
the window against the emulator's VRAM would come out at hundreds of differences;
it comes out at **zero** across all 768 tiles.

## The text, with a font borrowed from ROM

There are three blocks of strings, and only three:

| where | what |
|---|---|
| 0x8200 | the opening text, nine lines already broken to nineteen columns |
| 0xC28A | eleven on-screen labels |
| 0xCBF2 | five crossing disasters, 22 characters each and no terminator |

All of them are drawn with the BASIC ROM font (CGTABL, 0x1BBF), copied tile by
tile into the pattern table: the tape does not spend one byte on an alphabet of
its own for the game.

The only text that does **not** use that font is the loading screen's, which
uses its own tiles and is not even ASCII. That is covered in
[Findings](FINDINGS.md).
