/*******************************************************************************************
    CASO 1 – REPORTE DE ASESORÍAS (BANCA Y RETAIL)
    ---------------------------------------------------------
    Objetivo:
      - Obtener información consolidada de profesionales que han realizado asesorías
        en BANCA (sector 3) y RETAIL (sector 4).
      - Se requiere uso obligatorio de SUBCONSULTAS.
      - Se muestran montos formateados y totales de asesorías.
********************************************************************************************/

SELECT 
       p.id_profesional                                        AS "ID",
       INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS "PROFESIONAL",
       b.nro_asesoria_banca                                    AS "NRO ASESORIA BANCA",
       '$' || TO_CHAR(b.monto_total_banca, 'FM999G999G999')     AS "MONTO_TOTAL_BANCA",
       r.nro_asesoria_retail                                   AS "NRO ASESORIA RETAIL",
       '$' || TO_CHAR(r.monto_total_retail, 'FM999G999G999')    AS "MONTO_TOTAL_RETAIL",
       (b.nro_asesoria_banca + r.nro_asesoria_retail)           AS "TOTAL ASESORIAS",
       '$' || TO_CHAR(b.monto_total_banca + 
                      r.monto_total_retail, 'FM999G999G999')     AS "TOTAL HONORARIOS"
FROM (
    /* Uso de Operador SET (INTERSECT) para identificar profesionales en ambos sectores */
    SELECT id_profesional FROM asesoria WHERE cod_empresa IN (SELECT cod_empresa FROM empresa WHERE cod_sector = 3)
    INTERSECT
    SELECT id_profesional FROM asesoria WHERE cod_empresa IN (SELECT cod_empresa FROM empresa WHERE cod_sector = 4)
) set_profesionales
JOIN profesional p ON set_profesionales.id_profesional = p.id_profesional

/* Subconsulta BANCA */
JOIN (
    SELECT 
           id_profesional,
           COUNT(*) AS nro_asesoria_banca,
           SUM(honorario) AS monto_total_banca
    FROM asesoria a
    WHERE a.cod_empresa IN (
            SELECT cod_empresa FROM empresa WHERE cod_sector = 3
    )
    GROUP BY id_profesional
) b ON p.id_profesional = b.id_profesional

/* Subconsulta RETAIL */
JOIN (
    SELECT 
           id_profesional,
           COUNT(*) AS nro_asesoria_retail,
           SUM(honorario) AS monto_total_retail
    FROM asesoria a
    WHERE a.cod_empresa IN (
            SELECT cod_empresa FROM empresa WHERE cod_sector = 4
    )
    GROUP BY id_profesional
) r ON p.id_profesional = r.id_profesional;


/*******************************************************************************************
    CASO 2 – REPORTE MENSUAL DE HONORARIOS (ABRIL 2024)
    ----------------------------------------------------------
    Objetivo:
      - Crear tabla REPORTE_MES y poblarla con información de asesorías finalizadas
        en abril del año anterior (considerando que HOY es noviembre 2025).
********************************************************************************************/
/* -- Consulta de Prueba, para revisar el resultado del query
SELECT
       p.id_profesional AS "ID_PROF",
       INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS nombre_completo,
       INITCAP(pr.nombre_profesion) AS "NOMBRE_PROFESION",
       INITCAP(c.nom_comuna) AS "NOM_COMUNA",
       COUNT(a.honorario) AS nro_asesorias,
       ROUND(SUM(a.honorario),0) AS "MONTO_TOTAL_HONORARIOS",
       ROUND(AVG(a.honorario),0) AS "PROMEDIO_HONORARIOS",
       ROUND(MIN(a.honorario),0) AS "HONORARIO_MINIMO",
       ROUND(MAX(a.honorario),0) AS "HONORARIO_MAXIMO"
FROM profesional p
JOIN asesoria a
     ON a.id_profesional = p.id_profesional
JOIN profesion pr
     ON pr.cod_profesion = p.cod_profesion
JOIN comuna c
     ON c.cod_comuna = p.cod_comuna
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 4      -- Abril
  AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY 
       p.id_profesional,
       p.appaterno, p.apmaterno, p.nombre,
       pr.nombre_profesion,
       c.nom_comuna
ORDER BY p.id_profesional;

-- Descomentar en caso de querer borrar la tabla REPORTE_MES
DROP TABLE REPORTE_MES PURGE; */

-- Creación de la tabal Reporte_Mes (si no existe previamente)
CREATE TABLE REPORTE_MES (
    ID_PROF       NUMBER(10),
    NOMBRE_COMPLETO      VARCHAR2(100),
    NOMBRE_PROFESION     VARCHAR2(40),
    NOM_COMUNA           VARCHAR2(40),
    NRO_ASESORIAS        NUMBER(5),
    MONTO_TOTAL_HONORARIOS NUMBER(12),
    PROMEDIO_HONORARIO    NUMBER(12),
    HONORARIO_MINIMO      NUMBER(12),
    HONORARIO_MAXIMO      NUMBER(12)
);

-- Limpieza del reporte mensual previo (en caso de que existiera)
DELETE FROM REPORTE_MES;

