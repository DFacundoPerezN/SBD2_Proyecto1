USE proyecto1_mundiales;

SELECT 'pais' AS tabla, COUNT(*) AS total FROM pais
UNION ALL
SELECT 'mundial', COUNT(*) FROM mundial
UNION ALL
SELECT 'mundial_sede', COUNT(*) FROM mundial_sede
UNION ALL
SELECT 'grupo', COUNT(*) FROM grupo
UNION ALL
SELECT 'grupo_posicion', COUNT(*) FROM grupo_posicion
UNION ALL
SELECT 'partido', COUNT(*) FROM partido
UNION ALL
SELECT 'gol_partido', COUNT(*) FROM gol_partido
UNION ALL
SELECT 'goleador_mundial', COUNT(*) FROM goleador_mundial
UNION ALL
SELECT 'posicion_final', COUNT(*) FROM posicion_final
UNION ALL
SELECT 'jugador', COUNT(*) FROM jugador;

SELECT anio, sede_texto
FROM mundial
ORDER BY anio;

SELECT anio_mundial, nombre_grupo, num_selecciones, num_clasificados
FROM grupo
ORDER BY anio_mundial, nombre_grupo;

SELECT p.nombre AS pais, COUNT(*) AS participaciones
FROM posicion_final pf
JOIN pais p ON p.id_pais = pf.id_pais
GROUP BY p.nombre
ORDER BY participaciones DESC, p.nombre;

SELECT anio_mundial, posicion, jugador, goles
FROM goleador_mundial
WHERE posicion = 1
ORDER BY anio_mundial;

SELECT
    COUNT(*) AS goles_sin_partido
FROM stg_goles sg
LEFT JOIN partido p
    ON p.slug_partido = sg.url_partido
WHERE p.id_partido IS NULL;

CALL sp_mundial_detalle(2022, NULL, NULL, NULL);
CALL sp_pais_historial('Argentina', NULL);
