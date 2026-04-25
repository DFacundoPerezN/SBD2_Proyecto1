"""
Métodos de consulta para el Proyecto Fase 3 - Mundiales de Fútbol.

Uso rápido:
    python consultas.py mundial 1994
    python consultas.py mundial 1994 --grupo "Grupo A"
    python consultas.py mundial 1994 --pais "México"
    python consultas.py mundial 1994 --fecha 1994-06-17
    python consultas.py pais "Argentina"
    python consultas.py pais "Argentina" --anio 1986
"""

import sys
import argparse
from pymongo import MongoClient
from config import MONGO_URI, DB_NAME

# ---------------------------------------------------------------------------
# Helpers de formateo
# ---------------------------------------------------------------------------

SEP  = "=" * 70
SEP2 = "-" * 70


def header(title):
    print(f"\n{SEP}")
    print(f"  {title}")
    print(SEP)


def subheader(title):
    print(f"\n  {SEP2}")
    print(f"  {title}")
    print(f"  {SEP2}")


def resultado_partido(p):
    gf = p.get("goles_local", 0) or 0
    gc = p.get("goles_visitante", 0) or 0
    linea = f"    [{p.get('numero'):>3}] {p.get('fecha')}  {p.get('etapa')}"
    marcador = f"       {p.get('equipo_local'):<22} {gf} - {gc}  {p.get('equipo_visitante')}"
    extras = []
    if p.get("goles_local_et") is not None:
        extras.append(f"Prórroga: {p['goles_local_et']} - {p['goles_visit_et']}")
    if p.get("penales_local") is not None:
        extras.append(f"Penales: {p['penales_local']} - {p['penales_visit']}")
    print(linea)
    print(marcador)
    if extras:
        print("       " + " | ".join(extras))


def tabla_grupo(tabla):
    print(f"    {'#':<3} {'Selección':<25} {'Pts':>4} {'PJ':>4} {'PG':>4} {'PE':>4} {'PP':>4} {'GF':>4} {'GC':>4} {'Dif':>4} {'Cls':>4}")
    for r in tabla:
        cls = "SI" if r.get("clasificado") else "NO"
        print(f"    {r.get('posicion', ''):>2}  {r.get('seleccion', ''):<25} "
              f"{r.get('pts', 0):>4} {r.get('pj', 0):>4} {r.get('pg', 0):>4} "
              f"{r.get('pe', 0):>4} {r.get('pp', 0):>4} {r.get('gf', 0):>4} "
              f"{r.get('gc', 0):>4} {r.get('dif', 0):>4} {cls:>4}")


# ---------------------------------------------------------------------------
# Método c) consultar_mundial
# ---------------------------------------------------------------------------

def consultar_mundial(anio, grupo=None, pais=None, fecha=None):
    """
    Muestra toda la información de un Mundial.

    Parámetros opcionales:
        grupo  str  — filtra partidos/tabla a un grupo específico (ej: "Grupo A")
        pais   str  — filtra partidos donde participa ese país
        fecha  str  — filtra partidos de esa fecha (formato YYYY-MM-DD)
    """
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]

    doc = db.mundiales.find_one({"anio": int(anio)})
    if not doc:
        print(f"No se encontró el Mundial {anio}.")
        client.close()
        return

    header(f"MUNDIAL {doc['anio']}  —  Sede: {doc['sede']}")
    print(f"  Equipos: {doc['num_selecciones']}   Partidos: {doc['num_partidos']}   Goles: {doc['num_goles']}   Promedio: {doc['promedio_gol']}")
    print(f"  Campeón:    {doc.get('campeon', 'N/D')}")
    print(f"  Subcampeón: {doc.get('subcampeon', 'N/D')}")
    print(f"  3er lugar:  {doc.get('tercero', 'N/D')}")
    print(f"  4to lugar:  {doc.get('cuarto', 'N/D')}")

    # --- Grupos ---
    subheader("GRUPOS")
    for g in doc.get("grupos", []):
        if grupo and g["nombre"].lower() != grupo.lower():
            continue
        print(f"\n  {g['nombre']}  ({g['num_selecciones']} equipos, clasifican {g['num_clasificados']})")
        tabla_grupo(g.get("tabla", []))

    # --- Partidos ---
    partidos = doc.get("partidos", [])

    # aplicar filtros
    if grupo:
        partidos = [p for p in partidos if grupo.lower() in p.get("etapa", "").lower()]
    if pais:
        partidos = [p for p in partidos
                    if pais.lower() in p.get("equipo_local", "").lower()
                    or pais.lower() in p.get("equipo_visitante", "").lower()]
    if fecha:
        partidos = [p for p in partidos if p.get("fecha", "").startswith(fecha)]

    subheader(f"PARTIDOS ({len(partidos)})")
    for p in sorted(partidos, key=lambda x: x.get("numero") or 0):
        resultado_partido(p)
        # goles detalle
        for g in p.get("goles_detalle", []):
            et = " (ET)" if g.get("tiempo_extra") else ""
            tipo = f" [{g['tipo']}]" if g.get("tipo") and g["tipo"] != "normal" else ""
            print(f"           ⚽ {g['minuto_texto']:>4}'{et}  {g['jugador']} ({g['seleccion']}){tipo}")

    # --- Posiciones finales ---
    if not (grupo or pais or fecha):
        subheader("POSICIONES FINALES")
        print(f"    {'Pos':<5} {'Selección':<25} {'Etapa':<20} {'PJ':>4} {'PG':>4} {'GF':>4} {'GC':>4}")
        for p in doc.get("posiciones_finales", []):
            print(f"    {p.get('posicion', ''):>3}   {p.get('seleccion', ''):<25} "
                  f"{p.get('etapa_alcanzada', '')::<20} "
                  f"{p.get('pj', 0):>4} {p.get('pg', 0):>4} "
                  f"{p.get('gf', 0):>4} {p.get('gc', 0):>4}")

        subheader("MEJORES GOLEADORES")
        print(f"    {'#':<4} {'Jugador':<28} {'Selección':<22} {'Goles':>6} {'Partidos':>9}")
        for g in doc.get("mejores_goleadores", [])[:10]:
            print(f"    {g.get('posicion', ''):>2}.  {g.get('jugador', ''):<28} "
                  f"{g.get('seleccion', ''):<22} {g.get('goles', 0):>6} {g.get('partidos', 0):>9}")

    client.close()


