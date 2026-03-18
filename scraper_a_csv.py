"""
scraper_a_csv.py
================
Web scraper para https://www.losmundialesdefutbol.com
Extrae: info general, resultados, goleadores y posiciones finales
de los 23 Mundiales FIFA (1930-2022) y genera 4 archivos CSV.

Archivos generados:
    output/mundiales.csv
    output/partidos.csv
    output/mejores_goleadores.csv
    output/posiciones_finales.csv

Dependencias:
    pip install requests beautifulsoup4

Uso:
    python scraper_a_csv.py
"""

import csv
import os
import re
import time
import logging
import requests
from bs4 import BeautifulSoup
from datetime import datetime

# ─────────────────────────────────────────────
#  CONFIGURACIÓN
# ─────────────────────────────────────────────
BASE_URL   = "https://www.losmundialesdefutbol.com/mundiales"
DELAY      = 0.9
HEADERS    = {"User-Agent": "Mozilla/5.0 (educational scraper)"}
OUTPUT_DIR = "output_csv"

ANIOS = [
    1930, 1934, 1938, 1950, 1954, 1958, 1962, 1966,
    1970, 1974, 1978, 1982, 1986, 1990, 1994, 1998,
    2002, 2006, 2010, 2014, 2018, 2022,
]

# Para pruebas rápidas, usar solo un año:
#ANIOS = [1930]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


# ─────────────────────────────────────────────
#  COLUMNAS DE CADA CSV
# ─────────────────────────────────────────────
COLS = {
    "mundiales": [
        "anio", "sede", "campeon", "subcampeon", "tercero", "cuarto",
        "num_selecciones", "num_partidos", "num_goles", "promedio_gol",
    ],
    "partidos": [
        "anio_mundial", "numero_partido", "fecha", "etapa",
        "equipo_local", "equipo_visitante",
        "goles_local", "goles_visitante",
        "goles_local_et", "goles_visit_et",
        "penales_local", "penales_visit",
    ],
    "mejores_goleadores": [
        "anio_mundial", "posicion", "jugador", "seleccion",
        "goles", "partidos", "promedio_gol",
    ],
    "posiciones_finales": [
        "anio_mundial", "posicion", "seleccion", "etapa_alcanzada",
        "puntos", "pj", "pg", "pe", "pp", "gf", "gc", "dif",
    ],
}


# ─────────────────────────────────────────────
#  UTILIDADES
# ─────────────────────────────────────────────
def get_soup(url: str):
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        return BeautifulSoup(resp.text, "html.parser")
    except Exception as exc:
        log.warning(f"No se pudo obtener {url}: {exc}")
        return None


def safe_int(text: str):
    try:
        return int(re.sub(r"[^\d\-]", "", text.strip()))
    except (ValueError, AttributeError):
        return ""


def safe_float(text: str):
    try:
        return float(text.strip().replace(",", "."))
    except (ValueError, AttributeError):
        return ""


