-- Base histórica de La Ola. Una fila por OBSERVACIÓN, no por hecho.
--
-- La regla que manda todo este diseño: Valle reescribe sus respaldos.
-- El mismo día visto desde el respaldo de esa noche y desde el de tres días
-- después NO trae lo mismo (desaparecen cuentas enteras y el efectivo se va a
-- cero). Por eso aquí NUNCA se sobreescribe: cada respaldo entra como una
-- observación con su propia identidad, y la comparación entre observaciones
-- del mismo día es justamente el dato forense.
--
-- Corolario práctico: el respaldo más temprano que cubre un día es el íntegro.
-- La vista `v_dia_integro` aplica esa regla; `v_reescritura` mide el recorte.

PRAGMA journal_mode = WAL;

-- ---------------------------------------------------------------- respaldos
CREATE TABLE IF NOT EXISTS respaldos (
  respaldo_id        INTEGER PRIMARY KEY AUTOINCREMENT,
  md5                TEXT    NOT NULL UNIQUE,  -- candado anti-recarga
  archivo            TEXT    NOT NULL,         -- nombre del zip como llegó
  ruta_origen        TEXT,
  version_sr         TEXT,                     -- SR10 / SR11 / SR12
  sucursal           TEXT,                     -- resuelta por idestacion
  estaciones         TEXT,                     -- los idestacion vistos, separados por coma
  fecha_control_ini  TEXT,                     -- lo que DICE control.ini
  fecha_max_cheque   TEXT,                     -- MAX(fecha) real de cheques  <- la buena
  dia_cubierto       DATE,                     -- día de negocio que este respaldo cierra
  cheques_totales    INTEGER,
  venta_total        REAL,
  bytes_bak          INTEGER,
  cargado_en         TEXT DEFAULT (datetime('now','localtime')),
  notas              TEXT
);

CREATE INDEX IF NOT EXISTS ix_resp_suc_dia ON respaldos(sucursal, dia_cubierto);

-- ------------------------------------------------------- control de carga
-- Deja rastro de qué tabla se extrajo de qué respaldo y cuántas filas.
-- Si una tabla falta en una versión de Soft Restaurant, aquí se ve.
CREATE TABLE IF NOT EXISTS carga_log (
  respaldo_id  INTEGER NOT NULL REFERENCES respaldos(respaldo_id),
  tabla        TEXT    NOT NULL,
  filas        INTEGER,
  columnas     INTEGER,
  estado       TEXT,      -- ok | vacia | ausente | error
  detalle      TEXT,
  PRIMARY KEY (respaldo_id, tabla)
);

-- ------------------------------------------------------------ diccionario
-- Los ids de Soft Restaurant se repiten entre sucursales. Toda unión necesita
-- respaldo_id (o sucursal) además de la llave, o los importes salen por tres.
CREATE TABLE IF NOT EXISTS sucursales (
  estacion   TEXT PRIMARY KEY,
  sucursal   TEXT NOT NULL,
  version_sr TEXT,
  nota       TEXT
);

INSERT OR IGNORE INTO sucursales (estacion, sucursal, version_sr, nota) VALUES
  ('CAJA',            'Cervecería', 'SR10', 'sale limpia todos los días, 98-100% de folios'),
  ('COMANDERO',       'Cervecería', 'SR10', NULL),
  ('SERVIDOR',        'Valle',      'SR11', 'REESCRIBE: el respaldo nocturno es la única copia íntegra'),
  ('COMANDERO3',      'Valle',      'SR11', NULL),
  ('DESKTOP-TD1FME9', 'Las Brisas', 'SR11', 'respaldo manual de la mañana, cortado al día anterior'),
  ('DESKTOP-GAHNHUM', 'Solares',    'SR12', 'entrega respaldo desde ago-2026');

-- ------------------------------------------------------------------ vistas
--
-- OJO: las vistas se recrean en cada corrida (destilar.py hace DROP antes de
-- aplicar este archivo), así que se pueden editar aquí sin migrar nada.
--
-- La unidad de comparación es el DÍA DE NEGOCIO, no el día del respaldo. Un
-- respaldo del 24 contiene también el 23, el 22 y los tres años anteriores; lo
-- que interesa es cómo se ve CADA día desde CADA respaldo. Agrupar por
-- `respaldos.dia_cubierto` no compara nada: cada respaldo tiene el suyo y
-- ningún grupo llega a dos.

