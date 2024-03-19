###########################
# CREACIÓN DE BD Y TABLAS #
###########################

# creamos la base de datos
CREATE SCHEMA fruta;

# nos situamos dentro de esta base de datos
USE fruta;

# creamos tabla con tipos de fruta
CREATE TABLE frutas (
	fruta_id TINYINT PRIMARY KEY,
    tipo_fruta VARCHAR(20) NOT NULL
);

# creamos tabla con marcas de fruta
CREATE TABLE marcas (
	marca_id TINYINT PRIMARY KEY,
    nom_marca VARCHAR(50) NOT NULL
);

# creamos tabla con proveedores de fruta
CREATE TABLE proveedores (
	proveedor_id TINYINT PRIMARY KEY,
    nom_proveedor VARCHAR(50) NOT NULL
);

# creamos tabla con clientes que compran fruta
CREATE TABLE clientes (
	cliente_id TINYINT PRIMARY KEY,
    nom_cliente VARCHAR(50) NOT NULL
);

# creamos la tabla de ventas de la empresa
CREATE TABLE ventas (
id INT PRIMARY KEY,
fruta_id TINYINT NOT NULL,
marca_id TINYINT NOT NULL,
proveedor_id TINYINT NOT NULL,
cliente_id TINYINT NOT NULL,
coste_inicial DECIMAL (4, 3) NOT NULL,
precio_venta DECIMAL (4, 3) DEFAULT NULL,
tiempo_recogida DATETIME NOT NULL,
tiempo_venta DATETIME DEFAULT NULL,
peso DECIMAL (6, 3) NOT NULL,
FOREIGN KEY (fruta_id) REFERENCES frutas(fruta_id),
FOREIGN KEY (marca_id) REFERENCES marcas(marca_id),
FOREIGN KEY (proveedor_id) REFERENCES proveedores(proveedor_id),
FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
);

# creamos tabla con numeros de lotes
CREATE TABLE numeros_lotes (
	id INT PRIMARY KEY,
    numero_lote VARCHAR(50) NOT NULL,
    imagen VARCHAR(50) NOT NULL,
    FOREIGN KEY (id) REFERENCES ventas(id)
);

###################
# KPI's DEL GUIÓN #
###################

# 1. Calcular la cuantía total de las distribuciones
SELECT COUNT(id) distribuciones FROM ventas;

# 2. Calcular la media diaria de la cuantía de las distribuciones
SELECT ROUND(AVG(dist_diaria)) AS media_diaria_de_distribuciones
FROM (
    SELECT COUNT(*) as dist_diaria
    FROM ventas
    GROUP BY DATE(tiempo_venta)
) subquery;

# 3. ¿Qué días del mes se han producido más distribuciones y cuántas?
SELECT DATE(tiempo_venta) dia, COUNT(id) AS distribuciones
FROM ventas
GROUP BY dia
ORDER BY distribuciones DESC 
LIMIT 10;

# 4. ¿A qué horas del día se producen más recogidas de alimentos y cuántas?
SELECT HOUR(tiempo_recogida) hora, COUNT(*) AS distribuciones
FROM ventas
GROUP BY hora
ORDER BY distribuciones DESC 
LIMIT 10;

# 5. ¿Cuáles son los 5 clientes que más dinero han gastado comprando la fruta y cuánto?
SELECT c.nom_cliente, ROUND(SUM(v.precio_venta)) AS gasto
FROM ventas v
JOIN clientes c ON v.cliente_id = c.cliente_id
GROUP BY c.nom_cliente
ORDER BY gasto DESC
LIMIT 5;

# 6. ¿Cuáles son los 5 clientes que menos dinero han gastado comprando la fruta y cuánto?
SELECT c.nom_cliente, ROUND(SUM(v.precio_venta)) AS gasto
FROM ventas v
JOIN clientes c ON v.cliente_id = c.cliente_id
GROUP BY c.nom_cliente
ORDER BY gasto 
LIMIT 5;

# 7. ¿Cuáles son los 10 proveedores que han recibido más dinero y cuánto?
SELECT p.nom_proveedor, ROUND(SUM(v.coste_inicial)) AS ganancias
FROM ventas v
JOIN proveedores p ON v.proveedor_id = p.proveedor_id
GROUP BY p.nom_proveedor
ORDER BY ganancias DESC
LIMIT 10;

# 8. ¿Cuáles son los 3 productos con mayor beneficio a lo largo del mes (aquellos que al restarle   
# al coste de venta el precio de compra se quedan con un mejor resultado) y cuál ha sido su balance?
SELECT f.tipo_fruta,  ROUND(SUM(v.precio_venta - v.coste_inicial)) AS beneficio
FROM ventas v
JOIN frutas f ON v.fruta_id = f.fruta_id
GROUP BY f.tipo_fruta
ORDER BY beneficio DESC
LIMIT 3;

