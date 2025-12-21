/*
=========================================================
EVALUACIÓN FINAL TRANSVERSAL - SEMANA 9
CONTEXTO: MONTENEGRO S.A. - Asesorías Empresariales
=========================================================

Usuarios:

* SYSTEM (system)              : Administrador
* PRY2205_EFT (BuHo_12345678)   : Dueño del modelo (Owner)
* PRY2205_EFT_DES (DelFin_123456) : Desarrollador / Implementación CASO 2
* PRY2205_EFT_CON (CoCo_87654321) : Consultas / Ejecución CASO 2 y CASO 3
=========================================================
*/

ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE;

/* =========================================================
CASO 1 - ESTRATEGIA DE SEGURIDAD
========================================================= */

/* =========================================================
SECCIÓN SYSTEM
(Conectarse a usuario System o ADMIN)
========================================================= */

-- 1. Creación de usuarios con gestión de contraseñas y espacio
-- Contraseñas deben cumplir: mínimo 12 caracteres, 1 minúscula, 2 mayúsculas, 2 números

CREATE USER PRY2205_EFT IDENTIFIED BY BuHo_12345678
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_DES IDENTIFIED BY DelFin_123456
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_CON IDENTIFIED BY CoCo_87654321
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON USERS;

-- Privilegio básico de conexión
GRANT CREATE SESSION TO PRY2205_EFT;
GRANT CREATE SESSION TO PRY2205_EFT_DES;
GRANT CREATE SESSION TO PRY2205_EFT_CON;

-- 2. Creación de ROLES
CREATE ROLE PRY2205_ROL_D; -- Rol Desarrollador (para DES)
CREATE ROLE PRY2205_ROL_C; -- Rol Consultas (para CON)

-- 3. Asignación de Roles a Usuarios
GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;

-- 4. Privilegios Directos para PRY2205_EFT (Owner del Modelo)
-- Necesario para crear y gestionar toda la estructura
GRANT CREATE TABLE TO PRY2205_EFT;
GRANT CREATE VIEW TO PRY2205_EFT;
GRANT CREATE ANY INDEX TO PRY2205_EFT;
GRANT CREATE SEQUENCE TO PRY2205_EFT;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_EFT;
GRANT CREATE SYNONYM TO PRY2205_EFT;

-- 5. Privilegios Directos para PRY2205_EFT_DES (Desarrollador CASO 2)
-- Solo lo necesario para construir sus objetos de trabajo
GRANT CREATE TABLE TO PRY2205_EFT_DES;
GRANT CREATE SEQUENCE TO PRY2205_EFT_DES;
GRANT CREATE VIEW TO PRY2205_EFT_DES;

-- 6. Privilegios Directos para PRY2205_EFT_CON (Consultas)
-- Este usuario NO crea objetos, solo consulta
-- Los permisos se otorgarán vía ROL

COMMIT;

/* =========================================================
SECCIÓN PRY2205_EFT (OWNER)
Conectarse como PRY2205_EFT
IMPORTANTE: Ejecutar el script de poblado ANTES de continuar
========================================================= */

-- =========================================================
-- ESTRATEGIA DE SINÓNIMOS PÚBLICOS
-- =========================================================
-- Sinónimos PÚBLICOS: para tablas que serán accedidas por múltiples usuarios
-- Esto facilita el acceso sin necesidad de especificar el schema

-- Tablas principales del modelo de negocio
CREATE PUBLIC SYNONYM SYN_PROFESIONAL FOR PRY2205_EFT.PROFESIONAL;
CREATE PUBLIC SYNONYM SYN_TIPO_CONTRATO FOR PRY2205_EFT.TIPO_CONTRATO;
CREATE PUBLIC SYNONYM SYN_PROFESION FOR PRY2205_EFT.PROFESION;
CREATE PUBLIC SYNONYM SYN_ISAPRE FOR PRY2205_EFT.ISAPRE;
CREATE PUBLIC SYNONYM SYN_AFP FOR PRY2205_EFT.AFP;
CREATE PUBLIC SYNONYM SYN_RANGOS_SUELDOS FOR PRY2205_EFT.RANGOS_SUELDOS;
CREATE PUBLIC SYNONYM SYN_EMPRESA FOR PRY2205_EFT.EMPRESA;
CREATE PUBLIC SYNONYM SYN_ASESORIA FOR PRY2205_EFT.ASESORIA;
CREATE PUBLIC SYNONYM SYN_SECTOR FOR PRY2205_EFT.SECTOR;
CREATE PUBLIC SYNONYM SYN_COMUNA FOR PRY2205_EFT.COMUNA;

