# In the emulator

Reading the binary is not enough. This game has been **actually loaded** in
openMSX, and the RAM and VRAM with the game running have been compared byte for
byte with what the listings say.

## How it is done

    make emulador

`tools/omsx_carga.tcl` and `tools/omsx_parte2.tcl` load the tape on a **Philips
VG-8020**, which is an MSX1 with real ROM. The real machine is needed: the
loader calls the BIOS TAPION and TAPIN, so without ROM there is no load. The
scripts leave RAM and VRAM dumps in `work/omsx`, and `tools/coteja.py` compares
them with the listings.

It takes a few minutes: 36 and 66 KB of tape at 1200 baud, even emulated at full
speed.

## What comes out

    OK   0x4000-0x63FF = low part of the block    9216 bytes, 0 different
    OK   0x8000-0xD2FF = high part (45 bytes the game writes over)  21248 bytes
    OK   0xD300-0xD3DF = the loader (2 working bytes)    224 bytes
    OK   and the ones written over are the expected ones   45 addresses

    OK   name table, minus the wave band    704 bytes, 0 different
    OK   patterns of the tiles that are visible    0 different
    OK   colours of the tiles that are visible     0 different

    OK   0x4000-0x63FF = low part of the block    9216 bytes, 0 different
    OK   0x8000-0xD2FF: what is written over falls in the two work areas  743 bytes
    OK   patterns of the ship font, all three thirds  6144 bytes, 0 different
    OK   the window of the 128x52 map    768 tiles, 0 different

    OK: the machine says the same as the disassembly

## What each line proves

**The split of the tape comes out at zero differences** across 0x4000-0x63FF, in
both halves. Which means the carving up of the headerless block -three sync
bytes, 0x2400 low, 0x5300 high- is exactly what the machine does.

Of the 21,248 bytes of the first half's high block, the machine writes over only
**45**, and they are exactly the ones the listing says get written over: 0x915B,
a tile the start-up touches up, and 0x9E05-0x9E53, the sprites the routine at
0x4B1E flips in memory to draw the figure facing the other way.

In the second half the **743 bytes written over all fall** inside the two
declared work areas: the ship's record (0xB000) and the copy of the screen
(0xB058-0xB357).

**Screen 0, built by hand** from the tape by repeating the game's three upload
routines, matches the real VRAM byte for byte across every tile that is visible.
That is what settles that the three upload routines — and with them the
boundaries of the 103 data blocks — are read correctly.

And the **32x24 window of the ship map matches across all 768 tiles** with the
cut of the 128x52 map at column 50 and row 16, which are the first two bytes of
0xCBC6. If the width of 128 were wrong, this would come out at hundreds of
differences.

## The differences that show up and are not errors

They are listed one by one inside `coteja.py` itself, not hidden:

- **the wave band on rows 18 and 19**, which is animated and therefore matches
  no still frame;
- **tiles 199 onwards of the third third**, which are the text band: it is
  painted with the BASIC ROM font, which does not come on the tape;
- **the sprites**, which the game flips in memory depending on which way the
  figure is looking.

## How to reach the second half

The second half cannot be reached without playing the first all the way
through. To dump it, `omsx_parte2.tcl` forces the jump the game itself makes on
finishing:

    ld hl,(0xD300) / push hl / ret

which is what hands control back to the loader so it asks for the next block.

## What this does NOT prove

That a full game has been played. **It has not.** The screen names come from
looking at the artwork, and the mechanics -what each object does, how you move
between screens, what each setback counts- come from reading the code. Playing
it properly would probably correct one or two. That is said in
[Open questions](OPEN-QUESTIONS.md) too.
