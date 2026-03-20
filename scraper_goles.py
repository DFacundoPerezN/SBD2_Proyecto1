"""
scraper_goles.py
================
Extrae el detalle de cada gol anotado en todos los Mundiales FIFA.
Usa Wayback Machine como fuente para evitar bloqueos 403.

Flujo:
  1. Por cada año → {anio}_resultados.php → recoge URLs de partidos
  2. Por cada partido → /partidos/{slug}.php → extrae goles con detalle

Genera:
    output_csv/goles.csv

Columnas:
    anio_mundial     → año del mundial (ej: 2022)
    equipo_local     → nombre del equipo local
    equipo_visitante → nombre del equipo visitante
    url_partido      → slug único del partido (ej: 2022_argentina_francia)
    jugador          → nombre del goleador
    seleccion_gol    → selección a la que le corresponde el gol
                       (local si el minuto precede a la img, visitante si la sigue)
    minuto           → minuto del gol como texto (ej: "23", "90+1", "108")
    minuto_num       → minuto numérico (para ordenar; 90+1 → 91)
    tipo_gol         → "normal", "penal", "propia"
    tiempo_extra     → true/false (minuto > 90)

Dependencias:
    pip install requests beautifulsoup4

Uso:
    python scraper_goles.py
    python scraper_goles.py --anios 2018 2022    # solo esos años (prueba)
"""

import argparse
import csv
import os
import re
import random
import time
import logging
import requests
from bs4 import BeautifulSoup

# ─────────────────────────────────────────────
#  CONFIGURACIÓN
# ─────────────────────────────────────────────
ORIGINAL_BASE  = "https://www.losmundialesdefutbol.com"
WAYBACK        = "https://web.archive.org/"

DELAY_MIN = 0.5
DELAY_MAX = 2.5

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "es-ES,es;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Referer": "https://web.archive.org/",
    "Upgrade-Insecure-Requests": "1",
}

OUTPUT_DIR  = "output_csv"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "goles.csv")

ANIOS = [
    1930, 1934, 1938, 1950, 1954, 1958, 1962, 1966,
    1970, 1974, 1978, 1982, 1986, 1990, 1994, 1998,
    2002, 2006, 2010, 2014, 2018, 2022,
]

COLUMNAS = [
    "anio_mundial", "equipo_local", "equipo_visitante", "url_partido",
    "jugador", "seleccion_gol",
    "minuto", "minuto_num", "tipo_gol", "tiempo_extra",
]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

SESSION = requests.Session()
SESSION.headers.update(HEADERS)


# ─────────────────────────────────────────────
#  UTILIDADES
# ─────────────────────────────────────────────
def esperar():
    """Pausa aleatoria entre DELAY_MIN y DELAY_MAX para simular navegación humana."""
    time.sleep(random.uniform(DELAY_MIN, DELAY_MAX))


def get_soup(url: str) -> BeautifulSoup | None:
    """
    Descarga una página con reintentos y backoff exponencial.
    Reintentos: 4 intentos con esperas de 15s, 30s, 60s, 120s.
    """
    for intento in range(4):
        try:
            resp = SESSION.get(url, timeout=30)
            resp.raise_for_status()
            return BeautifulSoup(resp.text, "html.parser")
        except Exception as exc:
            espera = 15 * (2 ** intento)   # 15, 30, 60, 120 segundos
            if intento < 3:
                log.warning(
                    f"Intento {intento + 1} fallido para {url}. "
                    f"Reintentando en {espera}s... ({exc})"
                )
                time.sleep(espera)
            else:
                log.warning(f"Error al obtener {url}: {exc}")
    return None


