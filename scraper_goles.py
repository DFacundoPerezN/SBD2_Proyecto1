"""
scraper_goles.py
================
Extrae el detalle de cada gol anotado en todos los Mundiales FIFA.

Flujo:
  1. Por cada año → {anio}_resultados.php → recoge URLs de partidos
  2. Por cada partido → /partidos/{slug}.php → extrae goles con detalle (cuidado con el ..)

Genera:
    output_csv/goles.csv

Columnas:
    anio_mundial    → año del mundial (ej: 2022)
    equipo_local    → nombre del equipo local
    equipo_visitante→ nombre del equipo visitante
    url_partido     → slug único del partido (ej: 2022_argentina_francia)
    jugador         → nombre del goleador
    seleccion_gol   → selección a la que le corresponde el gol
                      (se deduce por la posición del gol respecto al marcador)
    minuto          → minuto del gol como texto (ej: "23", "90+1", "108")
    minuto_num      → minuto numérico (para ordenar; tiempo extra = minuto real)
    tipo_gol        → "normal", "penal", "propia"
    tiempo_extra    → true/false (si el minuto corresponde a tiempo extra, ≥91')

Nota sobre identificación del partido:
    Se usa url_partido (el slug de la URL) como identificador natural del
    partido. Este valor es único por partido y permite hacer JOIN con la
    tabla partidos.csv si se desea. También se incluyen equipo_local y
    equipo_visitante para que el CSV sea autocontenido y legible.

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
import time
import logging
import requests
from bs4 import BeautifulSoup

# ─────────────────────────────────────────────
#  CONFIGURACIÓN
# ─────────────────────────────────────────────
BASE_URL   = "https://www.losmundialesdefutbol.com"
DELAY      = 1.2
HEADERS    = {"User-Agent": "Mozilla/5.0 (educational scraper)"}
OUTPUT_DIR = "output_csv"
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


# ─────────────────────────────────────────────
#  UTILIDADES
# ─────────────────────────────────────────────
def get_soup(url: str) -> BeautifulSoup | None:
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        return BeautifulSoup(resp.text, "html.parser")
    except Exception as exc:
        log.warning(f"Error al obtener {url}: {exc}")
        return None


def parsear_minuto(texto: str) -> tuple[str, int]:
    """
    Convierte texto de minuto a (minuto_str, minuto_num).
    Ejemplos:
        "23'"     → ("23",   23)
        "90+1'"   → ("90+1", 91)
        "108'"    → ("108",  108)
        "120+3'"  → ("120+3",123)
    """
    txt = texto.strip().rstrip("'").strip()
    # Formato "90+1"
    m = re.match(r"(\d+)\+(\d+)", txt)
    if m:
        base  = int(m.group(1))
        extra = int(m.group(2))
        return txt, base + extra
    # Formato simple "23"
    if txt.isdigit():
        return txt, int(txt)
    return txt, 0


def es_tiempo_extra(minuto_num: int) -> str:
    """Retorna 'true' si el gol fue en tiempo extra (minuto > 90)."""
    return "true" if minuto_num > 90 else "false"


# ─────────────────────────────────────────────
#  PASO 1 — Recoger URLs de partidos desde resultados
# ─────────────────────────────────────────────
def obtener_urls_partidos(anio: int) -> list[dict]:
    """
    Lee {anio}_resultados.php y extrae todos los enlaces a /partidos/
    
    El scraper de resultados ya conoce esta estructura (divs, no tablas).
    Aquí solo necesitamos los hrefs, los equipos los extraemos de la URL del partido.
    
    Retorna lista de dicts:
        { url_partido: "...", slug: "2022_argentina_francia",
          equipo_local: "Argentina", equipo_visitante: "Francia" }
    """
    url  = f"{BASE_URL}/mundiales/{anio}_resultados.php"
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return []

    partidos = []
    vistos   = set()

    # ── Extraer desde bloques de partido (estructura div real del sitio) ──────
    # Cada bloque tiene: número, etapa, equipos (divs width:129px) y enlace al partido
    bloques_fecha = soup.find_all(
        "div",
        class_=lambda c: c and "max-1" in c and "margen-b8" in c and "bb-2" in c
    )

    for bloque in bloques_fecha:
        for bp in bloque.find_all(
            "div",
            class_=lambda c: c and "margen-y3" in c and "pad-y5" in c
        ):
            # Enlace al partido
            a_partido = bp.find("a", href=lambda h: h and "/partidos/" in h)
            if not a_partido:
                continue

            href = a_partido["href"]
            
            ##Quitar ".." del inicio si lo tiene
            href = href.lstrip("..")
            
            url_completa = (
                href if href.startswith("http")
                else BASE_URL + href
            )

            if url_completa in vistos:
                continue
            vistos.add(url_completa)

            # Slug: "2022_argentina_francia" a partir de la URL
            slug = href.split("/partidos/")[-1].replace(".php", "")

            # Equipos desde los divs con style "width: 129px"
            divs_eq = bp.find_all("div", style=lambda s: s and "width: 129px" in s)
            equipo_local  = divs_eq[0].get_text(strip=True) if len(divs_eq) > 0 else ""
            equipo_visit  = divs_eq[1].get_text(strip=True) if len(divs_eq) > 1 else ""

            partidos.append({
                "url":             url_completa,
                "slug":            slug,
                "equipo_local":    equipo_local,
                "equipo_visitante": equipo_visit,
            })

    log.info(f"  [{anio}] {len(partidos)} partidos encontrados en resultados")
    return partidos


# ─────────────────────────────────────────────
#  PASO 2 — Extraer goles de la ficha de un partido
# ─────────────────────────────────────────────
def extraer_goles(anio: int, partido: dict) -> list[dict]:
    """
    Analiza la ficha del partido y extrae cada gol.

    Estructura HTML de los goles (bloque "Goles:"):
    
    Los goles se muestran en un bloque libre (no tabla) con este patrón:
    
    Gol del equipo LOCAL (el minuto está A LA IZQUIERDA de la imagen):
        <div>23'</div>
        <img alt="Gol min 23">
        <div>Lionel Messi</div>
        <div>(de penal)</div>         ← opcional
    
    Gol del equipo VISITANTE (el minuto está A LA DERECHA de la imagen):
        <img alt="Gol min 80">
        <div>80'</div>
        <div>Kylian Mbappé</div>
        <div>(de penal)</div>         ← opcional

    La posición relativa del minuto respecto a la imagen indica qué equipo
    anotó: si el minuto precede a la imagen → local; si lo sigue → visitante.

    Tipos de gol detectados por texto entre paréntesis:
        "(de penal)"   → "penal"
        "(pen)"        → "penal"
        "(en propia)"  → "propia"
        "(pp)"         → "propia"
        sin texto      → "normal"
    """
    soup = get_soup(partido["url"])
    time.sleep(DELAY)
    if not soup:
        return []

    equipo_local  = partido["equipo_local"]
    equipo_visit  = partido["equipo_visitante"]
    slug          = partido["slug"]
    goles         = []

    # ── Encontrar el bloque "Goles:" ─────────────────────────────────────────
    # El bloque está entre el h3 "Ficha del Partido:" y el h3 "Jugadores"
    bloque_goles = None
    for tag in soup.find_all(["h3", "strong", "b"]):
        if "goles" in tag.get_text(strip=True).lower():
            # Tomar el padre o el siguiente hermano que contenga las imágenes ball.jpg
            padre = tag.parent
            if padre and padre.find("img", src=lambda s: s and "ball.jpg" in s):
                bloque_goles = padre
                break
            # Alternativa: buscar el siguiente div/p con imágenes de gol
            siguiente = tag.find_next_sibling()
            while siguiente:
                if siguiente.find("img", src=lambda s: s and "ball.jpg" in s):
                    bloque_goles = siguiente
                    break
                siguiente = siguiente.find_next_sibling()
            if bloque_goles:
                break

    # Fallback: buscar cualquier sección que tenga imágenes ball.jpg
    if not bloque_goles:
        for div in soup.find_all(["div", "section", "article"]):
            imgs = div.find_all("img", src=lambda s: s and "ball.jpg" in s)
            if imgs:
                bloque_goles = div
                break

    if not bloque_goles:
        log.debug(f"    Sin goles en {slug}")
        return []

    # ── Parsear goles del bloque ──────────────────────────────────────────────
    # Recorremos los nodos del bloque buscando imágenes de pelota
    # y extraemos contexto (minuto, jugador, tipo) del texto circundante.
    
    # Estrategia: convertir el bloque a lista de "tokens" (texto limpio + tags img)
    tokens = []
    for node in bloque_goles.descendants:
        if node.name == "img" and node.get("src", "") and "ball.jpg" in node["src"]:
            tokens.append({"tipo": "img_gol", "alt": node.get("alt", "")})
        elif node.name is None:  # nodo texto
            txt = node.strip()
            if txt:
                tokens.append({"tipo": "texto", "valor": txt})

    # Recorrer tokens buscando patrones alrededor de cada img_gol
    PATRON_MIN = re.compile(r"(\d+(?:\+\d+)?)'?$")
    PATRON_TIPO = re.compile(r"\((.+?)\)", re.IGNORECASE)

    i = 0
    while i < len(tokens):
        tok = tokens[i]

        if tok["tipo"] != "img_gol":
            i += 1
            continue

        # --- Determinar selección: ¿el minuto está ANTES o DESPUÉS de la img? ---
        # Buscar minuto en tokens anteriores (hasta 3 posiciones atrás)
        minuto_txt = ""
        minuto_antes = False
        for j in range(max(0, i - 3), i):
            if tokens[j]["tipo"] == "texto":
                m = PATRON_MIN.search(tokens[j]["valor"])
                if m:
                    minuto_txt  = m.group(1)
                    minuto_antes = True
                    break

        # Si no encontró antes, buscar después (hasta 3 posiciones adelante)
        if not minuto_txt:
            for j in range(i + 1, min(len(tokens), i + 4)):
                if tokens[j]["tipo"] == "texto":
                    m = PATRON_MIN.search(tokens[j]["valor"])
                    if m:
                        minuto_txt = m.group(1)
                        break

        # También intentar extraer minuto del alt de la img: "Gol min 23"
        if not minuto_txt:
            m_alt = re.search(r"(\d+)", tok["alt"])
            if m_alt:
                minuto_txt = m_alt.group(1)

        # Selección según posición del minuto
        if minuto_antes:
            seleccion_gol = equipo_local
        else:
            seleccion_gol = equipo_visit

        # --- Nombre del jugador: primer texto no-minuto después de la img ---
        jugador = ""
        for j in range(i + 1, min(len(tokens), i + 6)):
            if tokens[j]["tipo"] == "texto":
                txt = tokens[j]["valor"]
                # Descartar si es solo minuto
                if PATRON_MIN.fullmatch(txt.rstrip("'")):
                    continue
                # Descartar texto entre paréntesis (tipo gol)
                if txt.startswith("("):
                    continue
                # Descartar textos muy cortos o de sección
                if len(txt) < 2:
                    continue
                if txt.lower() in ("goles:", "goles", "definición por penales:"):
                    break
                jugador = txt
                break

        # --- Tipo de gol: buscar "(de penal)", "(pen)", "(en propia)", "(pp)" ---
        tipo_gol = "normal"
        for j in range(i + 1, min(len(tokens), i + 6)):
            if tokens[j]["tipo"] == "texto":
                txt = tokens[j]["valor"].lower()
                m_tipo = PATRON_TIPO.search(txt)
                if m_tipo:
                    contenido = m_tipo.group(1).lower()
                    if "penal" in contenido or "pen" in contenido:
                        tipo_gol = "penal"
                    elif "propia" in contenido or "pp" in contenido or "auto" in contenido:
                        tipo_gol = "propia"
                    break

        # --- Parsear minuto ---
        if minuto_txt:
            min_str, min_num = parsear_minuto(minuto_txt)
        else:
            min_str, min_num = "", 0

        # Solo registrar si tenemos jugador y minuto
        if jugador and min_str:
            goles.append({
                "anio_mundial":    anio,
                "equipo_local":    equipo_local,
                "equipo_visitante": equipo_visit,
                "url_partido":     slug,
                "jugador":         jugador,
                "seleccion_gol":   seleccion_gol,
                "minuto":          min_str,
                "minuto_num":      min_num,
                "tipo_gol":        tipo_gol,
                "tiempo_extra":    es_tiempo_extra(min_num),
            })

        i += 1

    log.debug(f"    {slug}: {len(goles)} goles")
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
            log.info(
                f"  [{anio}] Partido {total_partidos + 1:>4}: "
                f"{p['equipo_local']} vs {p['equipo_visitante']}"
            )
            goles = extraer_goles(anio, p)
            append_csv(goles)
            total_partidos += 1
            total_goles    += len(goles)

    # Resumen final
    log.info(f"\n{'═'*55}")
    log.info(f"✅ Proceso completado.")
    log.info(f"   Partidos procesados : {total_partidos}")
    log.info(f"   Goles registrados   : {total_goles}")
    log.info(f"   Archivo             : {OUTPUT_FILE}")
    log.info(f"{'═'*55}")


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
