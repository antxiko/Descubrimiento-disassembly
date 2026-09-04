# CARGA LA SEGUNDA PARTE Y VUELCA SU VRAM.
#
# Llegar a la segunda parte jugando no se puede automatizar, pero no hace
# falta: la primera parte termina saltando a (0xD300), que es 0xD369, el bucle
# del cargador. Aqui se hace ese mismo salto en cuanto la primera parte esta en
# marcha, y la cinta -que ya esta parada justo detras del bloque 1- entrega el
# bloque 2 igual que se lo entregaria al juego.
#
# El unico cuidado que hay que tener es callar antes el reproductor de musica:
# vive colgado de H.KEYI y su codigo esta en 0x4046, o sea justo donde va a
# caer el bloque nuevo. El propio juego hace lo mismo (0x5ECA) al cambiar de
# pantalla.
#
# Uso:  DESC_CAS=<ruta.cas> DESC_OUT=<dir> [DESC_TOPE=<segundos emulados>]
#           openmsx -machine Philips_VG_8020 -script este.tcl

set CAS  $::env(DESC_CAS)
set OUT  $::env(DESC_OUT)
set TOPE [expr {[info exists ::env(DESC_TOPE)] ? $::env(DESC_TOPE) : 1800}]
file mkdir $OUT
set LOG [open "$OUT/parte2.log" w]
proc say {m} {
    global LOG
    puts $LOG "\[emu [format %8.2f [machine_info time]]\] $m"
    flush $LOG
}

say "maquina: [machine_info config_name]"
set r [catch {cassetteplayer insert $CAS} msg]
if {$r} { say "ABORTADO: $msg"; exit 1 }
set throttle off
set speed 10000

proc arranca {} {
    say "tecleo RUN\"CAS:\""
    type "RUN\\\"CAS:\\\"\r"
    after time 2 vigila1
}
after time 6 arranca

set ::dentro 0
proc vigila1 {} {
    global TOPE
    set pc [reg PC]
    if {$pc >= 0x4200 && $pc < 0x6000} { incr ::dentro } else { set ::dentro 0 }
    if {$::dentro >= 8} {
        say [format "primera parte en marcha (PC=0x%04X); pido la segunda" $pc]
        after time 2 salta
        return
    }
    if {[machine_info time] > $TOPE} { say "TOPE en la primera parte"; exit 1 }
    after time 1 vigila1
}

proc salta {} {
    # calla la musica: su manejador esta en 0x4046 y el bloque nuevo lo pisa
    debug write memory 0xFD9F 0xC9
    set d [debug read memory 0xD300]
    set e [debug read memory 0xD301]
    set destino [expr {$d | ($e << 8)}]
    say [format "(0xD300) = 0x%04X; salto ahi" $destino]
    reg PC $destino
    reg SP 0xDAC0
    set ::dentro 0
    after time 1 vigila2
}

set ::hecho 0
proc vigila2 {} {
    global TOPE
    set pc [reg PC]
    if {$pc >= 0x401F && $pc < 0x5C3F} { incr ::dentro } else { set ::dentro 0 }
    if {$::dentro >= 8 && !$::hecho} {
        set ::hecho 1
        say [format "segunda parte en marcha (PC=0x%04X)" $pc]
        after time 5 vuelca
        return
    }
    if {[machine_info time] > $TOPE} {
        say [format "TOPE en la segunda parte; PC=0x%04X" $pc]
        exit 1
    }
    after time 1 vigila2
}

proc vuelca {} {
    global OUT
    say "vuelco la VRAM y la RAM de la segunda parte"
    set f [open "$OUT/vram2.bin" wb]
    fconfigure $f -translation binary
    for {set a 0} {$a < 16384} {incr a} {
        puts -nonewline $f [binary format c [debug read "VRAM" $a]]
    }
    close $f
    set g [open "$OUT/ram64k_2.bin" wb]
    fconfigure $g -translation binary
    for {set a 0} {$a < 65536} {incr a} {
        puts -nonewline $g [binary format c [debug read "memory" $a]]
    }
    close $g
    say "FIN"
    exit 0
}
