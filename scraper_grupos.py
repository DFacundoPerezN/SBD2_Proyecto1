"""
scraper_grupos.py
=================
Web scraper para extraer informacion de los grupos de cada Mundial FIFA.

Flujo:
  1. Por cada anio, visita {anio}_mundial.php y detecta enlaces de grupos.
  2. Por cada grupo, extrae la tabla de posiciones.

Genera:
    output_csv/grupos.csv
    output_csv/grupo_seleccion.csv

Uso:
    python scraper_grupos.py
    python scraper_grupos.py --anios 2022
"""

import argparse
import csv
import logging
import os
import re
import time

import requests
from bs4 import BeautifulSoup

ORIGINAL_BASE = "https://www.losmundialesdefutbol.com/mundiales"
WAYBACK = "https://web.archive.org/web/20260101"
BASE_URL = f"{WAYBACK}/{ORIGINAL_BASE}"
DELAY = 2.0
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
OUTPUT_DIR = "output_csv"

ANIOS = [
    1930, 1934, 1938, 1950, 1954, 1958, 1962, 1966,
    1970, 1974, 1978, 1982, 1986, 1990, 1994, 1998,
    2002, 2006, 2010, 2014, 2018, 2022,
]

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


def es_pagina_verificacion(html: str) -> bool:
    texto = (html or "").lower()
    return (
        "please wait while your request is being verified" in texto
        or "one moment, please" in texto
        or "/z0f76a1d14fd21a8fb5fd0d03e0fdc3d3cedae52f" in texto
    )


def extraer_url_original(url: str) -> str:
    if "/https://" in url:
        return "https://" + url.split("/https://", 1)[1]
    if "/http://" in url:
        return "http://" + url.split("/http://", 1)[1]
    if url.startswith("https://web.archive.org/web/"):
        partes = url.split("/", 5)
        if len(partes) >= 6 and partes[5].startswith(("http://", "https://")):
            return partes[5]
    return url


def obtener_capturas_alternas(url_objetivo: str, limite: int = 6) -> list[str]:
    url_objetivo = extraer_url_original(url_objetivo)
    cdx_url = (
        "https://web.archive.org/cdx/search/cdx"
        f"?url={url_objetivo}&output=json&fl=timestamp,original,statuscode,mimetype"
    )
    try:
        resp = SESSION.get(cdx_url, timeout=30)
        resp.raise_for_status()
        data = resp.json()
    except Exception as exc:
        log.warning(f"No se pudo consultar CDX para {url_objetivo}: {exc}")
        return []

    alternas = []
    for row in data[1:]:
        if len(row) < 4:
            continue
        timestamp, original, statuscode, mimetype = row[:4]
        if statuscode != "200" or "html" not in mimetype:
            continue
        alternas.append(f"https://web.archive.org/web/{timestamp}/{original}")

    # Priorizar capturas mas recientes sin repetir.
    resultado = []
    vistos = set()
    for item in reversed(alternas):
        if item not in vistos:
            vistos.add(item)
            resultado.append(item)
        if len(resultado) >= limite:
            break
    return resultado


def get_soup(url: str) -> BeautifulSoup | None:
    for intento in range(4):
        try:
            resp = SESSION.get(url, timeout=30)
            resp.raise_for_status()
            if es_pagina_verificacion(resp.text):
                raise ValueError("Wayback devolvio pagina de verificacion")
            return BeautifulSoup(resp.text, "html.parser")
        except Exception as exc:
            espera = 15 * (2 ** intento)
            if intento < 3:
                log.warning(
                    f"Intento {intento + 1} fallido para {url}. "
                    f"Reintentando en {espera}s..."
                )
                time.sleep(espera)
            else:
                log.warning(f"Error al obtener {url}: {exc}")

    alternas = obtener_capturas_alternas(url)
    for alt_url in alternas:
        try:
            log.info(f"Probando captura alterna: {alt_url}")
            resp = SESSION.get(alt_url, timeout=30)
            resp.raise_for_status()
            if es_pagina_verificacion(resp.text):
                continue
            return BeautifulSoup(resp.text, "html.parser")
        except Exception:
            continue

    return None


