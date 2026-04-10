-- =============================================================================
-- Proyecto 2 - SBD2: Tablas LOG y Triggers de Auditoría
-- Base de datos: proyecto1_mundiales
-- Motor: MySQL 8.0+
-- Descripción: Crea una tabla LOG por cada tabla principal del esquema.
--   Cada LOG registra operación (INSERT/UPDATE/DELETE/FRAGMENTACION),
--   usuario, timestamp, datos anteriores/nuevos (JSON) y nivel de
--   fragmentación de la tabla al momento de la operación masiva.
-- =============================================================================

USE proyecto1_mundiales;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. TABLAS LOG
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS log_pais;
CREATE TABLE log_pais (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL     COMMENT 'Porcentaje de fragmentacion de la tabla pais',
    datos_anteriores  JSON         NULL     COMMENT 'Valores previos al cambio (UPDATE/DELETE)',
    datos_nuevos      JSON         NULL     COMMENT 'Valores nuevos tras el cambio (INSERT/UPDATE)',
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla pais';

DROP TABLE IF EXISTS log_mundial;
CREATE TABLE log_mundial (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla mundial';

DROP TABLE IF EXISTS log_mundial_sede;
CREATE TABLE log_mundial_sede (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla mundial_sede';

DROP TABLE IF EXISTS log_grupo;
CREATE TABLE log_grupo (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla grupo';

DROP TABLE IF EXISTS log_grupo_posicion;
CREATE TABLE log_grupo_posicion (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla grupo_posicion';

DROP TABLE IF EXISTS log_partido;
CREATE TABLE log_partido (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla partido';

DROP TABLE IF EXISTS log_gol_partido;
CREATE TABLE log_gol_partido (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla gol_partido';

DROP TABLE IF EXISTS log_goleador_mundial;
CREATE TABLE log_goleador_mundial (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla goleador_mundial';

DROP TABLE IF EXISTS log_posicion_final;
CREATE TABLE log_posicion_final (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla posicion_final';

DROP TABLE IF EXISTS log_jugador;
CREATE TABLE log_jugador (
    id_log            BIGINT       NOT NULL AUTO_INCREMENT,
    operacion         ENUM('INSERT','UPDATE','DELETE','FRAGMENTACION') NOT NULL,
    fecha_log         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario           VARCHAR(100) NOT NULL DEFAULT (CURRENT_USER()),
    fragmentacion_pct DECIMAL(8,2) NULL,
    datos_anteriores  JSON         NULL,
    datos_nuevos      JSON         NULL,
    PRIMARY KEY (id_log)
) COMMENT='Registro de auditoria de la tabla jugador';


-- ---------------------------------------------------------------------------
-- 2. TRIGGERS — tabla pais
-- ---------------------------------------------------------------------------
DELIMITER $$

DROP TRIGGER IF EXISTS trg_pais_after_insert $$
CREATE TRIGGER trg_pais_after_insert
AFTER INSERT ON pais
FOR EACH ROW
BEGIN
    INSERT INTO log_pais (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT('id_pais', NEW.id_pais, 'nombre', NEW.nombre));
END $$

DROP TRIGGER IF EXISTS trg_pais_after_update $$
CREATE TRIGGER trg_pais_after_update
AFTER UPDATE ON pais
FOR EACH ROW
BEGIN
    INSERT INTO log_pais (operacion, datos_anteriores, datos_nuevos)
    VALUES ('UPDATE',
            JSON_OBJECT('id_pais', OLD.id_pais, 'nombre', OLD.nombre),
            JSON_OBJECT('id_pais', NEW.id_pais, 'nombre', NEW.nombre));
END $$

DROP TRIGGER IF EXISTS trg_pais_after_delete $$
CREATE TRIGGER trg_pais_after_delete
AFTER DELETE ON pais
FOR EACH ROW
BEGIN
    INSERT INTO log_pais (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT('id_pais', OLD.id_pais, 'nombre', OLD.nombre));
END $$


-- ---------------------------------------------------------------------------
-- 3. TRIGGERS — tabla mundial
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_mundial_after_insert $$
CREATE TRIGGER trg_mundial_after_insert
AFTER INSERT ON mundial
FOR EACH ROW
BEGIN
    INSERT INTO log_mundial (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'anio', NEW.anio,
                'sede_texto', NEW.sede_texto,
                'num_selecciones', NEW.num_selecciones,
                'num_partidos', NEW.num_partidos,
                'num_goles', NEW.num_goles
            ));
END $$

DROP TRIGGER IF EXISTS trg_mundial_after_update $$
CREATE TRIGGER trg_mundial_after_update
AFTER UPDATE ON mundial
FOR EACH ROW
BEGIN
    INSERT INTO log_mundial (operacion, datos_anteriores, datos_nuevos)
    VALUES ('UPDATE',
            JSON_OBJECT('anio', OLD.anio, 'sede_texto', OLD.sede_texto),
            JSON_OBJECT('anio', NEW.anio, 'sede_texto', NEW.sede_texto,
                        'num_selecciones', NEW.num_selecciones,
                        'num_partidos', NEW.num_partidos,
                        'num_goles', NEW.num_goles));
END $$

DROP TRIGGER IF EXISTS trg_mundial_after_delete $$
CREATE TRIGGER trg_mundial_after_delete
AFTER DELETE ON mundial
FOR EACH ROW
BEGIN
    INSERT INTO log_mundial (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT('anio', OLD.anio, 'sede_texto', OLD.sede_texto));
END $$


-- ---------------------------------------------------------------------------
-- 4. TRIGGERS — tabla partido
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_partido_after_insert $$
CREATE TRIGGER trg_partido_after_insert
AFTER INSERT ON partido
FOR EACH ROW
BEGIN
    INSERT INTO log_partido (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'id_partido',      NEW.id_partido,
                'anio_mundial',    NEW.anio_mundial,
                'numero_partido',  NEW.numero_partido,
                'fecha',           NEW.fecha,
                'etapa',           NEW.etapa,
                'local_id',        NEW.local_id,
                'visitante_id',    NEW.visitante_id,
                'goles_local',     NEW.goles_local,
                'goles_visitante', NEW.goles_visitante
            ));
END $$

DROP TRIGGER IF EXISTS trg_partido_after_update $$
CREATE TRIGGER trg_partido_after_update
AFTER UPDATE ON partido
FOR EACH ROW
BEGIN
    INSERT INTO log_partido (operacion, datos_anteriores, datos_nuevos)
    VALUES ('UPDATE',
            JSON_OBJECT(
                'id_partido',      OLD.id_partido,
                'goles_local',     OLD.goles_local,
                'goles_visitante', OLD.goles_visitante
            ),
            JSON_OBJECT(
                'id_partido',      NEW.id_partido,
                'goles_local',     NEW.goles_local,
                'goles_visitante', NEW.goles_visitante
            ));
END $$

DROP TRIGGER IF EXISTS trg_partido_after_delete $$
CREATE TRIGGER trg_partido_after_delete
AFTER DELETE ON partido
FOR EACH ROW
BEGIN
    INSERT INTO log_partido (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'id_partido',   OLD.id_partido,
                'anio_mundial', OLD.anio_mundial,
                'numero_partido', OLD.numero_partido
            ));
END $$


-- ---------------------------------------------------------------------------
-- 5. TRIGGERS — tabla gol_partido
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_gol_partido_after_insert $$
CREATE TRIGGER trg_gol_partido_after_insert
AFTER INSERT ON gol_partido
FOR EACH ROW
BEGIN
    INSERT INTO log_gol_partido (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'id_gol',       NEW.id_gol,
                'id_partido',   NEW.id_partido,
                'jugador',      NEW.jugador,
                'minuto',       NEW.minuto,
                'tipo_gol',     NEW.tipo_gol,
                'tiempo_extra', NEW.tiempo_extra
            ));
END $$

DROP TRIGGER IF EXISTS trg_gol_partido_after_delete $$
CREATE TRIGGER trg_gol_partido_after_delete
AFTER DELETE ON gol_partido
FOR EACH ROW
BEGIN
    INSERT INTO log_gol_partido (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'id_gol',     OLD.id_gol,
                'id_partido', OLD.id_partido,
                'jugador',    OLD.jugador,
                'minuto',     OLD.minuto
            ));
END $$


-- ---------------------------------------------------------------------------
-- 6. TRIGGERS — tabla goleador_mundial
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_goleador_after_insert $$
CREATE TRIGGER trg_goleador_after_insert
AFTER INSERT ON goleador_mundial
FOR EACH ROW
BEGIN
    INSERT INTO log_goleador_mundial (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'id_goleador',  NEW.id_goleador,
                'anio_mundial', NEW.anio_mundial,
                'jugador',      NEW.jugador,
                'goles',        NEW.goles,
                'id_pais',      NEW.id_pais
            ));
END $$

DROP TRIGGER IF EXISTS trg_goleador_after_delete $$
CREATE TRIGGER trg_goleador_after_delete
AFTER DELETE ON goleador_mundial
FOR EACH ROW
BEGIN
    INSERT INTO log_goleador_mundial (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'id_goleador',  OLD.id_goleador,
                'anio_mundial', OLD.anio_mundial,
                'jugador',      OLD.jugador,
                'goles',        OLD.goles
            ));
END $$


-- ---------------------------------------------------------------------------
-- 7. TRIGGERS — tabla posicion_final
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_posicion_final_after_insert $$
CREATE TRIGGER trg_posicion_final_after_insert
AFTER INSERT ON posicion_final
FOR EACH ROW
BEGIN
    INSERT INTO log_posicion_final (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'id_posicion_final', NEW.id_posicion_final,
                'anio_mundial',      NEW.anio_mundial,
                'posicion',          NEW.posicion,
                'id_pais',           NEW.id_pais,
                'etapa_alcanzada',   NEW.etapa_alcanzada
            ));
END $$

DROP TRIGGER IF EXISTS trg_posicion_final_after_delete $$
CREATE TRIGGER trg_posicion_final_after_delete
AFTER DELETE ON posicion_final
FOR EACH ROW
BEGIN
    INSERT INTO log_posicion_final (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'id_posicion_final', OLD.id_posicion_final,
                'anio_mundial',      OLD.anio_mundial,
                'id_pais',           OLD.id_pais
            ));