def wayback_url(path: str) -> str:
    """
    Construye la URL de Wayback Machine a partir de un path.
    Funciona sin importar si el path es relativo, absoluto del sitio,
    o ya viene envuelto en Wayback (evita el problema de URL duplicada).

    Ejemplos:
        "/mundiales/2022_resultados.php"
          → "https://web.archive.org/web/20260101/https://www.losmundiales.../mundiales/2022_resultados.php"

        "https://www.losmundialesdefutbol.com/partidos/2022_arg_fra.php"
          → "https://web.archive.org/web/20260101/https://www.losmundiales.../partidos/2022_arg_fra.php"

        "https://web.archive.org/web/20250813.../https://...sitio.../partidos/x.php"
          → extrae el segmento /partidos/x.php y lo reconstruye limpio
    """
    # Caso: ya es Wayback → extraer el segmento útil y reconstruir limpio
    if "web.archive.org" in path:
        for marca in ["/mundiales/", "/partidos/"]:
            if marca in path:
                segmento = marca + path.split(marca)[-1]
                return f"{WAYBACK}/{ORIGINAL_BASE}{segmento}"
        return path  # no se pudo extraer, devolver como está

    # Caso: URL absoluta del sitio original
    if path.startswith("http"):
        for marca in ["/mundiales/", "/partidos/"]:
            if marca in path:
                segmento = marca + path.split(marca)[-1]
                return f"{WAYBACK}/{ORIGINAL_BASE}{segmento}"
        return f"{WAYBACK}/{path}"
    
    print(f"URL: {path}")
    if path.startswith("/web/2"):
        #print ("empieza con web")
        #print(f"{WAYBACK}{path}")
        return f"{WAYBACK}{path}"

    # Caso: path relativo "/mundiales/..." o "/partidos/..."
    clean = path if path.startswith("/") else "/" + path
    return f"{WAYBACK}/{ORIGINAL_BASE}{clean}"


def parsear_minuto(texto: str) -> tuple[str, int]:
    """
    Convierte texto de minuto a (minuto_str, minuto_num).
    Ejemplos:
        "23'"    → ("23",   23)
        "90+1'"  → ("90+1", 91)
        "108'"   → ("108",  108)
        "120+3'" → ("120+3",123)
    """
    txt = texto.strip().rstrip("'").strip()
    m = re.match(r"(\d+)\+(\d+)", txt)
    if m:
        return txt, int(m.group(1)) + int(m.group(2))
    if txt.isdigit():
        return txt, int(txt)
    return txt, 0


def es_tiempo_extra(minuto_num: int) -> str:
    return "true" if minuto_num > 90 else "false"


# ─────────────────────────────────────────────
#  PASO 1 — Recoger URLs de partidos
# ─────────────────────────────────────────────
def obtener_urls_partidos(anio: int) -> list[dict]:
    """
    Lee {anio}_resultados.php y extrae todos los enlaces a /partidos/.
    Retorna lista de dicts con url, slug, equipo_local, equipo_visitante.

    La página usa divs (no tablas). Estructura:
      - Bloques de fecha: div.max-1.margen-b8.bb-2
        - Bloques de partido: div.margen-y3.pad-y5
          - Enlace al partido: <a href="/partidos/...">
          - Equipos: div[style="width: 129px"]
    """
    url_resultados = wayback_url(f"/mundiales/{anio}_resultados.php")
    soup = get_soup(url_resultados)
    esperar()
    if not soup:
        return []

    partidos = []
    vistos   = set()

    bloques_fecha = soup.find_all(
        "div",
        class_=lambda c: c and "max-1" in c and "margen-b8" in c and "bb-2" in c
    )

    for bloque in bloques_fecha:
        for bp in bloque.find_all(
            "div",
            class_=lambda c: c and "margen-y3" in c and "pad-y5" in c
        ):
            a_partido = bp.find("a", href=lambda h: h and "/partidos/" in h)
            if not a_partido:
                continue

            href = a_partido["href"]

            # Slug limpio: "2022_argentina_francia"
            slug_limpio = href.split("/partidos/")[-1].replace(".php", "")

            # URL via Wayback (usando wayback_url para evitar duplicados)
            url_partido = wayback_url(href)

            if url_partido in vistos:
                continue
            vistos.add(url_partido)

            # Equipos desde divs con style "width: 129px"
            divs_eq = bp.find_all("div", style=lambda s: s and "width: 129px" in s)
            equipo_local = divs_eq[0].get_text(strip=True) if len(divs_eq) > 0 else ""
            equipo_visit = divs_eq[1].get_text(strip=True) if len(divs_eq) > 1 else ""

            partidos.append({
                "url":              url_partido,
                "slug":             slug_limpio,
                "equipo_local":     equipo_local,
                "equipo_visitante": equipo_visit,
            })

    log.info(f"  [{anio}] {len(partidos)} partidos encontrados en resultados")
    return partidos


