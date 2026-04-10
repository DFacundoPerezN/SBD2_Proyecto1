# Documento tecnico - Proyecto 2

## 1. Identificacion

- Curso: Sistemas de Bases de Datos 2
- Proyecto: Proyecto 2 - Respaldo y Restauracion
- Motor: MySQL Community Server 9.2
- Sistema operativo: Windows

## 2. Metodologia

Describir aqui la metodologia ejecutada durante la practica real:

- Preparacion del entorno
- Carga de datos por dias
- Generacion de full backups
- Generacion de incrementales
- Restauraciones full
- Restauraciones incrementales
- Validacion de integridad

Espacio para redaccion final:

`[PENDIENTE: redactar metodologia definitiva despues de la corrida real]`

## 3. Modelo y base de datos utilizada

Base utilizada: la base del proyecto anterior con ampliacion para logs y respaldos.

Elementos principales:

- Tablas de negocio
- Tablas LOG para auditoria
- Triggers de auditoria
- Procedimiento de fragmentacion

Referencia:

- `docs/modelo_er.md`

Captura pendiente:

- `[CAPTURA TEC-01: modelo o esquema utilizado]`

## 4. Especificaciones tecnicas del servidor

Completar con valores reales al momento de la ejecucion:

- Version de MySQL:
- Puerto:
- Servicio Windows:
- Ruta del datadir:
- Ruta de backups:
- Usuario de ejecucion:
- Capacidad aproximada de disco:

Capturas pendientes:

- `[CAPTURA TEC-02: mysql --version o Workbench mostrando version]`
- `[CAPTURA TEC-03: configuracion de my.ini o variables relevantes]`

## 5. Plan de respaldo

### Full backup

- Tipo: copia fisica del `datadir`
- Momento: al final de cada dia de carga
- Frecuencia: 3 respaldos

### Incremental backup

- Tipo: respaldo de binlogs cerrados despues de `FLUSH BINARY LOGS`
- Base: full backup del dia 1
- Cadena:
  - Dia 1: marcador de inicio
  - Dia 2: binlogs cerrados del dia 2
  - Dia 3: binlogs cerrados del dia 3

## 6. Resultados de tiempos

Completar con datos reales desde:

- `runtime/backups/logs/tiempos_backup.csv`
- `runtime/backups/logs/tiempos_restauracion.csv`

| Dia | Tipo | Operacion | Duracion ms | Duracion seg | Observaciones |
|------|------|-----------|-------------|--------------|---------------|
| 1 | FULL | BACKUP | | | |
| 2 | FULL | BACKUP | | | |
| 3 | FULL | BACKUP | | | |
| 1 | INCREMENTAL | BACKUP | | | |
| 2 | INCREMENTAL | BACKUP | | | |
| 3 | INCREMENTAL | BACKUP | | | |
| 1 | FULL | RESTORE | | | |
| 2 | FULL | RESTORE | | | |
| 3 | FULL | RESTORE | | | |
| 1 | INCREMENTAL | RESTORE | | | |
| 2 | INCREMENTAL | RESTORE | | | |
| 3 | INCREMENTAL | RESTORE | | | |

## 7. Analisis comparativo

Preguntas a responder:

- Cual estrategia restaura mas rapido en este entorno
- Cual consume menos espacio
- Que complejidad operativa tiene cada una
- Que riesgos tiene cada flujo

Espacio para analisis:

`[PENDIENTE: redactar analisis comparativo con datos reales]`

## 8. Conclusiones

Espacio para conclusiones finales:

`[PENDIENTE: redactar conclusion y recomendacion final]`

## 9. Evidencia

Referenciar aqui las capturas y logs finales.

- `[PENDIENTE: insertar indice de capturas]`
- `[PENDIENTE: insertar resumen de evidencias]`
