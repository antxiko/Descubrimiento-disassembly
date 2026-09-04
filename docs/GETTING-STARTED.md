# Getting started

This repository does not carry the game. It carries the **commented
disassembly** of *El Descubrimiento de America* (Gema Software / OMK Software,
1987) and the tools that reproduce it.

## What you need

- The tape, exactly 66,371 bytes, in the root, named `descubrimiento.cas`. Its
  sha256 is
  `ac7b780000c2b92f0cbbd89f9ee36e741beb88a41261920680235e84b1c53077`.
- `pasmo` on the PATH.
- Python 3.
- `make`.

## The check that decides

    make                # extract, trace, build, reassemble, verify, test

It ends with this, and it is the only thing you have to look at:

    OK: la cinta entera se reproduce byte a byte

It means the **five** listings in `src/`, assembled and wrapped back up with the
headers and sentinels of the `.cas` format, give back the same 66,371 bytes. If
that fails, nothing else matters.

## Why five listings

Because the tape does not carry one program, it carries **two**, and both occupy
**the same addresses**. There is no single memory map to disassemble: there are
three.

| listing | addresses | bytes | what it is |
|---|---|---|---|
| `carga` | 0xC000-0xD3DF | 5,088 | the loader, which survives both programs |
| `p1bajo` | 0x4000-0x63FF | 9,216 | first half, the program |
| `p1alto` | 0x8000-0xD2FF | 21,248 | first half, the graphics |
| `p2bajo` | 0x4000-0x63FF | 9,216 | second half, the program |
| `p2alto` | 0x8000-0xD2FF | 21,248 | second half, the graphics |

The two `alto` listings do not hold **a single instruction**: they are data end
to end.

## What each command does

| command | what it does |
|---|---|
| `make extract` | splits the `.cas` on the sentinel and pulls out the four files |
| `make cuerpos` | builds the 64 KB image as it stands once each half is loaded |
| `make trazado` | follows the flow from the entry points in `src/*.entries` |
| `make listados` | writes the five `.asm` files, joining the trace and the notes |
| `make verify` | assembles, wraps back up and compares the sha256 with the original |
| `make sanity` | what reassembly does NOT cover (see below) |
| `make test` | the tests |
| `make densidad` | how much of the listings is commented |
| `make sin_leer` | the bytes nobody reads, counted from the notes themselves |
| `make imagenes` | draws the screens and maps from the tape |
| `make emulador` | loads the tape in openMSX and cross-checks RAM and VRAM |
| `make web` | generates these pages |

## Why `verify` is not enough

`verify` proves the bytes come back out, not that they have been **understood**.
A listing where everything was a `db` would reassemble just as well. So there
are four more checks, and all four have to pass:

- **`check_entradas`**: no tracer entry point falls inside a range declared as
  data.
- **`check_trace`**: no `.nocode` region -what the tape never loads- comes back
  marked as code. Without that barrier a single wrongly deduced destination
  sends the tracer into a sea of zeros and it "traces" the lot as `nop`: false
  coverage.
- **`check_datos`**: the **103 data regions** declared in the `.notes`,
  cross-checked one by one against the trace.
- **`presupuesto`**: not one byte without an owner. Right now, **66,016 of
  66,016**.

The 355 bytes between that figure and the tape's total are the `.cas` wrapper:
six eight-byte sentinels, two sixteen-byte file headers, the six of the BIN
header, the 256 of the BASIC loader, the two sync triplets and the alignment
padding. A test checks that split too.

## And the check that cannot be faked

`make emulador` loads the tape for real in openMSX -a Philips VG-8020, needed
because the loader calls the real BIOS TAPION and TAPIN- and dumps RAM and VRAM
with the game running. `tools/coteja.py` compares that with what the listings
say. The results are in [In the emulator](IN-THE-EMULATOR.md).
