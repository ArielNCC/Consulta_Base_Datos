/*
 * Autor: Nicolas Cavieres
 * Descripción: Consultas SQL para Experiencia 2 - Semana 4
 * Base de Datos: PRY2205_S4
 */

--------------------------------------------------------------------------------
-- CASO 1: LISTADO DE TRABAJADORES (FORMATO EXACTO SEGÚN FIGURA)
--------------------------------------------------------------------------------
SELECT
UPPER(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS "Nombre Completo Trabajador",
TO_CHAR(t.numrut, '99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
UPPER(tt.desc_categoria) AS "Tipo Trabajador",
UPPER(c.nombre_ciudad) AS "Ciudad Trabajador",
TO_CHAR(t.sueldo_base, 'FM$999G999G999') AS "Sueldo Base"
FROM trabajador t
LEFT JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
LEFT JOIN comuna_ciudad c ON t.id_ciudad = c.id_ciudad
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY c.nombre_ciudad DESC, t.sueldo_base ASC;


--------------------------------------------------------------------------------
-- CASO 2: LISTADO DE CAJEROS (FORMATO EXACTO SEGÚN FIGURA 3)
--------------------------------------------------------------------------------
SELECT
TO_CHAR(t.numrut, '99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
UPPER(t.nombre || ' ' || t.appaterno) AS "Nombre Trabajador",
COUNT(tc.nro_ticket) AS "Total Tickets",
TO_CHAR(SUM(tc.monto_ticket), 'FM$999G999G999') AS "Total Vendido",
TO_CHAR(SUM(NVL(ct.valor_comision,0)), 'FM$999G999G999') AS "Comisión Total",
UPPER(tt.desc_categoria) AS "Tipo Trabajador",
UPPER(c.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
JOIN comuna_ciudad c ON t.id_ciudad = c.id_ciudad
JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
LEFT JOIN comisiones_ticket ct ON tc.nro_ticket = ct.nro_ticket
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno, tt.desc_categoria, c.nombre_ciudad
HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC;


--------------------------------------------------------------------------------
-- CASO 3: LISTADO DE BONIFICACIONES
--------------------------------------------------------------------------------
SELECT
TO_CHAR(t.numrut, '99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
INITCAP(t.nombre || ' ' || t.appaterno) AS "Trabajador Nombre",
EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
(EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)) AS "Años Antigüedad",
NVL(cnt.cargas,0) AS "Num. Cargas Familiares",
INITCAP(i.nombre_isapre) AS "Nombre Isapre",
TO_CHAR(t.sueldo_base, 'FM$999G999G999') AS "Sueldo base",
CASE WHEN UPPER(i.nombre_isapre) = 'FONASA'
THEN TO_CHAR(ROUND(t.sueldo_base * 0.01), 'FM$999G999G999')
ELSE TO_CHAR(0, 'FM$999G999G999') END AS "Bono Fonasa",
CASE WHEN (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)) <= 10
THEN TO_CHAR(ROUND(t.sueldo_base * 0.10), 'FM$999G999G999')
ELSE TO_CHAR(ROUND(t.sueldo_base * 0.15), 'FM$999G999G999') END AS "Bono Antigüedad",
INITCAP(a.nombre_afp) AS "Nombre AFP",
UPPER(ec.desc_estcivil) AS "Estado Civil"
FROM trabajador t
JOIN isapre i ON t.cod_isapre = i.cod_isapre
JOIN afp a ON t.cod_afp = a.cod_afp
JOIN est_civil e ON t.numrut = e.numrut_t
JOIN estado_civil ec ON e.id_estcivil_est = ec.id_estcivil
LEFT JOIN (
SELECT numrut_t, COUNT(*) AS cargas
FROM asignacion_familiar
GROUP BY numrut_t
) cnt ON cnt.numrut_t = t.numrut
WHERE e.fecter_estcivil IS NULL OR e.fecter_estcivil > SYSDATE
ORDER BY t.numrut ASC;
--------------------------------------------------------------------------------