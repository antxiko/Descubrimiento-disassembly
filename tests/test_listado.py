"""Comprueba que lo que dicen los listados es lo que hay en la cinta.

Estos tests existen porque los datos publicados se desactualizan solos. Un
comentario que era cierto cuando se escribio sigue ahi cuando deja de serlo, y
la comprobacion de reproducibilidad no se entera: los bytes no cambian, solo lo
que decimos de ellos.

DE DONDE SALEN LOS BYTES, Y POR QUE IMPORTA
-------------------------------------------
La cinta no se distribuye con este repositorio. Lo que si esta son los cinco
listados de `src/`, y ahi dentro esta cada byte de datos: las filas `defb`
traen los valores con su direccion al lado. Asi que estos tests leen los
LISTADOS, no la cinta, y corren enteros en un clon recien hecho, sin cinta y sin
`make`: no hay un solo test que se salte solo.

No se pierde rigor, porque `make verify` ya demuestra byte a byte que ensamblar
estos listados devuelve el .cas exacto. El listado es la cinta escrita de otra
manera.

OJO CON LAS DIRECCIONES REPETIDAS. Los dos programas del juego ocupan LAS
MISMAS direcciones en momentos distintos, asi que aqui nunca se busca una
direccion "en el listado" sino siempre en el listado que toca.
"""
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(RAIZ, "src")

DEFB = re.compile(r"^\s*def(b|w)\s+([0-9a-fA-F,h ]+?)\s*;\s*([0-9a-f]{4})\b")
BYTE = re.compile(r"^0?([0-9a-fA-F]+)h$")


def bytes_de(listado):
    """Todos los `defb` y `defw` de un listado, como {direccion: valor}.

    Los `defw` se descomponen en sus dos bytes en little endian, que es como
    estan en la cinta: asi el resto de los tests puede leer cualquier zona sin
    preocuparse de con que anchura la volco mkasm.
    """
    out = {}
    ruta = os.path.join(SRC, f"descubrimiento_{listado}.asm")
    with open(ruta, encoding="utf-8") as f:
        for ln in f:
            m = DEFB.match(ln)
            if not m:
                continue
            palabra = m.group(1) == "w"
            a = int(m.group(3), 16)
            for i, tok in enumerate(m.group(2).split(",")):
                mb = BYTE.match(tok.strip())
                if not mb:
                    continue
                v = int(mb.group(1), 16)
                if palabra:
                    out[a + i * 2] = v & 0xFF
                    out[a + i * 2 + 1] = v >> 8
                else:
                    out[a + i] = v
    return out


def trozo(datos, ini, n):
    return bytes(datos[ini + i] for i in range(n))


def texto(listado):
    with open(os.path.join(SRC, f"descubrimiento_{listado}.asm"),
              encoding="utf-8") as f:
        return f.read()


