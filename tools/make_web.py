#!/usr/bin/env python3
"""Genera la portada de la web de El Descubrimiento de America, en dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/dibuja.py a
partir de los propios bytes de la cinta, ejecutando en Python las mismas
rutinas de volcado que corre el Z80. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre los listados generados, no de escribirlas a
# ojo: 66016 = 15504 + 50512, que es lo que imprime tools/presupuesto.py
# (make sanity). RUTINAS son las etiquetas con nombre propio y DENSIDAD la
# proporcion de instrucciones comentadas, las dos de tools/densidad_total.py
# (make densidad). SIN_LEER lo mide tools/sin_leer.py.
CODIGO = 15504
DATOS = 50512
CINTA = 66016              # sin el envoltorio del .cas (355 bytes mas)
RUTINAS = 733
ZONAS = 103
LISTADOS = 5
SIN_LEER = 7564
DENSIDAD = "26,7"
DENSIDAD_EN = "26.7"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="El Descubrimiento de America - desensamblado comentado",
        aviso="<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan "
              "<b>dibujadas desde los bytes de la cinta</b>, ejecutando en "
              "Python las mismas rutinas de volcado que corre el Z80. Los "
              "listados y las cifras se reproducen con <code>make</code>, y el "
              "reensamblado devuelve la cinta entera <b>byte a byte</b>.",
        claim="Dos programas que ocupan LAS MISMAS direcciones en momentos "
              "distintos, y por eso son cinco listados y no uno; una segunda "
              "parte que transcurre dentro de un plano de la carabela de "
              "128x52 baldosas; y 7.564 bytes que no lee nadie, porque la "
              "cinta graba bloques de tamano fijo pase lo que pase.",
        ficha=["Gema Software / OMK Software - <b>(c) 1987</b>",
               "Cinta, <b>66.371 bytes</b>",
               "MSX1 - <b>64 KB de RAM</b>", "Volcado <b>ac7b7800...</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "La cinta"),
                ("EL-CODIGO.html", "El codigo"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="La cinta en cifras", h_find="Lo que aparecio al desmontarlo",
        h_scr="Lo que dibuja la cinta",
        cifras=[("100 %", "de la cinta explicado"),
                (str(RUTINAS), "rutinas con nombre"),
                (DENSIDAD + " %", "de los listados comentado"),
                (mil(CODIGO, "es"), "bytes de codigo"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen esta de donde sale y que se esta "
                 "viendo.",
        pie_leg="Esto es trabajo de documentacion y preservacion: el codigo y "
                "los graficos siguen siendo de sus autores y de Gema / OMK "
                "Software, y la imagen de la cinta no se distribuye.",
    ),
    "en": dict(
        titulo="El Descubrimiento de America - a commented disassembly",
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the tape</b>, by running in Python the same "
              "upload routines the Z80 runs. The listings and the numbers "
              "are reproducible with <code>make</code>, and reassembling "
              "gives back the whole tape <b>byte for byte</b>.",
        claim="Two programs that occupy THE SAME addresses at different "
              "times, which is why there are five listings and not one; a "
              "second half that plays out inside a 128x52 tile cutaway of the "
              "caravel; and 7,564 bytes nobody ever reads, because the tape "
              "records fixed-size blocks no matter what.",
        ficha=["Gema Software / OMK Software - <b>(c) 1987</b>",
               "Tape, <b>66,371 bytes</b>",
               "MSX1 - <b>64 KB of RAM</b>", "Dump <b>ac7b7800...</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The tape"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The tape in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the tape draws",
        cifras=[("100%", "of the tape explained"),
                (str(RUTINAS), "named routines"),
                (DENSIDAD_EN + "%", "of the listings commented"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Gema / OMK "
                "Software, and the tape image is not distributed.",
    ),
}

# El contenido propio de este cartucho vive aparte, en contenido_web.py:
# asi el generador no lleva dentro ni un texto del juego anterior.
from contenido_web import HALLAZGOS, GALERIA        # noqa: E402


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que la propia cinta pinta en su pantalla de carga, dibujado desde los
    # bytes por dibuja.py y recortado. Si el PNG no esta, el trabajo NO esta
    # hecho: se cae al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" '
                f'alt="El Descubrimiento de America">'
                if os.path.exists(ruta_logo)
                else "<h1>El Descubrimiento de America</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        # un "{}" en el nombre se sustituye por el idioma: asi la lamina de
        # figuras sale rotulada en el idioma de la pagina
        if "{}" in fich:
            fich = fich.format("" if idioma == "es" else "_" + idioma)
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' - '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