END $$


-- ---------------------------------------------------------------------------
-- 8. TRIGGERS — tabla grupo
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_grupo_after_insert $$
CREATE TRIGGER trg_grupo_after_insert
AFTER INSERT ON grupo
FOR EACH ROW
BEGIN
    INSERT INTO log_grupo (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'id_grupo',        NEW.id_grupo,
                'anio_mundial',    NEW.anio_mundial,
                'nombre_grupo',    NEW.nombre_grupo,
                'num_selecciones', NEW.num_selecciones
            ));
END $$

DROP TRIGGER IF EXISTS trg_grupo_after_delete $$
CREATE TRIGGER trg_grupo_after_delete
AFTER DELETE ON grupo
FOR EACH ROW
BEGIN
    INSERT INTO log_grupo (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'id_grupo',     OLD.id_grupo,
                'anio_mundial', OLD.anio_mundial,
                'nombre_grupo', OLD.nombre_grupo
            ));
END $$


-- ---------------------------------------------------------------------------
-- 9. TRIGGERS — tabla grupo_posicion
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_grupo_posicion_after_insert $$
CREATE TRIGGER trg_grupo_posicion_after_insert
AFTER INSERT ON grupo_posicion
FOR EACH ROW
BEGIN
    INSERT INTO log_grupo_posicion (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'id_grupo_posicion', NEW.id_grupo_posicion,
                'id_grupo',          NEW.id_grupo,
                'id_pais',           NEW.id_pais,
                'posicion',          NEW.posicion,
                'pts',               NEW.pts,
                'clasificado',       NEW.clasificado
            ));