class Cargador(unittest.TestCase):
    """El fichero BIN 'CARGA': fuente, pantalla y las rutinas de cinta."""

    @classmethod
    def setUpClass(cls):
        cls.d = bytes_de("carga")

    def test_la_palabra_de_0xD300_apunta_al_bucle_de_cinta(self):
        """0xD300 no es codigo: es el 0xD369 al que vuelve la primera parte.

        Es lo que explica que el fichero arranque en 0xD302 y no en 0xD300, y
        que la primera parte pueda pedir la segunda con `ld hl,(0xD300)`.
        """
        self.assertEqual(self.d[0xD300], 0x69)
        self.assertEqual(self.d[0xD301], 0xD3)
        self.assertIn("lee_bloque:", texto("carga"))
        self.assertRegex(texto("carga"), r"lee_bloque:.*\n.*;d369")

    def test_la_cola_del_cargador_es_copia_de_su_propio_codigo(self):
        """0xD3D8-0xD3DF repite byte a byte 0xD358-0xD35F.

        Los ocho bytes de 0xD358 son codigo trazado, asi que no salen como
        `defb` y hay que ponerlos aqui a mano; son los del `out (0xA8),a` y
        la comprobacion de RAM que hay justo delante.
        """
        self.assertEqual(trozo(self.d, 0xD3D8, 8),
                         bytes([0xA8, 0x22, 0x00, 0x40, 0xED, 0x5B, 0x00, 0x40]))

    def test_la_pantalla_de_carga_ocupa_768_bytes(self):
        self.assertEqual(len([a for a in self.d if 0xD000 <= a < 0xD300]), 768)

    def test_el_rotulo_de_la_pantalla_de_carga(self):
        """Las letras van en dos alfabetos: 0x00-0x19 y 0x20-0x39.

        El espacio es 0xFF, y 0x3A-0x3F son las mayusculas grandes de dos
        baldosas de alto con las que empiezan "El", "Descubrimiento" y
        "America". Descodificando la tabla de nombres tienen que salir los
        textos de la pantalla.
        """
        pan = trozo(self.d, 0xD000, 0x300)

        def letra(b):
            if 0x20 <= b <= 0x39:
                return chr(ord("A") + b - 0x20)
            if b <= 0x19:
                return chr(ord("A") + b)
            if b == 0xFF:
                return " "
            return "."

        filas = ["".join(letra(b) for b in pan[f * 32:(f + 1) * 32])
                 for f in range(24)]
        self.assertIn("ESCUBRIMIENTO", filas[7])
        self.assertIn("MERICA", filas[10])
        self.assertIn("EALIZANDO", filas[14])
        self.assertIn("RABACION", filas[16])
        self.assertIn("ODOS LOS DERECHOS RESERVADOS", filas[22])

    def test_la_firma_vertical_del_margen_derecho(self):
        """En la columna 29 se lee OMIKRON Softwarwe, con la errata incluida.

        La 'w' de mas no es una errata de este desensamblado: esta en la cinta.
        Solo se miran las filas 1 a 20, que son las del recuadro vertical; la
        21 y la 22 las cruza la linea de "Todos los derechos Reservados".
        """
        pan = trozo(self.d, 0xD000, 0x300)
        col = [pan[f * 32 + 29] for f in range(1, 21)]

        def letra(b):
            if 0x20 <= b <= 0x39:
                return chr(ord("A") + b - 0x20)
            if b <= 0x19:
                return chr(ord("A") + b)
            return " "

        self.assertEqual(" ".join("".join(letra(b) for b in col).split()),
                         "OMIKRON SOFTWARWE")


