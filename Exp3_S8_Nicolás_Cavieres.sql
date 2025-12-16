/*
Usuarios:

* SYSTEM (system)           : Administrador
* PRY2205_USER1 (user1_pwd) : Dueño del modelo (Owner)
* PRY2205_USER2 (user2_pwd) : Desarrollador / Consultas
  =========================================================
  */

/* =========================================================
CASO 1 - ESTRATEGIA DE SEGURIDAD
========================================================= */

/* =========================================================
SECCIÓN SYSTEM
(Conectarse a usuario System)
========================================================= */

-- 1. Creación de usuarios (con componentes completos)
CREATE USER PRY2205_USER1 IDENTIFIED BY user1_pwd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_USER2 IDENTIFIED BY user2_pwd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA 20M ON USERS;

GRANT CREATE SESSION TO PRY2205_USER1;
GRANT CREATE SESSION TO PRY2205_USER2;

-- 2. Creación de ROLES
CREATE ROLE PRY2205_ROL_D; -- Rol Dueño
CREATE ROLE PRY2205_ROL_P; -- Rol Programador/Consulta

-- 3. Asignación de Roles
GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

-- 4. Privilegios Directos USER1 (Dueño del Modelo)
-- Necesarios para crear la estructura y seguridad
GRANT CREATE TABLE TO PRY2205_USER1;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_USER1;
GRANT CREATE SYNONYM TO PRY2205_USER1;
GRANT CREATE SEQUENCE TO PRY2205_USER1;
GRANT CREATE VIEW TO PRY2205_USER1; -- Refuerzo explícito

-- 5. Privilegios Directos USER2 (Desarrollador Caso 2)
-- Solo lo necesario para crear sus propios objetos de trabajo
GRANT CREATE TABLE TO PRY2205_USER2;
GRANT CREATE SEQUENCE TO PRY2205_USER2;
GRANT CREATE TRIGGER TO PRY2205_USER2;

COMMIT;

/* =========================================================
SECCIÓN PRY2205_USER1
Conectarse como PRY2205_USER1
========================================================= */

-- Creación de SINÓNIMOS PÚBLICOS (una sola vez)

CREATE PUBLIC SYNONYM SYN_LIBRO FOR PRY2205_USER1.LIBRO;
CREATE PUBLIC SYNONYM SYN_PRESTAMO FOR PRY2205_USER1.PRESTAMO;
CREATE PUBLIC SYNONYM SYN_EJEMPLAR FOR PRY2205_USER1.EJEMPLAR;

-- Otorgar SELECT mínimo mediante ROLE a USER2

GRANT SELECT ON PRY2205_USER1.LIBRO TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.PRESTAMO TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.EJEMPLAR TO PRY2205_ROL_P;
/* =========================================================
   CASO 2 - CONTROL STOCK BIBLIOGRÁFICO
   ========================================================= */

/* =========================================================
SECCIÓN PRY2205_USER2
Conectarse como PRY2205_USER2
========================================================= */
 
-- CREACION DE LA SECUENCIA DE CONTROL
CREATE SEQUENCE SEQ_CONTROL_STOCK
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- CREACIÓN DE TABLA CONTROL_STOCK_LIBROS

CREATE TABLE CONTROL_STOCK_LIBROS (
    id_control           NUMBER(6) NOT NULL,
    libro_id             NUMBER(5) NOT NULL,
    nombre_libro         VARCHAR2(70) NOT NULL,
    total_ejemplares     NUMBER NOT NULL,
    en_prestamo          NUMBER NOT NULL,
    disponibles          NUMBER NOT NULL,
    porcentaje_prestamo  NUMBER NOT NULL,
    stock_critico        VARCHAR2(1) NOT NULL,
    CONSTRAINT PK_CONTROL_STOCK PRIMARY KEY (id_control)
);

-- INSERCIÓN DE DATOS

INSERT INTO CONTROL_STOCK_LIBROS (
    id_control,
    libro_id,
    nombre_libro,
    total_ejemplares,
    en_prestamo,
    disponibles,
    porcentaje_prestamo,
    stock_critico
)
SELECT 
    SEQ_CONTROL_STOCK.NEXTVAL,
    libro_id,
    nombre_libro,
    total_ejemplares,
    en_prestamo,
    disponibles,
    porcentaje_prestamo,
    stock_critico