-- Insert con agrupación y EXTRACT para seleccionar abril del año pasado
INSERT INTO REPORTE_MES
SELECT
       p.id_profesional AS "ID_PROF",
       INITCAP(p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre) AS nombre_completo,
       INITCAP(pr.nombre_profesion) AS "NOMBRE_PROFESION",
       INITCAP(c.nom_comuna) AS "NOM_COMUNA",
       COUNT(a.honorario) AS nro_asesorias,
       ROUND(SUM(a.honorario),0) AS "MONTO_TOTAL_HONORARIOS",
       ROUND(AVG(a.honorario),0) AS "PROMEDIO_HONORARIO",
       ROUND(MIN(a.honorario),0) AS "HONORARIO_MINIMO",
       ROUND(MAX(a.honorario),0) AS "HONORARIO_MAXIMO"
FROM profesional p
JOIN asesoria a
     ON a.id_profesional = p.id_profesional
JOIN profesion pr
     ON pr.cod_profesion = p.cod_profesion
JOIN comuna c
     ON c.cod_comuna = p.cod_comuna
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 4      -- Abril
  AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY 
       p.id_profesional,
       p.appaterno, p.apmaterno, p.nombre,
       pr.nombre_profesion,
       c.nom_comuna
ORDER BY p.id_profesional;

COMMIT;

-- Mostrar tabla creada
SELECT * FROM REPORTE_MES;


/*******************************************************************************************
    CASO 3 – MODIFICACIÓN DE SUELDOS SEGÚN HONORARIOS (MARZO AÑO PASADO)
    ---------------------------------------------------------------------
    Objetivo:
      - Incentivar a profesionales según honorarios obtenidos en marzo del año anterior.
      - Si sumatoria < $1.000.000 → aumento 10%.
      - Si sumatoria ≥ $1.000.000 → aumento 15%.
********************************************************************************************/

-- 1) CONSULTA ANTES DE LA ACTUALIZACIÓN
--    Muestra honorarios de marzo del año pasado y sueldo actual antes del cambio.
--    El año está parametrizado con una función.

SELECT
       SUM(a.honorario) AS honorario,
       p.id_profesional,
       p.numrun_prof,
       p.sueldo
FROM profesional p
JOIN asesoria a 
     ON a.id_profesional = p.id_profesional
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
  AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY p.id_profesional, p.numrun_prof, p.sueldo
ORDER BY p.id_profesional;


--------------------------------------------------------------------------------------------
-- 2) ACTUALIZACIÓN DE SUELDOS
--    El CASE define el nuevo sueldo.
--    El WHERE filtra solo profesionales con asesorías en marzo del año pasado.
--------------------------------------------------------------------------------------------
/* 
-- Primero revisamos la lógica de la consulta

SELECT 
    p.id_profesional,
    p.numrun_prof,
    p.sueldo AS sueldo_actual,
    -- Total de honorarios en marzo del año pasado
    (
        SELECT NVL(SUM(a.honorario),0)
        FROM asesoria a
        WHERE a.id_profesional = p.id_profesional
          AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
          AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
    ) AS total_honorarios_marzo_anterior,
    -- Cálculo de el nuevo sueldo usando el mismo CASE del UPDATE
    CASE 
        WHEN (
            SELECT NVL(SUM(a.honorario),0)
            FROM asesoria a
            WHERE a.id_profesional = p.id_profesional
              AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
              AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
        ) < 1000000 
            THEN p.sueldo * 1.10
        ELSE p.sueldo * 1.15
    END AS sueldo_calculado
FROM profesional p
-- Filtrar solo profesionales con asesorías en marzo del año anterior
WHERE p.id_profesional IN (
      SELECT id_profesional
      FROM asesoria
      WHERE EXTRACT(MONTH FROM fin_asesoria) = 3
        AND EXTRACT(YEAR  FROM fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
)
ORDER BY p.id_profesional;
-- */

-- Actualizar los datos
-- Usaremos el CASE anterior dentro del SET para el sueldo.

UPDATE profesional p
SET sueldo = CASE 
                WHEN (
                    SELECT SUM(a.honorario)
                    FROM asesoria a
                    WHERE a.id_profesional = p.id_profesional
                      AND EXTRACT(MONTH FROM a.fin_asesoria) = 3
                      AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
                ) < 1000000 THEN p.sueldo * 1.10
                ELSE p.sueldo * 1.15
             END
WHERE p.id_profesional IN (
      SELECT id_profesional
      FROM asesoria
      WHERE EXTRACT(MONTH FROM fin_asesoria) = 3
        AND EXTRACT(YEAR  FROM fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
);

COMMIT;

--------------------------------------------------------------------------------------------
-- 3) CONSULTA DESPUÉS DE LA ACTUALIZACIÓN
--    Verifica el cambio mostrando sueldo actualizado y honorarios del periodo evaluado.
--------------------------------------------------------------------------------------------

SELECT
       SUM(a.honorario) AS honorario,
       p.id_profesional,
       p.numrun_prof,
       p.sueldo
FROM profesional p
JOIN asesoria a 
     ON a.id_profesional = p.id_profesional
WHERE EXTRACT(MONTH FROM a.fin_asesoria) = 3
  AND EXTRACT(YEAR  FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY p.id_profesional, p.numrun_prof, p.sueldo
ORDER BY p.id_profesional;
