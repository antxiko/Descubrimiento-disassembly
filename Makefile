# El Descubrimiento de America (Gema / OMK, 1987, MSX1) - desensamblado
#
# `make` extrae los cuatro ficheros de la cinta, monta la memoria como queda al
# cargar cada parte, la traza y comprueba que al rehacer los listados sale
# EXACTAMENTE el .cas original, byte a byte.
#
# Lo que hace raro a este juego: la cinta no trae UN programa sino DOS, cada uno
# de 30464 bytes, que ocupan LAS MISMAS DIRECCIONES en momentos distintos. El
# cargador de 0xD300 sobrevive a los dos y los lee con TAPIN byte a byte, sin
# cabecera. Por eso aqui hay cinco listados y no uno.

CAS     := descubrimiento.cas
CAS_SHA := ac7b780000c2b92f0cbbd89f9ee36e741beb88a41261920680235e84b1c53077
SYMS    := work/msx.sym
PY      := python3
PASMO   := C:/Users/Antxiko/AppData/Local/Programs/pasmo/pasmo.exe

LISTADOS := carga p1bajo p1alto p2bajo p2alto
ASMS     := $(patsubst %,src/descubrimiento_%.asm,$(LISTADOS))

export PYTHONIOENCODING=utf-8

.PHONY: all verify clean cinta extract cuerpos trazado listados sanity test \
        densidad imagenes emulador web sin_leer

all: verify test densidad

# ---------------------------------------------------------------- extraccion
cinta:
	@if [ ! -f "$(CAS)" ]; then \
	  echo ""; \
	  echo "  Falta la imagen de cinta: $(CAS)"; \
	  echo ""; \
	  echo "  No se distribuye con este repositorio, solo el trabajo de"; \
	  echo "  documentacion. Para reconstruirlo todo hace falta tu propia"; \
	  echo "  copia del .cas, con ese nombre y en la raiz del proyecto."; \
	  echo "  Debe dar este sha256:"; \
	  echo "      $(CAS_SHA)"; \
	  echo ""; \
	  exit 1; \
	fi
	@echo "$(CAS_SHA)  $(CAS)" | sha256sum -c - >/dev/null 2>&1 \
	  || echo "  AVISO: $(CAS) no da el sha256 esperado; los listados pueden no cuadrar."

extract: extracted/.stamp
extracted/.stamp: tools/cas_parse.py $(CAS) | cinta
	@mkdir -p work extracted
	$(PY) tools/cas_parse.py $(CAS) extracted > work/cas_parse.log
	@touch $@

cuerpos: work/modulos.json
work/modulos.json: tools/cuerpos.py extracted/.stamp
	$(PY) tools/cuerpos.py extracted work

# Los simbolos de la BIOS y de las variables de sistema del MSX. Se guardan en
# src/ y no se generan aqui: tools/gen_msx_syms.py los saca de los headers de
# MSXgl, que no tienen por que estar instalados para reconstruir el proyecto.
$(SYMS): src/msx.sym
	@mkdir -p work
	cp $< $@

# ------------------------------------------------------------------ trazado
# Cada parte se traza sobre su imagen de 64 KB: el codigo vive en 0x4000-0x5FFF
# pero lee tablas de 0x8000 arriba, y el trazador tiene que ver las dos mitades
# a la vez. Luego piezas.py corta el mapa en los dos trozos de cinta.
# z80trace solo admite UN fichero de zonas prohibidas, y aqui hay dos partes:
# las comunes a las dos imagenes de 64 KB (lo que la cinta no carga) y las
# propias de cada parte (sus graficos). Se pegan en work/.
work/p1.nocode: src/comun.nocode src/p1.datos
	@mkdir -p work
	cat src/comun.nocode src/p1.datos > $@
work/p2.nocode: src/comun.nocode src/p2.datos
	@mkdir -p work
	cat src/comun.nocode src/p2.datos > $@

work/p1.trace.json: tools/z80trace.py src/p1.entries work/p1.nocode work/modulos.json
	$(PY) tools/z80trace.py work/p1.img 0x0000 src/p1.entries work/p1 work/p1.nocode

work/p2.trace.json: tools/z80trace.py src/p2.entries work/p2.nocode work/modulos.json
	$(PY) tools/z80trace.py work/p2.img 0x0000 src/p2.entries work/p2 work/p2.nocode

work/carga.trace.json: tools/z80trace.py src/carga.entries src/carga.nocode work/modulos.json
	$(PY) tools/z80trace.py work/carga.bin 0xC000 src/carga.entries work/carga src/carga.nocode

work/p1bajo.trace.json work/p1alto.trace.json work/p2bajo.trace.json \
work/p2alto.trace.json &: tools/piezas.py work/p1.trace.json work/p2.trace.json
	$(PY) tools/piezas.py work

trazado: work/carga.trace.json work/p1bajo.trace.json

# ----------------------------------------------------------------- listados
listados: $(ASMS)

