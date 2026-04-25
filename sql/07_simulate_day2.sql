-- =============================================================================
-- Proyecto 2 - SBD2: Carga de Datos — DÍA 2
-- Simulación: segunda jornada de grupos + octavos de final del Mundial 2026
-- Motor: MySQL 8.0+
-- Prerequisito: haber ejecutado 06_simulate_day1.sql
-- =============================================================================

USE proyecto1_mundiales;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1. Segunda jornada de grupos (16 partidos nuevos)
-- ---------------------------------------------------------------------------

-- GRUPO A: Argentina vs Arabia Saudita, Polonia vs México
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1017, '2026-06-21', 'Fase de Grupos - Grupo A',
       p_local.id_pais, p_visit.id_pais, 1, 2,
       '2026_1017_argentina_vs_arabia_saudita'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Argentina' AND p_visit.nombre = 'Arabia Saudita';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1018, '2026-06-21', 'Fase de Grupos - Grupo A',
       p_local.id_pais, p_visit.id_pais, 0, 1,
       '2026_1018_polonia_vs_mexico'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Polonia' AND p_visit.nombre = 'México';

-- GRUPO B: Francia vs Dinamarca, Túnez vs Australia
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1019, '2026-06-22', 'Fase de Grupos - Grupo B',
       p_local.id_pais, p_visit.id_pais, 2, 1,
       '2026_1019_francia_vs_dinamarca'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Francia' AND p_visit.nombre = 'Dinamarca';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1020, '2026-06-22', 'Fase de Grupos - Grupo B',
       p_local.id_pais, p_visit.id_pais, 1, 0,
       '2026_1020_tunez_vs_australia'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Túnez' AND p_visit.nombre = 'Australia';

-- GRUPO C: Brasil vs Suiza, Serbia vs Camerún
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1021, '2026-06-23', 'Fase de Grupos - Grupo C',
       p_local.id_pais, p_visit.id_pais, 1, 0,
       '2026_1021_brasil_vs_suiza'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Brasil' AND p_visit.nombre = 'Suiza';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1022, '2026-06-23', 'Fase de Grupos - Grupo C',
       p_local.id_pais, p_visit.id_pais, 3, 3,
       '2026_1022_serbia_vs_camerun'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Serbia' AND p_visit.nombre = 'Camerún';

-- GRUPO D: Portugal vs Uruguay, Corea del Sur vs Ghana
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1023, '2026-06-24', 'Fase de Grupos - Grupo D',
       p_local.id_pais, p_visit.id_pais, 2, 0,
       '2026_1023_portugal_vs_uruguay'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Portugal' AND p_visit.nombre = 'Uruguay';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1024, '2026-06-24', 'Fase de Grupos - Grupo D',
       p_local.id_pais, p_visit.id_pais, 2, 3,
       '2026_1024_corea_del_sur_vs_ghana'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Corea del Sur' AND p_visit.nombre = 'Ghana';

-- GRUPO E: España vs Alemania, Japón vs Costa Rica
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1025, '2026-06-25', 'Fase de Grupos - Grupo E',
       p_local.id_pais, p_visit.id_pais, 1, 1,
       '2026_1025_espana_vs_alemania'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'España' AND p_visit.nombre = 'Alemania';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1026, '2026-06-25', 'Fase de Grupos - Grupo E',
       p_local.id_pais, p_visit.id_pais, 4, 0,
       '2026_1026_japon_vs_costa_rica'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Japón' AND p_visit.nombre = 'Costa Rica';

-- GRUPO F: Bélgica vs Marruecos, Canadá vs Croacia
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1027, '2026-06-26', 'Fase de Grupos - Grupo F',
       p_local.id_pais, p_visit.id_pais, 0, 2,
       '2026_1027_belgica_vs_marruecos'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Bélgica' AND p_visit.nombre = 'Marruecos';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1028, '2026-06-26', 'Fase de Grupos - Grupo F',
       p_local.id_pais, p_visit.id_pais, 4, 1,
       '2026_1028_canada_vs_croacia'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Canadá' AND p_visit.nombre = 'Croacia';

