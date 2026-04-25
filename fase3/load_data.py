"""
Carga los CSVs de output_csv/ a MongoDB Atlas.
Construye dos colecciones desnormalizadas:
  - mundiales: un documento por año con todo embebido
  - paises:    un documento por seleccion con todas sus participaciones
"""

import csv
import os
from collections import defaultdict
from pymongo import MongoClient
from config import MONGO_URI, DB_NAME, CSV_DIR


def read_csv(filename, encoding="utf-8-sig"):
    path = os.path.join(CSV_DIR, filename)
    with open(path, encoding=encoding, newline="") as f:
        return list(csv.DictReader(f))


def to_int(v):
    try:
        return int(v)
    except (ValueError, TypeError):
        return None


def to_float(v):
    try:
        return float(v)
    except (ValueError, TypeError):
        return None


def to_bool(v):
    return str(v).strip().lower() == "true"


# ---------------------------------------------------------------------------
# Carga de CSVs
# ---------------------------------------------------------------------------

def load_all_csvs():
    mundiales_raw    = read_csv("mundiales.csv")
    partidos_raw     = read_csv("partidos.csv")
    grupos_raw       = read_csv("grupos.csv")
    grupo_sel_raw    = read_csv("grupo_seleccion.csv")
    goles_raw        = read_csv("goles.csv")
    posiciones_raw   = read_csv("posiciones_finales.csv")
    goleadores_raw   = read_csv("mejores_goleadores.csv")

    return mundiales_raw, partidos_raw, grupos_raw, grupo_sel_raw, goles_raw, posiciones_raw, goleadores_raw


# ---------------------------------------------------------------------------
# Indexación auxiliar
# ---------------------------------------------------------------------------

def index_by(rows, *keys):
    idx = defaultdict(list)
    for r in rows:
        k = tuple(r[k] for k in keys)
        idx[k].append(r)
    return idx


def index_one(rows, *keys):
    idx = {}
    for r in rows:
        k = tuple(r[k] for k in keys)
        idx[k] = r
    return idx


# ---------------------------------------------------------------------------
# Construcción de documentos para colección `mundiales`
# ---------------------------------------------------------------------------

