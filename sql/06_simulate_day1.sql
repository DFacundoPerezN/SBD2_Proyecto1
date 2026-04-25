-- =============================================================================
-- Proyecto 2 - SBD2: Carga de Datos — DÍA 1
-- Simulación: partidos y resultados (fase de grupos) del Mundial 2026
-- Motor: MySQL 8.0+
-- Nota: El Mundial 2026 se celebra en USA, México y Canadá con 48 selecciones.
--       Se simulan 16 partidos de la primera jornada de grupos.
-- =============================================================================

USE proyecto1_mundiales;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. Insertar el Mundial 2026 (si no existe)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO pais (nombre) VALUES
    ('Estados Unidos'),
    ('México'),
    ('Canadá'),
    ('Arabia Saudita'),
    ('Marruecos'),
    ('Ecuador'),
    ('Senegal'),
    ('Gales'),
    ('Qatar'),
    ('Ghana'),
    ('Serbia'),
    ('Camerún'),
    ('Costa Rica'),
    ('Túnez'),
    ('Irán'),
    ('Australia');

INSERT IGNORE INTO mundial (anio, sede_texto, num_selecciones, num_partidos, num_goles)
VALUES (2026, 'Estados Unidos / México / Canadá', 48, 104, NULL);

-- Sedes del 2026
INSERT IGNORE INTO mundial_sede (anio_mundial, id_pais)
SELECT 2026, id_pais FROM pais WHERE nombre = 'Estados Unidos';

INSERT IGNORE INTO mundial_sede (anio_mundial, id_pais)
SELECT 2026, id_pais FROM pais WHERE nombre = 'México';

INSERT IGNORE INTO mundial_sede (anio_mundial, id_pais)
SELECT 2026, id_pais FROM pais WHERE nombre = 'Canadá';

-- ---------------------------------------------------------------------------
-- 2. Grupos del Mundial 2026 (primeros 4 grupos de 4 países c/u)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO grupo (anio_mundial, nombre_grupo, num_selecciones, num_clasificados) VALUES
    (2026, 'A', 4, 2),
    (2026, 'B', 4, 2),
    (2026, 'C', 4, 2),
    (2026, 'D', 4, 2);

-- ---------------------------------------------------------------------------
-- 3. Insertar partidos — Jornada 1, fase de grupos (16 partidos, Día 1)
--    Se usa subquery para obtener los id_pais a partir del nombre.
-- ---------------------------------------------------------------------------

-- GRUPO A: Argentina vs Polonia, Arabia Saudita vs México
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1001, '2026-06-11', 'Fase de Grupos - Grupo A',
       p_local.id_pais, p_visit.id_pais, 2, 0,
       '2026_1001_argentina_vs_polonia'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Argentina' AND p_visit.nombre = 'Polonia';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1002, '2026-06-11', 'Fase de Grupos - Grupo A',
       p_local.id_pais, p_visit.id_pais, 1, 2,
       '2026_1002_arabia_saudita_vs_mexico'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Arabia Saudita' AND p_visit.nombre = 'México';

-- GRUPO B: Francia vs Australia, Túnez vs Dinamarca
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1003, '2026-06-12', 'Fase de Grupos - Grupo B',
       p_local.id_pais, p_visit.id_pais, 4, 1,
       '2026_1003_francia_vs_australia'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Francia' AND p_visit.nombre = 'Australia';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1004, '2026-06-12', 'Fase de Grupos - Grupo B',
       p_local.id_pais, p_visit.id_pais, 0, 0,
       '2026_1004_tunez_vs_dinamarca'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Túnez' AND p_visit.nombre = 'Dinamarca';

-- GRUPO C: Brasil vs Serbia, Suiza vs Camerún
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1005, '2026-06-13', 'Fase de Grupos - Grupo C',
       p_local.id_pais, p_visit.id_pais, 2, 0,
       '2026_1005_brasil_vs_serbia'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Brasil' AND p_visit.nombre = 'Serbia';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1006, '2026-06-13', 'Fase de Grupos - Grupo C',
       p_local.id_pais, p_visit.id_pais, 1, 0,
       '2026_1006_suiza_vs_camerun'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Suiza' AND p_visit.nombre = 'Camerún';

-- GRUPO D: Portugal vs Ghana, Uruguay vs Corea del Sur
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1007, '2026-06-14', 'Fase de Grupos - Grupo D',
       p_local.id_pais, p_visit.id_pais, 3, 2,
       '2026_1007_portugal_vs_ghana'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Portugal' AND p_visit.nombre = 'Ghana';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1008, '2026-06-14', 'Fase de Grupos - Grupo D',
       p_local.id_pais, p_visit.id_pais, 0, 0,
       '2026_1008_uruguay_vs_corea_del_sur'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Uruguay' AND p_visit.nombre = 'Corea del Sur';

