USE proyecto1_mundiales;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE stg_mundiales;
TRUNCATE TABLE stg_partidos;
TRUNCATE TABLE stg_mejores_goleadores;
TRUNCATE TABLE stg_posiciones_finales;
TRUNCATE TABLE stg_goles;
TRUNCATE TABLE stg_grupos;
TRUNCATE TABLE stg_grupo_seleccion;
TRUNCATE TABLE stg_paises;
TRUNCATE TABLE stg_jugadores;

TRUNCATE TABLE gol_partido;
TRUNCATE TABLE grupo_posicion;
TRUNCATE TABLE grupo;
TRUNCATE TABLE goleador_mundial;
TRUNCATE TABLE posicion_final;
TRUNCATE TABLE jugador;
TRUNCATE TABLE partido;
TRUNCATE TABLE mundial_sede;
TRUNCATE TABLE mundial;
TRUNCATE TABLE pais;

SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/mundiales.csv'
INTO TABLE stg_mundiales CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/partidos.csv'
INTO TABLE stg_partidos CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/mejores_goleadores.csv'
INTO TABLE stg_mejores_goleadores CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/posiciones_finales.csv'
INTO TABLE stg_posiciones_finales CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/goles.csv'
INTO TABLE stg_goles CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/grupos.csv'
INTO TABLE stg_grupos CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/grupo_seleccion.csv'
INTO TABLE stg_grupo_seleccion CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/paises.csv'
INTO TABLE stg_paises CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/jugadoresA_G.csv'
INTO TABLE stg_jugadores CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/jugadoresH_N.csv'
INTO TABLE stg_jugadores CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/jugadoresO_R.csv'
INTO TABLE stg_jugadores CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/jugadoresS_T.csv'
INTO TABLE stg_jugadores CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/danii/OneDrive/Escritorio/Bases2/SBD2_Proyecto1/output_csv/jugadoresU_Z.csv'
INTO TABLE stg_jugadores CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

INSERT INTO pais (nombre)
SELECT nombre
FROM (
    SELECT DISTINCT TRIM(seleccion) AS nombre FROM stg_paises WHERE NULLIF(TRIM(seleccion), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(seleccion) FROM stg_posiciones_finales WHERE NULLIF(TRIM(seleccion), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(seleccion) FROM stg_mejores_goleadores WHERE NULLIF(TRIM(seleccion), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(equipo_local) FROM stg_partidos WHERE NULLIF(TRIM(equipo_local), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(equipo_visitante) FROM stg_partidos WHERE NULLIF(TRIM(equipo_visitante), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(seleccion_gol) FROM stg_goles WHERE NULLIF(TRIM(seleccion_gol), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(seleccion) FROM stg_grupo_seleccion WHERE NULLIF(TRIM(seleccion), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(seleccion) FROM stg_jugadores WHERE NULLIF(TRIM(seleccion), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(CASE WHEN sede LIKE '%/%' THEN SUBSTRING_INDEX(sede, '/', 1) ELSE sede END) FROM stg_mundiales WHERE NULLIF(TRIM(sede), '') IS NOT NULL
    UNION
    SELECT DISTINCT TRIM(SUBSTRING_INDEX(sede, '/', -1)) FROM stg_mundiales WHERE sede LIKE '%/%'
) AS catalogo
WHERE NULLIF(TRIM(nombre), '') IS NOT NULL
ORDER BY nombre;

INSERT INTO mundial (
    anio, sede_texto, campeon_id, subcampeon_id, tercero_id, cuarto_id,
    num_selecciones, num_partidos, num_goles, promedio_gol
)
SELECT
    CAST(sm.anio AS UNSIGNED),
    TRIM(sm.sede),
    pc.id_pais,
    ps.id_pais,
    pt.id_pais,
    pq.id_pais,
    CAST(NULLIF(TRIM(sm.num_selecciones), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sm.num_partidos), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sm.num_goles), '') AS UNSIGNED),
    CAST(NULLIF(REPLACE(TRIM(sm.promedio_gol), ',', '.'), '') AS DECIMAL(6,2))
FROM stg_mundiales sm
LEFT JOIN (
    SELECT
        anio_mundial,
        MAX(CASE WHEN CAST(posicion AS UNSIGNED) = 1 THEN seleccion END) AS campeon,
        MAX(CASE WHEN CAST(posicion AS UNSIGNED) = 2 THEN seleccion END) AS subcampeon,
        MAX(CASE WHEN CAST(posicion AS UNSIGNED) = 3 THEN seleccion END) AS tercero,
        MAX(CASE WHEN CAST(posicion AS UNSIGNED) = 4 THEN seleccion END) AS cuarto
    FROM stg_posiciones_finales
    GROUP BY anio_mundial
) pf ON pf.anio_mundial = sm.anio
LEFT JOIN pais pc ON pc.nombre = COALESCE(NULLIF(TRIM(pf.campeon), ''), NULLIF(TRIM(sm.campeon), ''))
LEFT JOIN pais ps ON ps.nombre = COALESCE(NULLIF(TRIM(pf.subcampeon), ''), NULLIF(TRIM(sm.subcampeon), ''))
LEFT JOIN pais pt ON pt.nombre = COALESCE(NULLIF(TRIM(pf.tercero), ''), NULLIF(TRIM(sm.tercero), ''))
LEFT JOIN pais pq ON pq.nombre = COALESCE(NULLIF(TRIM(pf.cuarto), ''), NULLIF(TRIM(sm.cuarto), ''))
WHERE NULLIF(TRIM(sm.anio), '') IS NOT NULL;

INSERT INTO mundial_sede (anio_mundial, id_pais)
SELECT DISTINCT
    m.anio,
    p.id_pais
FROM mundial m
JOIN stg_mundiales sm ON CAST(sm.anio AS UNSIGNED) = m.anio
JOIN pais p ON p.nombre = TRIM(CASE WHEN sm.sede LIKE '%/%' THEN SUBSTRING_INDEX(sm.sede, '/', 1) ELSE sm.sede END);

INSERT IGNORE INTO mundial_sede (anio_mundial, id_pais)
SELECT DISTINCT
    m.anio,
    p.id_pais
FROM mundial m
JOIN stg_mundiales sm ON CAST(sm.anio AS UNSIGNED) = m.anio
JOIN pais p ON p.nombre = TRIM(SUBSTRING_INDEX(sm.sede, '/', -1))
WHERE sm.sede LIKE '%/%';

INSERT INTO grupo (anio_mundial, nombre_grupo, num_selecciones, num_clasificados)
SELECT
    CAST(anio_mundial AS UNSIGNED),
    TRIM(nombre_grupo),
    CAST(NULLIF(TRIM(num_selecciones), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(num_clasificados), '') AS UNSIGNED)
FROM stg_grupos
WHERE NULLIF(TRIM(anio_mundial), '') IS NOT NULL
  AND NULLIF(TRIM(nombre_grupo), '') IS NOT NULL;

INSERT INTO grupo_posicion (
    id_grupo, id_pais, posicion, pts, pj, pg, pe, pp, gf, gc, dif, clasificado
)
SELECT
    g.id_grupo,
    p.id_pais,
    CAST(NULLIF(TRIM(sgs.posicion), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.pts), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.pj), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.pg), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.pe), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.pp), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.gf), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.gc), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(sgs.dif), '') AS SIGNED),
    CASE WHEN LOWER(TRIM(sgs.clasificado)) = 'true' THEN TRUE ELSE FALSE END
