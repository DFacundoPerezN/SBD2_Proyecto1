# Manual tecnico

## Resumen

Este proyecto corresponde a la Fase 1 del Proyecto 1 de Sistemas de Bases de Datos 2.
El objetivo es extraer informacion de los Mundiales de Futbol desde
`https://www.losmundialesdefutbol.com/mundiales.php`, modelarla y cargarla en una base
de datos relacional.

Con base en el enunciado, los entregables requeridos eran:

1. Modelo de datos y diagrama entidad relacion.
2. Extraccion y carga de datos a una base relacional.
3. Scripts SQL para crear modelo, tablas, llaves, indices y carga.
4. Stored procedure por anio del mundial.
5. Stored procedure por pais.

## Estado actual del repositorio

Actualmente el proyecto ya cuenta con:

- Scrapers en Python para mundiales, partidos, goleadores, posiciones finales, goles y jugadores.
- Archivos CSV generados en `output_csv/`.
- El enunciado original en `docs/Enunciado proyecto 1 - 2026 (1).pdf`.

Lo que hacia falta agregar para dejarlo alineado con el enunciado era:

- Modelo relacional documentado.
- Scripts SQL de creacion de esquema, llaves e indices.
- Script SQL de carga desde los CSV actuales.
- Stored procedures solicitados.

## Archivos agregados para completar la entrega

- `docs/modelo_er.md`
- `sql/01_schema_mysql.sql`
- `sql/02_load_data_mysql.sql`
- `sql/03_procedures_mysql.sql`

## Motor de base de datos elegido

Se dejo la solucion preparada para `MySQL`, y fue validada en una instalacion local con
`MySQL Server 9.2` y `MySQL Workbench 8.0 CE`.

Motivos:

- Soporta stored procedures facilmente.
- Permite `LOAD DATA LOCAL INFILE` para cargar los CSV existentes.
- Facilita una revision rapida durante la calificacion.

## Modelo de datos

El modelo final contempla estas entidades principales:

- `pais`
- `mundial`
- `mundial_sede`
- `grupo`
- `grupo_posicion`
- `partido`
- `gol_partido`
- `goleador_mundial`
- `posicion_final`
- `jugador`

La documentacion completa del modelo y el diagrama ER estan en:

- `docs/modelo_er.md`

## Como crear la base de datos

Ejecutar en este orden:

1. `sql/01_schema_mysql.sql`
2. `sql/02_load_data_mysql.sql`
3. `sql/03_procedures_mysql.sql`
4. `sql/04_validation_queries.sql`

## Como cargar los CSV

El script `sql/02_load_data_mysql.sql` ya incluye rutas absolutas a los CSV del proyecto,
por lo que no hace falta editar una variable de ruta antes de ejecutarlo.

Antes de correrlo, verifica que `LOAD DATA LOCAL INFILE` este habilitado tanto en el
servidor como en el cliente.

En el servidor:

```sql
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
```

En MySQL Workbench:

1. Ir a `Database > Manage Connections`.
2. Editar la conexion local.
3. En la pestana `Advanced`, agregar en `Others`:

```text
OPT_LOCAL_INFILE=1
```

4. Guardar la conexion y reconectar.

Luego ejecutar todo el script. Este hace lo siguiente:

- Limpia tablas de staging.
- Carga los CSV actuales.
- Inserta catalogos y tablas finales.
- Relaciona paises, mundiales, partidos, goles y jugadores.

Durante la implementacion se ajusto este script para:

- usar `LOAD DATA LOCAL INFILE` directo, compatible con MySQL Workbench
- leer CSV con finales de linea Windows `\r\n`
- generar `slug_partido` unico cuando hay partidos repetidos entre las mismas selecciones
- deduplicar jugadores por `url_ficha`

## Stored procedures disponibles

### `sp_mundial_detalle`

Parametros:

- `p_anio INT`
- `p_grupo VARCHAR(50)` opcional
- `p_pais VARCHAR(100)` opcional
- `p_fecha DATE` opcional

Uso:

```sql
CALL sp_mundial_detalle(2022, NULL, NULL, NULL);
CALL sp_mundial_detalle(2022, 'Grupo A', NULL, NULL);
CALL sp_mundial_detalle(2022, NULL, 'Argentina', NULL);
```

### `sp_pais_historial`

Parametros:

- `p_pais VARCHAR(100)`
- `p_anio INT` opcional

Uso:

```sql
CALL sp_pais_historial('Argentina', NULL);
CALL sp_pais_historial('Brasil', 2002);
```

## Observaciones importantes

1. La parte de grupos ya puede regenerarse con `scraper_grupos.py` y los CSV resultantes
   se integran con el script SQL de carga.
   El scraper ahora incluye un fallback para capturas alternas de Wayback cuando una
   captura devuelve pagina de verificacion, con lo que fue posible recuperar
   `1986_grupo_d.php` en la corrida completa.

2. Los CSV de jugadores estan divididos en varios archivos:

- `jugadoresA_G.csv`
- `jugadoresH_N.csv`
- `jugadoresO_R.csv`
- `jugadoresS_T.csv`
- `jugadoresU_Z.csv`

   El script de carga ya contempla esos cinco archivos.

3. En `mundiales.csv` hay al menos una inconsistencia en 1930 con campeon y subcampeon.
   Para evitar arrastrar ese error, la carga SQL corrige campeon, subcampeon, tercero y
   cuarto usando `posiciones_finales.csv` cuando esa informacion esta disponible.

4. La carga y validacion final si se ejecuto en un entorno local con MySQL Workbench.
   Los principales ajustes hechos durante la prueba real quedaron incorporados en
   `sql/02_load_data_mysql.sql`.

## Recomendacion para cerrar el proyecto

Para una entrega mas solida, el siguiente paso recomendado es:

1. Volver a ejecutar `scraper_grupos.py` cuando necesites regenerar los CSV de grupos.
2. Cargar nuevamente la base con `sql/02_load_data_mysql.sql`.
3. Probar los dos stored procedures con al menos 3 paises y 3 mundiales.