END $$

DROP TRIGGER IF EXISTS trg_grupo_posicion_after_delete $$
CREATE TRIGGER trg_grupo_posicion_after_delete
AFTER DELETE ON grupo_posicion
FOR EACH ROW
BEGIN
    INSERT INTO log_grupo_posicion (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'id_grupo_posicion', OLD.id_grupo_posicion,
                'id_grupo',          OLD.id_grupo,
                'id_pais',           OLD.id_pais
            ));
END $$


-- ---------------------------------------------------------------------------
-- 10. TRIGGERS — tabla mundial_sede
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_mundial_sede_after_insert $$
CREATE TRIGGER trg_mundial_sede_after_insert
AFTER INSERT ON mundial_sede
FOR EACH ROW
BEGIN
    INSERT INTO log_mundial_sede (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'anio_mundial', NEW.anio_mundial,
                'id_pais',      NEW.id_pais
            ));
END $$

DROP TRIGGER IF EXISTS trg_mundial_sede_after_delete $$
CREATE TRIGGER trg_mundial_sede_after_delete
AFTER DELETE ON mundial_sede
FOR EACH ROW
BEGIN
    INSERT INTO log_mundial_sede (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'anio_mundial', OLD.anio_mundial,
                'id_pais',      OLD.id_pais
            ));
