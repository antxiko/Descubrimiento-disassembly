# CARGA LA CINTA EN openMSX Y VUELCA LA VRAM CON EL JUEGO YA EN MARCHA.
#
# Para que: los dibujos de tools/dibuja.py salen de leer la cinta con la
# geometria del TMS9918, y eso puede estar bien "de vista" y mal de verdad.
# Mirar la imagen no basta. Lo que cierra el asunto es volcar la VRAM de la
# maquina y compararla byte a byte con la que monta el script.
#
# La maquina tiene que ser un MSX1 con ROM real -aqui el Philips VG-8020-,
# porque el cargador llama a TAPION y TAPIN de la BIOS.
#
# Uso:  DESC_CAS=<ruta.cas> DESC_OUT=<dir> [DESC_TOPE=<segundos emulados>]
#           openmsx -machine Philips_VG_8020 -script este.tcl

set CAS  $::env(DESC_CAS)
set OUT  $::env(DESC_OUT)
set TOPE [expr {[info exists ::env(DESC_TOPE)] ? $::env(DESC_TOPE) : 900}]
file mkdir $OUT
set LOG [open "$OUT/carga.log" w]
proc say {m} {
    global LOG
    puts $LOG "\[emu [format %8.2f [machine_info time]]\] $m"
    flush $LOG
}

say "maquina: [machine_info config_name]"
set r [catch {cassetteplayer insert $CAS} msg]
say "cassetteplayer insert rc=$r: $msg"
if {$r} { say "ABORTADO"; exit 1 }
set throttle off
set speed 10000

proc arranca {} {
    say "tecleo RUN\"CAS:\""
    type "RUN\\\"CAS:\\\"\r"
    after time 2 vigila
}
after time 6 arranca

# El juego de la primera parte vive en 0x4200-0x5FFF; el cargador, en 0xD3xx.
# Se espera a que el PC lleve un buen rato ahi dentro.
set ::dentro 0
set ::hecho 0
proc vigila {} {
    global OUT TOPE
    set pc [reg PC]
    if {$pc >= 0x4200 && $pc < 0x6000} { incr ::dentro } else { set ::dentro 0 }
    if {$::dentro >= 8 && !$::hecho} {
        set ::hecho 1
        say [format "PC estable en la primera parte (0x%04X)" $pc]
        after time 5 vuelca
        return
    }
    if {[machine_info time] > $TOPE} {
        say [format "TOPE alcanzado sin ver el juego; PC=0x%04X" $pc]
        exit 1
    }
    after time 1 vigila
}

proc vuelca {} {
    global OUT
    say "vuelco la VRAM y la RAM"
    set f [open "$OUT/vram.bin" wb]
    fconfigure $f -translation binary
    for {set a 0} {$a < 16384} {incr a} {
        puts -nonewline $f [binary format c [debug read "VRAM" $a]]
    }
    close $f
    set g [open "$OUT/ram64k.bin" wb]
    fconfigure $g -translation binary
    for {set a 0} {$a < 65536} {incr a} {
        puts -nonewline $g [binary format c [debug read "memory" $a]]
    }
    close $g
    say [format "PC=0x%04X" [reg PC]]
    say "FIN"
    exit 0
}