-- =========================================================
-- OTORGAR PERMISOS DE CONSULTA VÍA ROL
-- =========================================================
-- Estrategia: usar ROL para dar permisos de SELECT a múltiples usuarios
-- Principio de menor privilegio: solo SELECT, no INSERT/UPDATE/DELETE

-- Permisos para ROL_D (Desarrollador - PRY2205_EFT_DES)
GRANT SELECT ON PRY2205_EFT.PROFESIONAL TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.TIPO_CONTRATO TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.PROFESION TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.ISAPRE TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.AFP TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.RANGOS_SUELDOS TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.EMPRESA TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.ASESORIA TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.SECTOR TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.COMUNA TO PRY2205_ROL_D;

-- Permisos para ROL_C (Consultas - PRY2205_EFT_CON)
GRANT SELECT ON PRY2205_EFT.PROFESIONAL TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.TIPO_CONTRATO TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.PROFESION TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.ISAPRE TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.AFP TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.RANGOS_SUELDOS TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.EMPRESA TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.ASESORIA TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.SECTOR TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.COMUNA TO PRY2205_ROL_C;

COMMIT;

/* =========================================================
CASO 2 - CREACIÓN DE INFORME
INFORME: REMUNERACIONES DE PROFESIONALES
========================================================= */

/* =========================================================
SECCIÓN PRY2205_EFT_DES (DESARROLLADOR)
Conectarse como PRY2205_EFT_DES
========================================================= */

-- =========================================================
-- PASO 1: CREACIÓN DE SECUENCIA PARA ID DE CONTROL
-- =========================================================

CREATE SEQUENCE SEQ_CARTOLA_ID
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- =========================================================
-- PASO 2: CREACIÓN DE TABLA CARTOLA_PROFESIONALES
-- =========================================================

CREATE TABLE CARTOLA_PROFESIONALES (
    -- id_control                     NUMBER(8) DEFAULT SEQ_CARTOLA_ID.NEXTVAL NOT NULL,
    rut_profesional                VARCHAR2(10) NOT NULL,
    nombre_profesional             VARCHAR2(50) NOT NULL,
    profesion                      VARCHAR2(25) NOT NULL,
    isapre                         VARCHAR2(25),
    sueldo_base                    NUMBER(8) NOT NULL,
    porc_comision_profesional      NUMBER(4,2) NOT NULL,
    valor_total_comision           NUMBER(8) NOT NULL,
    porcentaje_honorario           NUMBER(8) NOT NULL,
    bono_movilizacion              NUMBER(6) NOT NULL,
    total_pagar                    NUMBER(8) NOT NULL,
    CONSTRAINT PK_CARTOLA_PROF PRIMARY KEY (rut_profesional)
);

-- =========================================================
-- PASO 3: INSERCIÓN DE DATOS EN CARTOLA_PROFESIONALES
-- =========================================================
-- Nota: id_control se genera automáticamente con DEFAULT SEQ_CARTOLA_ID.NEXTVAL

INSERT INTO CARTOLA_PROFESIONALES (
    rut_profesional,
    nombre_profesional,
    profesion,
    isapre,
    sueldo_base,
    porc_comision_profesional,
    valor_total_comision,
    porcentaje_honorario,
    bono_movilizacion,
    total_pagar
)
SELECT 
    rut_profesional,
    nombre_profesional,
    profesion,
    isapre,
    sueldo_base,
    porc_comision_profesional,
    valor_total_comision,
    porcentaje_honorario,
    bono_movilizacion,
    total_pagar
