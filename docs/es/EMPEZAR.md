# Empezar

Este repositorio no trae el juego. Trae el **desensamblado comentado** de *El
Descubrimiento de America* (Gema Software / OMK Software, 1987) y las
herramientas que lo reproducen.

## Lo que hace falta

- La cinta, 66.371 bytes exactos, en la raiz y con el nombre
  `descubrimiento.cas`. Su sha256 es
  `ac7b780000c2b92f0cbbd89f9ee36e741beb88a41261920680235e84b1c53077`.
- `pasmo` en el PATH.
- Python 3.
- `make`.

## La comprobacion que decide

    make                # extrae, traza, monta, reensambla, verifica y prueba

Termina con esto, y es lo unico que hay que mirar:

    OK: la cinta entera se reproduce byte a byte

Significa que los **cinco** listados de `src/`, ensamblados y vueltos a
envolver con las cabeceras y los centinelas del formato `.cas`, devuelven los
mismos 66.371 bytes. Si eso falla, todo lo demas sobra.

## Por que son cinco listados

Porque la cinta no trae un programa, trae **dos**, y los dos ocupan **las mismas
direcciones**. No hay un solo mapa de memoria que desensamblar: hay tres.

| listado | direcciones | bytes | que es |
|---|---|---|---|
| `carga` | 0xC000-0xD3DF | 5.088 | el cargador, que sobrevive a los dos programas |
| `p1bajo` | 0x4000-0x63FF | 9.216 | primera parte, el programa |
| `p1alto` | 0x8000-0xD2FF | 21.248 | primera parte, los graficos |
| `p2bajo` | 0x4000-0x63FF | 9.216 | segunda parte, el programa |
| `p2alto` | 0x8000-0xD2FF | 21.248 | segunda parte, los graficos |

Los dos listados `alto` no llevan **ni una instruccion**: son datos de punta a
punta.

## Lo que cada orden hace

| orden | que hace |
|---|---|
| `make extract` | trocea el `.cas` por el centinela y saca los cuatro ficheros |
| `make cuerpos` | monta la imagen de 64 KB tal como queda al cargar cada parte |
| `make trazado` | sigue el flujo desde los puntos de entrada de `src/*.entries` |
| `make listados` | escribe los cinco `.asm` juntando el trazado y las notas |
| `make verify` | ensambla, vuelve a envolver y compara el sha256 con el original |
| `make sanity` | lo que el reensamblado NO cubre (ver abajo) |
| `make test` | los tests |
| `make densidad` | cuanto de los listados esta comentado |
| `make sin_leer` | los bytes que nadie lee, contados desde las propias notas |
| `make imagenes` | dibuja las pantallas y los mapas desde la cinta |
| `make emulador` | carga la cinta en openMSX y coteja RAM y VRAM |
| `make web` | genera estas paginas |

## Por que `verify` no basta

`verify` demuestra que los bytes vuelven a salir, no que se hayan **entendido**.
Un listado en el que todo fuera `db` reensamblaria igual de bien. Por eso hay
cuatro controles mas, y los cuatro tienen que pasar:

- **`check_entradas`**: ningun punto de entrada del trazador cae dentro de un
  rango declarado como datos.
- **`check_trace`**: ninguna zona `.nocode` -lo que la cinta no llega a cargar-
  sale marcada como codigo. Sin esa barrera, un solo destino mal deducido mete
  al trazador en un mar de ceros y lo traza entero como `nop`: cobertura falsa.
- **`check_datos`**: las **103 zonas** de datos declaradas en los `.notes`,
  cruzadas una a una contra el trazado.
- **`presupuesto`**: ni un byte sin dueno. Ahora mismo, **66.016 de 66.016**.

Los 355 bytes que van del total de la cinta a esa cifra son el envoltorio del
`.cas`: seis centinelas de ocho bytes, dos cabeceras de fichero de dieciseis,
los seis de la cabecera BIN, los 256 del cargador BASIC, los dos tercetos de
sincronia y el relleno de alineacion. Ese reparto tambien lo comprueba un test.

## Y el control que no se puede falsear

`make emulador` carga la cinta de verdad en openMSX -un Philips VG-8020, que
hace falta porque el cargador llama a TAPION y TAPIN de la BIOS real- y vuelca
la RAM y la VRAM con el juego en marcha. `tools/coteja.py` compara eso con lo
que dicen los listados. Los resultados estan en
[En el emulador](EN-EL-EMULADOR.md).
