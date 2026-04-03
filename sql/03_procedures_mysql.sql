USE proyecto1_mundiales;

DROP PROCEDURE IF EXISTS sp_mundial_detalle;
DELIMITER $$
CREATE PROCEDURE sp_mundial_detalle(
    IN p_anio INT,
    IN p_grupo VARCHAR(50),
    IN p_pais VARCHAR(100),
    IN p_fecha DATE
)
BEGIN
    SELECT
        m.anio,
        m.sede_texto,
        pc.nombre AS campeon,
        ps.nombre AS subcampeon,
        pt.nombre AS tercero,
        pq.nombre AS cuarto,
        m.num_selecciones,
        m.num_partidos,
        m.num_goles,
        m.promedio_gol,
        GROUP_CONCAT(DISTINCT ph.nombre ORDER BY ph.nombre SEPARATOR ', ') AS paises_sede
    FROM mundial m
    LEFT JOIN pais pc ON pc.id_pais = m.campeon_id
    LEFT JOIN pais ps ON ps.id_pais = m.subcampeon_id
    LEFT JOIN pais pt ON pt.id_pais = m.tercero_id
    LEFT JOIN pais pq ON pq.id_pais = m.cuarto_id
    LEFT JOIN mundial_sede ms ON ms.anio_mundial = m.anio
    LEFT JOIN pais ph ON ph.id_pais = ms.id_pais
    WHERE m.anio = p_anio
    GROUP BY
        m.anio, m.sede_texto, pc.nombre, ps.nombre, pt.nombre, pq.nombre,
        m.num_selecciones, m.num_partidos, m.num_goles, m.promedio_gol;

    SELECT
        pf.posicion,
        p.nombre AS pais,
        pf.etapa_alcanzada,
        pf.puntos,
        pf.pj,
        pf.pg,
        pf.pe,
        pf.pp,
        pf.gf,
        pf.gc,
        pf.dif
    FROM posicion_final pf
    JOIN pais p ON p.id_pais = pf.id_pais
    WHERE pf.anio_mundial = p_anio
      AND (p_pais IS NULL OR p.nombre = p_pais)
    ORDER BY pf.posicion, p.nombre;

    SELECT
        g.nombre_grupo,
        gp.posicion,
        p.nombre AS pais,
        gp.pts,
        gp.pj,
        gp.pg,
        gp.pe,
        gp.pp,
        gp.gf,
        gp.gc,
        gp.dif,
        gp.clasificado
    FROM grupo g
    JOIN grupo_posicion gp ON gp.id_grupo = g.id_grupo
    JOIN pais p ON p.id_pais = gp.id_pais
    WHERE g.anio_mundial = p_anio
      AND (p_grupo IS NULL OR g.nombre_grupo = p_grupo)
      AND (p_pais IS NULL OR p.nombre = p_pais)
    ORDER BY g.nombre_grupo, gp.posicion, p.nombre;

    SELECT
        pa.numero_partido,
        pa.fecha,
        pa.etapa,
        pl.nombre AS equipo_local,
        pv.nombre AS equipo_visitante,
        pa.goles_local,
        pa.goles_visitante,
        pa.goles_local_et,
        pa.goles_visit_et,
        pa.penales_local,
        pa.penales_visit,
        pa.slug_partido
    FROM partido pa
    JOIN pais pl ON pl.id_pais = pa.local_id
    JOIN pais pv ON pv.id_pais = pa.visitante_id
    WHERE pa.anio_mundial = p_anio
      AND (p_fecha IS NULL OR pa.fecha = p_fecha)
      AND (p_pais IS NULL OR pl.nombre = p_pais OR pv.nombre = p_pais)
    ORDER BY pa.fecha, pa.numero_partido;

    SELECT
        pa.numero_partido,
        pa.fecha,
        pl.nombre AS equipo_local,
        pv.nombre AS equipo_visitante,
        pg.nombre AS seleccion_gol,
        gp.jugador,
        gp.minuto,
        gp.minuto_num,
        gp.tipo_gol,
        gp.tiempo_extra
    FROM gol_partido gp
    JOIN partido pa ON pa.id_partido = gp.id_partido
    JOIN pais pl ON pl.id_pais = pa.local_id
    JOIN pais pv ON pv.id_pais = pa.visitante_id
    LEFT JOIN pais pg ON pg.id_pais = gp.id_pais_gol
    WHERE gp.anio_mundial = p_anio
      AND (p_fecha IS NULL OR pa.fecha = p_fecha)
      AND (p_pais IS NULL OR pl.nombre = p_pais OR pv.nombre = p_pais OR pg.nombre = p_pais)
    ORDER BY pa.fecha, pa.numero_partido, gp.minuto_num, gp.jugador;

    SELECT
        gm.posicion,
        gm.jugador,
        p.nombre AS seleccion,
        gm.goles,
        gm.partidos,
        gm.promedio_gol
    FROM goleador_mundial gm
    LEFT JOIN pais p ON p.id_pais = gm.id_pais
    WHERE gm.anio_mundial = p_anio
      AND (p_pais IS NULL OR p.nombre = p_pais)
    ORDER BY gm.posicion, gm.goles DESC, gm.jugador;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_pais_historial;
