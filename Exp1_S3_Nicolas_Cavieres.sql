/*
================================================================================
*
* Sumativa 1 - Semana 3
* Usuario PRY2205_S3
*
================================================================================
*/

-- CASO 1
-- Listado de Clientes con Rango de Renta

DEFINE RENTA_MINIMA = 190000;
DEFINE RENTA_MAXIMA = 1200000;

SELECT
    -- Formatea el RUT con puntos y guion (ej: 12.947.165-6)
    SUBSTR(TO_CHAR(numrut_cli), 1, 2) || '.' ||
    SUBSTR(TO_CHAR(numrut_cli), 3, 3) || '.' ||
    SUBSTR(TO_CHAR(numrut_cli), 6, 3) || '-' || dvrut_cli AS "RUT Cliente",
    
    -- Nombre completo del cliente
    INITCAP(nombre_cli || ' ' || appaterno_cli || ' ' || apmaterno_cli) AS "Nombre Completo Cliente",
    
    -- Dirección del cliente
    direccion_cli AS "Dirección Cliente",
    
    -- Renta formateada con símbolo $ y puntos como separadores de miles
    '$' || TO_CHAR(renta_cli, 'FM999G999G999') AS "Renta Cliente",
    
    -- Número de celular del cliente formateado como XX-XXX-XXXX
    SUBSTR(TO_CHAR(celular_cli), 1, 2) || '-' ||
    SUBSTR(TO_CHAR(celular_cli), 3, 3) || '-' ||
    SUBSTR(TO_CHAR(celular_cli), 6, 4) AS "N Celular Cliente",
    
    -- Clasificación por tramos de renta
    CASE
        WHEN renta_cli > 500000 THEN 'TRAMO 1'
        WHEN renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END AS "Tramo Renta Cliente"
FROM
    cliente
WHERE
    renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
    AND celular_cli IS NOT NULL
ORDER BY
    "Nombre Completo Cliente" ASC;


-- CASO 2
-- Sueldo Promedio por Categoría de Empleado

DEFINE SUELDO_PROMEDIO_MINIMO = 1100000;

SELECT
    -- Código de categoría del empleado
    id_categoria_emp AS "CODIGO_CATEGORIA",
    
    -- Descripción de la categoría del empleado
    CASE id_categoria_emp
        WHEN 1 THEN 'Gerente'
        WHEN 2 THEN 'Supervisor'
        WHEN 3 THEN 'Ejecutivo de Arriendo'
        WHEN 4 THEN 'Auxiliar'
    END AS "DESCRIPCION_CATEGORIA",
    
    -- Cantidad de empleados en esa categoría y sucursal
    COUNT(*) AS "CANTIDAD_EMPLEADOS",
    
    -- Descripción de la sucursal
    CASE id_sucursal
        WHEN 10 THEN 'Sucursal Las Condes'
        WHEN 20 THEN 'Sucursal Santiago Centro'
        WHEN 30 THEN 'Sucursal Providencia'
        WHEN 40 THEN 'Sucursal Vitacura'
    END AS "SUCURSAL",
    
    -- Sueldo promedio formateado con símbolo $ y separadores de miles
    '$' || TO_CHAR(ROUND(AVG(sueldo_emp)), 'FM999G999G999') AS "SUELDO_PROMEDIO"
FROM
    empleado
GROUP BY
    id_categoria_emp,
    id_sucursal
HAVING
    AVG(sueldo_emp) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY
    AVG(sueldo_emp) DESC;


-- CASO 3
-- Arriendo Promedio por Tipo de Propiedad

DEFINE VALOR_ARRIENDO_M2_MINIMO = 1000;

SELECT
    -- Código del tipo de propiedad
    id_tipo_propiedad AS "CODIGO_TIPO",
    
    -- Descripción del tipo de propiedad
    CASE id_tipo_propiedad
        WHEN 'A' THEN 'CASA'
        WHEN 'B' THEN 'DEPARTAMENTO'
        WHEN 'C' THEN 'LOCAL'
        WHEN 'D' THEN 'PARCELA SIN CASA'
        WHEN 'E' THEN 'PARCELA CON CASA'
    END AS "DESCRIPCION_TIPO",
    
    -- Total de propiedades de ese tipo
    COUNT(*) AS "TOTAL_PROPIEDADES",
    
    -- Promedio de valor de arriendo formateado
    '$' || TO_CHAR(ROUND(AVG(valor_arriendo)), 'FM999G999G999') AS "PROMEDIO_ARRIENDO",
    
    -- Promedio de superficie con 2 decimales
    TO_CHAR(ROUND(AVG(superficie), 2), 'FM999G999G990D00') AS "PROMEDIO_SUPERFICIE",
    
    -- Valor de arriendo por m2 formateado
    '$' || TO_CHAR(ROUND(AVG(valor_arriendo / superficie)), 'FM999G999') AS "VALOR_ARRIENDO_M2",
    
    -- Clasificación según valor de arriendo por m2
    CASE
        WHEN AVG(valor_arriendo / superficie) < 5000 THEN 'Económico'
        WHEN AVG(valor_arriendo / superficie) BETWEEN 5000 AND 10000 THEN 'Medio'
        ELSE 'Alto'
    END AS "CLASIFICACION"
FROM
    propiedad
GROUP BY
    id_tipo_propiedad
HAVING
    AVG(valor_arriendo / superficie) > &VALOR_ARRIENDO_M2_MINIMO
ORDER BY
    AVG(valor_arriendo / superficie) DESC;