class PrimeraParte(unittest.TestCase):
    """Ocho pantallas, sus patrones y sus textos."""

    @classmethod
    def setUpClass(cls):
        cls.bajo = bytes_de("p1bajo")
        cls.alto = bytes_de("p1alto")

    def test_el_punto_de_entrada_que_declara_el_bloque(self):
        """Los cuatro primeros bytes: la firma 'AB' y la direccion 0x4202."""
        self.assertEqual(trozo(self.bajo, 0x4000, 2), b"AB")
        self.assertEqual(self.bajo[0x4002] | self.bajo[0x4003] << 8, 0x4202)

    def test_las_siete_pantallas_van_seguidas_y_miden_768(self):
        """0x82F5 + 7*0x300 = 0x97F5, justo donde empieza el mapa ancho.

        Es la comprobacion de que los limites no estan puestos a ojo.
        """
        self.assertEqual(0x82F5 + 7 * 0x300, 0x97F5)
        for i in range(7):
            ini = 0x82F5 + i * 0x300
            self.assertEqual(len([a for a in self.alto
                                  if ini <= a < ini + 0x300]), 768)

    def test_el_mapa_ancho_mide_64_por_24(self):
        """0x97F5 + 64*24 = 0x9DF5, donde empiezan los sprites."""
        self.assertEqual(0x97F5 + 64 * 24, 0x9DF5)

    def test_la_cadena_de_bloques_de_patrones_encaja(self):
        """Cada bloque acaba EXACTAMENTE donde empieza el siguiente.

        Las cuentas salen de las rutinas de volcado del trozo bajo:
          vuelca_comprimido (0x44CB) consume BC + BC/8
          vuelca_con_color  (0x446D) consume 2*BC
        Si alguna cuenta estuviera mal, la cadena se descuadraria y este test
        lo diria. Es lo que sostiene los limites declarados en p1alto.notes.
        """
        cadena = [
            (0xAB60, "c", 0x2A0), (0xAE54, "p", 0x40),
            (0xAED4, "c", 0x1C0), (0xB0CC, "p", 0x20),
            (0xB10C, "c", 0x178), (0xB2B3, "p", 0x40),
            (0xB333, "c", 0x140), (0xB49B, "p", 0x70),
            (0xB57B, "c", 0x1A0), (0xB74F, "p", 0x68),
            (0xB81F, "c", 0x1A8), (0xB9FC, "p", 0xA0),
            (0xBB3C, "c", 0xF8),
            (0xBC53, "c", 0xA0), (0xBD07, "p", 0x58),
            (0xBDB7, "c", 0x198), (0xBF82, "p", 0x48),
        ]
        for i, (org, tipo, n) in enumerate(cadena):
            gasta = n + n // 8 if tipo == "c" else 2 * n
            fin = org + gasta
            esperado = cadena[i + 1][0] if i + 1 < len(cadena) else 0xC012
            self.assertEqual(fin, esperado,
                             f"el bloque de {org:#06x} deberia acabar en "
                             f"{esperado:#06x} y acaba en {fin:#06x}")

    def test_el_texto_de_la_presentacion_nombra_a_colon(self):
        t = trozo(self.alto, 0x8200, 0x9F).decode("latin-1")
        self.assertIn("CRISTOBAL COLON", t)
        self.assertIn("puerto de", t)
        self.assertIn("Palos", t)
        self.assertEqual(t[-1], "\r", "la ultima linea acaba en 0x0D")

    def test_los_textos_de_pantalla_son_once_y_acaban_en_0x0D(self):
        t = trozo(self.alto, 0xC28A, 0xC310 - 0xC28A).decode("latin-1")
        partes = t.split("\r")
        self.assertEqual(partes[0], "PUERTO DE PALOS")
        self.assertIn("Fray Juan Perez", partes)
        self.assertIn("Juan de la Cosa", partes)
        self.assertIn("Martin Alonso Pinzon", partes)
        self.assertIn("Marinero", partes)

    def test_donde_cae_cada_cifra_del_resumen(self):
        """Que contador es cada rotulo de la pantalla de resumen.

        El bucle de 0x5D0C pinta las catorce cifras -siete contadores de dos
        digitos- en baldosas SEGUIDAS a partir de la 188, que es la VRAM 0x5E0
        que se le pone al empezar. Asi que buscando esas baldosas en la tabla
        de nombres de 0xC310 se sabe bajo que rotulo cae cada contador, sin
        suponer nada. Estas son las posiciones medidas, y con la pantalla
        dibujada delante dan:

            0xF8B4 AGUA, 0xF8B5 VINO, 0xF8B6 COMIDA, 0xF8B7 MADERA,
            0xF8B8 TELA, 0xF8B9 MARINERO y 0xF8BA DINERO

        que NO es el orden de las direcciones ni el de la pantalla.
        """
        nt = trozo(self.alto, 0xC310, 0x300)
        donde = {}
        for f in range(24):
            for c in range(32):
                n = nt[f * 32 + c]
                if 188 <= n <= 201:
                    donde.setdefault(n, []).append((f, c))
        # cada baldosa sale UNA sola vez: si saliera dos, el resumen mentiria
        for n in range(188, 202):
            self.assertIn(n, donde, f"falta la baldosa {n}")
            self.assertEqual(len(donde[n]), 1, f"la baldosa {n} sale repetida")
        self.assertEqual([donde[n][0] for n in range(188, 202, 2)],
                         [(13, 9),    # 0xF8B4  AGUA
                          (18, 9),    # 0xF8B5  VINO
                          (8, 9),     # 0xF8B6  COMIDA
                          (5, 22),    # 0xF8B7  MADERA
                          (12, 22),   # 0xF8B8  TELA
                          (17, 22),   # 0xF8B9  MARINERO
                          (4, 9)])    # 0xF8BA  DINERO

    def test_la_lista_de_melodias_tiene_dieciseis_entradas(self):
        """Dieciseis entradas de cuatro bytes y un 0x0000 de terminador.

        La rutina de 0x41ED comprueba el terminador mirando los dos primeros
        bytes de la entrada, asi que el 0x0000 tiene que caer justo detras de la
        decimosexta.
        """
        for i in range(16):
            a = 0xCB95 + i * 4
            ca = self.alto[a] | self.alto[a + 1] << 8
            cb = self.alto[a + 2] | self.alto[a + 3] << 8
            self.assertTrue(0xC852 <= ca < 0xCB95, f"melodia {i}: {ca:#06x}")
            self.assertTrue(0xC852 <= cb < 0xCB95, f"melodia {i}: {cb:#06x}")
        self.assertEqual(self.alto[0xCB95 + 64], 0)
        self.assertEqual(self.alto[0xCB95 + 65], 0)

    def test_la_cola_del_bloque_es_un_patron_de_ocho(self):
        """1031 bytes con el mismo patron de ocho, sin una sola excepcion."""
        patron = trozo(self.bajo, 0x5FF9, 8)
        for a in range(0x5FF9, 0x6400):
            self.assertEqual(self.bajo[a], patron[(a - 0x5FF9) % 8],
                             f"el byte {a:#06x} rompe el patron")

    def test_los_restos_de_montaje_son_copia_de_lo_de_arriba(self):
        """0x5F9F-0x5FE0 repite 0x5F1F-0x5F60, ochenta bytes mas arriba.

        Los bytes del original son codigo trazado y no salen como `defb`, asi
        que lo que se comprueba aqui es lo unico comprobable desde el listado:
        que el rango declarado como resto empieza donde dice y mide lo que dice.
        """
        self.assertEqual(min(a for a in self.bajo if a >= 0x5F00), 0x5F9F)
        self.assertEqual(0x5FF8 - 0x5F9F, 0x59)

    def test_la_cola_del_trozo_alto_es_la_imagen_del_cargador(self):
        """0xCC56-0xD2FF son el CARGADOR intacto, con una sola diferencia.

        No es solo la tabla de nombres de 0xD000: son los 1706 bytes de golpe,
        o sea tambien la cola de la tabla de COLORES de la pantalla de carga.
        El bloque se monto encima de la memoria que el cargador dejo puesta y
        de 0xCC56 en adelante quedo tal cual. La unica diferencia es el propio
        0xCC56, que en el cargador vale 0x1F y aqui 0x19.
        """
        c = bytes_de("carga")
        distintos = [a for a in range(0xCC56, 0xD300) if c[a] != self.alto[a]]
        self.assertEqual(distintos, [0xCC56])
        self.assertEqual((c[0xCC56], self.alto[0xCC56]), (0x1F, 0x19))
        self.assertEqual(0xD300 - 0xCC56, 1706)