-- GRUPO G: Ecuador vs Países Bajos, Senegal vs Qatar
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1029, '2026-06-27', 'Fase de Grupos - Grupo G',
       p_local.id_pais, p_visit.id_pais, 1, 1,
       '2026_1029_ecuador_vs_paises_bajos'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Ecuador' AND p_visit.nombre = 'Países Bajos';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1030, '2026-06-27', 'Fase de Grupos - Grupo G',
       p_local.id_pais, p_visit.id_pais, 2, 1,
       '2026_1030_senegal_vs_qatar'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Senegal' AND p_visit.nombre = 'Qatar';

-- GRUPO H: Estados Unidos vs Irán, Gales vs Inglaterra
INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1031, '2026-06-28', 'Fase de Grupos - Grupo H',
       p_local.id_pais, p_visit.id_pais, 1, 0,
       '2026_1031_estados_unidos_vs_iran'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Estados Unidos' AND p_visit.nombre = 'Irán';

INSERT IGNORE INTO partido
    (anio_mundial, numero_partido, fecha, etapa, local_id, visitante_id,
     goles_local, goles_visitante, slug_partido)
SELECT 2026, 1032, '2026-06-28', 'Fase de Grupos - Grupo H',
       p_local.id_pais, p_visit.id_pais, 0, 3,
       '2026_1032_gales_vs_inglaterra'
FROM pais p_local, pais p_visit
WHERE p_local.nombre = 'Gales' AND p_visit.nombre = 'Inglaterra';

-- ---------------------------------------------------------------------------
-- 2. Goles adicionales del Día 2
-- ---------------------------------------------------------------------------

-- Argentina 1-2 Arabia Saudita (histórico similar)
INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'L. Messi', '10', 10, 'penal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1017_argentina_vs_arabia_saudita'
  AND pa.nombre = 'Argentina';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'Al-Shehri', '48', 48, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1017_argentina_vs_arabia_saudita'
  AND pa.nombre = 'Arabia Saudita';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'Al-Dawsari', '53', 53, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1017_argentina_vs_arabia_saudita'
  AND pa.nombre = 'Arabia Saudita';

-- Brasil 1-0 Suiza
INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'Casemiro', '83', 83, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1021_brasil_vs_suiza'
  AND pa.nombre = 'Brasil';

-- Francia 2-1 Dinamarca
INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'K. Mbappé', '68', 68, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1019_francia_vs_dinamarca'
  AND pa.nombre = 'Francia';

INSERT INTO gol_partido (id_partido, anio_mundial, id_pais_gol, jugador, minuto, minuto_num, tipo_gol, tiempo_extra)
SELECT p.id_partido, 2026, pa.id_pais, 'K. Mbappé', '88', 88, 'normal', FALSE
FROM partido p, pais pa
WHERE p.slug_partido = '2026_1019_francia_vs_dinamarca'
  AND pa.nombre = 'Francia';

-- ---------------------------------------------------------------------------
-- 3. Actualizar estadísticas del Mundial 2026 (goles totales acumulados)
-- ---------------------------------------------------------------------------
UPDATE mundial
SET num_goles = (
    SELECT COUNT(*) FROM gol_partido WHERE anio_mundial = 2026
)
WHERE anio = 2026;

-- ---------------------------------------------------------------------------
-- 4. Registrar fragmentación en todos los LOG al final del Día 2
-- ---------------------------------------------------------------------------
CALL sp_registrar_fragmentacion();

-- ---------------------------------------------------------------------------
-- 5. Validación final del Día 2
-- ---------------------------------------------------------------------------
SELECT 'DIA 2 - Total partidos 2026:' AS info, COUNT(*) AS total
FROM partido WHERE anio_mundial = 2026;

SELECT 'DIA 2 - Total goles 2026:' AS info, COUNT(*) AS total
FROM gol_partido WHERE anio_mundial = 2026;

SELECT 'DIA 2 - Total partidos historicos:' AS info, COUNT(*) AS total
FROM partido;
