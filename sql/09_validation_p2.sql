-- =============================================================================
-- Proyecto 2 - SBD2: Consultas de Validación
-- Ejecutar ANTES y DESPUÉS de cada backup/restauración para evidencia.
-- Las capturas de pantalla deben mostrar fecha/hora del sistema operativo.
-- =============================================================================

SET @db_name = IFNULL(@db_name, 'proyecto1_mundiales');
SET @sql_use = CONCAT('USE `', REPLACE(@db_name, '`', '``'), '`');
PREPARE stmt_use FROM @sql_use;
EXECUTE stmt_use;
DEALLOCATE PREPARE stmt_use;
SET NAMES utf8mb4;

-- Mostrar timestamp de ejecución
SELECT NOW() AS timestamp_validacion, DATABASE() AS base_de_datos;

-- ===========================================================================
-- A. SELECT COUNT(*) — todas las tablas principales y LOG
-- ===========================================================================
SELECT
    'pais'              AS tabla, COUNT(*) AS total FROM pais
UNION ALL SELECT 'mundial',             COUNT(*) FROM mundial
UNION ALL SELECT 'mundial_sede',        COUNT(*) FROM mundial_sede
UNION ALL SELECT 'grupo',               COUNT(*) FROM grupo
UNION ALL SELECT 'grupo_posicion',      COUNT(*) FROM grupo_posicion
UNION ALL SELECT 'partido',             COUNT(*) FROM partido
UNION ALL SELECT 'gol_partido',         COUNT(*) FROM gol_partido
UNION ALL SELECT 'goleador_mundial',    COUNT(*) FROM goleador_mundial
UNION ALL SELECT 'posicion_final',      COUNT(*) FROM posicion_final
UNION ALL SELECT 'jugador',             COUNT(*) FROM jugador
UNION ALL SELECT '--- TABLAS LOG ---',  0
UNION ALL SELECT 'log_pais',            COUNT(*) FROM log_pais
UNION ALL SELECT 'log_mundial',         COUNT(*) FROM log_mundial
UNION ALL SELECT 'log_mundial_sede',    COUNT(*) FROM log_mundial_sede
UNION ALL SELECT 'log_grupo',           COUNT(*) FROM log_grupo
UNION ALL SELECT 'log_grupo_posicion',  COUNT(*) FROM log_grupo_posicion
UNION ALL SELECT 'log_partido',         COUNT(*) FROM log_partido
UNION ALL SELECT 'log_gol_partido',     COUNT(*) FROM log_gol_partido
UNION ALL SELECT 'log_goleador_mundial',COUNT(*) FROM log_goleador_mundial
UNION ALL SELECT 'log_posicion_final',  COUNT(*) FROM log_posicion_final
UNION ALL SELECT 'log_jugador',         COUNT(*) FROM log_jugador;

-- ===========================================================================
-- B. SELECT * — muestra de cada tabla (LIMIT 10 para evitar resultados enormes)
-- ===========================================================================

SELECT '=== pais ===' AS tabla_muestra; SELECT * FROM pais LIMIT 10;
SELECT '=== mundial ===' AS tabla_muestra; SELECT * FROM mundial LIMIT 10;
SELECT '=== mundial_sede ===' AS tabla_muestra; SELECT * FROM mundial_sede LIMIT 10;
SELECT '=== grupo ===' AS tabla_muestra; SELECT * FROM grupo LIMIT 10;
SELECT '=== grupo_posicion ===' AS tabla_muestra; SELECT * FROM grupo_posicion LIMIT 10;
SELECT '=== partido (2026) ===' AS tabla_muestra;
    SELECT * FROM partido WHERE anio_mundial = 2026 LIMIT 20;
SELECT '=== gol_partido (2026) ===' AS tabla_muestra;
    SELECT * FROM gol_partido WHERE anio_mundial = 2026 LIMIT 20;
SELECT '=== goleador_mundial ===' AS tabla_muestra; SELECT * FROM goleador_mundial LIMIT 10;
SELECT '=== posicion_final ===' AS tabla_muestra; SELECT * FROM posicion_final LIMIT 10;
SELECT '=== jugador ===' AS tabla_muestra; SELECT * FROM jugador LIMIT 10;

-- ===========================================================================
-- C. Nivel de fragmentación actual de todas las tablas
-- ===========================================================================
SELECT
    TABLE_NAME                                                                       AS tabla,
    ENGINE                                                                           AS motor,
    TABLE_ROWS                                                                       AS filas_estimadas,
    ROUND(DATA_LENGTH / 1024 / 1024, 2)                                              AS datos_MB,
    ROUND(INDEX_LENGTH / 1024 / 1024, 2)                                             AS indices_MB,
    ROUND(DATA_FREE / 1024 / 1024, 2)                                                AS libre_MB,
    ROUND(IFNULL(DATA_FREE, 0) /
          NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)               AS fragmentacion_pct
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME NOT LIKE 'stg_%'
ORDER BY fragmentacion_pct DESC, TABLE_NAME;

-- ===========================================================================
-- D. Historial de fragmentación por tabla (desde los LOG)
-- ===========================================================================
SELECT 'log_pais' AS log_tabla, fecha_log, fragmentacion_pct
FROM log_pais WHERE operacion = 'FRAGMENTACION'
UNION ALL
SELECT 'log_mundial', fecha_log, fragmentacion_pct
FROM log_mundial WHERE operacion = 'FRAGMENTACION'
UNION ALL
SELECT 'log_partido', fecha_log, fragmentacion_pct
FROM log_partido WHERE operacion = 'FRAGMENTACION'
UNION ALL
SELECT 'log_gol_partido', fecha_log, fragmentacion_pct
FROM log_gol_partido WHERE operacion = 'FRAGMENTACION'
ORDER BY log_tabla, fecha_log;