FROM stg_grupo_seleccion sgs
JOIN grupo g ON g.anio_mundial = CAST(sgs.anio_mundial AS UNSIGNED) AND g.nombre_grupo = TRIM(sgs.nombre_grupo)
JOIN pais p ON p.nombre = TRIM(sgs.seleccion)
WHERE NULLIF(TRIM(sgs.anio_mundial), '') IS NOT NULL
  AND NULLIF(TRIM(sgs.nombre_grupo), '') IS NOT NULL
  AND NULLIF(TRIM(sgs.seleccion), '') IS NOT NULL;

INSERT INTO partido (
    anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
    goles_local, goles_visitante, goles_local_et, goles_visit_et,
    penales_local, penales_visit, slug_partido
)
SELECT
    spx.anio_mundial_num,
    spx.numero_partido_num,
    STR_TO_DATE(NULLIF(TRIM(spx.fecha), ''), '%Y-%m-%d'),
    NULLIF(TRIM(spx.etapa), ''),
    pl.id_pais,
    pv.id_pais,
    CAST(NULLIF(TRIM(spx.goles_local), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spx.goles_visitante), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spx.goles_local_et), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spx.goles_visit_et), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spx.penales_local), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spx.penales_visit), '') AS UNSIGNED),
    CONCAT(
        spx.anio_mundial_num, '_',
        slugify_text(spx.equipo_local), '_',
        slugify_text(spx.equipo_visitante),
        CASE
            WHEN spx.duplicado_orden > 1 THEN CONCAT('_', spx.duplicado_orden)
            ELSE ''
        END
    )
FROM (
    SELECT
        sp.*,
        CAST(sp.anio_mundial AS UNSIGNED) AS anio_mundial_num,
        CAST(sp.numero_partido AS UNSIGNED) AS numero_partido_num,
        ROW_NUMBER() OVER (
            PARTITION BY
                CAST(sp.anio_mundial AS UNSIGNED),
                slugify_text(sp.equipo_local),
                slugify_text(sp.equipo_visitante)
            ORDER BY CAST(sp.numero_partido AS UNSIGNED)
        ) AS duplicado_orden
    FROM stg_partidos sp
    WHERE NULLIF(TRIM(sp.anio_mundial), '') IS NOT NULL
      AND NULLIF(TRIM(sp.numero_partido), '') IS NOT NULL
) spx
JOIN pais pl ON pl.nombre = TRIM(spx.equipo_local)
JOIN pais pv ON pv.nombre = TRIM(spx.equipo_visitante);

