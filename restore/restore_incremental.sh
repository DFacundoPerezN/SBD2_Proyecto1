#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Restauración desde Backups Incrementales (Días 1, 2 y 3)
# Herramienta: Percona XtraBackup
# Descripción: Aplica en orden los 3 incrementales sobre el full base (day1).
#              Esto reconstruye el estado completo al final del Día 3 usando
#              solo los backups incrementales (más eficiente en espacio).
#
# Secuencia de restauración incremental:
#   1. Preparar full base con --apply-log-only
#   2. Aplicar incremental day1 con --apply-log-only
#   3. Aplicar incremental day2 con --apply-log-only
#   4. Aplicar incremental day3 (último, SIN --apply-log-only)
#   5. Stop MySQL → limpiar datadir → copy-back → fix perms → start MySQL
#
# ADVERTENCIA: Detiene MySQL y borra el datadir actual.
# Uso: sudo bash restore_incremental.sh [1|2|3]
#      Argumento opcional: hasta qué día restaurar (default: 3)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../backup/config.sh"

TARGET_DAY="${1:-3}"   # Restaurar hasta este día (1, 2 o 3)
LOG_FILE="${LOG_DIR}/restore_incremental_day${TARGET_DAY}.log"

FULL_BASE="${FULL_DIR}/day1"       # Siempre partimos del full del día 1
INC_DAY1="${INC_DIR}/day1"
INC_DAY2="${INC_DIR}/day2"
INC_DAY3="${INC_DIR}/day3"

# Directorio de trabajo: copia del full para no modificar el original
WORK_DIR="${BACKUP_BASE_DIR}/restore_work_inc_day${TARGET_DAY}"

echo "============================================================" | tee "${LOG_FILE}"
echo "  RESTAURACION INCREMENTAL - HASTA DIA ${TARGET_DAY}" | tee -a "${LOG_FILE}"
echo "  Inicio: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

# Verificar que los backups necesarios existan
if [ ! -d "${FULL_BASE}" ]; then
    echo "[ERROR] Full base no existe: ${FULL_BASE}" | tee -a "${LOG_FILE}"
    exit 1
fi

if [ "${TARGET_DAY}" -ge 1 ] && [ ! -d "${INC_DAY1}" ]; then
    echo "[ERROR] Incremental día 1 no existe: ${INC_DAY1}" | tee -a "${LOG_FILE}"
    exit 1
fi

if [ "${TARGET_DAY}" -ge 2 ] && [ ! -d "${INC_DAY2}" ]; then
    echo "[ERROR] Incremental día 2 no existe: ${INC_DAY2}" | tee -a "${LOG_FILE}"
    exit 1
fi

if [ "${TARGET_DAY}" -ge 3 ] && [ ! -d "${INC_DAY3}" ]; then
    echo "[ERROR] Incremental día 3 no existe: ${INC_DAY3}" | tee -a "${LOG_FILE}"
    exit 1
fi

# ---------------------------------------------------------------------------
# FASE 1: Copiar full base a directorio de trabajo (para no dañar original)
# ---------------------------------------------------------------------------
echo "[INFO] Fase 1: Copiando full base a directorio de trabajo ..." | tee -a "${LOG_FILE}"
[ -d "${WORK_DIR}" ] && rm -rf "${WORK_DIR}"
cp -a "${FULL_BASE}" "${WORK_DIR}"

PREPARE_START=$(date +%s%N)

# ---------------------------------------------------------------------------
# FASE 2: Preparar el full base con --apply-log-only
# ---------------------------------------------------------------------------
echo "[INFO] Fase 2: Preparando full base (--apply-log-only) ..." | tee -a "${LOG_FILE}"
xtrabackup --prepare --apply-log-only \
    --target-dir="${WORK_DIR}" \
    2>&1 | tee -a "${LOG_FILE}"

# ---------------------------------------------------------------------------
# FASE 3: Aplicar incrementales en orden
# ---------------------------------------------------------------------------
if [ "${TARGET_DAY}" -ge 1 ]; then
    echo "[INFO] Fase 3a: Aplicando incremental Día 1 ..." | tee -a "${LOG_FILE}"
    if [ "${TARGET_DAY}" -eq 1 ]; then
        # Último a aplicar: sin --apply-log-only
        xtrabackup --prepare \
            --target-dir="${WORK_DIR}" \
            --incremental-dir="${INC_DAY1}" \
            2>&1 | tee -a "${LOG_FILE}"
    else
        xtrabackup --prepare --apply-log-only \
            --target-dir="${WORK_DIR}" \
            --incremental-dir="${INC_DAY1}" \
            2>&1 | tee -a "${LOG_FILE}"
    fi
