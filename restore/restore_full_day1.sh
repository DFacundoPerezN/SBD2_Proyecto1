#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Restauración desde Full Backup — Día 1
# Herramienta: Percona XtraBackup
# Descripción: Elimina la base de datos actual y restaura el estado del Día 1.
#              Restaura a una segunda instancia llamada "proyecto2_mundiales".
# ADVERTENCIA: Este script DETIENE MySQL y BORRA el datadir.
#              Ejecutar solo con permisos de superusuario.
# Uso: sudo bash restore_full_day1.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../backup/config.sh"

BACKUP_DIR="${FULL_DIR}/day1"
LOG_FILE="${LOG_DIR}/restore_full_day1.log"
SECOND_DB="proyecto2_mundiales"

echo "============================================================" | tee "${LOG_FILE}"
echo "  RESTAURACION FULL BACKUP - DIA 1" | tee -a "${LOG_FILE}"
echo "  Inicio: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Origen: ${BACKUP_DIR}" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

# Verificar que el backup exista
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "[ERROR] Backup no encontrado: ${BACKUP_DIR}" | tee -a "${LOG_FILE}"
    exit 1
fi

# ---------------------------------------------------------------------------
# FASE 1: Preparar el backup (apply redo log)
# ---------------------------------------------------------------------------
echo "[INFO] Fase 1: Preparando backup (--prepare) ..." | tee -a "${LOG_FILE}"

PREPARE_START=$(date +%s%N)

xtrabackup --prepare \
    --target-dir="${BACKUP_DIR}" \
    2>&1 | tee -a "${LOG_FILE}"

PREPARE_END=$(date +%s%N)
PREPARE_MS=$(( (PREPARE_END - PREPARE_START) / 1000000 ))

echo "[INFO] Preparacion completada en $(echo "scale=3; ${PREPARE_MS}/1000" | bc) seg" | tee -a "${LOG_FILE}"

# ---------------------------------------------------------------------------
# FASE 2: Detener MySQL
# ---------------------------------------------------------------------------
echo "[INFO] Fase 2: Deteniendo servicio MySQL (${MYSQL_SERVICE}) ..." | tee -a "${LOG_FILE}"
systemctl stop "${MYSQL_SERVICE}"
sleep 2