# 9. ¿Cuáles son los 3 productos con peor beneficio a lo largo de todo el mes y cuál ha sido?
SELECT f.tipo_fruta,  ROUND(SUM(v.precio_venta - v.coste_inicial)) AS beneficio
FROM ventas v
JOIN frutas f ON v.fruta_id = f.fruta_id
GROUP BY f.tipo_fruta
ORDER BY beneficio 
LIMIT 3;

# 10. ¿Cuál es el precio de venta medio de cada fruta?
SELECT f.tipo_fruta,  ROUND(AVG(precio_venta), 2) AS precio_venta
FROM ventas v
JOIN frutas f ON v.fruta_id = f.fruta_id
GROUP BY f.tipo_fruta
ORDER BY precio_venta DESC;

# 11. Suponiendo que si no se dispone de información de venta se trata de una fruta  que no ha podido venderse   
# por haber sido dañada durante la distribución, ¿cuánta fruta de cada tipo ha sido dañada?
SELECT f.tipo_fruta, COUNT(*) AS fruta_dañada
FROM ventas v
LEFT JOIN frutas f ON f.fruta_id = v.fruta_id
WHERE v.tiempo_venta IS NULL
GROUP BY f.tipo_fruta
ORDER BY fruta_dañada DESC;

# 12. ¿Cuál ha sido la pérdida total de la fruta dañada?
SELECT ROUND(SUM(coste_inicial), 2) AS pérdida_total
FROM ventas v
WHERE v.tiempo_venta IS NULL
ORDER BY pérdida_total DESC;


# 13. ¿Cuál es la cuantía total de cada tipo de fruta que han comprado los 5 clientes que más dinero han gastado?
WITH top_clientes AS (
    SELECT c.nom_cliente, ROUND(SUM(v.precio_venta)) AS gasto
    FROM ventas v
    JOIN clientes c ON v.cliente_id = c.cliente_id
    GROUP BY c.nom_cliente
    ORDER BY gasto DESC
    LIMIT 5
)

SELECT c.nom_cliente, f.tipo_fruta, COUNT(*) AS cuantía_total
FROM ventas v
JOIN clientes c ON c.cliente_id = v.cliente_id
JOIN frutas f ON f.fruta_id = v.fruta_id
WHERE c.nom_cliente IN (SELECT nom_cliente FROM top_clientes)
GROUP BY c.nom_cliente, f.tipo_fruta;

# 14. Para cada producto, calcular el porcentaje de beneficio.
# porcentaje de beneficio = ((precio_venta - coste_inicial) / coste_inicial) * 100
SELECT f.tipo_fruta, ROUND(((SUM(precio_venta) - SUM(coste_inicial)) / SUM(coste_inicial)) * 100, 2) AS porcentaje_de_beneficio
FROM ventas v
JOIN frutas f ON v.fruta_id = f.fruta_id
GROUP BY f.tipo_fruta
ORDER BY porcentaje_de_beneficio DESC;

###################
## KPI's PROPIOS ##
###################

# 1. Cuantos compras hace un cliente en cada dia.
SELECT DATE(v.tiempo_venta) AS fecha, COUNT(v.id) AS compra_por_dia
FROM ventas v
GROUP BY  fecha
ORDER BY fecha;

# 2. Beneficio de cada fruta por dia
SELECT DATE(v.tiempo_venta) AS fecha, f.tipo_fruta, SUM(v.precio_venta) as beneficio_dia
FROM ventas v 
JOIN frutas f ON v.fruta_id = f.fruta_id
GROUP BY fecha, v.fruta_id
ORDER BY fecha;

#################
# 3.Tiempo promedio desde la recogida hasta la venta de cada fruta a cada proveedor.
SELECT f.tipo_fruta , SEC_TO_TIME(AVG( TIME_TO_SEC( TIMEDIFF( v.tiempo_venta, v.tiempo_recogida) ) ) ) AS tiempo_medio_recogida 
FROM ventas v
JOIN frutas f ON v.fruta_id = f.fruta_id
GROUP BY f.tipo_fruta;

##### TIMEDIFF -> devuelve la diferencia entre dos valores DATETIME en tipo TIME(expresado en segundos)
##### TIME_TO_SEC -> transforma valor tipo TIME a tipo numerico (para poder hacer la media)
##### SEC_TO_TIME -> pasa segundos(de tipo numerico) a HH:MM:SS (de tipo TIME)

# 4.Peso total (en gramos) de las frutas vendidas por dias.
SELECT DATE(v.tiempo_venta) as fecha, SUM(v.peso) as peso
FROM ventas v
GROUP BY fecha
ORDER BY fecha;

# 5.Los dias del mes en el que se obtiene mas beneficio
SELECT DATE(tiempo_venta) AS fecha, SUM(precio_venta - coste_inicial) AS beneficio_diario
FROM ventas
GROUP BY fecha
ORDER BY beneficio_diario DESC
limit 5;
