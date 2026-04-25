# Grupo Base de Datos 2
# Proyecto 1 SBD2

| Nombre | Carnet | Usuario |
|--------------|--------------|--------------|
| Daniel Izas       | 201801105       | DanielIzas       |
| Diego Facundo Pérez Nicolau | 202106538  | DFacundoPerezN   |
| Aaron Emanuel Trujillo Ibarra|201801608       | atrujillo69       |

## Objetivo

Este repositorio contiene la base del Proyecto 2 de Sistemas de Bases de Datos 2,
adaptada para ejecutarse en Windows con `MySQL Community Server 9.2`.

La estrategia de trabajo definida para este entorno es:

- Carga de datos y auditoria en MySQL.
- Full backup fisico por copia del `datadir` con el servicio detenido.
- Incremental backup usando binlogs de MySQL.
- Restauracion fisica del `datadir`.
- Validacion posterior con consultas SQL y evidencia en capturas.

## Estado del entorno Windows

Detectado en esta maquina:

- Servicio MySQL: `MySQL92`
- Cliente MySQL: `C:\Program Files\MySQL\MySQL Server 9.2\bin\mysql.exe`
- Utilidad incremental: `C:\Program Files\MySQL\MySQL Server 9.2\bin\mysqlbinlog.exe`
- Archivo de configuracion: `C:\ProgramData\MySQL\MySQL Server 9.2\my.ini`
- `log-bin` habilitado en `my.ini`

Pendiente de configurar por el usuario antes de la ejecucion real:

- Usuario y password de MySQL con permisos suficientes.
- Confirmar nombre del esquema origen.
- Confirmar que PowerShell se ejecuta como Administrador para stop/start del servicio.

## Archivos principales

SQL:

- `sql/01_schema_mysql.sql`
- `sql/02_load_data_mysql.sql`
- `sql/03_procedures_mysql.sql`
- `sql/05_log_tables.sql`
- `sql/06_simulate_day1.sql`
- `sql/07_simulate_day2.sql`
- `sql/08_update_day3.sql`
- `sql/09_validation_p2.sql`

Backups y restore para Windows:

- `backup/config.ps1`
- `backup/common.ps1`
- `backup/full_backup_day1.ps1`
- `backup/full_backup_day2.ps1`
- `backup/full_backup_day3.ps1`
- `backup/incremental_backup_day1.ps1`
- `backup/incremental_backup_day2.ps1`
- `backup/incremental_backup_day3.ps1`
- `restore/restore_full_day1.ps1`
- `restore/restore_full_day2.ps1`
- `restore/restore_full_day3.ps1`
- `restore/restore_incremental.ps1`

Documentacion:

- `docs/manual_proyecto2_windows.md`
- `docs/proyecto2_tecnico.md`
- `docs/evidencia_proyecto2.md`

## Orden de ejecucion

### 1. Configurar entorno

Editar `backup/config.ps1` y completar al menos:

- `MySqlUser`
- `MySqlPassword`
- `SourceSchema`
- `RestoreSchema`

### 2. Crear y cargar la base de datos

Ejecutar en MySQL, en este orden:

1. `sql/01_schema_mysql.sql`
2. `sql/02_load_data_mysql.sql`
3. `sql/03_procedures_mysql.sql`
4. `sql/05_log_tables.sql`

### 3. Ejecutar por dias

Dia 1:

1. `sql/06_simulate_day1.sql`
2. `sql/09_validation_p2.sql`
3. `backup/full_backup_day1.ps1`
4. `backup/incremental_backup_day1.ps1`

Dia 2:

1. `sql/07_simulate_day2.sql`
2. `sql/09_validation_p2.sql`
3. `backup/full_backup_day2.ps1`
4. `backup/incremental_backup_day2.ps1`

Dia 3:

1. `sql/08_update_day3.sql`
2. `sql/09_validation_p2.sql`
3. `backup/full_backup_day3.ps1`
4. `backup/incremental_backup_day3.ps1`

### 4. Restauraciones

Full:

- `restore/restore_full_day1.ps1`
- `restore/restore_full_day2.ps1`
- `restore/restore_full_day3.ps1`

Incrementales:

- `restore/restore_incremental.ps1 -TargetDay 1`
- `restore/restore_incremental.ps1 -TargetDay 2`
- `restore/restore_incremental.ps1 -TargetDay 3`

## Ubicacion de salidas

Los scripts PowerShell guardan resultados en:

- `runtime/backups/full`
- `runtime/backups/incremental`
- `runtime/backups/logs`
- `runtime/evidence`

## Nota sobre la estrategia incremental

En Windows con MySQL Community, este proyecto usa una estrategia incremental basada en
binlogs en lugar de `xtrabackup`. Esto permite medir tiempos reales y mantener todo el
flujo desde consola.