def build_mundiales(mundiales_raw, partidos_raw, grupos_raw, grupo_sel_raw,
                    goles_raw, posiciones_raw, goleadores_raw):

    partidos_by_anio   = index_by(partidos_raw, "anio_mundial")
    grupos_by_anio     = index_by(grupos_raw, "anio_mundial")
    grupo_sel_by_anio  = index_by(grupo_sel_raw, "anio_mundial")
    goles_by_partido   = index_by(goles_raw, "anio_mundial", "equipo_local", "equipo_visitante")
    posiciones_by_anio = index_by(posiciones_raw, "anio_mundial")
    goleadores_by_anio = index_by(goleadores_raw, "anio_mundial")

    docs = []
    for m in mundiales_raw:
        anio = m["anio"]

        # posiciones finales
        pos_list = sorted(posiciones_by_anio.get((anio,), []), key=lambda x: to_int(x["posicion"]) or 999)
        pos_by_num = {to_int(p["posicion"]): p["seleccion"] for p in pos_list}

        posiciones_finales = [
            {
                "posicion": to_int(p["posicion"]),
                "seleccion": p["seleccion"],
                "etapa_alcanzada": p["etapa_alcanzada"],
                "puntos": to_int(p["puntos"]),
                "pj": to_int(p["pj"]),
                "pg": to_int(p["pg"]),
                "pe": to_int(p["pe"]),
                "pp": to_int(p["pp"]),
                "gf": to_int(p["gf"]),
                "gc": to_int(p["gc"]),
                "dif": to_int(p["dif"]),
            }
            for p in pos_list
        ]

        # grupos con tabla de posiciones embebida
        tabla_by_grupo = defaultdict(list)
        for gs in grupo_sel_by_anio.get((anio,), []):
            tabla_by_grupo[gs["nombre_grupo"]].append({
                "posicion": to_int(gs["posicion"]),
                "seleccion": gs["seleccion"],
                "pts": to_int(gs["pts"]),
                "pj": to_int(gs["pj"]),
                "pg": to_int(gs["pg"]),
                "pe": to_int(gs["pe"]),
                "pp": to_int(gs["pp"]),
                "gf": to_int(gs["gf"]),
                "gc": to_int(gs["gc"]),
                "dif": to_int(gs["dif"]),
                "clasificado": to_bool(gs["clasificado"]),
            })

        grupos = []
        for g in grupos_by_anio.get((anio,), []):
            tabla = sorted(tabla_by_grupo.get(g["nombre_grupo"], []), key=lambda x: x["posicion"] or 999)
            grupos.append({
                "nombre": g["nombre_grupo"],
                "num_selecciones": to_int(g["num_selecciones"]),
                "num_clasificados": to_int(g["num_clasificados"]),
                "tabla": tabla,
            })

        # partidos con goles embebidos
        partidos = []
        for p in partidos_by_anio.get((anio,), []):
            key = (anio, p["equipo_local"], p["equipo_visitante"])
            goles_partido = [
                {
                    "jugador": g["jugador"],
                    "seleccion": g["seleccion_gol"],
                    "minuto": to_int(g["minuto_num"]),
                    "minuto_texto": g["minuto"],
                    "tipo": g["tipo_gol"],
                    "tiempo_extra": to_bool(g["tiempo_extra"]),
                }
                for g in goles_by_partido.get(key, [])
            ]
            partidos.append({
                "numero": to_int(p["numero_partido"]),
                "fecha": p["fecha"],
                "etapa": p["etapa"],
                "equipo_local": p["equipo_local"],
                "equipo_visitante": p["equipo_visitante"],
                "goles_local": to_int(p["goles_local"]),
                "goles_visitante": to_int(p["goles_visitante"]),
                "goles_local_et": to_int(p["goles_local_et"]),
                "goles_visit_et": to_int(p["goles_visit_et"]),
                "penales_local": to_int(p["penales_local"]),
                "penales_visit": to_int(p["penales_visit"]),
                "goles_detalle": goles_partido,
            })

        # mejores goleadores
        goleadores = [
            {
                "posicion": to_int(g["posicion"]),
                "jugador": g["jugador"],
                "seleccion": g["seleccion"],
                "goles": to_int(g["goles"]),
                "partidos": to_int(g["partidos"]),
                "promedio": to_float(g["promedio_gol"]),
            }
            for g in sorted(goleadores_by_anio.get((anio,), []), key=lambda x: to_int(x["posicion"]) or 999)
        ]

        docs.append({
            "anio": to_int(anio),
            "sede": m["sede"],
            "num_selecciones": to_int(m["num_selecciones"]),
            "num_partidos": to_int(m["num_partidos"]),
            "num_goles": to_int(m["num_goles"]),
            "promedio_gol": to_float(m["promedio_gol"]),
            "campeon": pos_by_num.get(1),
            "subcampeon": pos_by_num.get(2),
            "tercero": pos_by_num.get(3),
            "cuarto": pos_by_num.get(4),
            "grupos": grupos,
            "partidos": partidos,
            "posiciones_finales": posiciones_finales,
            "mejores_goleadores": goleadores,
        })

    return docs


# ---------------------------------------------------------------------------
# Construcción de documentos para colección `paises`
# ---------------------------------------------------------------------------