def safe_int(text: str):
    try:
        return int(re.sub(r"[^\d\-]", "", text.strip()))
    except (ValueError, AttributeError):
        return ""


def normalizar_url_wayback(href: str) -> str:
    href = (href or "").strip()
    if not href:
        return ""

    if href.startswith("https://web.archive.org"):
        return href

    if href.startswith("/web/"):
        return f"https://web.archive.org{href}"

    if href.startswith("http://") or href.startswith("https://"):
        if "losmundialesdefutbol.com" in href:
            return f"{WAYBACK}/{href}"
        return href

    if href.startswith("/"):
        return f"{WAYBACK}/https://www.losmundialesdefutbol.com{href}"

    return f"{BASE_URL}/{href.lstrip('/')}"


def extraer_nombre_grupo(texto: str, grupo_id: str) -> str:
    texto = re.sub(r"\s+", " ", (texto or "")).strip()
    match = re.search(r"\bGrupo\s+([A-Z0-9]+)\b", texto, re.IGNORECASE)
    if match:
        return f"Grupo {match.group(1).upper()}"
    return f"Grupo {grupo_id.upper()}"


def seleccionar_tabla_posiciones(soup: BeautifulSoup):
    mejor_tabla = None
    mejor_score = -1

    for tbl in soup.find_all("table"):
        texto = " ".join(tbl.stripped_strings).lower()
        score = 0
        for token in ("posicion", "seleccion", "pts", "pj", "pg", "pe", "pp", "gf", "gc", "dif"):
            if token in texto:
                score += 1
        if "clasificado" in texto:
            score += 2

        if score > mejor_score:
            mejor_score = score
            mejor_tabla = tbl

    return mejor_tabla if mejor_score >= 6 else None


def obtener_urls_grupos(anio: int) -> list[dict]:
    url = f"{BASE_URL}/{anio}_mundial.php"
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return []

    grupos = []
    vistos = set()
    patron = re.compile(rf"{anio}_grupo_([a-z0-9]+)\.php", re.IGNORECASE)

    for a in soup.find_all("a", href=True):
        href = a["href"]
        match = patron.search(href)
        if not match:
            continue

        grupo_id = match.group(1)
        url_grupo = normalizar_url_wayback(href)
        if not url_grupo or url_grupo in vistos:
            continue

        vistos.add(url_grupo)
        grupos.append({
            "nombre_grupo": extraer_nombre_grupo(a.get_text(" ", strip=True), grupo_id),
            "grupo_id": grupo_id,
            "url": url_grupo,
        })

    def sort_key(grupo: dict):
        gid = grupo["grupo_id"]
        return (0, int(gid)) if gid.isdigit() else (1, gid.upper())

    grupos.sort(key=sort_key)
    log.info(f"  [{anio}] {len(grupos)} grupos detectados: {[g['nombre_grupo'] for g in grupos]}")
    return grupos


