"""
scraper_jugadores.py
====================
Web scraper para https://www.losmundialesdefutbol.com/jugadores_indice/letra_X.php

Usa Wayback Machine como fuente para evitar bloqueos 403 del servidor original.

Flujo en 2 pasos:
  1. Por cada letra (A-Z) recoge los enlaces a las fichas individuales
  2. Por cada ficha extrae: nombre, apellido, selección, fecha de nacimiento y posición

Genera:
    output_csv/jugadores.csv

Dependencias:
    pip install requests beautifulsoup4

Uso:
    python scraper_jugadores.py
    python scraper_jugadores.py --letras A B C     # solo esas letras (prueba rápida)
"""

import argparse
import csv
import os
import re
import random
import string
import time
import logging
import requests
from bs4 import BeautifulSoup

# ─────────────────────────────────────────────
#  CONFIGURACIÓN
# ─────────────────────────────────────────────
ORIGINAL_BASE_INDICE  = "https://www.losmundialesdefutbol.com/jugadores_indice"
ORIGINAL_BASE_JUGADOR = "https://www.losmundialesdefutbol.com/jugadores"
ORIGINAL_BASE         = "https://www.losmundialesdefutbol.com"
WAYBACK               = "https://web.archive.org/web/20260101"

# Prefijos de URL a través de Wayback Machine
BASE_INDICE  = f"{WAYBACK}/{ORIGINAL_BASE_INDICE}/letra_{{letra}}.php"
BASE_JUGADOR = f"{WAYBACK}/{ORIGINAL_BASE_JUGADOR}"

DELAY_MIN = 0.5     # segundos mínimos entre peticiones
DELAY_MAX = 2.5     # segundos máximos entre peticiones

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

OUTPUT_DIR   = "output_csv"
OUTPUT_FILE  = os.path.join(OUTPUT_DIR, "jugadores.csv")

SESSION = requests.Session()
SESSION.headers.update(HEADERS)

COLUMNAS = ["apellido", "nombre", "nombre_completo", "seleccion",
            "fecha_nacimiento", "posicion", "url_ficha"]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


# ─────────────────────────────────────────────
#  UTILIDADES
# ─────────────────────────────────────────────
def esperar():
    """Pausa aleatoria entre DELAY_MIN y DELAY_MAX para simular navegación humana."""
    time.sleep(random.uniform(DELAY_MIN, DELAY_MAX))