fi

if [ "${TARGET_DAY}" -ge 2 ]; then
    echo "[INFO] Fase 3b: Aplicando incremental Día 2 ..." | tee -a "${LOG_FILE}"
    if [ "${TARGET_DAY}" -eq 2 ]; then
        xtrabackup --prepare \
            --target-dir="${WORK_DIR}" \
            --incremental-dir="${INC_DAY2}" \
            2>&1 | tee -a "${LOG_FILE}"
    else
        xtrabackup --prepare --apply-log-only \
            --target-dir="${WORK_DIR}" \
            --incremental-dir="${INC_DAY2}" \
            2>&1 | tee -a "${LOG_FILE}"
    fi
fi

if [ "${TARGET_DAY}" -ge 3 ]; then
    echo "[INFO] Fase 3c: Aplicando incremental Día 3 (último, sin --apply-log-only) ..." | tee -a "${LOG_FILE}"
    xtrabackup --prepare \
        --target-dir="${WORK_DIR}" \
        --incremental-dir="${INC_DAY3}" \
        2>&1 | tee -a "${LOG_FILE}"
fi

PREPARE_END=$(date +%s%N)
PREPARE_MS=$(( (PREPARE_END - PREPARE_START) / 1000000 ))
echo "[INFO] Preparacion total: $(echo "scale=3; ${PREPARE_MS}/1000" | bc) seg" | tee -a "${LOG_FILE}"

# ---------------------------------------------------------------------------
# FASE 4: Detener MySQL, limpiar datadir, copiar backup
# ---------------------------------------------------------------------------
echo "[INFO] Fase 4: Deteniendo MySQL ..." | tee -a "${LOG_FILE}"
systemctl stop "${MYSQL_SERVICE}"
sleep 2

echo "[INFO] Limpiando datadir: ${MYSQL_DATADIR} ..." | tee -a "${LOG_FILE}"
rm -rf "${MYSQL_DATADIR}"/*

RESTORE_START=$(date +%s%N)

echo "[INFO] Copiando backup restaurado a datadir ..." | tee -a "${LOG_FILE}"
xtrabackup --copy-back \
    --target-dir="${WORK_DIR}" \
    --datadir="${MYSQL_DATADIR}" \
    2>&1 | tee -a "${LOG_FILE}"

RESTORE_END=$(date +%s%N)
RESTORE_MS=$(( (RESTORE_END - RESTORE_START) / 1000000 ))
RESTORE_SEC=$(echo "scale=3; ${RESTORE_MS}/1000" | bc)

# ---------------------------------------------------------------------------
# FASE 5: Corregir permisos e iniciar MySQL
# ---------------------------------------------------------------------------
echo "[INFO] Fase 5: Restaurando permisos ..." | tee -a "${LOG_FILE}"
chown -R "${MYSQL_OS_USER}:${MYSQL_OS_GROUP}" "${MYSQL_DATADIR}"

echo "[INFO] Iniciando MySQL ..." | tee -a "${LOG_FILE}"
systemctl start "${MYSQL_SERVICE}"
sleep 3

echo "" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"
echo "  RESTAURACION INCREMENTAL COMPLETADA" | tee -a "${LOG_FILE}"
echo "  Hasta día     : ${TARGET_DAY}" | tee -a "${LOG_FILE}"
echo "  Fin           : $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "  Tiempo prepare: $(echo "scale=3; ${PREPARE_MS}/1000" | bc) seg" | tee -a "${LOG_FILE}"
echo "  Tiempo copy   : ${RESTORE_SEC} seg (${RESTORE_MS} ms)" | tee -a "${LOG_FILE}"
echo "============================================================" | tee -a "${LOG_FILE}"

TIMES_FILE="${LOG_DIR}/tiempos_restauracion.csv"
[ ! -f "${TIMES_FILE}" ] && echo "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg" > "${TIMES_FILE}"
echo "${TARGET_DAY},INCREMENTAL,RESTORE,$(date -d "@$((RESTORE_START/1000000000))" '+%Y-%m-%d %H:%M:%S'),$(date '+%Y-%m-%d %H:%M:%S'),${RESTORE_MS},${RESTORE_SEC}" >> "${TIMES_FILE}"

echo "[OK] Restauracion incremental hasta Día ${TARGET_DAY} completada."