DELIMITER $$
CREATE PROCEDURE sp_pais_historial(
    IN p_pais VARCHAR(100),
    IN p_anio INT
)
BEGIN
    SELECT
        p.nombre AS pais,
        COUNT(DISTINCT pf.anio_mundial) AS participaciones_registradas,
        GROUP_CONCAT(DISTINCT ms.anio_mundial ORDER BY ms.anio_mundial SEPARATOR ', ') AS anios_sede
    FROM pais p
    LEFT JOIN posicion_final pf
        ON pf.id_pais = p.id_pais
       AND (p_anio IS NULL OR pf.anio_mundial = p_anio)
    LEFT JOIN mundial_sede ms
        ON ms.id_pais = p.id_pais
       AND (p_anio IS NULL OR ms.anio_mundial = p_anio)
    WHERE p.nombre = p_pais
    GROUP BY p.nombre;

    SELECT
        pf.anio_mundial,
        pf.posicion,
        pf.etapa_alcanzada,
        pf.puntos,
        pf.pj,
        pf.pg,
        pf.pe,
        pf.pp,
        pf.gf,
        pf.gc,
        pf.dif
    FROM posicion_final pf
    JOIN pais p ON p.id_pais = pf.id_pais
    WHERE p.nombre = p_pais
      AND (p_anio IS NULL OR pf.anio_mundial = p_anio)
    ORDER BY pf.anio_mundial;

    SELECT
        g.anio_mundial,
        g.nombre_grupo,
        gp.posicion,
        gp.pts,
        gp.pj,
        gp.pg,
        gp.pe,
        gp.pp,
        gp.gf,
        gp.gc,
        gp.dif,
        gp.clasificado
    FROM grupo_posicion gp
    JOIN grupo g ON g.id_grupo = gp.id_grupo
    JOIN pais p ON p.id_pais = gp.id_pais
    WHERE p.nombre = p_pais
      AND (p_anio IS NULL OR g.anio_mundial = p_anio)
    ORDER BY g.anio_mundial, g.nombre_grupo;

    SELECT
        pa.anio_mundial,
        pa.fecha,
        pa.etapa,
        pl.nombre AS equipo_local,
        pv.nombre AS equipo_visitante,
        pa.goles_local,
        pa.goles_visitante,
        pa.goles_local_et,
        pa.goles_visit_et,
        pa.penales_local,
        pa.penales_visit
    FROM partido pa
    JOIN pais pl ON pl.id_pais = pa.local_id
    JOIN pais pv ON pv.id_pais = pa.visitante_id
    WHERE (pl.nombre = p_pais OR pv.nombre = p_pais)
      AND (p_anio IS NULL OR pa.anio_mundial = p_anio)
    ORDER BY pa.anio_mundial, pa.fecha, pa.numero_partido;

    SELECT
        gp.anio_mundial,
        pa.fecha,
        pl.nombre AS equipo_local,
        pv.nombre AS equipo_visitante,
        COALESCE(pg.nombre, p_pais) AS seleccion_gol,
        gp.jugador,
        gp.minuto,
        gp.tipo_gol,
        gp.tiempo_extra
    FROM gol_partido gp
    JOIN partido pa ON pa.id_partido = gp.id_partido
    JOIN pais pl ON pl.id_pais = pa.local_id
    JOIN pais pv ON pv.id_pais = pa.visitante_id
    LEFT JOIN pais pg ON pg.id_pais = gp.id_pais_gol
    WHERE (pl.nombre = p_pais OR pv.nombre = p_pais OR pg.nombre = p_pais)
      AND (p_anio IS NULL OR gp.anio_mundial = p_anio)
    ORDER BY gp.anio_mundial, pa.fecha, gp.minuto_num, gp.jugador;

    SELECT
        m.anio,
        CASE WHEN ms.id_pais IS NULL THEN 'no' ELSE 'si' END AS fue_sede
    FROM mundial m
    LEFT JOIN mundial_sede ms
        ON ms.anio_mundial = m.anio
       AND ms.id_pais = (SELECT id_pais FROM pais WHERE nombre = p_pais LIMIT 1)
    WHERE p_anio IS NULL OR m.anio = p_anio
    ORDER BY m.anio;
END $$
DELIMITER ;