FROM (
    SELECT 
        -- RUT del profesional sin formato (sin puntos ni guión)
        p.rutprof AS rut_profesional,
        
        -- Nombre completo del profesional (Nombre + Apellido paterno + Apellido materno)
        INITCAP(p.nompro || ' ' || p.apppro || ' ' || p.apmpro) AS nombre_profesional,
        
        -- Profesión en INITCAP
        INITCAP(pr.nomprofesion) AS profesion,
        
        -- Nombre de la Isapre en INITCAP
        INITCAP(i.nomisapre) AS isapre,
        
        -- Sueldo base sin formato (NUMBER)
        p.sueldo AS sueldo_base,
        
        -- Porcentaje de comisión con formato 0,00 (si no tiene comisión = 0)
        ROUND(NVL(p.comision, 0), 2) AS porc_comision_profesional,
        
        -- Valor de comisión calculado (sin formato, NUMBER)
        ROUND(p.sueldo * NVL(p.comision, 0), 0) AS valor_total_comision,
        
        -- Valor de honorarios calculado (sueldo * porcentaje / 100)
        ROUND(p.sueldo * NVL(rs.honor_pct, 0) / 100, 0) AS porcentaje_honorario,
        
        -- Bono de movilización según tipo de contrato (sin formato, NUMBER)
        CASE tc.idtcontrato
            WHEN 1 THEN 150000  -- Indefinido Jornada Completa
            WHEN 2 THEN 120000  -- Indefinido Jornada Parcial
            WHEN 3 THEN 60000   -- Plazo fijo
            WHEN 4 THEN 50000   -- Honorarios
            ELSE 0
        END AS bono_movilizacion,
        
        -- Total a pagar (suma de todos los conceptos, sin formato, NUMBER)
        ROUND(
            p.sueldo + 
            (p.sueldo * NVL(p.comision, 0)) +
            (p.sueldo * NVL(rs.honor_pct, 0) / 100) +
            CASE tc.idtcontrato
                WHEN 1 THEN 150000
                WHEN 2 THEN 120000
                WHEN 3 THEN 60000
                WHEN 4 THEN 50000
                ELSE 0
            END,
            0
        ) AS total_pagar,
        
        -- Columnas auxiliares para ordenamiento
        pr.nomprofesion AS orden_profesion,
        p.sueldo AS orden_sueldo,
        NVL(p.comision, 0) AS orden_comision,
        p.rutprof AS orden_rut
    
    FROM SYN_PROFESIONAL p
    
    -- INNER JOIN con TIPO_CONTRATO
    INNER JOIN SYN_TIPO_CONTRATO tc
        ON p.idtcontrato = tc.idtcontrato
    
    -- INNER JOIN con PROFESION
    INNER JOIN SYN_PROFESION pr
        ON p.idprofesion = pr.idprofesion
    
    -- INNER JOIN con ISAPRE
    INNER JOIN SYN_ISAPRE i
        ON p.idisapre = i.idisapre
    
    -- LEFT JOIN con RANGOS_SUELDOS (para calcular porcentaje de honorarios)
    LEFT JOIN SYN_RANGOS_SUELDOS rs
        ON p.sueldo BETWEEN rs.s_min AND rs.s_max
    
    -- Ordenamiento según requerimientos: profesión ASC, sueldo DESC, comisión ASC, RUT ASC
    ORDER BY 
        pr.nomprofesion ASC,
        p.sueldo DESC,
        NVL(p.comision, 0) ASC,
        p.rutprof ASC
);

COMMIT; 

-- Verificación de datos insertados
SELECT * FROM CARTOLA_PROFESIONALES;

-- =========================================================
-- PASO 4: OTORGAR PERMISOS A PRY2205_EFT_CON
-- =========================================================

-- Otorgar permiso al rol PRY2205_ROL_C
GRANT SELECT ON PRY2205_EFT_DES.CARTOLA_PROFESIONALES TO PRY2205_ROL_C;

COMMIT;

/* =========================================================
VALIDACIÓN DEL CASO 2
Conectarse como PRY2205_EFT_CON y ejecutar:
========================================================= */

SELECT * FROM PRY2205_EFT_DES.CARTOLA_PROFESIONALES;

/* =========================================================
CASO 3 - OPTIMIZACIÓN DE SENTENCIAS SQL
========================================================= */

/* =========================================================
CASO 3.1 - CREACIÓN DE VISTA
VISTA: VW_EMPRESAS_ASESORADAS
========================================================= */

/* =========================================================
SECCIÓN PRY2205_EFT (OWNER)
Conectarse como PRY2205_EFT
========================================================= */

