-- =============================================================================
-- Proyecto 2 - SBD2: Carga de Datos — DÍA 3
-- Operación: Cambiar nombres de todos los países a MAYÚSCULAS
-- Motor: MySQL 8.0+
-- Prerequisito: haber ejecutado 06 y 07.
-- Nota: Esta operación activa el trigger trg_pais_after_update para cada fila,
--       registrando en log_pais los valores anteriores (minúsculas) y
--       los nuevos (mayúsculas).
-- =============================================================================

USE proyecto1_mundiales;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. Mostrar estado ANTES de la actualización
-- ---------------------------------------------------------------------------
SELECT 'ANTES - Primeros 10 paises:' AS estado;
SELECT id_pais, nombre FROM pais ORDER BY id_pais LIMIT 10;

SELECT 'ANTES - Total paises:' AS info, COUNT(*) AS total FROM pais;

-- ---------------------------------------------------------------------------
-- 2. Actualizar nombres a MAYÚSCULAS
--    El trigger trg_pais_after_update registra el cambio en log_pais.
-- ---------------------------------------------------------------------------
UPDATE pais
SET nombre = UPPER(nombre)
WHERE nombre != UPPER(nombre);   -- Solo actualiza los que no estén ya en mayúsculas

-- ---------------------------------------------------------------------------
-- 3. Mostrar estado DESPUÉS de la actualización
-- ---------------------------------------------------------------------------
SELECT 'DESPUES - Primeros 10 paises (mayusculas):' AS estado;
SELECT id_pais, nombre FROM pais ORDER BY id_pais LIMIT 10;

-- Verificar que NO queden nombres en minúsculas
SELECT 'Nombres que aun tienen minusculas (debe ser 0):' AS verificacion,
       COUNT(*) AS total
FROM pais
WHERE nombre != UPPER(nombre);

-- ---------------------------------------------------------------------------
-- 4. Actualizar también las tablas de staging para consistencia
-- ---------------------------------------------------------------------------
UPDATE stg_paises      SET seleccion  = UPPER(seleccion)  WHERE seleccion  != UPPER(seleccion);
UPDATE stg_mundiales   SET campeon    = UPPER(campeon)    WHERE campeon    != UPPER(campeon);
UPDATE stg_mundiales   SET subcampeon = UPPER(subcampeon) WHERE subcampeon != UPPER(subcampeon);
UPDATE stg_mundiales   SET tercero    = UPPER(tercero)    WHERE tercero    != UPPER(tercero);
UPDATE stg_mundiales   SET cuarto     = UPPER(cuarto)     WHERE cuarto     != UPPER(cuarto);

-- ---------------------------------------------------------------------------
-- 5. Registrar fragmentación en todos los LOG al final del Día 3
-- ---------------------------------------------------------------------------
CALL sp_registrar_fragmentacion();

-- ---------------------------------------------------------------------------
-- 6. Revisión de log_pais para validar que se registraron los cambios
-- ---------------------------------------------------------------------------
SELECT 'Cambios registrados en log_pais (tipo UPDATE):' AS info,
       COUNT(*) AS total_updates
FROM log_pais
WHERE operacion = 'UPDATE';

SELECT 'Snapshots de fragmentacion en log_pais:' AS info,
       COUNT(*) AS total_frag
FROM log_pais
WHERE operacion = 'FRAGMENTACION';

-- Muestra últimas 5 entradas del log_pais
SELECT id_log, operacion, fecha_log, usuario, fragmentacion_pct,
       JSON_UNQUOTE(JSON_EXTRACT(datos_anteriores, '$.nombre')) AS nombre_anterior,
       JSON_UNQUOTE(JSON_EXTRACT(datos_nuevos,     '$.nombre')) AS nombre_nuevo
FROM log_pais
ORDER BY id_log DESC
LIMIT 5;

-- ---------------------------------------------------------------------------
-- 7. Resumen final del Día 3
-- ---------------------------------------------------------------------------
SELECT 'RESUMEN DIA 3' AS seccion, '' AS detalle
UNION ALL
SELECT 'Total paises actualizados a MAYUSCULAS', CAST(COUNT(*) AS CHAR)
FROM pais
WHERE nombre = UPPER(nombre)
UNION ALL
SELECT 'Total registros en log_pais', CAST(COUNT(*) AS CHAR)
FROM log_pais;