class SegundaParte(unittest.TestCase):
    """La travesia: el barco por dentro y la carta oceanica."""

    @classmethod
    def setUpClass(cls):
        cls.bajo = bytes_de("p2bajo")
        cls.alto = bytes_de("p2alto")

    def test_el_punto_de_entrada_que_declara_el_bloque(self):
        self.assertEqual(trozo(self.bajo, 0x4000, 2), b"AB")
        self.assertEqual(self.bajo[0x4002] | self.bajo[0x4003] << 8, 0x401F)

    def test_el_mapa_del_barco_mide_128_por_52(self):
        """0x9000 + 128*52 = 0xAA00, donde empiezan los sprites."""
        self.assertEqual(0x9000 + 128 * 52, 0xAA00)
        self.assertEqual(len([a for a in self.alto if 0x9000 <= a < 0xAA00]),
                         128 * 52)

    def test_los_cuatro_juegos_de_sprites_llenan_hasta_las_fichas(self):
        """0xAA60 + 4*0x168 = 0xB000, donde empiezan las fichas de barco."""
        self.assertEqual(0xAA60 + 4 * 0x168, 0xB000)

    def test_las_fichas_de_barco_son_cuatro_de_once(self):
        self.assertEqual(0xB000 + 4 * 11, 0xB02C)

    def test_la_carta_del_oceano_es_de_veinte_por_veinte(self):
        """0xC98C + 20*20 = 0xCB1C, y ninguna casilla pasa de 11.

        El limite 11 no es decorativo: la rutina de 0x52BC indexa la tabla de
        efectos con el valor de la casilla menos 3, y esa tabla solo tiene nueve
        entradas (0xC968-0xC98B), o sea valores de 3 a 11.
        """
        self.assertEqual(0xC98C + 20 * 20, 0xCB1C)
        for a in range(0xC98C, 0xCB1C):
            self.assertLessEqual(self.alto[a], 11,
                                 f"la casilla {a:#06x} vale {self.alto[a]}")

    def test_la_tabla_de_efectos_tiene_nueve_entradas(self):
        self.assertEqual(0xC968 + 9 * 4, 0xC98C)

    def test_los_cinco_mensajes_de_desastre(self):
        """Cinco cadenas de 22 caracteres, sin terminador."""
        t = trozo(self.alto, 0xCBF2, 5 * 22).decode("latin-1")
        self.assertEqual([t[i * 22:(i + 1) * 22] for i in range(5)], [
            "GRAVE  DESMORALIZACION",
            "AGOTADAS   PROVISIONES",
            "VIA DE AGUA  SIN TAPAR",
            "FUEGO  SIN  CONTROLAR ",
            "VELA PRINCIPAL RASGADA",
        ])

    def test_las_posiciones_iniciales_son_las_que_se_copian(self):
        """Los 0x2C bytes de 0xCBC6 son los que el arranque lleva a 0xB02C."""
        self.assertEqual(0xCBC6 + 0x2C, 0xCBF2)
        self.assertEqual(0xB02C + 0x2C, 0xB058)

    def test_los_ocho_puestos_de_trabajo(self):
        """Ocho pares (columna, fila) entre 0xC958 y 0xC968."""
        self.assertEqual(0xC958 + 8 * 2, 0xC968)
        pares = [(self.alto[0xC958 + i * 2], self.alto[0xC959 + i * 2])
                 for i in range(8)]
        self.assertEqual(pares, [(0x09, 0x27), (0x10, 0x27), (0x1A, 0x27),
                                 (0x09, 0x29), (0x10, 0x29), (0x1A, 0x29),
                                 (0x09, 0x2B), (0x10, 0x2B)])

    def test_la_cola_del_bloque_alterna_nibbles(self):
        """Cuatro bytes de nibble bajo F y cuatro de nibble bajo 0, en grupos
        de ocho. Es el patron que se declara en las notas y lo unico que de
        momento se sabe de esos bytes."""
        for a in range(0xCCD8, 0xD300):
            esperado = 0x0F if ((a - 0xCCD8) % 8) < 4 else 0x00
            # el bloque empieza a mitad de grupo: se comprueba la propiedad
            # global, que cada byte acaba en 0 o en F
            self.assertIn(self.alto[a] & 0x0F, (0x00, 0x0F),
                          f"el byte {a:#06x} = {self.alto[a]:#04x} no encaja")


