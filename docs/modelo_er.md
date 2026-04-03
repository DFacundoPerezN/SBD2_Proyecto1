# Modelo ER

## Alcance

El modelo fue construido a partir de los CSV ya existentes en `output_csv/` y del
enunciado del proyecto. El objetivo es poder consultar:

- informacion general por mundial,
- partidos y resultados,
- posiciones finales,
- goles detallados,
- goleadores,
- informacion por pais,
- informacion de grupos cuando esa fuente este disponible.

## Entidades principales

### `pais`

Catalogo unico de selecciones o paises participantes.

### `mundial`

Contiene el resumen por anio del mundial.

### `mundial_sede`

Relaciona un mundial con uno o varios paises sede. Se separa de `mundial` porque un
mundial puede tener mas de una sede, por ejemplo `Corea / Japon`.

### `partido`

Guarda cada partido del mundial, con fecha, etapa, marcador, tiempo extra y penales.

### `gol_partido`

Detalle de goles anotados por partido.

### `goleador_mundial`

Tabla historica de goleadores por mundial.

### `posicion_final`

Tabla de posiciones finales por mundial.

### `grupo`

Representa cada grupo de un mundial.

### `grupo_posicion`

Posiciones de cada seleccion dentro de cada grupo.

### `jugador`

Catalogo de jugadores extraidos desde las fichas del sitio.

## Relaciones

- Un `pais` puede aparecer en muchos `mundiales` como campeon, subcampeon, tercero o cuarto.
- Un `mundial` puede tener uno o varios `mundial_sede`.
- Un `mundial` tiene muchos `partidos`.
- Un `partido` tiene muchos `gol_partido`.
- Un `mundial` tiene muchas filas en `goleador_mundial`.
- Un `mundial` tiene muchas filas en `posicion_final`.
- Un `mundial` puede tener muchos `grupo`.
- Un `grupo` tiene muchas filas en `grupo_posicion`.
- Un `pais` puede tener muchos `jugador`.

## Diagrama entidad relacion

```mermaid
erDiagram
    PAIS ||--o{ MUNDIAL_SEDE : es_sede_de
    PAIS ||--o{ PARTIDO : participa_como_local
    PAIS ||--o{ PARTIDO : participa_como_visitante
    PAIS ||--o{ GOL_PARTIDO : anota
    PAIS ||--o{ GOLEADOR_MUNDIAL : representa
    PAIS ||--o{ POSICION_FINAL : obtiene
    PAIS ||--o{ GRUPO_POSICION : integra
    PAIS ||--o{ JUGADOR : pertenece_a

    MUNDIAL ||--o{ MUNDIAL_SEDE : tiene
    MUNDIAL ||--o{ PARTIDO : incluye
    MUNDIAL ||--o{ GOLEADOR_MUNDIAL : registra
    MUNDIAL ||--o{ POSICION_FINAL : resume
    MUNDIAL ||--o{ GRUPO : organiza

    GRUPO ||--o{ GRUPO_POSICION : contiene
    PARTIDO ||--o{ GOL_PARTIDO : registra

    PAIS {
        int id_pais PK
        varchar nombre UK
    }

    MUNDIAL {
        int anio PK
        varchar sede_texto
        int campeon_id FK
        int subcampeon_id FK
        int tercero_id FK
        int cuarto_id FK
        int num_selecciones
        int num_partidos
        int num_goles
        decimal promedio_gol
    }

    MUNDIAL_SEDE {
        int anio_mundial FK
        int id_pais FK
    }

    PARTIDO {
        bigint id_partido PK
        int anio_mundial FK
        int numero_partido
        date fecha
        varchar etapa
        int local_id FK
        int visitante_id FK
        int goles_local
        int goles_visitante
        int goles_local_et
        int goles_visit_et
        int penales_local
        int penales_visit
        varchar slug_partido UK
    }

    GOL_PARTIDO {
        bigint id_gol PK
        bigint id_partido FK
        int anio_mundial FK
        int id_pais_gol FK
        varchar jugador
        varchar minuto
        int minuto_num
        varchar tipo_gol
        boolean tiempo_extra
    }

    GOLEADOR_MUNDIAL {
        bigint id_goleador PK
        int anio_mundial FK
        int id_pais FK
        int posicion
        varchar jugador
        int goles
        int partidos
        decimal promedio_gol
    }

    POSICION_FINAL {
        bigint id_posicion_final PK
        int anio_mundial FK
        int id_pais FK
        int posicion
        varchar etapa_alcanzada
        int puntos
        int pj
        int pg
        int pe
        int pp
        int gf
        int gc
        int dif
    }

    GRUPO {
        bigint id_grupo PK
        int anio_mundial FK
        varchar nombre_grupo
        int num_selecciones
        int num_clasificados
    }

    GRUPO_POSICION {
        bigint id_grupo_posicion PK
        bigint id_grupo FK
        int id_pais FK
        int posicion
        int pts
        int pj
        int pg
        int pe
        int pp
        int gf
        int gc
        int dif
        boolean clasificado
    }

    JUGADOR {
        bigint id_jugador PK
        int id_pais FK
        varchar apellido
        varchar nombre
        varchar nombre_completo
        varchar fecha_nacimiento_texto
        varchar posicion
        varchar url_ficha UK
    }
```

## Notas de modelado

1. Se uso `pais` como catalogo central para selecciones y sedes.
2. Las sedes se normalizaron con una tabla intermedia porque un mundial puede tener mas
   de un pais anfitrion.
3. `slug_partido` se almacena para relacionar facilmente `partido` con `gol_partido`.
4. Los datos de grupo quedaron modelados.
5. La fecha de nacimiento del jugador se conserva como texto para no perder informacion original del sitio.
