"""
scraper_jugadores.py
====================
Web scraper para https://www.losmundialesdefutbol.com/jugadores_indice/letra_X.php

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
import string
import time
import logging
import requests
from bs4 import BeautifulSoup

# ─────────────────────────────────────────────
#  CONFIGURACIÓN
# ─────────────────────────────────────────────
BASE_INDICE  = "https://www.losmundialesdefutbol.com/jugadores_indice/letra_{letra}.php"
BASE_JUGADOR = "https://www.losmundialesdefutbol.com"
DELAY        = 0.5          # segundos entre peticiones
HEADERS      = {"User-Agent": "Mozilla/5.0 (educational scraper)"}
OUTPUT_DIR   = "output_csv"
OUTPUT_FILE  = os.path.join(OUTPUT_DIR, "jugadores.csv")

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
def get_soup(url: str) -> BeautifulSoup | None:
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        return BeautifulSoup(resp.text, "html.parser")
    except Exception as exc:
        log.warning(f"Error al obtener {url}: {exc}")
        return None


def separar_nombre_apellido(nombre_completo: str) -> tuple[str, str]:
    """
    El sitio muestra los nombres como 'Apellido, Nombre' o solo 'Nombre'.
    Ejemplos:
        'Messi, Lionel'      → apellido='Messi',     nombre='Lionel'
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
    """
    url  = BASE_INDICE.format(letra=letra.lower())
    soup = get_soup(url)
    time.sleep(DELAY)
    if not soup:
        return []

    jugadores = []

    # Los jugadores están listados como <a href="/jugadores/xxx.php">Apellido, Nombre</a>
    # dentro de la sección principal (después del h3 con el título)
    for a in soup.find_all("a", href=True):
        href = a["href"]
        if "/jugadores/" not in href:
            continue
        #print(f"  → Encontrado enlace: {href} con texto '{a.get_text(strip=True)}'")

        ##Quitar ".." del inicio si lo tiene
        href = href.lstrip("..")

        # Descartar enlaces del menú de navegación (que también apuntan a /jugadores/)
        if href.endswith("/jugadores.php") or "jugadores.php#" in href:
            continue

        # El texto del enlace es el nombre completo, pero a veces puede estar vacío o ser muy corto (ej: solo un guion)
        nombre_txt = a.get_text(strip=True)
        if not nombre_txt or len(nombre_txt) < 1:
            continue

        apellido, nombre = separar_nombre_apellido(nombre_txt)

        # URL completa
        url_ficha = href if href.startswith("http") else BASE_JUGADOR + href

        jugadores.append({
            "nombre_completo": nombre_txt,
            "apellido":        apellido,
            "nombre":          nombre,
            "url_ficha":       url_ficha,
        })

    # Eliminar posibles duplicados por URL
    vistas = set()
    unicos = []
    for j in jugadores:
        if j["url_ficha"] not in vistas:
            vistas.add(j["url_ficha"])
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
    time.sleep(DELAY)
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
            # La imagen de la bandera está justo después (en el mismo bloque o tag siguiente)
            siguiente = h3.find_next_sibling()
            if siguiente:
                img = siguiente.find("img")
                if img and img.get("alt"):
                    data["seleccion"] = img["alt"]
                    break
            # Alternativa: img dentro del mismo h3
            img = h3.find("img")
            if img and img.get("alt"):
                data["seleccion"] = img["alt"]
                break

    # Si no encontró selección por h3, buscar la img de bandera más cercana al h2 del jugador
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
        log.info(f" Procesando letra: {letra.upper()}")
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
            print(f"      → Ficha extraída: {ficha}")
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
                "url_ficha":        jug["url_ficha"],
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
    log.info(f" / Proceso completado.")
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