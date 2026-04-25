#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Incremental Backup — Día 2
# Base LSN: incremental del Día 1 (captura solo cambios del Día 2)
# Prerequisito: incremental_backup_day1.sh ya ejecutado
# Uso: sudo bash incremental_backup_day2.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

TARGET_DIR="${INC_DIR}/day2"
BASE_DIR="${INC_DIR}/day1"         # Se basa en el incremental del día anterior
LOG_FILE="${LOG_DIR}/inc_backup_day2.log"

echo "============================================================" | tee "${LOG_FILE}"
echo "  INCREMENTAL BACKUP - DIA 2" | tee -a "${LOG_FILE}"
echo "  Inicio : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Base   : ${BASE_DIR}" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

if ! command -v xtrabackup &>/dev/null; then
    echo "[ERROR] xtrabackup no está instalado." | tee -a "${LOG_FILE}"
    exit 1
fi

if [ ! -d "${BASE_DIR}" ]; then
    echo "[ERROR] Base incremental no existe: ${BASE_DIR}" | tee -a "${LOG_FILE}"
    exit 1
fi

[ -d "${TARGET_DIR}" ] && rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

PASS_PARAM=""
[ -n "${MYSQL_PASS}" ] && PASS_PARAM="--password=${MYSQL_PASS}"

START_TS=$(date +%s%N)

xtrabackup \
    --backup \
    --target-dir="${TARGET_DIR}" \
    --incremental-basedir="${BASE_DIR}" \
    --user="${MYSQL_USER}" \
    ${PASS_PARAM} \
    --host="${MYSQL_HOST}" \
    --port="${MYSQL_PORT}" \
    --no-timestamp \
    2>&1 | tee -a "${LOG_FILE}"

END_TS=$(date +%s%N)
ELAPSED_MS=$(( (END_TS - START_TS) / 1000000 ))
ELAPSED_SEC=$(echo "scale=3; ${ELAPSED_MS} / 1000" | bc)

echo "  Fin      : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Duracion : ${ELAPSED_SEC} seg (${ELAPSED_MS} ms)" | tee -a "${LOG_FILE}"
echo "  Tamaño   : $(du -sh "${TARGET_DIR}" | cut -f1)" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

TIMES_FILE="${LOG_DIR}/tiempos_backup.csv"
[ ! -f "${TIMES_FILE}" ] && echo "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg,tamano" > "${TIMES_FILE}"
echo "2,INCREMENTAL,BACKUP,$(date -d "@$((START_TS/1000000000))" '+%Y-%m-%d %H:%M:%S'),$(date '+%Y-%m-%d %H:%M:%S'),${ELAPSED_MS},${ELAPSED_SEC},$(du -sh "${TARGET_DIR}" | cut -f1)" >> "${TIMES_FILE}"

echo "[OK] Incremental backup Día 2 finalizado."