-- Cada día de negocio tal como lo ve cada respaldo. Es la base de las demás.
-- El día rueda a las 4 AM: un cheque de las 02:00 pertenece al día anterior.
CREATE VIEW v_dia_por_respaldo AS
SELECT r.sucursal,
       r.respaldo_id,
       r.dia_cubierto                       AS dia_del_respaldo,
       date(c.fecha, '-4 hours')            AS dia,
       COUNT(*)                             AS cuentas,
       ROUND(SUM(c.total), 2)               AS venta
FROM cheques c
JOIN respaldos r ON r.respaldo_id = c.respaldo_id
WHERE c.cancelado = 0 AND c.fecha IS NOT NULL
GROUP BY r.sucursal, r.respaldo_id, date(c.fecha, '-4 hours');

-- El día en su versión MÁS COMPLETA. Fuente de cualquier cifra que se publique.
--
-- Se toma el respaldo con más cuentas, y esa sola regla resuelve los dos casos
-- opuestos: en Valle el más completo es el nocturno del mismo día (los de
-- después ya vienen recortados), y en las otras tres es uno posterior, porque
-- el respaldo tomado a media tarde deja el día a medias. Ordenar por cercanía
-- de fecha, como se hacía antes, elegía días truncados en Cervecería, Brisas y
-- Solares.
CREATE VIEW v_dia_integro AS
SELECT sucursal, dia, respaldo_id, dia_del_respaldo, cuentas, venta
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY sucursal, dia
           ORDER BY cuentas DESC,
                    julianday(dia_del_respaldo) - julianday(dia) ASC
         ) AS rn
  FROM v_dia_por_respaldo
)
WHERE rn = 1;

-- Reescritura DE VERDAD: un respaldo posterior que reporta MENOS cuentas para
-- el mismo día que uno anterior. Es decir, el día se encogió después de los
-- hechos.
--
-- OJO con lo que esta vista deliberadamente NO cuenta. Comparar simplemente el
-- máximo contra el mínimo del día mete un falso positivo grande: el respaldo
-- tomado durante el propio día trae el día a medias, así que sale "más chico"
-- sin que nadie haya editado nada. Con ese criterio Brisas y Solares aparecían
-- encogiendo 17-24 cuentas, contradiciendo que sólo Valle reescribe. Aquí un
-- día sólo cuenta si lo que vino DESPUÉS trae menos que lo que ya se había
-- visto.
CREATE VIEW v_reescritura AS
SELECT antes.sucursal,
       antes.dia,
       COUNT(DISTINCT despues.respaldo_id) + 1        AS veces_respaldado,
       MAX(antes.cuentas)                             AS cuentas_max,
       MIN(despues.cuentas)                           AS cuentas_min,
       MAX(antes.cuentas) - MIN(despues.cuentas)      AS cuentas_desaparecidas,
       ROUND(MAX(antes.venta) - MIN(despues.venta), 2) AS dinero_desaparecido,
       ROUND(100.0 * (MAX(antes.cuentas) - MIN(despues.cuentas))
             / MAX(antes.cuentas), 1)                 AS pct_perdido
FROM v_dia_por_respaldo antes
JOIN v_dia_por_respaldo despues
  ON  despues.sucursal = antes.sucursal
  AND despues.dia      = antes.dia
  AND despues.dia_del_respaldo > antes.dia_del_respaldo
  AND despues.cuentas  < antes.cuentas
GROUP BY antes.sucursal, antes.dia;

-- Qué días tenemos y cuáles faltan por sucursal. Un hueco en Valle no se
-- recupera pidiendo respaldo nuevo; en las otras tres sí.
CREATE VIEW v_cobertura AS
SELECT sucursal,
       MIN(dia) AS desde,
       MAX(dia) AS hasta,
       COUNT(DISTINCT dia) AS dias_con_dato,
       CAST(julianday(MAX(dia)) - julianday(MIN(dia)) + 1 AS INT) AS dias_del_rango,
       CAST(julianday(MAX(dia)) - julianday(MIN(dia)) + 1 AS INT)
         - COUNT(DISTINCT dia) AS dias_faltantes
FROM v_dia_por_respaldo
GROUP BY sucursal;