def build_paises(mundiales_raw, partidos_raw, grupos_raw, grupo_sel_raw,
                 goles_raw, posiciones_raw):

    mundiales_dict   = {m["anio"]: m for m in mundiales_raw}
    sedes_por_anio   = {m["anio"]: m["sede"] for m in mundiales_raw}

    grupo_sel_idx    = index_by(grupo_sel_raw, "anio_mundial", "seleccion")
    posiciones_idx   = index_one(posiciones_raw, "anio_mundial", "seleccion")
    goles_idx        = index_by(goles_raw, "anio_mundial", "seleccion_gol")

    # Obtener todos los países que aparecen en grupo_seleccion
    all_paises = set(r["seleccion"] for r in grupo_sel_raw)
    # También incluir los que solo aparecen en posiciones_finales (ej. campeones sin grupo)
    all_paises.update(r["seleccion"] for r in posiciones_raw)

    # Mapa de seleccion -> años en que fue sede
    sede_por_seleccion = defaultdict(list)
    for anio, sede in sedes_por_anio.items():
        sede_por_seleccion[sede].append(to_int(anio))

    # Índice de partidos: por anio, para cada seleccion sus partidos
    partidos_por_pais = defaultdict(list)
    for p in partidos_raw:
        anio = p["anio_mundial"]
        for rol, rival, gf, gc in [
            ("local",     p["equipo_visitante"], p["goles_local"],     p["goles_visitante"]),
            ("visitante", p["equipo_local"],     p["goles_visitante"], p["goles_local"]),
        ]:
            seleccion = p["equipo_local"] if rol == "local" else p["equipo_visitante"]
            partidos_por_pais[(anio, seleccion)].append({
                "numero": to_int(p["numero_partido"]),
                "fecha": p["fecha"],
                "etapa": p["etapa"],
                "rival": rival,
                "condicion": rol,
                "goles_favor": to_int(gf),
                "goles_contra": to_int(gc),
                "goles_favor_et": to_int(p["goles_local_et"] if rol == "local" else p["goles_visit_et"]),
                "goles_contra_et": to_int(p["goles_visit_et"] if rol == "local" else p["goles_local_et"]),
                "penales_favor": to_int(p["penales_local"] if rol == "local" else p["penales_visit"]),
                "penales_contra": to_int(p["penales_visit"] if rol == "local" else p["penales_local"]),
            })

    docs = []
    for seleccion in sorted(all_paises):
        anios_sede = sorted(sede_por_seleccion.get(seleccion, []))

        # Años en que participó (aparece en grupo_seleccion o posiciones_finales)
        anios_part = set()
        for k in grupo_sel_idx:
            if k[1] == seleccion:
                anios_part.add(k[0])
        for k in posiciones_idx:
            if k[1] == seleccion:
                anios_part.add(k[0])

        participaciones = []
        for anio in sorted(anios_part):
            fue_sede = seleccion == sedes_por_anio.get(anio)

            # info de grupo
            gs_rows = grupo_sel_idx.get((anio, seleccion), [])
            if gs_rows:
                gs = gs_rows[0]
                grupo_info = {
                    "nombre": gs["nombre_grupo"],
                    "posicion_en_grupo": to_int(gs["posicion"]),
                    "clasifico": to_bool(gs["clasificado"]),
                    "pts": to_int(gs["pts"]),
                    "pj": to_int(gs["pj"]),
                    "pg": to_int(gs["pg"]),
                    "pe": to_int(gs["pe"]),
                    "pp": to_int(gs["pp"]),
                    "gf": to_int(gs["gf"]),
                    "gc": to_int(gs["gc"]),
                    "dif": to_int(gs["dif"]),
                }
            else:
                grupo_info = None

            # posicion final
            pf = posiciones_idx.get((anio, seleccion))
            posicion_final = to_int(pf["posicion"]) if pf else None
            etapa_alcanzada = pf["etapa_alcanzada"] if pf else None

            # partidos
            partidos = sorted(partidos_por_pais.get((anio, seleccion), []), key=lambda x: x["numero"] or 0)

            # goles marcados
            goles = [
                {
                    "jugador": g["jugador"],
                    "minuto": to_int(g["minuto_num"]),
                    "minuto_texto": g["minuto"],
                    "tipo": g["tipo_gol"],
                    "tiempo_extra": to_bool(g["tiempo_extra"]),
                    "partido": f"{g['equipo_local']} vs {g['equipo_visitante']}",
                }
                for g in goles_idx.get((anio, seleccion), [])
            ]

            participaciones.append({
                "anio": to_int(anio),
                "fue_sede": fue_sede,
                "grupo": grupo_info,
                "posicion_final": posicion_final,
                "etapa_alcanzada": etapa_alcanzada,
                "partidos": partidos,
                "goles_marcados": goles,
            })

        docs.append({
            "seleccion": seleccion,
            "anios_sede": anios_sede,
            "num_participaciones": len(participaciones),
            "participaciones": participaciones,
        })

    return docs


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("Conectando a MongoDB Atlas...")
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]

    print("Leyendo CSVs...")
    mundiales_raw, partidos_raw, grupos_raw, grupo_sel_raw, goles_raw, posiciones_raw, goleadores_raw = load_all_csvs()

    # --- Colección mundiales ---
    print("Construyendo colección 'mundiales'...")
    mundiales_docs = build_mundiales(
        mundiales_raw, partidos_raw, grupos_raw, grupo_sel_raw,
        goles_raw, posiciones_raw, goleadores_raw
    )
    col_mundiales = db["mundiales"]
    col_mundiales.drop()
    col_mundiales.insert_many(mundiales_docs)
    print(f"  Insertados {len(mundiales_docs)} documentos en 'mundiales'")

    # --- Colección paises ---
    print("Construyendo colección 'paises'...")
    paises_docs = build_paises(
        mundiales_raw, partidos_raw, grupos_raw, grupo_sel_raw,
        goles_raw, posiciones_raw
    )
    col_paises = db["paises"]
    col_paises.drop()
    col_paises.insert_many(paises_docs)
    print(f"  Insertados {len(paises_docs)} documentos en 'paises'")

    client.close()
    print("Carga completada exitosamente.")


if __name__ == "__main__":
    main()