# ─────────────────────────────────────────────
#  PASO 2 — Extraer goles de la ficha de un partido
# ─────────────────────────────────────────────
def extraer_goles(anio: int, partido: dict) -> list[dict]:
    """
    Extrae los goles de la ficha del partido.

    Estructura HTML real confirmada por el HTML completo del partido:

    1. <strong>Goles:</strong> dentro de:
         <div class="margen-b3 pad-l15 clearfix clear bb-2">
             <strong>Goles:</strong>
         </div>

    2. Contenedor de filas (div hermano siguiente):
         <div class="a-left clearfix clear overflow-x-auto">
             <div class="clear"></div>                               ignorar
             <div class="left a-right w-50" style="padding-right">  LOCAL
             <div class="left w-50" style="padding-left">           VISITANTE
             <div class="clear"></div>                               ignorar
             ...
         </div>

    3. En Wayback Machine los src tienen prefijo "/web/20250524im_/https://..."
       Se detectan imagenes de gol por alt="Gol min X" ademas del src.

    4. Columna LOCAL: clases incluyen "a-right".
       Columna VISITANTE: NO incluye "a-right".
    """
    soup = get_soup(partido["url"])
    esperar()
    if not soup:
        return []

    equipo_local = partido["equipo_local"]
    equipo_visit = partido["equipo_visitante"]
    slug         = partido["slug"]
    goles        = []

    PATRON_MIN  = re.compile(r"(\d+(?:\+\d+)?)'")
    PATRON_MIN2 = re.compile(r"^(\d+(?:\+\d+)?)$")
    PATRON_TIPO = re.compile(r"\((.+?)\)", re.IGNORECASE)

    def tiene_imagen_gol(div) -> bool:
        """Verifica si un div tiene imagen de pelota (compatible con Wayback)."""
        for img in div.find_all("img"):
            if "ball.jpg" in img.get("src", "") or "Gol min" in img.get("alt", ""):
                return True
        return False

    def extraer_minuto_de_div(div) -> str:
        """Extrae el texto del minuto de un div de columna."""
        for node in div.descendants:
            if node.name is None:
                txt = node.strip()
                m = PATRON_MIN.search(txt)
                if m and txt.replace(m.group(), "").strip() == "":
                    return m.group(1)
                m2 = PATRON_MIN2.match(txt)
                if m2:
                    return m2.group(1)
        # Fallback: alt de la imagen "Gol min 23"
        for img in div.find_all("img"):
            m_alt = re.search(r"Gol min (\d+(?:\+\d+)?)", img.get("alt", ""))
            if m_alt:
                return m_alt.group(1)
        return ""

    def extraer_jugador_de_div(div) -> str:
        """Extrae el nombre del jugador del div con clase overflow-x-auto."""
        div_jug = div.find("div", class_=lambda c: c and "overflow-x-auto" in c)
        if not div_jug:
            return ""
        partes = []
        for child in div_jug.children:
            if child.name is None:
                t = child.strip()
                if t:
                    partes.append(t)
            elif child.name == "div":
                t = child.get_text(strip=True)
                if t and not t.startswith("("):
                    partes.append(t)
        return " ".join(partes).strip()

    def extraer_tipo_de_div(div) -> str:
        """Extrae el tipo de gol buscando texto entre parentesis."""
        texto = div.get_text(separator=" ").lower()
        m = PATRON_TIPO.search(texto)
        if m:
            c = m.group(1).lower()
            if "penal" in c or c == "pen":
                return "penal"
            if "propia" in c or c == "pp" or "auto" in c:
                return "propia"
        return "normal"

    def procesar_columna(col_div, seleccion: str) -> list[dict]:
        """Procesa una columna y retorna lista con 0 o 1 gol."""
        if not tiene_imagen_gol(col_div):
            return []
        minuto_txt = extraer_minuto_de_div(col_div)
        jugador    = extraer_jugador_de_div(col_div)
        tipo_gol   = extraer_tipo_de_div(col_div)
        if not minuto_txt or not jugador:
            return []
        min_str, min_num = parsear_minuto(minuto_txt)
        return [{
            "anio_mundial":     anio,
            "equipo_local":     equipo_local,
            "equipo_visitante": equipo_visit,
            "url_partido":      slug,
            "jugador":          jugador,
            "seleccion_gol":    seleccion,
            "minuto":           min_str,
            "minuto_num":       min_num,
            "tipo_gol":         tipo_gol,
            "tiempo_extra":     es_tiempo_extra(min_num),
        }]

    # ── Localizar el contenedor de goles ─────────────────────────────────────
    # Patron: <strong>Goles:</strong> → div padre → div hermano siguiente
    contenedor_goles = None

    for strong in soup.find_all(["strong", "b"]):
        if strong.get_text(strip=True).lower().startswith("goles"):
            padre = strong.parent
            if not padre:
                continue
            sig = padre.find_next_sibling()
            while sig:
                if sig.name == "div":
                    if tiene_imagen_gol(sig):
                        contenedor_goles = sig
                        break
                    # Aceptar tambien si tiene divs w-50 (puede no tener goles)
                    if sig.find_all("div", class_=lambda c: c and "w-50" in c and "left" in c):
                        contenedor_goles = sig
                        break
                sig = sig.find_next_sibling()
            if contenedor_goles:
                break

    if not contenedor_goles:
        log.warning(f"    [{slug}] No se encontro contenedor de goles")
        return []

    # ── Recolectar divs "left w-50" solo hijos directos del contenedor ───────
    todos_w50 = [
        d for d in contenedor_goles.find_all(
            "div",
            class_=lambda c: c and "w-50" in c and "left" in c
        )
        if d.parent == contenedor_goles
    ]

    if not todos_w50:
        todos_w50 = contenedor_goles.find_all(
            "div",
            class_=lambda c: c and "w-50" in c and "left" in c
        )

    log.debug(f"    [{slug}] {len(todos_w50)} columnas w-50 encontradas")

    # ── Procesar pares: posicion par = local, impar = visitante ──────────────
    i = 0
    while i + 1 < len(todos_w50):
        goles.extend(procesar_columna(todos_w50[i],     equipo_local))
        goles.extend(procesar_columna(todos_w50[i + 1], equipo_visit))
        i += 2

    log.info(f"    [{slug}] {len(goles)} goles extraidos")
    return goles

