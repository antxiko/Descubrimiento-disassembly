# Aviso legal y atribucion

*(Also available [in English](LEGAL-NOTICE.md).)*

## De quien es cada cosa

**El juego no es nuestro.** *El Descubrimiento de America* lo publico **Gema
Software / OMK Software** para MSX en 1987, en cinta. Todos los derechos sobre
el juego siguen siendo de sus titulares.

**Lo que si es nuestro** son las herramientas de este repositorio, los
comentarios de los listados, el analisis y la documentacion. Eso se publica con
la licencia de `LICENSE`.

## Que hay en este repositorio

Los cinco ficheros `src/descubrimiento_*.asm` son el desensamblado comentado de
la cinta. Se publican para la **preservacion, el estudio y la documentacion** de
un titulo que es parte de la historia del software espanol para MSX.

Son cinco y no uno porque la cinta trae **dos programas que ocupan las mismas
direcciones** en momentos distintos: `carga` es el cargador, `p1bajo` y `p1alto`
la primera parte, y `p2bajo` y `p2alto` la segunda.

La imagen de la cinta (`.cas`) **no** se distribuye aqui. Quien quiera volver a
montar los listados tiene que poner la suya, y el `Makefile` comprueba su sha256
antes de hacer nada.

Las imagenes de `docs/imagenes/` no son ilustraciones traidas de fuera ni
capturas del emulador: las dibuja `tools/dibuja.py` leyendo los propios bloques
de la cinta, en las direcciones que dicen los listados. Son parte de la prueba
de que la lectura del binario es correcta: si estuviera mal, saldria ruido.

## En que se apoya

En nada de nadie. Todo lo que se afirma aqui sale de leer este binario o de
medirlo corriendo, y cada afirmacion lleva su evidencia al lado: la instruccion
que lee un dato, la tabla que cierra exactamente donde tiene que cerrar, o la
medida hecha en el emulador. Lo que no esta cerrado se dice que no lo esta, y
esta recogido en [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md).

## Si eres uno de los autores

Si trabajaste en *El Descubrimiento de America* o tienes derechos sobre el
juego, y preferirias que este material no estuviera publicado, **dilo y se
retira, sin discusion**. La intencion de este trabajo es justo la contraria de
perjudicarte: es dejar constancia de como se hizo.

Y si sabes **quien lo programo**, nos interesa: en las cinco piezas de la cinta
no hay ni un credito ni unas iniciales, y el unico nombre que aparece es el de
la casa, dibujado en la pantalla de carga.
