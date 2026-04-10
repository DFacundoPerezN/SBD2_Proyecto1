#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Full Backup — Día 2
# Prerequisito: Haber ejecutado 07_simulate_day2.sql en MySQL
# Uso: sudo bash full_backup_day2.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

TARGET_DIR="${FULL_DIR}/day2"
LOG_FILE="${LOG_DIR}/full_backup_day2.log"

echo "============================================================" | tee "${LOG_FILE}"
echo "  FULL BACKUP - DIA 2" | tee -a "${LOG_FILE}"
echo "  Inicio: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

if ! command -v xtrabackup &>/dev/null; then
    echo "[ERROR] xtrabackup no está instalado." | tee -a "${LOG_FILE}"
    exit 1
fi

if [ -d "${TARGET_DIR}" ]; then
    rm -rf "${TARGET_DIR}"
fi
mkdir -p "${TARGET_DIR}"

PASS_PARAM=""
[ -n "${MYSQL_PASS}" ] && PASS_PARAM="--password=${MYSQL_PASS}"

START_TS=$(date +%s%N)

xtrabackup \
    --backup \
    --target-dir="${TARGET_DIR}" \
    --user="${MYSQL_USER}" \
    ${PASS_PARAM} \
    --host="${MYSQL_HOST}" \
    --port="${MYSQL_PORT}" \
    --no-timestamp \
    2>&1 | tee -a "${LOG_FILE}"

END_TS=$(date +%s%N)
ELAPSED_MS=$(( (END_TS - START_TS) / 1000000 ))
ELAPSED_SEC=$(echo "scale=3; ${ELAPSED_MS} / 1000" | bc)

echo "" | tee -a "${LOG_FILE}"
echo "  Fin      : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Duracion : ${ELAPSED_SEC} seg (${ELAPSED_MS} ms)" | tee -a "${LOG_FILE}"
echo "  Tamaño   : $(du -sh "${TARGET_DIR}" | cut -f1)" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

TIMES_FILE="${LOG_DIR}/tiempos_backup.csv"
[ ! -f "${TIMES_FILE}" ] && echo "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg,tamano" > "${TIMES_FILE}"
echo "2,FULL,BACKUP,$(date -d "@$((START_TS/1000000000))" '+%Y-%m-%d %H:%M:%S'),$(date '+%Y-%m-%d %H:%M:%S'),${ELAPSED_MS},${ELAPSED_SEC},$(du -sh "${TARGET_DIR}" | cut -f1)" >> "${TIMES_FILE}"

echo "[OK] Full backup Día 2 finalizado."
