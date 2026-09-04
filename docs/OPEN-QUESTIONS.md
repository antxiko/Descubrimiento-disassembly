# Open questions

Every byte of the tape is accounted for and every routine has a name, but that
does not mean everything is known. What is still open is set out here, with the
measurement that has been made and the one that has not.

## 1. What the block fillers are

There are three, **4,534 bytes in total**, and no instruction reads them:

| listing | range | bytes |
|---|---|---|
| `p1bajo` | 0x5FF8-0x63FF | 1,032 |
| `p2bajo` | 0x5C7A-0x63FF | 1,926 |
| `p2alto` | 0xCCD8-0xD2FF | 1,576 |

### What is known

**The first half's is empty.** It repeats `00 FF FF FF FF 00 00 00` from 0x5FF9
with not a single exception, and its autocorrelation is 100% at every multiple
of 8. It does not carry one bit of information.

**The second half's two do not.** They have 39 and 13 distinct values, and a
clear structure: eight-byte records in which **four end in `F` and four end in
`0`**.

### What has been ruled out, and with what measurement

**It is not a SCREEN 2 colour table**, however much it looks like one. Two
measurements knock that down:

- The low nibble is 0 or F in **100%** of the bytes; across this same game's
  colour tables that happens between 0% and 36.5% of the time
  (`colores_comunes` 12.5, `pantalla_1_colores` 0.0, `pantalla_4_colores` 4.4,
  `fuente_barco_colores` 6.3, `pantalla_3_colores` 36.5). The only table on the
  tape with this shape is the loading screen's, which is ink on white and gives
  98.4%.
- And above all, **the phase**. Sweeping all eight possible offsets, the
  four-and-four rule holds at 100% starting at 0x5C7A, 0xCCDA and 0x5FFA, and
  only at 50% at the 8-aligned addresses. In all three fillers the records fall
  at addresses with **remainder 2 when divided by 8**. A SCREEN 2 colour table
  is 8-aligned by construction, base + tile*8.

**It is not a picture**: drawn at widths 32, 40, 48 and 64 all that comes out is
vertical stripes, which is what an eight-byte structure with nothing in two
dimensions produces.

**It is not a copy of anything on the tape**: searching 24-byte windows across
the five listings, `p2bajo`'s filler does not appear outside itself.

**It was not on screen**: against the two openMSX VRAM dumps, 16 KB each, there
is **not one 32-byte match**.

**It is not what the first half left in memory** at those addresses: 27.5% and
4.1% of the bytes match, against a background match between the two programs of
2.3%.

### What is left

That the phase is **the same across all three fillers**, living in unrelated
areas of memory, says the three come from the same place and that it is not
coincidence. The live lead is that two-byte offset: it points at eight-byte
records with a two-byte header in front, or at a buffer that starts two bytes
in. What exactly, is not known.

## 2. The sprites nobody names

From 0xA66D to 0xA6BF in the first half there are 0x53 bytes that are **still
sprite artwork** -two more blocks of the 0x30 series the routine at 0x59FB uses,
the second one cut in half- but that no instruction names. From 0xA6C0 to 0xAAFC
there are 1,085 consecutive zeros, with not one exception.

It could be an animation that was dropped, or simply reserved room. There is no
way to settle it from the binary.

## 3. No full game has been played

The game has been loaded and started in openMSX, and the second half has been
reached by forcing the jump to (0xD300), but it has **not been played from start
to finish**.

What that means: the screen names come from looking at the artwork, and the
mechanics -what each object does, how you move between screens, what each
setback counts- come from reading the code. Playing it properly would probably
correct one or two.

## 4. Who programmed it

Across the five pieces on the tape there is **not one credit nor a set of
initials** in ASCII. The only texts are the opening, eleven on-screen labels and
five disaster messages. The only name that shows up is the publisher's, and it
is drawn in tiles, not written: **OMIKRON Softwarwe**, typo included.

If anyone knows who signed this game, we would like to hear.
