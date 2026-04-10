#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Incremental Backup — Día 1
# Herramienta: Percona XtraBackup
# Descripción: Backup incremental basado en el full backup del Día 1.
#              En el Día 1 el incremental es idéntico al full (no hay cambios
#              posteriores), pero establece la cadena LSN para días siguientes.
# Prerequisito: Haber ejecutado full_backup_day1.sh
# Uso: sudo bash incremental_backup_day1.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

TARGET_DIR="${INC_DIR}/day1"
BASE_DIR="${FULL_DIR}/day1"        # El incremental día 1 se basa en el full día 1
LOG_FILE="${LOG_DIR}/inc_backup_day1.log"
DAY_LABEL="DIA 1"

echo "============================================================" | tee "${LOG_FILE}"
echo "  INCREMENTAL BACKUP - ${DAY_LABEL}" | tee -a "${LOG_FILE}"
echo "  Inicio: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Base (LSN desde): ${BASE_DIR}" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

# Verificar que xtrabackup esté instalado
if ! command -v xtrabackup &>/dev/null; then
    echo "[ERROR] xtrabackup no está instalado." | tee -a "${LOG_FILE}"
    exit 1
fi

# Verificar que el full backup base exista
if [ ! -d "${BASE_DIR}" ]; then
    echo "[ERROR] Directorio base no existe: ${BASE_DIR}" | tee -a "${LOG_FILE}"
    echo "  Ejecute primero: full_backup_day1.sh" | tee -a "${LOG_FILE}"
    exit 1
fi

# Eliminar backup anterior si existe
if [ -d "${TARGET_DIR}" ]; then
    rm -rf "${TARGET_DIR}"
fi
mkdir -p "${TARGET_DIR}"

if [ -n "${MYSQL_PASS}" ]; then
    PASS_PARAM="--password=${MYSQL_PASS}"
else
    PASS_PARAM=""
fi

echo "[INFO] Iniciando xtrabackup incremental backup ..." | tee -a "${LOG_FILE}"
echo "[INFO] Target dir        : ${TARGET_DIR}" | tee -a "${LOG_FILE}"
echo "[INFO] Incremental basedir: ${BASE_DIR}" | tee -a "${LOG_FILE}"

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

echo "" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"
echo "  INCREMENTAL BACKUP COMPLETADO" | tee -a "${LOG_FILE}"
echo "  Fin      : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Duracion : ${ELAPSED_SEC} segundos (${ELAPSED_MS} ms)" | tee -a "${LOG_FILE}"
echo "  Directorio: ${TARGET_DIR}" | tee -a "${LOG_FILE}"
echo "  Tamaño   : $(du -sh "${TARGET_DIR}" | cut -f1)" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

TIMES_FILE="${LOG_DIR}/tiempos_backup.csv"
if [ ! -f "${TIMES_FILE}" ]; then
    echo "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg,tamano" > "${TIMES_FILE}"
fi
echo "1,INCREMENTAL,BACKUP,$(date -d "@$((START_TS/1000000000))" '+%Y-%m-%d %H:%M:%S'),$(date '+%Y-%m-%d %H:%M:%S'),${ELAPSED_MS},${ELAPSED_SEC},$(du -sh "${TARGET_DIR}" | cut -f1)" >> "${TIMES_FILE}"

echo "[OK] Incremental backup Día 1 finalizado exitosamente."
