#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Full Backup — Día 1
# Herramienta: Percona XtraBackup (xtrabackup)
# Descripción: Realiza un backup completo (binario) de toda la instancia MySQL
#              al finalizar la carga del Día 1. Registra tiempo de ejecución.
# Uso: sudo bash full_backup_day1.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

TARGET_DIR="${FULL_DIR}/day1"
LOG_FILE="${LOG_DIR}/full_backup_day1.log"
DAY_LABEL="DIA 1"

echo "============================================================" | tee "${LOG_FILE}"
echo "  FULL BACKUP - ${DAY_LABEL}" | tee -a "${LOG_FILE}"
echo "  Inicio: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

# Verificar que xtrabackup esté instalado
if ! command -v xtrabackup &>/dev/null; then
    echo "[ERROR] xtrabackup no está instalado." | tee -a "${LOG_FILE}"
    echo "  Instalar con: sudo apt install percona-xtrabackup-80" | tee -a "${LOG_FILE}"
    exit 1
fi

# Eliminar backup anterior si existe (para re-ejecución limpia)
if [ -d "${TARGET_DIR}" ]; then
    echo "[INFO] Eliminando backup anterior en ${TARGET_DIR} ..." | tee -a "${LOG_FILE}"
    rm -rf "${TARGET_DIR}"
fi

mkdir -p "${TARGET_DIR}"

# --- Construir parámetro de password ---
if [ -n "${MYSQL_PASS}" ]; then
    PASS_PARAM="--password=${MYSQL_PASS}"
else
    PASS_PARAM=""
fi

echo "[INFO] Iniciando xtrabackup full backup ..." | tee -a "${LOG_FILE}"
echo "[INFO] Target dir: ${TARGET_DIR}" | tee -a "${LOG_FILE}"

# --- Medir tiempo de ejecución ---
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
echo "============================================================" | tee -a "${LOG_FILE}"
echo "  BACKUP COMPLETADO" | tee -a "${LOG_FILE}"
echo "  Fin      : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Duracion : ${ELAPSED_SEC} segundos (${ELAPSED_MS} ms)" | tee -a "${LOG_FILE}"
echo "  Directorio: ${TARGET_DIR}" | tee -a "${LOG_FILE}"
echo "  Tamaño   : $(du -sh "${TARGET_DIR}" | cut -f1)" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

# Registrar resultado en archivo de tiempos comparativos
TIMES_FILE="${LOG_DIR}/tiempos_backup.csv"
if [ ! -f "${TIMES_FILE}" ]; then
    echo "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg,tamano" > "${TIMES_FILE}"
fi
echo "1,FULL,BACKUP,$(date -d "@$((START_TS/1000000000))" '+%Y-%m-%d %H:%M:%S'),$(date '+%Y-%m-%d %H:%M:%S'),${ELAPSED_MS},${ELAPSED_SEC},$(du -sh "${TARGET_DIR}" | cut -f1)" >> "${TIMES_FILE}"

echo "[OK] Full backup Día 1 finalizado exitosamente."
