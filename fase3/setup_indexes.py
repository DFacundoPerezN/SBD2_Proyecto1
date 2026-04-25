"""
Crea los índices en MongoDB Atlas para optimizar las consultas.
Ejecutar DESPUÉS de load_data.py.
"""

from pymongo import MongoClient, ASCENDING
from config import MONGO_URI, DB_NAME


def main():
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]

    # mundiales: búsqueda por año
    db.mundiales.create_index([("anio", ASCENDING)], unique=True, name="idx_mundiales_anio")
    # mundiales: búsqueda por sede
    db.mundiales.create_index([("sede", ASCENDING)], name="idx_mundiales_sede")
    # mundiales: búsqueda por país dentro de partidos
    db.mundiales.create_index([("partidos.equipo_local", ASCENDING)], name="idx_mundiales_local")
    db.mundiales.create_index([("partidos.equipo_visitante", ASCENDING)], name="idx_mundiales_visitante")
    # mundiales: búsqueda por grupo
    db.mundiales.create_index([("grupos.nombre", ASCENDING)], name="idx_mundiales_grupo")

    # paises: búsqueda por nombre de selección
    db.paises.create_index([("seleccion", ASCENDING)], unique=True, name="idx_paises_seleccion")
    # paises: búsqueda por año de participación
    db.paises.create_index([("participaciones.anio", ASCENDING)], name="idx_paises_anio")
    # paises: búsqueda por si fue sede
    db.paises.create_index([("anios_sede", ASCENDING)], name="idx_paises_sede")

    client.close()
    print("Índices creados correctamente.")


if __name__ == "__main__":
    main()