UPDATE partido p
JOIN stg_goles sg ON sg.url_partido = p.slug_partido
SET p.slug_partido = sg.url_partido
WHERE NULLIF(TRIM(sg.url_partido), '') IS NOT NULL;

INSERT INTO gol_partido (
    id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra
)
SELECT
    pt.id_partido,
    CAST(sg.anio_mundial AS UNSIGNED),
    pg.id_pais,
    TRIM(sg.jugador),
    TRIM(sg.minuto),
    CAST(NULLIF(TRIM(sg.minuto_num), '') AS UNSIGNED),
    COALESCE(NULLIF(TRIM(sg.tipo_gol), ''), 'normal'),
    CASE WHEN LOWER(TRIM(sg.tiempo_extra)) = 'true' THEN TRUE ELSE FALSE END
FROM stg_goles sg
JOIN partido pt ON pt.slug_partido = TRIM(sg.url_partido)
LEFT JOIN pais pg ON pg.nombre = TRIM(sg.seleccion_gol)
WHERE NULLIF(TRIM(sg.url_partido), '') IS NOT NULL
  AND NULLIF(TRIM(sg.jugador), '') IS NOT NULL;

INSERT INTO goleador_mundial (
    anio_mundial, posicion, id_pais, jugador, goles, partidos, promedio_gol
)
SELECT
    CAST(smg.anio_mundial AS UNSIGNED),
    CAST(NULLIF(TRIM(smg.posicion), '') AS UNSIGNED),
    p.id_pais,
    TRIM(smg.jugador),
    CAST(NULLIF(TRIM(smg.goles), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(smg.partidos), '') AS UNSIGNED),
    CAST(NULLIF(REPLACE(TRIM(smg.promedio_gol), ',', '.'), '') AS DECIMAL(6,2))
FROM stg_mejores_goleadores smg
LEFT JOIN pais p ON p.nombre = TRIM(smg.seleccion)
WHERE NULLIF(TRIM(smg.anio_mundial), '') IS NOT NULL
  AND NULLIF(TRIM(smg.jugador), '') IS NOT NULL;

INSERT INTO posicion_final (
    anio_mundial, posicion, id_pais, etapa_alcanzada, puntos, pj, pg, pe, pp, gf, gc, dif
)
SELECT
    CAST(spf.anio_mundial AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.posicion), '') AS UNSIGNED),
    p.id_pais,
    NULLIF(TRIM(spf.etapa_alcanzada), ''),
    CAST(NULLIF(TRIM(spf.puntos), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.pj), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.pg), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.pe), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.pp), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.gf), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.gc), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(spf.dif), '') AS SIGNED)
FROM stg_posiciones_finales spf
JOIN pais p ON p.nombre = TRIM(spf.seleccion)
WHERE NULLIF(TRIM(spf.anio_mundial), '') IS NOT NULL
  AND NULLIF(TRIM(spf.seleccion), '') IS NOT NULL;

INSERT INTO jugador (
    id_pais, apellido, nombre, nombre_completo, fecha_nacimiento_texto, posicion, url_ficha
)
SELECT
    p.id_pais,
    NULLIF(TRIM(sj.apellido), ''),
    NULLIF(TRIM(sj.nombre), ''),
    TRIM(sj.nombre_completo),
    NULLIF(TRIM(sj.fecha_nacimiento), ''),
    NULLIF(TRIM(sj.posicion), ''),
    NULLIF(TRIM(sj.url_ficha), '')
FROM (
    SELECT
        MIN(seleccion) AS seleccion,
        MIN(apellido) AS apellido,
        MIN(nombre) AS nombre,
        MIN(nombre_completo) AS nombre_completo,
        MIN(fecha_nacimiento) AS fecha_nacimiento,
        MIN(posicion) AS posicion,
        MIN(NULLIF(TRIM(url_ficha), '')) AS url_ficha
    FROM stg_jugadores
    WHERE NULLIF(TRIM(nombre_completo), '') IS NOT NULL
    GROUP BY
        CASE
            WHEN NULLIF(TRIM(url_ficha), '') IS NOT NULL THEN NULLIF(TRIM(url_ficha), '')
            ELSE CONCAT('__sin_url__', TRIM(nombre_completo), '__', COALESCE(TRIM(seleccion), ''))
        END
) sj
LEFT JOIN pais p ON p.nombre = TRIM(sj.seleccion);
