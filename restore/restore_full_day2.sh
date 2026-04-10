#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Restauración desde Full Backup — Día 2
# Uso: sudo bash restore_full_day2.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../backup/config.sh"

BACKUP_DIR="${FULL_DIR}/day2"
LOG_FILE="${LOG_DIR}/restore_full_day2.log"

echo "============================================================" | tee "${LOG_FILE}"
echo "  RESTAURACION FULL BACKUP - DIA 2" | tee -a "${LOG_FILE}"
echo "  Inicio: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

[ ! -d "${BACKUP_DIR}" ] && echo "[ERROR] Backup no encontrado: ${BACKUP_DIR}" | tee -a "${LOG_FILE}" && exit 1

echo "[INFO] Preparando backup ..." | tee -a "${LOG_FILE}"
xtrabackup --prepare --target-dir="${BACKUP_DIR}" 2>&1 | tee -a "${LOG_FILE}"

echo "[INFO] Deteniendo MySQL ..." | tee -a "${LOG_FILE}"
systemctl stop "${MYSQL_SERVICE}"
sleep 2

echo "[INFO] Limpiando datadir ..." | tee -a "${LOG_FILE}"
rm -rf "${MYSQL_DATADIR}"/*

RESTORE_START=$(date +%s%N)

echo "[INFO] Copiando backup ..." | tee -a "${LOG_FILE}"
xtrabackup --copy-back --target-dir="${BACKUP_DIR}" --datadir="${MYSQL_DATADIR}" 2>&1 | tee -a "${LOG_FILE}"

RESTORE_END=$(date +%s%N)
RESTORE_MS=$(( (RESTORE_END - RESTORE_START) / 1000000 ))
RESTORE_SEC=$(echo "scale=3; ${RESTORE_MS}/1000" | bc)

echo "[INFO] Restaurando permisos ..." | tee -a "${LOG_FILE}"
chown -R "${MYSQL_OS_USER}:${MYSQL_OS_GROUP}" "${MYSQL_DATADIR}"

echo "[INFO] Iniciando MySQL ..." | tee -a "${LOG_FILE}"
systemctl start "${MYSQL_SERVICE}"
sleep 3

echo "  Fin     : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Duracion: ${RESTORE_SEC} seg (${RESTORE_MS} ms)" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

TIMES_FILE="${LOG_DIR}/tiempos_restauracion.csv"
[ ! -f "${TIMES_FILE}" ] && echo "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg" > "${TIMES_FILE}"
echo "2,FULL,RESTORE,$(date -d "@$((RESTORE_START/1000000000))" '+%Y-%m-%d %H:%M:%S'),$(date '+%Y-%m-%d %H:%M:%S'),${RESTORE_MS},${RESTORE_SEC}" >> "${TIMES_FILE}"

echo "[OK] Restauracion Full Dia 2 completada."