# ---------------------------------------------------------------------------
# FASE 3: Limpiar datadir (eliminar BD actual)
# ---------------------------------------------------------------------------
echo "[INFO] Fase 3: Eliminando datadir actual: ${MYSQL_DATADIR}" | tee -a "${LOG_FILE}"
echo "[WARN] Esta operacion es IRREVERSIBLE sin los backups." | tee -a "${LOG_FILE}"
rm -rf "${MYSQL_DATADIR}"/*

# ---------------------------------------------------------------------------
# FASE 4: Copiar backup al datadir
# ---------------------------------------------------------------------------
echo "[INFO] Fase 4: Copiando backup a ${MYSQL_DATADIR} ..." | tee -a "${LOG_FILE}"

RESTORE_START=$(date +%s%N)

xtrabackup --copy-back \
    --target-dir="${BACKUP_DIR}" \
    --datadir="${MYSQL_DATADIR}" \
    2>&1 | tee -a "${LOG_FILE}"

RESTORE_END=$(date +%s%N)
RESTORE_MS=$(( (RESTORE_END - RESTORE_START) / 1000000 ))
RESTORE_SEC=$(echo "scale=3; ${RESTORE_MS}/1000" | bc)

# ---------------------------------------------------------------------------
# FASE 5: Corregir permisos
# ---------------------------------------------------------------------------
echo "[INFO] Fase 5: Restaurando permisos a ${MYSQL_OS_USER}:${MYSQL_OS_GROUP} ..." | tee -a "${LOG_FILE}"
chown -R "${MYSQL_OS_USER}:${MYSQL_OS_GROUP}" "${MYSQL_DATADIR}"

# ---------------------------------------------------------------------------
# FASE 6: Iniciar MySQL
# ---------------------------------------------------------------------------
echo "[INFO] Fase 6: Iniciando servicio MySQL ..." | tee -a "${LOG_FILE}"
systemctl start "${MYSQL_SERVICE}"
sleep 3

# ---------------------------------------------------------------------------
# FASE 7: Crear segunda base de datos (segundo esquema) copiando desde la restaurada
# ---------------------------------------------------------------------------
echo "[INFO] Fase 7: Creando segundo esquema: ${SECOND_DB} ..." | tee -a "${LOG_FILE}"

PASS_PARAM=""
[ -n "${MYSQL_PASS}" ] && PASS_PARAM="-p${MYSQL_PASS}"

mysql -u "${MYSQL_USER}" ${PASS_PARAM} -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" <<SQL 2>&1 | tee -a "${LOG_FILE}"
-- Crear el segundo esquema
DROP DATABASE IF EXISTS ${SECOND_DB};
CREATE DATABASE ${SECOND_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Copiar todas las tablas (estructura + datos) al segundo esquema
-- sin usar mysqldump: uso de CREATE TABLE...SELECT (operacion SQL nativa)
USE ${SECOND_DB};

CREATE TABLE pais            LIKE ${MYSQL_DB}.pais;
INSERT INTO  pais            SELECT * FROM ${MYSQL_DB}.pais;

CREATE TABLE mundial         LIKE ${MYSQL_DB}.mundial;
INSERT INTO  mundial         SELECT * FROM ${MYSQL_DB}.mundial;

CREATE TABLE mundial_sede    LIKE ${MYSQL_DB}.mundial_sede;
INSERT INTO  mundial_sede    SELECT * FROM ${MYSQL_DB}.mundial_sede;

CREATE TABLE grupo           LIKE ${MYSQL_DB}.grupo;
INSERT INTO  grupo           SELECT * FROM ${MYSQL_DB}.grupo;

CREATE TABLE grupo_posicion  LIKE ${MYSQL_DB}.grupo_posicion;
INSERT INTO  grupo_posicion  SELECT * FROM ${MYSQL_DB}.grupo_posicion;

CREATE TABLE partido         LIKE ${MYSQL_DB}.partido;
INSERT INTO  partido         SELECT * FROM ${MYSQL_DB}.partido;

CREATE TABLE gol_partido     LIKE ${MYSQL_DB}.gol_partido;
INSERT INTO  gol_partido     SELECT * FROM ${MYSQL_DB}.gol_partido;

CREATE TABLE goleador_mundial LIKE ${MYSQL_DB}.goleador_mundial;
INSERT INTO  goleador_mundial SELECT * FROM ${MYSQL_DB}.goleador_mundial;

CREATE TABLE posicion_final  LIKE ${MYSQL_DB}.posicion_final;
INSERT INTO  posicion_final  SELECT * FROM ${MYSQL_DB}.posicion_final;

CREATE TABLE jugador         LIKE ${MYSQL_DB}.jugador;
INSERT INTO  jugador         SELECT * FROM ${MYSQL_DB}.jugador;

-- Verificacion
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = '${SECOND_DB}'
ORDER BY TABLE_NAME;
SQL

TOTAL_MS=$(( (RESTORE_END - RESTORE_START) / 1000000 ))

echo "" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"
echo "  RESTAURACION COMPLETADA" | tee -a "${LOG_FILE}"
echo "  Fin           : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Tiempo restore: ${RESTORE_SEC} seg (${RESTORE_MS} ms)" | tee -a "${LOG_FILE}"
echo "  Segundo esquema creado: ${SECOND_DB}" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

# Registrar tiempo de restauración
TIMES_FILE="${LOG_DIR}/tiempos_restauracion.csv"
[ ! -f "${TIMES_FILE}" ] && echo "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg" > "${TIMES_FILE}"
echo "1,FULL,RESTORE,$(date -d "@$((RESTORE_START/1000000000))" '+%Y-%m-%d %H:%M:%S'),$(date '+%Y-%m-%d %H:%M:%S'),${RESTORE_MS},${RESTORE_SEC}" >> "${TIMES_FILE}"

echo "[OK] Restauracion Full Dia 1 completada."
