DROP DATABASE IF EXISTS proyecto1_mundiales;
CREATE DATABASE proyecto1_mundiales CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE proyecto1_mundiales;

SET NAMES utf8mb4;

DROP FUNCTION IF EXISTS slugify_text;
DELIMITER $$
CREATE FUNCTION slugify_text(input_text VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE txt VARCHAR(255);
    SET txt = LOWER(TRIM(COALESCE(input_text, '')));
    SET txt = REPLACE(txt, 'á', 'a');
    SET txt = REPLACE(txt, 'é', 'e');
    SET txt = REPLACE(txt, 'í', 'i');
    SET txt = REPLACE(txt, 'ó', 'o');
    SET txt = REPLACE(txt, 'ú', 'u');
    SET txt = REPLACE(txt, 'ü', 'u');
    SET txt = REPLACE(txt, 'ñ', 'n');
    SET txt = REPLACE(txt, '''', '');
    SET txt = REPLACE(txt, '.', '');
    SET txt = REPLACE(txt, ',', '');
    SET txt = REPLACE(txt, '-', '_');
    SET txt = REPLACE(txt, '/', '_');
    SET txt = REPLACE(txt, ' ', '_');
    WHILE INSTR(txt, '__') > 0 DO
        SET txt = REPLACE(txt, '__', '_');
    END WHILE;
    RETURN txt;
END $$
DELIMITER ;

CREATE TABLE pais (
    id_pais INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(120) NOT NULL,
    PRIMARY KEY (id_pais),
    UNIQUE KEY uk_pais_nombre (nombre)
);

CREATE TABLE mundial (
    anio INT NOT NULL,
    sede_texto VARCHAR(150) NOT NULL,
    campeon_id INT NULL,
    subcampeon_id INT NULL,
    tercero_id INT NULL,
    cuarto_id INT NULL,
    num_selecciones INT NULL,
    num_partidos INT NULL,
    num_goles INT NULL,
    promedio_gol DECIMAL(6,2) NULL,
    PRIMARY KEY (anio),
    KEY idx_mundial_campeon (campeon_id),
    KEY idx_mundial_subcampeon (subcampeon_id),
    CONSTRAINT fk_mundial_campeon FOREIGN KEY (campeon_id) REFERENCES pais (id_pais),
    CONSTRAINT fk_mundial_subcampeon FOREIGN KEY (subcampeon_id) REFERENCES pais (id_pais),
    CONSTRAINT fk_mundial_tercero FOREIGN KEY (tercero_id) REFERENCES pais (id_pais),
    CONSTRAINT fk_mundial_cuarto FOREIGN KEY (cuarto_id) REFERENCES pais (id_pais)
);

CREATE TABLE mundial_sede (
    anio_mundial INT NOT NULL,
    id_pais INT NOT NULL,
    PRIMARY KEY (anio_mundial, id_pais),
    CONSTRAINT fk_mundial_sede_mundial FOREIGN KEY (anio_mundial) REFERENCES mundial (anio),
    CONSTRAINT fk_mundial_sede_pais FOREIGN KEY (id_pais) REFERENCES pais (id_pais)
);

CREATE TABLE grupo (
    id_grupo BIGINT NOT NULL AUTO_INCREMENT,
    anio_mundial INT NOT NULL,
    nombre_grupo VARCHAR(50) NOT NULL,
    num_selecciones INT NULL,
    num_clasificados INT NULL,
    PRIMARY KEY (id_grupo),
    UNIQUE KEY uk_grupo_anio_nombre (anio_mundial, nombre_grupo),
    KEY idx_grupo_anio (anio_mundial),
    CONSTRAINT fk_grupo_mundial FOREIGN KEY (anio_mundial) REFERENCES mundial (anio)
);

CREATE TABLE grupo_posicion (
    id_grupo_posicion BIGINT NOT NULL AUTO_INCREMENT,
    id_grupo BIGINT NOT NULL,
    id_pais INT NOT NULL,
    posicion INT NULL,
    pts INT NULL,
    pj INT NULL,
    pg INT NULL,
    pe INT NULL,
    pp INT NULL,
    gf INT NULL,
    gc INT NULL,
    dif INT NULL,
    clasificado BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_grupo_posicion),
    UNIQUE KEY uk_grupo_pais (id_grupo, id_pais),
    KEY idx_grupo_posicion_pais (id_pais),
    CONSTRAINT fk_grupo_posicion_grupo FOREIGN KEY (id_grupo) REFERENCES grupo (id_grupo),
    CONSTRAINT fk_grupo_posicion_pais FOREIGN KEY (id_pais) REFERENCES pais (id_pais)
);

CREATE TABLE partido (
    id_partido BIGINT NOT NULL AUTO_INCREMENT,
    anio_mundial INT NOT NULL,
    numero_partido INT NOT NULL,
    fecha DATE NULL,
    etapa VARCHAR(120) NULL,
    local_id INT NOT NULL,
    visitante_id INT NOT NULL,
    goles_local INT NULL,
    goles_visitante INT NULL,
    goles_local_et INT NULL,
    goles_visit_et INT NULL,
    penales_local INT NULL,
    penales_visit INT NULL,
    slug_partido VARCHAR(160) NULL,
    PRIMARY KEY (id_partido),
    UNIQUE KEY uk_partido_anio_numero (anio_mundial, numero_partido),
    UNIQUE KEY uk_partido_slug (slug_partido),
    KEY idx_partido_fecha (fecha),
    KEY idx_partido_local (local_id),
    KEY idx_partido_visitante (visitante_id),
    CONSTRAINT fk_partido_mundial FOREIGN KEY (anio_mundial) REFERENCES mundial (anio),
    CONSTRAINT fk_partido_local FOREIGN KEY (local_id) REFERENCES pais (id_pais),
    CONSTRAINT fk_partido_visitante FOREIGN KEY (visitante_id) REFERENCES pais (id_pais)
);

CREATE TABLE gol_partido (
    id_gol BIGINT NOT NULL AUTO_INCREMENT,
    id_partido BIGINT NOT NULL,
    anio_mundial INT NOT NULL,
    id_pais_gol INT NULL,
    jugador VARCHAR(160) NOT NULL,
    minuto VARCHAR(15) NOT NULL,
    minuto_num INT NULL,
    tipo_gol VARCHAR(20) NOT NULL,
    tiempo_extra BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_gol),
    KEY idx_gol_partido (id_partido),
    KEY idx_gol_anio (anio_mundial),
    KEY idx_gol_pais (id_pais_gol),
    KEY idx_gol_jugador (jugador),
    CONSTRAINT fk_gol_partido_partido FOREIGN KEY (id_partido) REFERENCES partido (id_partido),
    CONSTRAINT fk_gol_partido_mundial FOREIGN KEY (anio_mundial) REFERENCES mundial (anio),
    CONSTRAINT fk_gol_partido_pais FOREIGN KEY (id_pais_gol) REFERENCES pais (id_pais)
);

CREATE TABLE goleador_mundial (
    id_goleador BIGINT NOT NULL AUTO_INCREMENT,
    anio_mundial INT NOT NULL,
    posicion INT NULL,
    id_pais INT NULL,
    jugador VARCHAR(160) NOT NULL,
    goles INT NULL,
    partidos INT NULL,
    promedio_gol DECIMAL(6,2) NULL,
    PRIMARY KEY (id_goleador),
    KEY idx_goleador_anio (anio_mundial),
    KEY idx_goleador_pais (id_pais),
    CONSTRAINT fk_goleador_mundial FOREIGN KEY (anio_mundial) REFERENCES mundial (anio),
    CONSTRAINT fk_goleador_pais FOREIGN KEY (id_pais) REFERENCES pais (id_pais)
);

CREATE TABLE posicion_final (
    id_posicion_final BIGINT NOT NULL AUTO_INCREMENT,
    anio_mundial INT NOT NULL,
    posicion INT NULL,
    id_pais INT NOT NULL,
    etapa_alcanzada VARCHAR(80) NULL,
    puntos INT NULL,
    pj INT NULL,
    pg INT NULL,
    pe INT NULL,
    pp INT NULL,
    gf INT NULL,
    gc INT NULL,
    dif INT NULL,
    PRIMARY KEY (id_posicion_final),
    UNIQUE KEY uk_posicion_final (anio_mundial, id_pais),
    KEY idx_posicion_final_anio (anio_mundial),
    KEY idx_posicion_final_posicion (posicion),
    CONSTRAINT fk_posicion_final_mundial FOREIGN KEY (anio_mundial) REFERENCES mundial (anio),
    CONSTRAINT fk_posicion_final_pais FOREIGN KEY (id_pais) REFERENCES pais (id_pais)
);

CREATE TABLE jugador (
    id_jugador BIGINT NOT NULL AUTO_INCREMENT,
    id_pais INT NULL,
    apellido VARCHAR(120) NULL,
    nombre VARCHAR(120) NULL,
    nombre_completo VARCHAR(200) NOT NULL,
    fecha_nacimiento_texto VARCHAR(120) NULL,
    posicion VARCHAR(80) NULL,
    url_ficha VARCHAR(255) NULL,
    PRIMARY KEY (id_jugador),
    UNIQUE KEY uk_jugador_url (url_ficha),
    KEY idx_jugador_pais (id_pais),
    KEY idx_jugador_nombre (nombre_completo),
    CONSTRAINT fk_jugador_pais FOREIGN KEY (id_pais) REFERENCES pais (id_pais)
);

CREATE TABLE stg_mundiales (
    anio VARCHAR(20),
    sede VARCHAR(150),
    campeon VARCHAR(120),
    subcampeon VARCHAR(120),
    tercero VARCHAR(120),
    cuarto VARCHAR(120),
    num_selecciones VARCHAR(20),
    num_partidos VARCHAR(20),
    num_goles VARCHAR(20),
    promedio_gol VARCHAR(20)
);

CREATE TABLE stg_partidos (
    anio_mundial VARCHAR(20),
    numero_partido VARCHAR(20),
    fecha VARCHAR(20),
    etapa VARCHAR(120),
    equipo_local VARCHAR(120),
    equipo_visitante VARCHAR(120),
    goles_local VARCHAR(20),
    goles_visitante VARCHAR(20),
    goles_local_et VARCHAR(20),
    goles_visit_et VARCHAR(20),
    penales_local VARCHAR(20),
    penales_visit VARCHAR(20)
);

CREATE TABLE stg_mejores_goleadores (
    anio_mundial VARCHAR(20),
    posicion VARCHAR(20),
    jugador VARCHAR(160),
    seleccion VARCHAR(120),
    goles VARCHAR(20),
    partidos VARCHAR(20),
    promedio_gol VARCHAR(20)
);

CREATE TABLE stg_posiciones_finales (
    anio_mundial VARCHAR(20),
    posicion VARCHAR(20),
    seleccion VARCHAR(120),
    etapa_alcanzada VARCHAR(80),
    puntos VARCHAR(20),
    pj VARCHAR(20),
    pg VARCHAR(20),
    pe VARCHAR(20),
    pp VARCHAR(20),
    gf VARCHAR(20),
    gc VARCHAR(20),
    dif VARCHAR(20)
);

CREATE TABLE stg_goles (
    anio_mundial VARCHAR(20),
    equipo_local VARCHAR(120),
    equipo_visitante VARCHAR(120),
    url_partido VARCHAR(160),
    jugador VARCHAR(160),
    seleccion_gol VARCHAR(120),
    minuto VARCHAR(15),
    minuto_num VARCHAR(20),
    tipo_gol VARCHAR(20),
    tiempo_extra VARCHAR(10)
);

CREATE TABLE stg_grupos (
    anio_mundial VARCHAR(20),
    nombre_grupo VARCHAR(50),
    num_selecciones VARCHAR(20),
    num_clasificados VARCHAR(20)
);

CREATE TABLE stg_grupo_seleccion (
    anio_mundial VARCHAR(20),
    nombre_grupo VARCHAR(50),
    posicion VARCHAR(20),
    seleccion VARCHAR(120),
    pts VARCHAR(20),
    pj VARCHAR(20),
    pg VARCHAR(20),
    pe VARCHAR(20),
    pp VARCHAR(20),
    gf VARCHAR(20),
    gc VARCHAR(20),
    dif VARCHAR(20),
    clasificado VARCHAR(10)
);

CREATE TABLE stg_paises (
    seleccion VARCHAR(120)
);

CREATE TABLE stg_jugadores (
    apellido VARCHAR(120),
    nombre VARCHAR(120),
    nombre_completo VARCHAR(200),
    seleccion VARCHAR(120),
    fecha_nacimiento VARCHAR(120),
    posicion VARCHAR(80),
    url_ficha VARCHAR(255)
);
