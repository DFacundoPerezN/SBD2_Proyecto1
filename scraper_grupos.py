"""
scraper_grupos.py
=================
Web scraper para extraer información de los grupos de cada Mundial FIFA.

Flujo:
  1. Por cada año, visita {año}_mundial.php y detecta los enlaces de grupos
     desde el menú de navegación (ej: 1962_grupo_1.php, 2022_grupo_a.php)
  2. Por cada grupo, extrae la tabla de posiciones

Genera:
    output_csv/grupos.csv          → un registro por grupo
    output_csv/grupo_seleccion.csv → un registro por selección por grupo

Columnas grupos.csv:
    anio_mundial, nombre_grupo, num_selecciones, num_clasificados

Columnas grupo_seleccion.csv:
    anio_mundial, nombre_grupo, posicion, seleccion,
    pts, pj, pg, pe, pp, gf, gc, dif, clasificado

Dependencias:
    pip install requests beautifulsoup4

Uso:
    python scraper_grupos.py
"""

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
ORIGINAL_BASE = "https://www.losmundialesdefutbol.com/mundiales"
WAYBACK       = "https://web.archive.org/web/20260101"
BASE_URL      = f"{WAYBACK}/{ORIGINAL_BASE}"
DELAY      = 2.0
HEADERS    = {
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
OUTPUT_DIR = "output_csv"

ANIOS = [
    1930, 1934, 1938, 1950, 1954, 1958, 1962, 1966,
    1970, 1974, 1978, 1982, 1986, 1990, 1994, 1998,
    2002, 2006, 2010, 2014, 2018, 2022,
]

## Para pruebas rápidas, usar solo un año:
#ANIOS = [1962]

COLS_GRUPOS = [
    "anio_mundial", "nombre_grupo", "num_selecciones", "num_clasificados",
]

COLS_GRUPO_SEL = [
    "anio_mundial", "nombre_grupo", "posicion", "seleccion",
    "pts", "pj", "pg", "pe", "pp", "gf", "gc", "dif", "clasificado",
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
def get_soup(url: str) -> BeautifulSoup | None:
    for intento in range(4):
        try:
            resp = SESSION.get(url, timeout=30)
            resp.raise_for_status()
            return BeautifulSoup(resp.text, "html.parser")
        except Exception as exc:
            espera = 15 * (2 ** intento)  # 15s, 30s, 60s, 120s
            if intento < 3:
                log.warning(f"Intento {intento+1} fallido. Reintentando en {espera}s...")
                time.sleep(espera)
            else:
                log.warning(f"Error al obtener {url}: {exc}")
    return None


def safe_int(text: str):
    try:
        return int(re.sub(r"[^\d\-]", "", text.strip()))
    except (ValueError, AttributeError):
        return ""


# ─────────────────────────────────────────────
#  PASO 1 — Detectar grupos desde {año}_mundial.php
# ─────────────────────────────────────────────
def obtener_urls_grupos(anio: int) -> list[dict]:
    """
    Lee el menú de navegación de {anio}_mundial.php y extrae todos los
    enlaces con patrón {anio}_grupo_X.php.

    Retorna lista de dicts:
        { nombre_grupo: "Grupo A", url: "https://...2022_grupo_a.php" }
    """
    url  = f"{BASE_URL}/{anio}_mundial.php"
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return []

    grupos = []
    vistos = set()

    # Patrón de URL: /{anio}_grupo_{id}.php  donde id puede ser número o letra
    patron = re.compile(rf"{anio}_grupo_(\w+)\.php", re.IGNORECASE)

    for a in soup.find_all("a", href=True):
        href = a["href"]
        m = patron.search(href)
        if not m:
            continue

        grupo_id = m.group(1)           # "1", "2", "a", "b", etc.
        original = f"{ORIGINAL_BASE}/{anio}_grupo_{grupo_id}.php"
        url_grupo = (
            href if href.startswith("https://web.archive.org")
            else f"{WAYBACK}/{original}"
        )

        if url_grupo in vistos:
            continue
        vistos.add(url_grupo)

        # Nombre legible: "Grupo 1" o "Grupo A"
        nombre_grupo = f"Grupo {grupo_id.upper()}"

        grupos.append({
            "nombre_grupo": nombre_grupo,
            "grupo_id":     grupo_id,
            "url":          url_grupo,
        })

    # Ordenar por grupo_id para consistencia
    grupos.sort(key=lambda g: g["grupo_id"])
    log.info(f"  [{anio}] {len(grupos)} grupos detectados: "
             f"{[g['nombre_grupo'] for g in grupos]}")
    return grupos


# ─────────────────────────────────────────────
#  PASO 2 — Extraer tabla de posiciones de un grupo
# ─────────────────────────────────────────────
def scrape_grupo(anio: int, nombre_grupo: str, url: str) -> dict:
    """
    Extrae la tabla de posiciones del grupo.

    Estructura HTML de la tabla:
        <table>
          <tr>  ← encabezado: Posición | Selección | PTS | PJ | PG | PE | PP | GF | GC | Dif | Clasificado
          <tr>  ← fila selección
          <tr>  ← fila separadora (celdas vacías)
          ...
        </table>

    Retorna:
        {
          "grupo":     { anio_mundial, nombre_grupo, num_selecciones, num_clasificados },
          "filas_sel": [ { anio_mundial, nombre_grupo, posicion, seleccion,
                           pts, pj, pg, pe, pp, gf, gc, dif, clasificado }, ... ]
        }
    """
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return {}

    filas_sel      = []
    posicion_actual = None

    # Buscar la tabla de posiciones: la que tenga encabezados PTS, PJ, etc.
    tabla_pos = None
    for tbl in soup.find_all("table"):
        texto_tbl = tbl.get_text(separator=" ").lower()
        if "pts" in texto_tbl and "clasificado" in texto_tbl:
            tabla_pos = tbl
            break

    if not tabla_pos:
        log.warning(f"    No se encontró tabla de posiciones en {url}")
        return {}

    for tr in tabla_pos.find_all("tr"):
        celdas = [td.get_text(strip=True) for td in tr.find_all("td")]

        # Saltar encabezados y filas separadoras
        if not celdas or all(c == "" for c in celdas):
            continue
        if celdas[0].lower() in ("posición", "posicion", "pos"):
            continue

        # Fila de selección: primera celda es número de posición (puede ser vacía en empate)
        pos_txt = celdas[0].rstrip(".")
        if pos_txt.isdigit():
            posicion_actual = int(pos_txt)

        # Necesitamos al menos: pos | seleccion | pts | pj | pg | pe | pp | gf | gc | dif | clasificado
        if len(celdas) < 10:
            continue

        seleccion  = celdas[1]  if len(celdas) > 1  else ""
        pts        = safe_int(celdas[2])  if len(celdas) > 2  else ""
        pj         = safe_int(celdas[3])  if len(celdas) > 3  else ""
        pg         = safe_int(celdas[4])  if len(celdas) > 4  else ""
        pe         = safe_int(celdas[5])  if len(celdas) > 5  else ""
        pp         = safe_int(celdas[6])  if len(celdas) > 6  else ""
        gf         = safe_int(celdas[7])  if len(celdas) > 7  else ""
        gc         = safe_int(celdas[8])  if len(celdas) > 8  else ""
        dif        = safe_int(celdas[9])  if len(celdas) > 9  else ""
        clas_txt   = celdas[10].strip().lower() if len(celdas) > 10 else ""

        # Normalizar clasificado → booleano como "true"/"false"
        clasificado = "true" if clas_txt in ("si", "sí", "yes", "1") else "false"

        # Ignorar filas que no son de selección real
        if not seleccion or len(seleccion) < 2:
            continue
        if seleccion.lower() in ("selección", "seleccion"):
            continue

        filas_sel.append({
            "anio_mundial": anio,
            "nombre_grupo": nombre_grupo,
            "posicion":     posicion_actual,
            "seleccion":    seleccion,
            "pts":          pts,
            "pj":           pj,
            "pg":           pg,
            "pe":           pe,
            "pp":           pp,
            "gf":           gf,
            "gc":           gc,
            "dif":          dif,
            "clasificado":  clasificado,
        })

    # Derivar métricas del grupo a partir de las filas
    num_selecciones  = len(filas_sel)
    num_clasificados = sum(1 for f in filas_sel if f["clasificado"] == "true")

    grupo_row = {
        "anio_mundial":    anio,
        "nombre_grupo":    nombre_grupo,
        "num_selecciones": num_selecciones,
        "num_clasificados": num_clasificados,
    }

    log.info(
        f"    {nombre_grupo}: {num_selecciones} selecciones, "
        f"{num_clasificados} clasificados → {[f['seleccion'] for f in filas_sel]}"
    )

    return {"grupo": grupo_row, "filas_sel": filas_sel}


# ─────────────────────────────────────────────
#  CSV helpers
# ─────────────────────────────────────────────
def init_csv(path: str, cols: list[str]):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    if os.path.exists(path):
        os.remove(path)
    with open(path, "w", newline="", encoding="utf-8") as f:
        csv.DictWriter(f, fieldnames=cols).writeheader()


def append_csv(path: str, cols: list[str], rows: list[dict]):
    if not rows:
        return
    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        writer.writerows(rows)


# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────
def main():
    path_grupos  = os.path.join(OUTPUT_DIR, "grupos.csv")
    path_gru_sel = os.path.join(OUTPUT_DIR, "grupo_seleccion.csv")

    init_csv(path_grupos,  COLS_GRUPOS)
    init_csv(path_gru_sel, COLS_GRUPO_SEL)

    total_grupos = 0
    total_filas  = 0

    for anio in ANIOS:
        log.info(f"\n{'═'*55}")
        log.info(f"  Mundial {anio}")
        log.info(f"{'═'*55}")

        # Paso 1: detectar URLs de grupos desde la página del mundial
        grupos_info = obtener_urls_grupos(anio)

        for g in grupos_info:
            log.info(f"  → Scrapeando {g['nombre_grupo']} ...")

            resultado = scrape_grupo(anio, g["nombre_grupo"], g["url"])
            if not resultado:
                continue

            append_csv(path_grupos,  COLS_GRUPOS,   [resultado["grupo"]])
            append_csv(path_gru_sel, COLS_GRUPO_SEL, resultado["filas_sel"])

            total_grupos += 1
            total_filas  += len(resultado["filas_sel"])

    # Resumen
    log.info(f"\n{'═'*55}")
    log.info(f" \\/ Proceso completado.")
    log.info(f"   Grupos procesados          : {total_grupos}")
    log.info(f"   Filas grupo_seleccion      : {total_filas}")
    log.info(f"   {path_grupos}")
    log.info(f"   {path_gru_sel}")
    log.info(f"{'═'*55}")


if __name__ == "__main__":
    main()