def get_soup(url: str) -> BeautifulSoup | None:
    """
    Descarga una página con reintentos y backoff exponencial.
    Usa la Session global con headers de navegador real.
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


def separar_nombre_apellido(nombre_completo: str) -> tuple[str, str]:
    """
    El sitio muestra los nombres como 'Apellido, Nombre' o solo 'Nombre'.
    Ejemplos:
        'Messi, Lionel'      → apellido='Messi',     nombre='Lionel'
        'Mbappé, Kylian'     → apellido='Mbappé',    nombre='Kylian'
        'Pelé'               → apellido='',           nombre='Pelé'
        'Abel Xavier'        → apellido='',           nombre='Abel Xavier'
        'A'Court, Alan'      → apellido="A'Court",   nombre='Alan'
    """
    txt = nombre_completo.strip()
    if "," in txt:
        partes = txt.split(",", 1)
        return partes[0].strip(), partes[1].strip()
    return "", txt


# ─────────────────────────────────────────────
#  PASO 1 — Recoger URLs del índice por letra
# ─────────────────────────────────────────────
def obtener_urls_letra(letra: str) -> list[dict]:
    """
    Devuelve lista de dicts con {nombre_completo, apellido, nombre, url_ficha}
    para todos los jugadores de esa letra.
    Las URLs de fichas se construyen apuntando a Wayback Machine.
    """
    url  = BASE_INDICE.format(letra=letra.lower())
    soup = get_soup(url)
    esperar()
    if not soup:
        return []

    jugadores = []

    # Los jugadores están listados como <a href="/jugadores/xxx.php">Apellido, Nombre</a>
    for a in soup.find_all("a", href=True):
        href = a["href"]

        # Filtrar solo enlaces a fichas individuales de jugadores
        if "/jugadores/" not in href:
            continue
        if href.endswith("/jugadores.php") or "jugadores.php#" in href:
            continue

        nombre_txt = a.get_text(strip=True)
        if not nombre_txt or len(nombre_txt) < 2:
            continue

        apellido, nombre = separar_nombre_apellido(nombre_txt)

        # ── Normalizar href a URL original limpia ────────────────────────────
        # Wayback devuelve hrefs que pueden tener varias formas:
        #   (a) Ya es Wayback:  "https://web.archive.org/web/20250813.../https://...sitio.../jugadores/x.php"
        #   (b) Relativa:       "/jugadores/x.php"
        #   (c) Absoluta sitio: "https://www.losmundialesdefutbol.com/jugadores/x.php"
        # En todos los casos extraemos solo el slug "/jugadores/x.php"

        # Extraer la parte desde "/jugadores/" en adelante
        slug_jugador = "/jugadores/" + href.split("/jugadores/")[-1]

        # URL original limpia (para guardar en CSV)
        url_original = ORIGINAL_BASE + slug_jugador

        # URL a consultar vía Wayback  (igual que en scraper_grupos.py)
        # Formato:  https://web.archive.org/web/20260101/https://www.sitio.com/jugadores/x.php
        url_ficha = f"{WAYBACK}/{ORIGINAL_BASE}{slug_jugador}"

        jugadores.append({
            "nombre_completo": nombre_txt,
            "apellido":        apellido,
            "nombre":          nombre,
            "url_ficha":       url_ficha,
            "url_original":    url_original,
        })

    # Eliminar posibles duplicados por URL original
    vistas = set()
    unicos = []
    for j in jugadores:
        key = j["url_original"]
        if key not in vistas:
            vistas.add(key)
            unicos.append(j)

    log.info(f"  Letra {letra.upper()}: {len(unicos)} jugadores encontrados en el índice")
    return unicos


# ─────────────────────────────────────────────
#  PASO 2 — Extraer detalle de la ficha
# ─────────────────────────────────────────────
def extraer_ficha(url: str) -> dict:
    """
    Extrae de la ficha individual:
        - nombre_completo (del h2 o tabla)
        - seleccion
        - fecha_nacimiento
        - posicion

    Estructura real de la tabla de ficha:
        <table>
          <tr><td>Nombre completo:</td>  <td>Lionel Andrés Messi</td></tr>
          <tr><td>Fecha de Nacimiento:</td><td>24 de junio de 1987</td></tr>
          <tr><td>Posición:</td>         <td>Delantero</td></tr>
          ...
        </table>
    La selección aparece como imagen con alt="Argentina" cerca del título
    "Selección Nacional".
    """
    soup = get_soup(url)
    esperar()
    if not soup:
        return {}

    data = {
        "nombre_completo_ficha": "",
        "seleccion":             "",
        "fecha_nacimiento":      "",
        "posicion":              "",
    }

    # ── Tabla de ficha (pares clave: valor) ──────────────────────────────────
    for tbl in soup.find_all("table"):
        filas = tbl.find_all("tr")
        for tr in filas:
            celdas = tr.find_all("td")
            if len(celdas) < 2:
                continue
            clave = celdas[0].get_text(strip=True).lower().rstrip(":")
            valor = celdas[1].get_text(strip=True)

            if "nombre completo" in clave:
                data["nombre_completo_ficha"] = valor
            elif "fecha de nacimiento" in clave:
                data["fecha_nacimiento"] = valor
            elif "posición" in clave or "posicion" in clave:
                data["posicion"] = valor

    # ── Selección: buscar img alt dentro de "Selección Nacional" ─────────────
    for h3 in soup.find_all("h3"):
        if "selección nacional" in h3.get_text(strip=True).lower():
            siguiente = h3.find_next_sibling()
            if siguiente:
                img = siguiente.find("img")
                if img and img.get("alt"):
                    data["seleccion"] = img["alt"]
                    break
            img = h3.find("img")
            if img and img.get("alt"):
                data["seleccion"] = img["alt"]
                break

    # Si no encontró selección por h3, buscar la img de bandera más cercana
    if not data["seleccion"]:
        for img in soup.find_all("img", alt=True):
            src = img.get("src", "")
            if "banderas" in src and "_sml_" in src:
                data["seleccion"] = img["alt"]
                break

    return data


# ─────────────────────────────────────────────
#  ESCRITURA CSV
# ─────────────────────────────────────────────
def inicializar_csv():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    if os.path.exists(OUTPUT_FILE):
        os.remove(OUTPUT_FILE)
        log.info(f"Archivo previo eliminado: {OUTPUT_FILE}")
    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNAS)
        writer.writeheader()


def guardar_jugadores(filas: list[dict]):
    with open(OUTPUT_FILE, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNAS, extrasaction="ignore")
        writer.writerows(filas)


# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────
def main(letras: list[str]):
    inicializar_csv()
    total_jugadores = 0

    for letra in letras:
        log.info(f"\n{'═'*50}")
        log.info(f"  Procesando letra: {letra.upper()}")
        log.info(f"{'═'*50}")

        # Paso 1: obtener lista de jugadores del índice
        jugadores_letra = obtener_urls_letra(letra)

        batch = []
        for i, jug in enumerate(jugadores_letra, 1):
            log.info(
                f"    [{i:>4}/{len(jugadores_letra)}] "
                f"{jug['nombre_completo']:<40} → {jug['url_ficha']}"
            )

            # Paso 2: extraer detalle de la ficha individual
            ficha = extraer_ficha(jug["url_ficha"])

            # Construir registro final
            # Priorizar nombre_completo_ficha si lo encontró,
            # si no, usar lo que vino del índice
            nombre_completo_final = (
                ficha.get("nombre_completo_ficha") or jug["nombre_completo"]
            )
            apellido_final, nombre_final = separar_nombre_apellido(nombre_completo_final)
            # Si el índice ya tenía apellido bien separado y la ficha no lo tiene, usarlo
            if not apellido_final and jug["apellido"]:
                apellido_final = jug["apellido"]
                nombre_final   = jug["nombre"]

            registro = {
                "apellido":         apellido_final,
                "nombre":           nombre_final,
                "nombre_completo":  nombre_completo_final or jug["nombre_completo"],
                "seleccion":        ficha.get("seleccion", ""),
                "fecha_nacimiento": ficha.get("fecha_nacimiento", ""),
                "posicion":         ficha.get("posicion", ""),
                # Guardar la URL original del sitio (no la de Wayback) en el CSV
                "url_ficha":        jug.get("url_original", jug["url_ficha"]),
            }
            batch.append(registro)

            # Guardar en lotes de 50 para no perder datos si se interrumpe
            if len(batch) >= 50:
                guardar_jugadores(batch)
                total_jugadores += len(batch)
                batch = []

        # Guardar el resto del lote
        if batch:
            guardar_jugadores(batch)
            total_jugadores += len(batch)

        log.info(f"  Letra {letra.upper()} completada.")

    # Resumen
    log.info(f"\n{'═'*50}")
    log.info(f"✅ Proceso completado.")
    log.info(f"   Total jugadores guardados : {total_jugadores}")
    log.info(f"   Archivo CSV               : {OUTPUT_FILE}")
    log.info(f"{'═'*50}")


# ─────────────────────────────────────────────
#  PUNTO DE ENTRADA
# ─────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Scraper de jugadores de losmundialesdefutbol.com"
    )
    parser.add_argument(
        "--letras",
        nargs="+",
        metavar="LETRA",
        help="Letras a procesar (ej: --letras A B C). Por defecto: todas (A-Z).",
        default=list(string.ascii_uppercase),
    )
    args = parser.parse_args()

    # Normalizar y validar letras
    letras_validas = [l.upper() for l in args.letras if l.isalpha()]
    if not letras_validas:
        print("No se especificaron letras válidas.")
        exit(1)

    main(letras_validas)