-- GRUPO E: España vs Costa Rica, Alemania vs Japón
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1009, '2026-06-15', 'Fase de Grupos - Grupo E',
       p_local.id_pais, p_visit.id_pais, 7, 0,
       '2026_1009_espana_vs_costa_rica'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'España' AND p_visit.nombre = 'Costa Rica';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1010, '2026-06-15', 'Fase de Grupos - Grupo E',
       p_local.id_pais, p_visit.id_pais, 1, 2,
       '2026_1010_alemania_vs_japon'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Alemania' AND p_visit.nombre = 'Japón';

-- GRUPO F: Bélgica vs Canadá, Marruecos vs Croacia
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1011, '2026-06-16', 'Fase de Grupos - Grupo F',
       p_local.id_pais, p_visit.id_pais, 1, 0,
       '2026_1011_belgica_vs_canada'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Bélgica' AND p_visit.nombre = 'Canadá';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1012, '2026-06-16', 'Fase de Grupos - Grupo F',
       p_local.id_pais, p_visit.id_pais, 0, 0,
       '2026_1012_marruecos_vs_croacia'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Marruecos' AND p_visit.nombre = 'Croacia';

-- GRUPO G: Brasil vs Suiza, Serbia vs Camerún
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1013, '2026-06-17', 'Fase de Grupos - Grupo G',
       p_local.id_pais, p_visit.id_pais, 1, 0,
       '2026_1013_ecuador_vs_senegal'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Ecuador' AND p_visit.nombre = 'Senegal';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1014, '2026-06-17', 'Fase de Grupos - Grupo G',
       p_local.id_pais, p_visit.id_pais, 2, 1,
       '2026_1014_holanda_vs_qatar'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Países Bajos' AND p_visit.nombre = 'Qatar';

-- GRUPO H: México vs Polonia, Estados Unidos vs Gales
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1015, '2026-06-18', 'Fase de Grupos - Grupo H',
       p_local.id_pais, p_visit.id_pais, 0, 0,
       '2026_1015_mexico_vs_polonia'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'México' AND p_visit.nombre = 'Polonia';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1016, '2026-06-18', 'Fase de Grupos - Grupo H',
       p_local.id_pais, p_visit.id_pais, 1, 1,
       '2026_1016_estados_unidos_vs_gales'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Estados Unidos' AND p_visit.nombre = 'Gales';

-- ---------------------------------------------------------------------------
-- 4. Goles del Día 1 (para partidos que sí existen garantizados)
--    Solo insertamos goles para partidos que usan países históricos (Argentina,
--    Francia, Brasil, España, Portugal, Uruguay) que ya deberían estar en pais.
-- ---------------------------------------------------------------------------

-- Partido 1001: Argentina 2-0 Polonia
INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'L. Messi', '36', 36, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1001_argentina_vs_polonia'
  AND pa.nombre = 'Argentina';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'J. Álvarez', '67', 67, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1001_argentina_vs_polonia'
  AND pa.nombre = 'Argentina';

-- Partido 1003: Francia 4-1 Australia
INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'K. Mbappé', '12', 12, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1003_francia_vs_australia'
  AND pa.nombre = 'Francia';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'O. Giroud', '27', 27, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1003_francia_vs_australia'
  AND pa.nombre = 'Francia';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'K. Mbappé', '45', 45, 'penal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1003_francia_vs_australia'
  AND pa.nombre = 'Francia';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'A. Griezmann', '78', 78, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1003_francia_vs_australia'
  AND pa.nombre = 'Francia';

-- Partido 1005: Brasil 2-0 Serbia
INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'Vinicius Jr.', '62', 62, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1005_brasil_vs_serbia'
  AND pa.nombre = 'Brasil';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'Richarlison', '73', 73, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1005_brasil_vs_serbia'
  AND pa.nombre = 'Brasil';

-- ---------------------------------------------------------------------------
-- 5. Registrar fragmentación en todos los LOG al final del Día 1
-- ---------------------------------------------------------------------------
CALL sp_registrar_fragmentacion();

-- ---------------------------------------------------------------------------
-- 6. Validación final del Día 1
-- ---------------------------------------------------------------------------
SELECT 'DIA 1 - Partidos insertados:' AS info, COUNT(*) AS total
FROM partido WHERE anio_mundial = 2026;

SELECT 'DIA 1 - Goles insertados:' AS info, COUNT(*) AS total
FROM gol_partido WHERE anio_mundial = 2026;