def scrape_grupo(anio: int, nombre_grupo: str, url: str) -> dict:
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return {}

    tabla_pos = seleccionar_tabla_posiciones(soup)
    if not tabla_pos:
        log.warning(f"    No se encontro tabla de posiciones en {url}")
        return {}

    filas_sel = []
    posicion_actual = None

    for tr in tabla_pos.find_all("tr"):
        celdas = [td.get_text(" ", strip=True) for td in tr.find_all("td")]
        if not celdas or all(c == "" for c in celdas):
            continue

        encabezado = celdas[0].lower()
        if encabezado in ("posicion", "posición", "pos"):
            continue

        pos_txt = celdas[0].rstrip(".")
        if pos_txt.isdigit():
            posicion_actual = int(pos_txt)

        if len(celdas) < 10:
            continue

        seleccion = re.sub(r"\s+", " ", celdas[1]).strip()
        pts = safe_int(celdas[2]) if len(celdas) > 2 else ""
        pj = safe_int(celdas[3]) if len(celdas) > 3 else ""
        pg = safe_int(celdas[4]) if len(celdas) > 4 else ""
        pe = safe_int(celdas[5]) if len(celdas) > 5 else ""
        pp = safe_int(celdas[6]) if len(celdas) > 6 else ""
        gf = safe_int(celdas[7]) if len(celdas) > 7 else ""
        gc = safe_int(celdas[8]) if len(celdas) > 8 else ""
        dif = safe_int(celdas[9]) if len(celdas) > 9 else ""
        clas_txt = celdas[10].strip().lower() if len(celdas) > 10 else ""

        clasificado = "true" if clas_txt in ("si", "sí", "yes", "1", "true") else "false"

        if not seleccion or len(seleccion) < 2:
            continue
        if seleccion.lower() in ("seleccion", "selección"):
            continue
        if posicion_actual is None:
            continue

        filas_sel.append({
            "anio_mundial": anio,
            "nombre_grupo": nombre_grupo,
            "posicion": posicion_actual,
            "seleccion": seleccion,
            "pts": pts,
            "pj": pj,
            "pg": pg,
            "pe": pe,
            "pp": pp,
            "gf": gf,
            "gc": gc,
            "dif": dif,
            "clasificado": clasificado,
        })

    num_selecciones = len(filas_sel)
    num_clasificados = sum(1 for fila in filas_sel if fila["clasificado"] == "true")

    grupo_row = {
        "anio_mundial": anio,
        "nombre_grupo": nombre_grupo,
        "num_selecciones": num_selecciones,
        "num_clasificados": num_clasificados,
    }

    log.info(
        f"    {nombre_grupo}: {num_selecciones} selecciones, "
        f"{num_clasificados} clasificados -> {[f['seleccion'] for f in filas_sel]}"
    )
    return {"grupo": grupo_row, "filas_sel": filas_sel}


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


def main(anios: list[int]):
    path_grupos = os.path.join(OUTPUT_DIR, "grupos.csv")
    path_gru_sel = os.path.join(OUTPUT_DIR, "grupo_seleccion.csv")

    init_csv(path_grupos, COLS_GRUPOS)
    init_csv(path_gru_sel, COLS_GRUPO_SEL)

    total_grupos = 0
    total_filas = 0

    for anio in anios:
        log.info(f"\n{'=' * 55}")
        log.info(f"  Mundial {anio}")
        log.info(f"{'=' * 55}")

        grupos_info = obtener_urls_grupos(anio)
        for grupo in grupos_info:
            log.info(f"  -> Scrapeando {grupo['nombre_grupo']} ...")
            resultado = scrape_grupo(anio, grupo["nombre_grupo"], grupo["url"])
            if not resultado:
                continue

            append_csv(path_grupos, COLS_GRUPOS, [resultado["grupo"]])
            append_csv(path_gru_sel, COLS_GRUPO_SEL, resultado["filas_sel"])

            total_grupos += 1
            total_filas += len(resultado["filas_sel"])

    log.info(f"\n{'=' * 55}")
    log.info("  Proceso completado.")
    log.info(f"  Grupos procesados     : {total_grupos}")
    log.info(f"  Filas grupo_seleccion : {total_filas}")
    log.info(f"  {path_grupos}")
    log.info(f"  {path_gru_sel}")
    log.info(f"{'=' * 55}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Scraper de grupos de los mundiales")
    parser.add_argument(
        "--anios",
        nargs="+",
        type=int,
        metavar="ANIO",
        default=ANIOS,
        help="Anios a procesar. Por defecto procesa todos los mundiales configurados.",
    )
    args = parser.parse_args()
    main(args.anios)