-- =========================================================
-- PASO 1: CREACIÓN DE LA VISTA VW_EMPRESAS_ASESORADAS
-- =========================================================
-- Nota: La vista usa los sinónimos públicos creados en el CASO 1

CREATE OR REPLACE VIEW VW_EMPRESAS_ASESORADAS AS
SELECT
    -- RUT de la empresa con formato XX.XXX.XXX-X
    SUBSTR(TO_CHAR(e.rut_empresa), 1, LENGTH(TO_CHAR(e.rut_empresa)) - 6) || '.' ||
    SUBSTR(TO_CHAR(e.rut_empresa), LENGTH(TO_CHAR(e.rut_empresa)) - 5, 3) || '.' ||
    SUBSTR(TO_CHAR(e.rut_empresa), LENGTH(TO_CHAR(e.rut_empresa)) - 2, 3) || '-' ||
    e.dv_empresa AS rut_empresa,
    
    -- Nombre de la empresa
    UPPER(e.nomempresa) AS nombre_empresa,
    
    -- Años de existencia (desde fecha de inicio de actividades)
    TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecha_iniciacion_actividades) / 12) AS anios_existencia,
    
    -- IVA declarado SIN formato (solo el número)
    e.iva_declarado AS iva,
    
    -- Número promedio de asesorías anuales (total / 12) - redondeado a entero
    ROUND(COUNT(a.inicio) / 12.0, 0) AS total_asesorias_anuales,
    
    -- Monto estimado devolución IVA SIN formato (solo el número)
    ROUND((e.iva_declarado * (COUNT(a.inicio) / 12.0)) / 100, 0) AS devolucion_iva,
    
    -- Tipo de cliente según número de asesorías anuales (promedio redondeado)
    CASE
        WHEN ROUND(COUNT(a.inicio) / 12.0, 0) > 5 THEN 'CLIENTE PREMIUM'
        WHEN ROUND(COUNT(a.inicio) / 12.0, 0) BETWEEN 3 AND 5 THEN 'CLIENTE'
        WHEN ROUND(COUNT(a.inicio) / 12.0, 0) < 3 THEN 'CLIENTE POCO CONCURRIDO'
    END AS tipo_cliente,
    
    -- Promoción o recomendación según tipo de cliente y número de asesorías totales
    CASE
        -- CLIENTE PREMIUM (promedio > 5)
        WHEN ROUND(COUNT(a.inicio) / 12.0, 0) > 5 THEN
            CASE
                WHEN COUNT(a.inicio) >= 7 THEN '1 ASESORÍA GRATIS'
                ELSE '1 ASESORÍA 40% DE DESCUENTO'
            END
        -- CLIENTE (promedio entre 3 y 5)
        WHEN ROUND(COUNT(a.inicio) / 12.0, 0) BETWEEN 3 AND 5 THEN
            CASE
                WHEN ROUND(COUNT(a.inicio) / 12.0, 0) = 5 THEN '1 ASESORÍA 30% DE DESCUENTO'
                ELSE '1 ASESORÍA 20% DE DESCUENTO'
            END
        -- CLIENTE POCO CONCURRIDO (promedio < 3)
        WHEN ROUND(COUNT(a.inicio) / 12.0, 0) < 3 THEN 'CAPTAR CLIENTE'
    END AS corresponde

FROM SYN_EMPRESA e

-- LEFT JOIN con ASESORIA usando sinónimo público del CASO 1
LEFT JOIN SYN_ASESORIA a
    ON e.idempresa = a.idempresa
    -- Solo asesorías terminadas el año anterior al actual
    AND EXTRACT(YEAR FROM a.fin) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -12))
    AND a.fin IS NOT NULL

-- GROUP BY: Agrupar por empresa
GROUP BY
    e.rut_empresa,
    e.dv_empresa,
    e.nomempresa,
    e.fecha_iniciacion_actividades,
    e.iva_declarado,
    e.idempresa

-- HAVING: Filtrar solo empresas con al menos 1 asesoría registrada
HAVING COUNT(a.inicio) > 0

-- ORDER BY: Ordenar por nombre de empresa ascendente
ORDER BY
    e.nomempresa ASC;

COMMIT; 

-- Verificación de la vista
SELECT * FROM VW_EMPRESAS_ASESORADAS;