def parse_date(text: str):
    for fmt in ("%d-%b-%Y", "%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(text.strip(), fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    return text.strip()


# ─────────────────────────────────────────────
#  SCRAPERS
# ─────────────────────────────────────────────

def scrape_info_general(anio: int) -> dict:
    url  = f"{BASE_URL}/{anio}_mundial.php"
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return {}

    data = {k: "" for k in COLS["mundiales"]}
    data["anio"] = anio

    # Estadísticas generales (lista de viñetas)
    for line in soup.get_text(separator="\n").splitlines():
        line = line.strip()
        if line.startswith("- Organizador:"):
            data["sede"] = line.split(":", 1)[1].strip()
        elif line.startswith("- Selecciones:"):
            data["num_selecciones"] = safe_int(line.split(":")[1])
        elif line.startswith("- Partidos:"):
            data["num_partidos"] = safe_int(line.split(":")[1])
        elif line.startswith("- Goles:"):
            data["num_goles"] = safe_int(line.split(":")[1])
        elif line.startswith("- Promedio de Gol:"):
            data["promedio_gol"] = safe_float(line.split(":")[1])

    # Top 4 desde el resumen de Posiciones Finales
    for h3 in soup.find_all("h3"):
        if "Posiciones Finales" in h3.get_text():
            tbl = h3.find_next("table")
            if tbl:
                equipos = []
                for tr in tbl.find_all("tr"):
                    for td in tr.find_all("td"):
                        txt = td.get_text(strip=True)
                        if txt and not txt.isdigit() and len(txt) > 2 and "." not in txt:
                            equipos.append(txt)
                keys = ["campeon", "subcampeon", "tercero", "cuarto"]
                for i, key in enumerate(keys):
                    data[key] = equipos[i] if i < len(equipos) else ""
            break

    log.info(f"  [{anio}] Info general → sede={data['sede']}, campeón={data['campeon']}")
    return data


def get_soup(url: str):
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        return BeautifulSoup(resp.text, "html.parser")
    except Exception as exc:
        log.warning(f"No se pudo obtener {url}: {exc}")
        return None
 
 
def parse_date(text: str):
    for fmt in ("%d-%b-%Y", "%d/%m/%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(text.strip(), fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    return text.strip()
 
 
def scrape_resultados(anio: int) -> list[dict]:
    url  = f"{BASE_URL}/{anio}_resultados.php"
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return []
 
    partidos     = []
    fecha_actual = ""
 
    # ── 1. Iterar sobre bloques de fecha ──────────────────────────────────────
    # Cada bloque de fecha está envuelto en:
    # <div class="clearfix clear overflow-x-auto max-1 margen-b8 bb-2">
    #   <h3 ...>Fecha: <strong>13-Jul-1930</strong></h3>
    #   <div class="clearfix clear overflow-x-auto margen-y3 pad-y5"> ← partido
    #   <div class="clearfix clear overflow-x-auto margen-y3 pad-y5 bt-2"> ← partido
    # </div>
 
    bloques_fecha = soup.find_all(
        "div",
        class_=lambda c: c and "max-1" in c and "margen-b8" in c and "bb-2" in c
    )
 
    log.info(f"  [{anio}] Bloques de fecha encontrados: {len(bloques_fecha)}")
 
    for bloque in bloques_fecha:
 
        # ── Extraer fecha del h3 ──────────────────────────────────────────────
        h3 = bloque.find("h3")
        if h3:
            strong = h3.find("strong")
            if strong:
                fecha_actual = parse_date(strong.get_text(strip=True))
 
        # ── Encontrar bloques individuales de partido ─────────────────────────
        # Clase distintiva: "margen-y3 pad-y5" (con o sin "bt-2")
        bloques_partido = bloque.find_all(
            "div",
            class_=lambda c: c and "margen-y3" in c and "pad-y5" in c
        )
 
        for bp in bloques_partido:
 
            # ── Número de partido ─────────────────────────────────────────────
            div_num = bp.find("div", class_=lambda c: c and "wpx-30" in c)
            if not div_num:
                continue
            num_txt = div_num.get_text(strip=True).rstrip(".")
            if not num_txt.isdigit():
                continue
            num_partido = int(num_txt)
 
            # ── Etapa ─────────────────────────────────────────────────────────
            div_etapa = bp.find("div", class_=lambda c: c and "wpx-170" in c)
            etapa = div_etapa.get_text(strip=True) if div_etapa else ""
 
            # ── Marcador desde el enlace al partido ───────────────────────────
            # El enlace tiene href con "/partidos/" y texto "N - N"
            enlace_marcador = bp.find(
                "a",
                href=lambda h: h and "/partidos/" in h
            )
            if not enlace_marcador:
                continue
 
            marcador_txt = enlace_marcador.get_text(strip=True)
            score_m = re.match(r"^(\d+)\s*-\s*(\d+)$", marcador_txt)
            if not score_m:
                continue
 
            goles_l = int(score_m.group(1))
            goles_v = int(score_m.group(2))
 
            # ── Equipos desde los div con "width: 129px" ──────────────────────
            # El local tiene clase "negri" (negrita), el visitante no.
            # Ambos tienen style="width: 129px"
            divs_equipo = bp.find_all(
                "div",
                style=lambda s: s and "width: 129px" in s
            )
 
            equipo_local  = ""
            equipo_visit  = ""
 
            if len(divs_equipo) >= 2:
                equipo_local = divs_equipo[0].get_text(strip=True)
                equipo_visit = divs_equipo[1].get_text(strip=True)
            elif len(divs_equipo) == 1:
                equipo_local = divs_equipo[0].get_text(strip=True)
 
            # ── Tiempo extra: texto "( N - N )" ──────────────────────────────
            goles_l_et = goles_v_et = ""
            bloque_txt  = bp.get_text(separator=" ")
            et_m = re.search(r"\(\s*(\d+)\s*-\s*(\d+)\s*\)", bloque_txt)
            if et_m:
                goles_l_et = int(et_m.group(1))
                goles_v_et = int(et_m.group(2))
 
            # ── Penales: texto "N - N por penales" ───────────────────────────
            penales_l = penales_v = ""
            pen_m = re.search(r"(\d+)\s*-\s*(\d+)\s*por penales", bloque_txt)
            if pen_m:
                penales_l = int(pen_m.group(1))
                penales_v = int(pen_m.group(2))
 
            partidos.append({
                "anio_mundial":      anio,
                "numero_partido":    num_partido,
                "fecha":             fecha_actual,
                "etapa":             etapa,
                "equipo_local":      equipo_local,
                "equipo_visitante":  equipo_visit,
                "goles_local":       goles_l,
                "goles_visitante":   goles_v,
                "goles_local_et":    goles_l_et,
                "goles_visit_et":    goles_v_et,
                "penales_local":     penales_l,
                "penales_visit":     penales_v,
            })
 
    log.info(f"  [{anio}] Resultados → {len(partidos)} partidos encontrados")
    return partidos

def scrape_goleadores(anio: int) -> list[dict]:
    url  = f"{BASE_URL}/{anio}_goleadores.php"
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return []

    goleadores = []
    posicion_actual = ""

    for tbl in soup.find_all("table"):
        for tr in tbl.find_all("tr"):
            cells = [td.get_text(strip=True) for td in tr.find_all("td")]
            if not cells or len(cells) < 3:
                continue
            if cells[1].lower() in ("jugador", ""):
                continue

            pos_txt = cells[0].rstrip(".")
            if pos_txt.isdigit():
                posicion_actual = int(pos_txt)

            jugador   = cells[1] if len(cells) > 1 else ""
            goles     = safe_int(cells[2]) if len(cells) > 2 else ""
            partidos  = safe_int(cells[3]) if len(cells) > 3 else ""
            promedio  = safe_float(cells[4]) if len(cells) > 4 else ""
            seleccion = cells[5] if len(cells) > 5 else ""

            if jugador and goles != "":
                goleadores.append({
                    "anio_mundial": anio,
                    "posicion":     posicion_actual,
                    "jugador":      jugador,
                    "seleccion":    seleccion,
                    "goles":        goles,
                    "partidos":     partidos,
                    "promedio_gol": promedio,
                })

    log.info(f"  [{anio}] Goleadores → {len(goleadores)} registros")
    return goleadores


def scrape_posiciones(anio: int) -> list[dict]:
    url  = f"{BASE_URL}/{anio}_posiciones_finales.php"
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return []

    posiciones = []
    posicion_actual = ""

    for tbl in soup.find_all("table"):
        for tr in tbl.find_all("tr"):
            cells = [td.get_text(strip=True) for td in tr.find_all("td")]
            if not cells or len(cells) < 4:
                continue
            if cells[0].lower() in ("posición", "posicion", ""):
                continue
            if all(c == "" for c in cells):
                continue

            pos_txt = cells[0].rstrip(".")
            if pos_txt.isdigit():
                posicion_actual = int(pos_txt)

            seleccion = cells[1] if len(cells) > 1 else ""
            etapa     = cells[2] if len(cells) > 2 else ""
            pts       = safe_int(cells[3])  if len(cells) > 3  else ""
            pj        = safe_int(cells[4])  if len(cells) > 4  else ""
            pg        = safe_int(cells[5])  if len(cells) > 5  else ""
            pe        = safe_int(cells[6])  if len(cells) > 6  else ""
            pp        = safe_int(cells[7])  if len(cells) > 7  else ""
            gf        = safe_int(cells[8])  if len(cells) > 8  else ""
            gc        = safe_int(cells[9])  if len(cells) > 9  else ""
            dif       = safe_int(cells[10]) if len(cells) > 10 else ""

            if seleccion and len(seleccion) > 1:
                posiciones.append({
                    "anio_mundial":     anio,
                    "posicion":         posicion_actual,
                    "seleccion":        seleccion,
                    "etapa_alcanzada":  etapa,
                    "puntos":           pts,
                    "pj": pj, "pg": pg, "pe": pe, "pp": pp,
                    "gf": gf, "gc": gc, "dif": dif,
                })

    log.info(f"  [{anio}] Posiciones → {len(posiciones)} selecciones")
    return posiciones


# ─────────────────────────────────────────────
#  ESCRITURA DE CSV
# ─────────────────────────────────────────────

def escribir_csv(nombre: str, filas: list[dict]):
    """Agrega filas al CSV correspondiente (modo append)."""
    path = os.path.join(OUTPUT_DIR, f"{nombre}.csv")
    cols = COLS[nombre]
    file_exists = os.path.exists(path)

    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        if not file_exists:
            writer.writeheader()
        writer.writerows(filas)


# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────

def main():
    # Crear directorio de salida
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Limpiar CSVs previos para evitar duplicados al re-ejecutar
    for nombre in COLS:
        path = os.path.join(OUTPUT_DIR, f"{nombre}.csv")
        if os.path.exists(path):
            os.remove(path)
            log.info(f"Archivo anterior eliminado: {path}")

    log.info(f"Los CSVs se guardarán en: ./{OUTPUT_DIR}/")
    log.info(f"Mundiales a procesar: {len(ANIOS)}\n")

    for anio in ANIOS:
        log.info(f"══ Mundial {anio} ══")

        info = scrape_info_general(anio)
        if info:
            escribir_csv("mundiales", [info])

        partidos = scrape_resultados(anio)
        if partidos:
            escribir_csv("partidos", partidos)

        goles = scrape_goleadores(anio)
        if goles:
            escribir_csv("mejores_goleadores", goles)

        posiciones = scrape_posiciones(anio)
        if posiciones:
            escribir_csv("posiciones_finales", posiciones)

    # Resumen final
    log.info("\n/ Scraping completado. Archivos generados:")
    for nombre in COLS:
        path = os.path.join(OUTPUT_DIR, f"{nombre}.csv")
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                lineas = sum(1 for _ in f) - 1  # descontar encabezado
            log.info(f"   {path:45s} → {lineas:>5} filas")


if __name__ == "__main__":
    main()
