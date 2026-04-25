#!/usr/bin/env bash
# =============================================================================
# Proyecto 2 - SBD2: Configuración global de backups
# Editar este archivo antes de ejecutar cualquier script de backup/restore.
# =============================================================================

# --- Credenciales MySQL ---
MYSQL_USER="root"
MYSQL_PASS=""           # Dejar vacío si no tiene contraseña; poner entre comillas si tiene
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="3306"
MYSQL_DB="proyecto1_mundiales"

# --- Directorio donde se guardan los backups ---
BACKUP_BASE_DIR="/var/backups/sbd2_proyecto2"

# --- Subdirectorios por tipo ---
FULL_DIR="${BACKUP_BASE_DIR}/full"
INC_DIR="${BACKUP_BASE_DIR}/incremental"
LOG_DIR="${BACKUP_BASE_DIR}/logs"

# --- Datadir de MySQL (verificar con: mysql -e "SELECT @@datadir") ---
MYSQL_DATADIR="/var/lib/mysql"

# --- Servicio MySQL (systemd) ---
MYSQL_SERVICE="mysql"      # En algunas distros puede ser "mysqld"

# --- Usuario del sistema que posee los archivos MySQL ---
MYSQL_OS_USER="mysql"
MYSQL_OS_GROUP="mysql"

# Crear directorios si no existen
mkdir -p "${FULL_DIR}" "${INC_DIR}" "${LOG_DIR}"