-- =========================================================
-- PASO 2: OTORGAR PERMISOS A PRY2205_EFT_CON
-- =========================================================

-- Otorgar permiso al rol PRY2205_ROL_C
GRANT SELECT ON PRY2205_EFT.VW_EMPRESAS_ASESORADAS TO PRY2205_ROL_C;

COMMIT;

/* =========================================================
VALIDACIÓN DEL CASO 3.1
Conectarse como PRY2205_EFT_CON y ejecutar:
========================================================= */

SELECT * FROM PRY2205_EFT.VW_EMPRESAS_ASESORADAS;

/* =========================================================
CASO 3.2 - CREACIÓN DE ÍNDICES
OPTIMIZACIÓN: Mejorar rendimiento de VW_EMPRESAS_ASESORADAS
========================================================= */

/* =========================================================
SECCIÓN PRY2205_EFT (OWNER)
Conectarse como PRY2205_EFT
========================================================= */

-- =========================================================
-- ANÁLISIS DEL PLAN DE EJECUCIÓN
-- =========================================================
-- Antes de crear índices, ejecutar:
EXPLAIN PLAN FOR SELECT * FROM VW_EMPRESAS_ASESORADAS;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- =========================================================
-- CREACIÓN DE ÍNDICES PARA OPTIMIZACIÓN
-- =========================================================
-- Basado en el análisis del plan de ejecución

-- ÍNDICE 1: Optimiza filtro en fecha FIN de ASESORIA
CREATE INDEX IDX_ASESORIA_FIN
ON ASESORIA(fin);

-- ÍNDICE 2: Optimiza JOIN ASESORIA → EMPRESA
CREATE INDEX IDX_ASESORIA_IDEMPRESA
ON ASESORIA(idempresa);

-- NOTA: No se crea índice en EMPRESA.idempresa porque ya existe
-- automáticamente por ser PRIMARY KEY

-- ÍNDICE 3: Optimiza ORDER BY nombre_empresa
CREATE INDEX IDX_EMPRESA_NOMBRE
ON EMPRESA(nomempresa);

-- ÍNDICE 4: Índice compuesto para consultas complejas en ASESORIA
CREATE INDEX IDX_ASESORIA_COMPUESTO
ON ASESORIA(idempresa, fin);

-- ÍNDICE 5: Optimiza cálculo de antigüedad (fecha_iniciacion_actividades)
CREATE INDEX IDX_EMPRESA_FECHA_INICIO
ON EMPRESA(fecha_iniciacion_actividades);

COMMIT;

-- =========================================================
-- VERIFICACIÓN DE ÍNDICES CREADOS
-- =========================================================

SELECT 
    index_name,
    table_name,
    uniqueness,
    status
FROM user_indexes
WHERE table_name IN ('EMPRESA', 'ASESORIA', 'SECTOR')
ORDER BY table_name, index_name;

-- =========================================================
-- VERIFICAR MEJORA EN EL PLAN DE EJECUCIÓN
-- =========================================================
-- Después de crear índices, ejecutar nuevamente:
EXPLAIN PLAN FOR SELECT * FROM VW_EMPRESAS_ASESORADAS;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Comparar con el plan anterior para verificar el uso de índices

COMMIT;

/* =========================================================
VALIDACIÓN FINAL DE LA IMPLEMENTACIÓN
========================================================= */

-- =========================================================
-- VALIDAR COMO PRY2205_EFT_CON (USUARIO DE CONSULTAS)
-- =========================================================

-- Conectarse como PRY2205_EFT_CON y ejecutar:
SHOW USER;

-- Verificar acceso a CARTOLA_PROFESIONALES (CASO 2)
SELECT * FROM PRY2205_EFT_DES.CARTOLA_PROFESIONALES;

-- Verificar acceso a VW_EMPRESAS_ASESORADAS (CASO 3)
SELECT * FROM PRY2205_EFT.VW_EMPRESAS_ASESORADAS;

-- Verificar uso de sinónimos públicos
SELECT * FROM SYN_PROFESIONAL WHERE ROWNUM <= 5;
SELECT * FROM SYN_EMPRESA WHERE ROWNUM <= 5;

/* =========================================================
FIN DEL SCRIPT
========================================================= */