END $$


-- ---------------------------------------------------------------------------
-- 11. TRIGGERS — tabla jugador
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_jugador_after_insert $$
CREATE TRIGGER trg_jugador_after_insert
AFTER INSERT ON jugador
FOR EACH ROW
BEGIN
    INSERT INTO log_jugador (operacion, datos_nuevos)
    VALUES ('INSERT',
            JSON_OBJECT(
                'id_jugador',      NEW.id_jugador,
                'id_pais',         NEW.id_pais,
                'nombre_completo', NEW.nombre_completo,
                'posicion',        NEW.posicion
            ));
END $$

DROP TRIGGER IF EXISTS trg_jugador_after_delete $$
CREATE TRIGGER trg_jugador_after_delete
AFTER DELETE ON jugador
FOR EACH ROW
BEGIN
    INSERT INTO log_jugador (operacion, datos_anteriores)
    VALUES ('DELETE',
            JSON_OBJECT(
                'id_jugador',      OLD.id_jugador,
                'id_pais',         OLD.id_pais,
                'nombre_completo', OLD.nombre_completo
            ));
END $$

DELIMITER ;


-- ---------------------------------------------------------------------------
-- 12. PROCEDIMIENTO: registrar nivel de fragmentación en todos los LOG
--     Llamar al FINAL de cada día de carga.
--     Usa information_schema.TABLES para calcular:
--       fragmentacion = DATA_FREE / (DATA_LENGTH + INDEX_LENGTH + DATA_FREE) * 100
-- ---------------------------------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_fragmentacion $$
CREATE PROCEDURE sp_registrar_fragmentacion()
BEGIN
    DECLARE v_frag_pais             DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_mundial          DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_mundial_sede     DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_grupo            DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_grupo_posicion   DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_partido          DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_gol_partido      DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_goleador_mundial DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_posicion_final   DECIMAL(8,2) DEFAULT 0;
    DECLARE v_frag_jugador          DECIMAL(8,2) DEFAULT 0;

    -- Obtener fragmentacion de cada tabla desde information_schema
    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_pais
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'pais';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_mundial
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mundial';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_mundial_sede
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mundial_sede';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_grupo
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grupo';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_grupo_posicion
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grupo_posicion';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_partido
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'partido';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_gol_partido
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'gol_partido';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_goleador_mundial
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'goleador_mundial';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_posicion_final
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'posicion_final';

    SELECT ROUND(IFNULL(DATA_FREE, 0) /
                 NULLIF(DATA_LENGTH + INDEX_LENGTH + DATA_FREE, 0) * 100, 2)
    INTO v_frag_jugador
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'jugador';

    -- Insertar snapshot de fragmentacion en cada LOG
    INSERT INTO log_pais             (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_pais, 0));
    INSERT INTO log_mundial          (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_mundial, 0));
    INSERT INTO log_mundial_sede     (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_mundial_sede, 0));
    INSERT INTO log_grupo            (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_grupo, 0));
    INSERT INTO log_grupo_posicion   (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_grupo_posicion, 0));
    INSERT INTO log_partido          (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_partido, 0));
    INSERT INTO log_gol_partido      (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_gol_partido, 0));
    INSERT INTO log_goleador_mundial (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_goleador_mundial, 0));
    INSERT INTO log_posicion_final   (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_posicion_final, 0));
    INSERT INTO log_jugador          (operacion, fragmentacion_pct) VALUES ('FRAGMENTACION', IFNULL(v_frag_jugador, 0));

    SELECT 'Fragmentacion registrada en todos los LOG.' AS resultado;
END $$

DELIMITER ;

-- Verificar creación de tablas LOG
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'log_%'
ORDER BY TABLE_NAME;
