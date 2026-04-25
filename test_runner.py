#!/usr/bin/env python
"""
Script para ejecutar todas las pruebas finales de Fase 3
"""
import subprocess
import sys
import os
from pathlib import Path

# Cambiar al directorio fase3
os.chdir(Path(__file__).parent / "fase3")

print("=" * 60)
print("PRUEBAS FINALES FASE 3 - MUNDIALES DE FÚTBOL")
print("=" * 60)

# PASO 1: Instalar dependencias
print("\n[PASO 1] Instalando dependencias...")
result = subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], 
                       capture_output=True, text=True)
if result.returncode == 0:
    print("✅ Dependencias instaladas correctamente")
else:
    print("❌ Error instalando dependencias:")
    print(result.stderr)
    sys.exit(1)

# PASO 2: Cargar datos a MongoDB
print("\n[PASO 2] Cargando datos a MongoDB...")
result = subprocess.run([sys.executable, "load_data.py"], 
                       capture_output=True, text=True)
print(result.stdout)
if result.returncode != 0:
    print("❌ Error cargando datos:")
    print(result.stderr)
    sys.exit(1)
print("✅ Datos cargados exitosamente")

# PASO 3: Crear índices
print("\n[PASO 3] Creando índices...")
result = subprocess.run([sys.executable, "setup_indexes.py"], 
                       capture_output=True, text=True)
print(result.stdout)
if result.returncode != 0:
    print("❌ Error creando índices:")
    print(result.stderr)
    sys.exit(1)
print("✅ Índices creados correctamente")

# PASO 4: Probar consulta por Mundial
print("\n[PASO 4] Probando consulta por Mundial (1994)...")
result = subprocess.run([sys.executable, "consultas.py", "mundial", "1994"], 
                       capture_output=True, text=True)
print(result.stdout[:2000])  # Primeras 2000 caracteres
if result.returncode != 0:
    print("❌ Error en consulta mundial:")
    print(result.stderr)
else:
    print("✅ Consulta mundial funciona")

# PASO 5: Probar consulta por País
print("\n[PASO 5] Probando consulta por País (Argentina)...")
result = subprocess.run([sys.executable, "consultas.py", "pais", "Argentina"], 
                       capture_output=True, text=True)
print(result.stdout[:2000])
if result.returncode != 0:
    print("❌ Error en consulta país:")
    print(result.stderr)
else:
    print("✅ Consulta país funciona")

# PASO 6: Probar filtro por grupo
print("\n[PASO 6] Probando filtro por grupo...")
result = subprocess.run([sys.executable, "consultas.py", "mundial", "1994", "--grupo", "Grupo A"], 
                       capture_output=True, text=True)
if result.returncode == 0:
    print("✅ Filtro por grupo funciona")
else:
    print("⚠️  Filtro por grupo no disponible o error")

print("\n" + "=" * 60)
print("PRUEBAS COMPLETADAS")
print("=" * 60)
