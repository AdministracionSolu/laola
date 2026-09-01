"""Hablar con el SQL Server que corre dentro del contenedor.

No hay driver ODBC en la Mac, así que todo pasa por las herramientas de línea de
comandos dentro del contenedor. Hay dos caminos y NO son intercambiables:

  · `sqlcmd` para metadatos y escalares (nombres de tabla, conteos, fechas).
  · `bcp`    para los DATOS.

**Por qué bcp y no sqlcmd para los datos.** sqlcmd formatea la salida en
columnas y RELLENA CON ESPACIOS a la derecha. Cuando el JSON de una tabla se
parte en varias líneas, al reensamblarlas ese relleno queda metido DENTRO del
valor: una cadena de 3,000 caracteres regresa con 8,967. Peor todavía, el JSON
sigue siendo válido y `json.loads` lo acepta sin quejarse, así que los datos se
corrompen en silencio. Medido el 1-sep-2026.

bcp escribe el contenido tal cual, sin relleno ni columnas. Verificado: la misma
cadena de 3,000 regresa con 3,000, y `'dos  espacios'` conserva sus dos espacios.

Banderas que se pelean entre sí (todas descubiertas a golpes):
  · `-y` y `-W` son mutuamente excluyentes.
  · `-h` y `-y 0` son mutuamente excluyentes.
  · `-C` en sqlcmd18 es "confiar en el certificado"; en bcp18 esa bandera es `-u`
    y `-C` significa codepage. No son lo mismo aunque se escriban igual.
"""

import json
import subprocess

CONTENEDOR = "mssql"
SA_PASS = "LaOla#2026#Destilar"

BIN = "/opt/mssql-tools18/bin"
# -C aquí = trust server certificate (el contenedor usa autofirmado)
SQLCMD = [f"{BIN}/sqlcmd", "-S", "localhost", "-U", "sa", "-C"]
# -u aquí = trust server certificate; -C 65001 = codepage UTF-8
BCP = [f"{BIN}/bcp"]
BCP_CONN = ["-S", "localhost", "-U", "sa", "-c", "-C", "65001", "-u"]

RUTA_LOTE = "/tmp/lote_laola.json"


class ErrorSQL(RuntimeError):
    pass


def _exec(args, timeout=1800):
    # sin -i: no hay stdin que dar, y heredarlo cuelga el proceso en background
    return subprocess.run(["docker", "exec", CONTENEDOR] + args,
                          capture_output=True, text=True, timeout=timeout)


def sqlcmd(consulta, base=None, timeout=1800):
    """Consulta de metadatos. Devuelve stdout como texto, sin encabezados.

    Usa -W (recorta espacios), que es seguro AQUÍ porque los metadatos son
    cortos y de una sola línea. Nunca uses esta función para traer datos.
    """
    args = SQLCMD + ["-P", SA_PASS]
    if base:
        args += ["-d", base]
    args += ["-h", "-1", "-W", "-Q", consulta]
    p = _exec(args, timeout=timeout)
    salida = p.stdout or ""
    if p.returncode != 0:
        raise ErrorSQL(((p.stderr or "") + salida).strip()[:600])
    if "Msg " in salida and "Level 15" in salida:
        raise ErrorSQL(salida.strip()[:600])
    return salida


def _limpias(texto):
    for linea in texto.splitlines():
        t = linea.strip()
        if not t or t.startswith("(") or set(t) <= {"-"}:
            continue
        if "rows affected" in t:
            continue
        yield t


def escalar(consulta, base=None):
    """Primera celda del resultado, o None."""
    for t in _limpias(sqlcmd(consulta, base=base)):
        return None if t == "NULL" else t
    return None


def json_lote(consulta_select, base, offset, tam):
    """Un lote de filas como lista de dicts, vía bcp + FOR JSON PATH.

    `consulta_select` va SIN ORDER BY ni OFFSET: se los ponemos aquí.
    INCLUDE_NULL_VALUES conserva las columnas nulas, que importan para no
    perder el ancho real de la tabla.
    """
    q = (f"SET NOCOUNT ON; SELECT * FROM (SELECT * FROM ({consulta_select}) _q "
         f"ORDER BY (SELECT NULL) OFFSET {offset} ROWS FETCH NEXT {tam} ROWS ONLY"
         f") _p FOR JSON PATH, INCLUDE_NULL_VALUES")

    # bcp NO hereda la base de nada: sin -d busca las tablas en master y
    # responde "Invalid object name 'cheques'".
    args = BCP + [q, "queryout", RUTA_LOTE] + BCP_CONN + ["-P", SA_PASS]
    if base:
        args += ["-d", base]
    p = _exec(args, timeout=3600)
    if p.returncode != 0:
        raise ErrorSQL(((p.stderr or "") + (p.stdout or "")).strip()[:600])

    c = _exec(["cat", RUTA_LOTE], timeout=600)
    if c.returncode != 0:
        return []
    # Las líneas se concatenan SIN tocarlas: bcp no rellena, así que cualquier
    # espacio que venga aquí es parte del dato.
    crudo = "".join(c.stdout.split("\n")).strip()
    if not crudo or crudo == "NULL":
        return []
    try:
        return json.loads(crudo)
    except json.JSONDecodeError as e:
        raise ErrorSQL(f"JSON ilegible ({e}); primeros 200: {crudo[:200]}")


def tablas_de(base):
    """Nombres de tabla base que existen en la base."""
    q = ("SET NOCOUNT ON; SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES "
         "WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME")
    return list(_limpias(sqlcmd(q, base=base)))


# Tipos que no viajan a JSON ni sirven para análisis.
TIPOS_FUERA = {"image", "varbinary", "binary", "geography", "geometry",
               "xml", "timestamp", "sql_variant", "hierarchyid"}


def columnas_de(tabla, base):
    """Columnas de una tabla, en orden, saltando los tipos que no viajan."""
    q = ("SET NOCOUNT ON; SELECT COLUMN_NAME + '|' + DATA_TYPE "
         f"FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='{tabla}' "
         "ORDER BY ORDINAL_POSITION")
    cols = []
    for t in _limpias(sqlcmd(q, base=base)):
        if "|" not in t:
            continue
        nombre, tipo = t.rsplit("|", 1)
        if tipo.strip().lower() in TIPOS_FUERA:
            continue
        cols.append(nombre.strip())
    return cols


def contar(tabla, base, donde=None):
    q = f"SET NOCOUNT ON; SELECT COUNT(*) FROM [{tabla}]"
    if donde:
        q += f" WHERE {donde}"
    try:
        return int(escalar(q, base=base) or 0)
    except (TypeError, ValueError):
        return 0