define LISTADO
src/descubrimiento_$(1).asm: work/$(1).trace.json src/$(1).notes tools/mkasm.py $(SYMS)
	$(PY) tools/mkasm.py work/$(1).bin $(2) work/$(1).trace.json \
	  src/$(1).notes $(SYMS) $$@ "EL DESCUBRIMIENTO DE AMERICA - MSX - $(3)"
endef
$(eval $(call LISTADO,carga,0xC000,el cargador de cinta y la pantalla de carga))
$(eval $(call LISTADO,p1bajo,0x4000,primera parte: el programa))
$(eval $(call LISTADO,p1alto,0x8000,primera parte: graficos y pantallas))
$(eval $(call LISTADO,p2bajo,0x4000,segunda parte: el programa))
$(eval $(call LISTADO,p2alto,0x8000,segunda parte: graficos y pantallas))

# ------------------------------------------------------------------ sanidad
sanity: listados
	@echo "=================================================================="
	@echo " Coherencia: ningun punto de entrada dentro de una zona de datos"
	@echo "=================================================================="
	@$(PY) tools/check_entradas.py src/p1.entries src/p1bajo.notes work/p1.nocode
	@$(PY) tools/check_entradas.py src/p2.entries src/p2bajo.notes work/p2.nocode
	@$(PY) tools/check_entradas.py src/carga.entries src/carga.notes src/carga.nocode
	@echo ""
	@echo "=================================================================="
	@echo " Sanidad del trazado: las zonas de datos no pueden salir como codigo"
	@echo "=================================================================="
	@$(PY) tools/check_trace.py work/p1.trace.json work/p1.nocode
	@$(PY) tools/check_trace.py work/p2.trace.json work/p2.nocode
	@$(PY) tools/check_trace.py work/carga.trace.json src/carga.nocode
	@echo ""
	@echo "=================================================================="
	@echo " Cruce COMPLETO: todas las zonas D contra lo que el trazador cree"
	@echo "=================================================================="
	@$(PY) tools/check_datos.py work src
	@echo ""
	@echo "=================================================================="
	@echo " La maquina de verdad: RAM y VRAM de openMSX contra el listado"
	@echo "=================================================================="
	@$(PY) tools/coteja.py work
	@echo ""
	@echo "=================================================================="
	@echo " Presupuesto de la cinta: no deben quedar bytes sin explicar"
	@echo "=================================================================="
	@$(PY) tools/presupuesto.py work src $(CAS)

verify: listados
	@$(PY) tools/verifica.py src work $(CAS)
	@$(MAKE) --no-print-directory sanity

densidad:
	@$(PY) tools/densidad_total.py src

imagenes: work/modulos.json
	@mkdir -p docs/imagenes
	@$(PY) tools/dibuja.py work docs/imagenes

# Los bytes que estan identificados pero que ninguna instruccion lee: casi todo
# es cola de bloque de tamano fijo. La cifra sale de las propias directivas D.
sin_leer:
	@$(PY) tools/sin_leer.py

# ------------------------------------------------------------------- la web
# Las paginas van en docs/ (ingles) y docs/es/ (castellano), y las dos portadas
# salen autocontenidas con las imagenes dentro. check_enlaces.py caza enlaces e
# imagenes rotas antes de publicar.
web:
	@$(PY) tools/md2html.py docs en
	@$(PY) tools/md2html.py docs/es es
	@$(PY) tools/make_web.py docs/imagenes docs/index.html en
	@$(PY) tools/make_web.py docs/imagenes docs/es/index.html es
	@$(PY) tools/check_enlaces.py docs

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@$(PY) -m unittest discover -s tests -v

clean:
	rm -rf extracted
	rm -f work/*.bin work/*.img work/*.json work/*.blocks work/*.log \
	      work/*.trace.json

# ---------------------------------------------------------------- emulador
# Carga la cinta en openMSX dos veces -una para cada parte del juego- y deja en
# work/omsx el volcado de la RAM y de la VRAM con el juego en marcha. Tarda
# unos minutos: son 36 y 66 KB de cinta a 1200 baudios, aunque emulados a toda
# velocidad. Luego coteja.py compara esos volcados con lo que dice el listado.
OPENMSX := C:/Program Files/openMSX/openmsx.exe
MAQUINA := Philips_VG_8020

emulador:
	@mkdir -p work/omsx
	DESC_CAS="$(CURDIR)/$(CAS)" DESC_OUT="$(CURDIR)/work/omsx" \
	  "$(OPENMSX)" -machine $(MAQUINA) \
	  -script "$(CURDIR)/tools/omsx_carga.tcl"
	DESC_CAS="$(CURDIR)/$(CAS)" DESC_OUT="$(CURDIR)/work/omsx" \
	  "$(OPENMSX)" -machine $(MAQUINA) \
	  -script "$(CURDIR)/tools/omsx_parte2.tcl"
	@$(PY) tools/coteja.py work
