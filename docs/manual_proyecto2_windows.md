# Manual de usuario - Proyecto 2 en Windows

## 1. Objetivo

Este manual explica como ejecutar el Proyecto 2 en Windows para:

- cargar los datos,
- generar full backups,
- generar backups incrementales,
- restaurar cada escenario,
- validar integridad,
- y documentar evidencia real.

La implementacion de Windows usa:

- Full backup fisico por copia del `datadir`
- Incremental backup basado en binlogs

## 2. Requisitos

Antes de iniciar, verificar:

- `MySQL Community Server 9.2` instalado
- Servicio `MySQL92` disponible
- PowerShell ejecutado como Administrador
- `mysql.exe`, `mysqladmin.exe` y `mysqlbinlog.exe` instalados
- Usuario MySQL con permisos suficientes

Configuracion detectada en esta maquina:

- Servicio: `MySQL92`
- Puerto en `my.ini`: `3308`
- `datadir`: `C:/ProgramData/MySQL/MySQL Server 9.2/Data`
- `log-bin`: habilitado

## 3. Configuracion inicial

Editar `backup/config.ps1` y completar:

```powershell
MySqlUser
MySqlPassword
SourceSchema
RestoreSchema
```

## 4. Preparacion de la base

Ejecutar los scripts SQL en este orden:

1. `sql/01_schema_mysql.sql`
2. `sql/02_load_data_mysql.sql`
3. `sql/03_procedures_mysql.sql`
4. `sql/05_log_tables.sql`

Captura pendiente:

- `[CAPTURA 01: esquema creado correctamente]`
- `[CAPTURA 02: tablas LOG creadas]`

## 5. Flujo por dias

### Dia 1

1. Ejecutar `sql/06_simulate_day1.sql`
2. Ejecutar `sql/09_validation_p2.sql`
3. Guardar capturas
4. Ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File .\backup\full_backup_day1.ps1
powershell -ExecutionPolicy Bypass -File .\backup\incremental_backup_day1.ps1
```

Capturas pendientes:

- `[CAPTURA D1-A: SELECT COUNT(*) despues de la carga del dia 1]`
- `[CAPTURA D1-B: SELECT * de tablas principales y LOG del dia 1]`
- `[CAPTURA D1-C: full backup dia 1 finalizado]`
- `[CAPTURA D1-D: incremental dia 1 finalizado]`

### Dia 2

1. Ejecutar `sql/07_simulate_day2.sql`
2. Ejecutar `sql/09_validation_p2.sql`
3. Ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File .\backup\full_backup_day2.ps1
powershell -ExecutionPolicy Bypass -File .\backup\incremental_backup_day2.ps1
```

Capturas pendientes:

- `[CAPTURA D2-A: validacion posterior a carga dia 2]`
- `[CAPTURA D2-B: full backup dia 2]`
- `[CAPTURA D2-C: incremental dia 2]`

### Dia 3

1. Ejecutar `sql/08_update_day3.sql`
2. Ejecutar `sql/09_validation_p2.sql`
3. Ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File .\backup\full_backup_day3.ps1
powershell -ExecutionPolicy Bypass -File .\backup\incremental_backup_day3.ps1
```

Capturas pendientes:

- `[CAPTURA D3-A: validacion posterior a carga dia 3]`
- `[CAPTURA D3-B: full backup dia 3]`
- `[CAPTURA D3-C: incremental dia 3]`

## 6. Restauraciones full

Ejecutar una por una:

```powershell
powershell -ExecutionPolicy Bypass -File .\restore\restore_full_day1.ps1
powershell -ExecutionPolicy Bypass -File .\restore\restore_full_day2.ps1
powershell -ExecutionPolicy Bypass -File .\restore\restore_full_day3.ps1
```

Despues de cada una:

1. Ejecutar `sql/09_validation_p2.sql` apuntando al esquema restaurado
2. Registrar tiempo de restauracion
3. Tomar capturas de `SELECT COUNT(*)` y `SELECT *`

Capturas pendientes:

- `[CAPTURA RF1-A: restore full dia 1]`
- `[CAPTURA RF1-B: validacion full dia 1]`
- `[CAPTURA RF2-A: restore full dia 2]`
- `[CAPTURA RF2-B: validacion full dia 2]`
- `[CAPTURA RF3-A: restore full dia 3]`
- `[CAPTURA RF3-B: validacion full dia 3]`

## 7. Restauraciones incrementales

Ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File .\restore\restore_incremental.ps1 -TargetDay 1
powershell -ExecutionPolicy Bypass -File .\restore\restore_incremental.ps1 -TargetDay 2
powershell -ExecutionPolicy Bypass -File .\restore\restore_incremental.ps1 -TargetDay 3
```

Despues de cada una:

1. Ejecutar `sql/09_validation_p2.sql`
2. Registrar tiempo de restauracion
3. Tomar capturas

Capturas pendientes:

- `[CAPTURA RI1-A: restore incremental dia 1]`
- `[CAPTURA RI1-B: validacion incremental dia 1]`
- `[CAPTURA RI2-A: restore incremental dia 2]`
- `[CAPTURA RI2-B: validacion incremental dia 2]`
- `[CAPTURA RI3-A: restore incremental dia 3]`
- `[CAPTURA RI3-B: validacion incremental dia 3]`

## 8. Archivos generados

Los scripts dejan evidencia automatica en:

- `runtime/backups/full`
- `runtime/backups/incremental`
- `runtime/backups/logs`
- `runtime/evidence`

Los CSV de tiempos se generan en:

- `runtime/backups/logs/tiempos_backup.csv`
- `runtime/backups/logs/tiempos_restauracion.csv`

## 9. Validacion SQL

El archivo `sql/09_validation_p2.sql` permite cambiar el esquema a validar.

Ejemplo para esquema original:

```sql
SET @db_name = 'proyecto1_mundiales';
SOURCE sql/09_validation_p2.sql;
```

Ejemplo para esquema restaurado:

```sql
SET @db_name = 'proyecto2_mundiales';
SOURCE sql/09_validation_p2.sql;
```

## 10. Observaciones

- La primera corrida real requiere conocer el password del usuario MySQL.
- Los scripts de restauracion modifican el `datadir`, por lo que deben ejecutarse con cuidado.
- Las capturas deben mostrar fecha y hora del sistema operativo.