# ─────────────────────────────────────────────
#  CSV helpers
# ─────────────────────────────────────────────
def init_csv():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    if os.path.exists(OUTPUT_FILE):
        os.remove(OUTPUT_FILE)
    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        csv.DictWriter(f, fieldnames=COLUMNAS).writeheader()


def append_csv(rows: list[dict]):
    if not rows:
        return
    with open(OUTPUT_FILE, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNAS, extrasaction="ignore")
        writer.writerows(rows)


# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────
def main(anios: list[int]):
    init_csv()
    total_partidos = 0
    total_goles    = 0

    for anio in anios:
        log.info(f"\n{'═'*55}")
        log.info(f"  Mundial {anio}")
        log.info(f"{'═'*55}")

        partidos = obtener_urls_partidos(anio)

        for p in partidos:
            total_partidos += 1
            log.info(
                f"  [{anio}] Partido {total_partidos:>4}: "
                f"{p['equipo_local']} vs {p['equipo_visitante']}"
            )
            goles = extraer_goles(anio, p)
            append_csv(goles)
            total_goles += len(goles)
            log.info(f"           → {len(goles)} goles registrados")

    log.info(f"\n{'═'*55}")
    log.info(f"✅ Proceso completado.")
    log.info(f"   Partidos procesados : {total_partidos}")
    log.info(f"   Goles registrados   : {total_goles}")
    log.info(f"   Archivo             : {OUTPUT_FILE}")
    log.info(f"{'═'*55}")


# ─────────────────────────────────────────────
#  PUNTO DE ENTRADA
# ─────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Scraper de goles detallados por partido"
    )
    parser.add_argument(
        "--anios",
        nargs="+",
        type=int,
        metavar="AÑO",
        help="Años a procesar (ej: --anios 2018 2022). Por defecto: todos.",
        default=ANIOS,
    )
    args = parser.parse_args()
    main(args.anios)