# ---------------------------------------------------------------------------
# Método d) consultar_pais
# ---------------------------------------------------------------------------

def consultar_pais(pais, anio=None):
    """
    Muestra toda la información de un país en los mundiales.

    Parámetros opcionales:
        anio  int  — filtra a un mundial específico
    """
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]

    doc = db.paises.find_one({"seleccion": {"$regex": f"^{pais}$", "$options": "i"}})
    if not doc:
        print(f"No se encontró información para '{pais}'.")
        client.close()
        return

    header(f"SELECCIÓN: {doc['seleccion']}")
    print(f"  Participaciones: {doc['num_participaciones']}")

    sedes = doc.get("anios_sede", [])
    if sedes:
        print(f"  Fue sede en:     {', '.join(str(a) for a in sorted(sedes))}")
    else:
        print(f"  Fue sede:        Nunca")

    participaciones = doc.get("participaciones", [])
    if anio:
        participaciones = [p for p in participaciones if p["anio"] == int(anio)]

    for part in participaciones:
        subheader(f"MUNDIAL {part['anio']}" + (" [SEDE]" if part.get("fue_sede") else ""))

        pf = part.get("posicion_final")
        etapa = part.get("etapa_alcanzada", "N/D")
        print(f"  Posición final:  {pf if pf else 'N/D'}  ({etapa})")

        g = part.get("grupo")
        if g:
            print(f"  Grupo:           {g['nombre']}  —  Posición: {g['posicion_en_grupo']}  —  Clasificó: {'Sí' if g['clasifico'] else 'No'}")
            print(f"  Stats grupo:     PJ:{g['pj']}  PG:{g['pg']}  PE:{g['pe']}  PP:{g['pp']}  GF:{g['gf']}  GC:{g['gc']}  Dif:{g['dif']}  Pts:{g['pts']}")

        print(f"\n  Partidos ({len(part.get('partidos', []))}):")
        print(f"    {'#':>3}  {'Fecha':<12} {'Condición':<10} {'Rival':<25} {'Resultado':>10}")
        for p in part.get("partidos", []):
            gf = p.get("goles_favor", 0) or 0
            gc = p.get("goles_contra", 0) or 0
            res = f"{gf} - {gc}"
            if p.get("goles_favor_et") is not None:
                res += f"  (ET {p['goles_favor_et']}-{p['goles_contra_et']})"
            if p.get("penales_favor") is not None:
                res += f"  (Pen {p['penales_favor']}-{p['penales_contra']})"
            cond = p.get("condicion", "")
            print(f"    {p.get('numero', ''):>3}  {p.get('fecha', '')::<12} {cond:<10} {p.get('rival', '')::<25} {res:>10}")
            print(f"         {p.get('etapa', '')}")

        goles = part.get("goles_marcados", [])
        if goles:
            print(f"\n  Goles marcados ({len(goles)}):")
            for g in goles:
                et = " (ET)" if g.get("tiempo_extra") else ""
                tipo = f" [{g['tipo']}]" if g.get("tipo") and g["tipo"] != "normal" else ""
                print(f"    ⚽ {g.get('minuto_texto', ''):>4}'{et}  {g.get('jugador', '')}{tipo}  —  {g.get('partido', '')}")

    client.close()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Consultas Mundiales de Fútbol - MongoDB")
    sub = parser.add_subparsers(dest="cmd")

    p_mundial = sub.add_parser("mundial", help="Consulta por año de mundial")
    p_mundial.add_argument("anio", type=int)
    p_mundial.add_argument("--grupo", default=None, help='Ej: "Grupo A"')
    p_mundial.add_argument("--pais", default=None, help='Ej: "México"')
    p_mundial.add_argument("--fecha", default=None, help="Ej: 1994-06-17")

    p_pais = sub.add_parser("pais", help="Consulta por selección")
    p_pais.add_argument("pais")
    p_pais.add_argument("--anio", type=int, default=None)

    args = parser.parse_args()

    if args.cmd == "mundial":
        consultar_mundial(args.anio, grupo=args.grupo, pais=args.pais, fecha=args.fecha)
    elif args.cmd == "pais":
        consultar_pais(args.pais, anio=args.anio)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