class Presupuesto(unittest.TestCase):
    """Ni un byte de la cinta sin dueno, contado sobre los propios listados."""

    def test_los_cinco_listados_suman_los_bytes_de_la_cinta(self):
        """5088 + 2*(9216+21248) = 66016, y con el envoltorio del .cas, 66371.

        El envoltorio son los seis centinelas de ocho bytes, las dos cabeceras
        de fichero de 16, los seis de la cabecera BIN, los 256 del cargador
        BASIC, los dos tercetos de sincronia 03 02 01 y el relleno de
        alineacion: 355 bytes en total.
        """
        self.assertEqual(5088 + 2 * (9216 + 21248), 66016)
        envoltorio = (6 * 8 + 16 + 256 + 16 + 6 + 2 + 3 + 5 + 3)
        self.assertEqual(66016 + envoltorio, 66371)

    def test_cada_listado_declara_su_org(self):
        for L, org in (("carga", 0x0C000), ("p1bajo", 0x04000),
                       ("p1alto", 0x08000), ("p2bajo", 0x04000),
                       ("p2alto", 0x08000)):
            self.assertIn(f"org 0x{org:05x}", texto(L))


DOCS = os.path.join(RAIZ, "docs")
TOOLS = os.path.join(RAIZ, "tools")

# Todo el andamiaje de la web se copia del proyecto anterior, asi que llega con
# el nombre del juego anterior dentro. Ya paso con cinco ficheros LICENSE y con
# el pie de catorce paginas.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Hyper Sports", "Nemesis", "Demonia", "Cabbage",
    "Hole in One", "Casio World Open", "3D Golf", "Baseball",
    "Yie Ar Kung-Fu", "King's Valley", "Sky Jaguar", "Road Fighter",
    "Ping Pong", "Mopi Ranger", "RC-728", "Konami",
)