FROM (
    -- SUBCONSULTA con GROUP BY
    SELECT
        l.libroid AS libro_id,
        l.nombre_libro AS nombre_libro,
        
        -- Total de ejemplares por libro
        COUNT(DISTINCT e.ejemplarid) AS total_ejemplares,
        
        -- Ejemplares en préstamo: ejemplares con préstamos SIN devolver
        -- del periodo hace 2 años por empleados 190, 180, 150
        COUNT(DISTINCT CASE 
            WHEN p.prestamoid IS NOT NULL 
                 AND p.fecha_entrega IS NULL 
            THEN e.ejemplarid 
        END) AS en_prestamo,
        
        -- Ejemplares disponibles: total - en préstamo
        COUNT(DISTINCT e.ejemplarid) - COUNT(DISTINCT CASE 
            WHEN p.prestamoid IS NOT NULL 
                 AND p.fecha_entrega IS NULL 
            THEN e.ejemplarid 
        END) AS disponibles,
        
        -- Porcentaje de ejemplares en préstamo respecto al total
        ROUND(
            NVL(
                COUNT(DISTINCT CASE 
                    WHEN p.prestamoid IS NOT NULL 
                         AND p.fecha_entrega IS NULL 
                    THEN e.ejemplarid 
                END) * 100.0 / NULLIF(COUNT(DISTINCT e.ejemplarid), 0),
                0
            ),
            0
        ) AS porcentaje_prestamo,
        
        -- Indicador de stock crítico: 'S' si disponibles > 2, 'N' si disponibles <= 2
        CASE
            WHEN (COUNT(DISTINCT e.ejemplarid) - COUNT(DISTINCT CASE 
                WHEN p.prestamoid IS NOT NULL 
                     AND p.fecha_entrega IS NULL 
                THEN e.ejemplarid 
            END)) > 2
            THEN 'S'
            ELSE 'N'
        END AS stock_critico

    FROM SYN_LIBRO l
    
    -- INNER JOIN: Solo libros que tienen préstamos del periodo por empleados específicos
    INNER JOIN (
        -- Pre-filtrar: solo libros con préstamos del periodo por empleados 190, 180, 150
        SELECT DISTINCT libroid
        FROM SYN_PRESTAMO
        WHERE empleadoid IN (190, 180, 150)
          AND EXTRACT(YEAR FROM fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
    ) libros_validos
        ON l.libroid = libros_validos.libroid
    
    -- INNER JOIN: Obtener ejemplares de estos libros
    INNER JOIN SYN_EJEMPLAR e
        ON l.libroid = e.libroid
    
    -- LEFT JOIN: Unir con préstamos para contar cuáles están en préstamo
    LEFT JOIN SYN_PRESTAMO p
        ON e.libroid = p.libroid
       AND e.ejemplarid = p.ejemplarid
       AND p.empleadoid IN (190, 180, 150)
       AND EXTRACT(YEAR FROM p.fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))

    -- GROUP BY: Agrupar por libro
    GROUP BY
        l.libroid,
        l.nombre_libro

    -- ORDER BY: Ordenar por id de libro
    ORDER BY
        l.libroid
);

-- Validación
SELECT * FROM CONTROL_STOCK_LIBROS;


/* =========================================================
CASO 3 – INFORME DE MULTAS POR ATRASO
SECCIÓN PRY2205_USER1
Conectarse como PRY2205_USER1
========================================================= */

-- PASO 1: CREACIÓN DE SINÓNIMOS PRIVADOS

CREATE SYNONYM SYN_PRESTAMO_PRIV     FOR PRY2205_USER1.PRESTAMO;
CREATE SYNONYM SYN_ALUMNO_PRIV       FOR PRY2205_USER1.ALUMNO;
CREATE SYNONYM SYN_CARRERA_PRIV      FOR PRY2205_USER1.CARRERA;
CREATE SYNONYM SYN_LIBRO_PRIV        FOR PRY2205_USER1.LIBRO;
CREATE SYNONYM SYN_REBAJA_MULTA_PRIV FOR PRY2205_USER1.REBAJA_MULTA;

-- =====================================================================
-- PASO 2: CREACIÓN DE LA VISTA VW_DETALLE_MULTAS
-- =====================================================================
-- La vista accede a las tablas mediante los sinónimos privados

CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT
    -- ID del préstamo
    p.prestamoid AS id_prestamo,
    -- Nombre completo del alumno (formato: Primer_nombre Primer_apellido)
    INITCAP(a.nombre) || ' ' || INITCAP(a.apaterno) AS nombre_alumno,
    -- Nombre de la carrera
    INITCAP(c.descripcion) AS nombre_carrera,    
    -- ID del libro
    l.libroid AS id_libro,   
    -- Valor del libro con formato $000.000
    '$' || TO_CHAR(l.precio, 'FM999G999') AS valor_libro,    
    -- Fecha de término del préstamo (formato DD/MM/YYYY)
    TO_CHAR(p.fecha_termino, 'DD/MM/YYYY') AS fecha_termino,    
    -- Fecha de entrega real (formato DD/MM/YYYY)
    TO_CHAR(p.fecha_entrega, 'DD/MM/YYYY') AS fecha_entrega,    
    -- Días de atraso (fecha_entrega - fecha_termino)
    (p.fecha_entrega - p.fecha_termino) AS dias_atraso,    
    -- Valor de la multa con formato $000.000
    '$' || TO_CHAR(ROUND(l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino), 0), 'FM999G999') AS valor_multa,    
    -- Porcentaje de rebaja (formato 0,00)
    TO_CHAR(NVL(rm.porc_rebaja_multa, 0), 'FM0D00') AS porcentaje_rebaja_multa,    
    -- Valor rebajado con formato $000.000
    '$' || TO_CHAR(
        ROUND(
            l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino) - 
            (l.precio * 0.03 * (p.fecha_entrega - p.fecha_termino) * NVL(rm.porc_rebaja_multa, 0) / 100),
            0
        ),
        'FM999G999'
    ) AS valor_rebajado
FROM SYN_PRESTAMO_PRIV p
-- JOIN con ALUMNO
INNER JOIN SYN_ALUMNO_PRIV a
    ON p.alumnoid = a.alumnoid
-- JOIN con CARRERA
INNER JOIN SYN_CARRERA_PRIV c
    ON a.carreraid = c.carreraid
-- JOIN con LIBRO
INNER JOIN SYN_LIBRO_PRIV l
    ON p.libroid = l.libroid
-- LEFT JOIN con REBAJA_MULTA (no todas las carreras tienen rebaja)
-- Carreras con convenio: 180, 320, 160, 220
LEFT JOIN SYN_REBAJA_MULTA_PRIV rm
    ON c.carreraid = rm.carreraid
WHERE
    -- Solo préstamos con fecha de término de hace 2 años (24 meses)
    EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
    -- Solo préstamos entregados con atraso (fecha_termino < fecha_entrega)
    AND p.fecha_termino < p.fecha_entrega
    -- Solo préstamos que fueron entregados (tienen fecha_entrega)
    AND p.fecha_entrega IS NOT NULL
-- Ordenar por fecha de entrega descendente
ORDER BY p.fecha_entrega DESC;

-- =====================================================================
-- PASO 3: CREACIÓN DE ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================================
-- Basado en el análisis del plan de ejecución de VW_DETALLE_MULTAS

-- ÍNDICE 1: Optimiza filtro WHERE en fecha_termino
CREATE INDEX IDX_PRESTAMO_FECHA_TERMINO
ON SYN_PRESTAMO_PRIV(fecha_termino);

-- ÍNDICE 2: Optimiza JOIN PRESTAMO → ALUMNO
CREATE INDEX IDX_PRESTAMO_ALUMNOID
ON SYN_PRESTAMO_PRIV(alumnoid);

-- ÍNDICE 3: Optimiza JOIN ALUMNO → CARRERA
CREATE INDEX IDX_ALUMNO_CARRERAID
ON SYN_ALUMNO_PRIV(carreraid);

-- ÍNDICE 4: Optimiza JOIN PRESTAMO → LIBRO
CREATE INDEX IDX_PRESTAMO_LIBROID
ON SYN_PRESTAMO_PRIV(libroid);

-- ÍNDICE 5: Optimiza LEFT JOIN CARRERA → REBAJA_MULTA
CREATE INDEX IDX_REBAJA_MULTA_CARRERAID
ON SYN_REBAJA_MULTA_PRIV(carreraid);

-- ÍNDICE 6: Optimiza ORDER BY fecha_entrega DESC
CREATE INDEX IDX_PRESTAMO_FECHA_ENTREGA
ON SYN_PRESTAMO_PRIV(fecha_entrega DESC);

-- ÍNDICE 7: Índice compuesto para consultas complejas
CREATE INDEX IDX_PRESTAMO_COMPUESTO
ON SYN_PRESTAMO_PRIV(fecha_termino, fecha_entrega, alumnoid, libroid);

-- =====================================================================
-- VERIFICACIÓN DE ÍNDICES CREADOS
-- =====================================================================

-- Ver índices creados
SELECT 
    index_name,
    table_name,
    uniqueness,
    status
FROM user_indexes
WHERE table_name IN ('PRESTAMO', 'ALUMNO', 'CARRERA', 'LIBRO', 'REBAJA_MULTA')
ORDER BY table_name, index_name;