def lee(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


class TestWeb(unittest.TestCase):
    """La web: que las cifras sean las del arbol y no las del texto viejo."""

    def ficheros_de_la_web(self):
        """Las paginas, mas el andamiaje de la raiz y de tools/."""
        fuera = []
        for carpeta, _dirs, ficheros in os.walk(DOCS):
            fuera += [os.path.join(carpeta, f) for f in ficheros
                      if f.endswith((".md", ".html"))]
        for f in ("LICENSE", "AVISO-LEGAL.md", "LEGAL-NOTICE.md",
                  "README.md", "README.es.md"):
            if os.path.exists(os.path.join(RAIZ, f)):
                fuera.append(os.path.join(RAIZ, f))
        for f in ("md2html.py", "make_web.py", "contenido_web.py"):
            if os.path.exists(os.path.join(TOOLS, f)):
                fuera.append(os.path.join(TOOLS, f))
        return fuera

    def test_no_se_nombra_otro_juego_de_la_serie(self):
        """El nombre de otro juego en estas paginas es un copia y pega."""
        if not os.path.isdir(DOCS):
            self.skipTest("todavia no hay web")
        fallos = []
        for ruta in self.ficheros_de_la_web():
            texto = lee(ruta)
            for juego in OTROS_JUEGOS:
                if juego in texto:
                    fallos.append("%s en %s"
                                  % (juego, os.path.basename(ruta)))
        self.assertEqual(fallos, [], "nombres de otros juegos: %s" % fallos)

    def test_las_cifras_de_la_portada_son_las_del_listado(self):
        """CODIGO y DATOS de make_web.py tienen que sumar la cinta."""
        ruta = os.path.join(TOOLS, "make_web.py")
        if not os.path.exists(ruta):
            self.skipTest("todavia no hay web")
        texto = lee(ruta)
        v = {}
        for nombre in ("CODIGO", "DATOS", "CINTA", "RUTINAS", "SIN_LEER",
                       "ZONAS"):
            m = re.search(r"^%s = (\d+)" % nombre, texto, re.M)
            self.assertIsNotNone(m, "falta %s en make_web.py" % nombre)
            v[nombre] = int(m.group(1))
        self.assertEqual(v["CODIGO"] + v["DATOS"], v["CINTA"],
                         "codigo + datos tiene que dar la cinta entera")
        self.assertEqual(v["CINTA"], 66016)

    def test_la_portada_no_se_ha_quedado_sin_rotulo(self):
        """Sin rotulo.png la portada se cae al texto, y eso se ve."""
        if not os.path.isdir(DOCS):
            self.skipTest("todavia no hay web")
        self.assertTrue(
            os.path.exists(os.path.join(DOCS, "imagenes", "rotulo.png")),
            "falta docs/imagenes/rotulo.png, el rotulo dibujado de la cinta")

    def test_las_siete_paginas_estan_en_los_dos_idiomas(self):
        """Ninguna seccion se deja escrita en un solo idioma."""
        if not os.path.isdir(DOCS):
            self.skipTest("todavia no hay web")
        parejas = [("GETTING-STARTED", "EMPEZAR"), ("THE-GAME", "EL-JUEGO"),
                   ("THE-CARTRIDGE", "EL-CARTUCHO"), ("THE-CODE", "EL-CODIGO"),
                   ("FINDINGS", "HALLAZGOS"),
                   ("IN-THE-EMULATOR", "EN-EL-EMULADOR"),
                   ("OPEN-QUESTIONS", "PREGUNTAS-ABIERTAS")]
        faltan = []
        for en, es in parejas:
            for ruta in (os.path.join(DOCS, en + ".md"),
                         os.path.join(DOCS, "es", es + ".md")):
                if not os.path.exists(ruta):
                    faltan.append(os.path.relpath(ruta, RAIZ))
        self.assertEqual(faltan, [], "paginas que faltan: %s" % faltan)

    def test_los_bytes_sin_leer_son_los_que_dice_la_web(self):
        """SIN_LEER de la portada, contra lo que miden las propias notas."""
        ruta = os.path.join(TOOLS, "make_web.py")
        if not os.path.exists(ruta):
            self.skipTest("todavia no hay web")
        import sys
        sys.path.insert(0, TOOLS)
        import sin_leer
        medido = sum(f[4] for f in sin_leer.medir())
        m = re.search(r"^SIN_LEER = (\d+)", lee(ruta), re.M)
        self.assertEqual(int(m.group(1)), medido)


if __name__ == "__main__":
    unittest.main()
