#!/usr/bin/env python3
"""Las cifras de la junta del martes, sacadas de la base histórica.

Uso:
    ./junta.py                      # la última semana con dato
    ./junta.py --desde 2026-08-18 --hasta 2026-08-24
    ./junta.py --cobertura          # sólo qué días tenemos y cuáles faltan
    ./junta.py --reescritura        # qué días encogieron (el chequeo obligatorio)

Reglas de lectura que este script ya aplica, y que NO hay que volver a discutir:
  - La venta sale de `cheques.total` con `cancelado=0`. Nunca de sumar renglones.
  - El día de negocio rueda a las 4 AM.
  - Se lee del respaldo MÁS TEMPRANO de cada día (el íntegro). Ver v_dia_integro.
  - Los ids se repiten entre sucursales: todo une por respaldo_id además de la llave.
  - `cheqdet.descuento` es PORCENTAJE, no importe.
  - Las cifras son MEDIDAS, sin escalar. El ajuste por canal se hace aparte y
    con las cifras de cortes, no aquí.
"""

import argparse
import sqlite3
from pathlib import Path

BASE = Path.home() / "Desktop" / "LA-OLA-DATOS" / "laola-historico.db"


def titulo(t):
    print(f"\n\033[1m{t}\033[0m")


def tabla(filas, encabezados, alineacion=None):
    if not filas:
        print("  (sin datos)")
        return
    anchos = [max(len(str(e)), max((len(str(f[i])) for f in filas), default=0))
              for i, e in enumerate(encabezados)]
    alineacion = alineacion or ["<"] * len(encabezados)
    linea = "  " + "  ".join(f"{e:{alineacion[i]}{anchos[i]}}"
                             for i, e in enumerate(encabezados))
    print(linea)
    print("  " + "  ".join("-" * a for a in anchos))
    for f in filas:
        print("  " + "  ".join(f"{str(v):{alineacion[i]}{anchos[i]}}"
                               for i, v in enumerate(f)))


def rango_por_defecto(conn):
    r = conn.execute("SELECT MAX(dia) FROM v_dia_integro").fetchone()
    if not r or not r[0]:
        raise SystemExit("La base está vacía. Corre destilar.py primero.")
    hasta = r[0]
    desde = conn.execute("SELECT date(?, '-6 days')", (hasta,)).fetchone()[0]
    return desde, hasta


def venta(conn, desde, hasta):
    titulo(f"Venta medida por sucursal y día  ({desde} a {hasta})")
    # v_dia_integro ya trae un renglón por (sucursal, día) con el respaldo
    # tomado más cerca de esa noche. No hay que volver a unir con `respaldos`:
    # `respaldos.cheques_totales` es el total del .bak entero (tres años), no
    # el del día.
    filas = conn.execute("""
        SELECT sucursal, dia, cuentas, ROUND(venta, 0),
               ROUND(venta / NULLIF(cuentas, 0), 0)
        FROM v_dia_integro
        WHERE dia BETWEEN ? AND ?
        ORDER BY sucursal, dia
    """, (desde, hasta)).fetchall()
    tabla([(a, b, f"{c:,}" if c else "0", f"{d:,.0f}" if d else "0",
            f"{e:,.0f}" if e else "-") for a, b, c, d, e in filas],
          ["Sucursal", "Día", "Cuentas", "Venta", "Ticket"],
          ["<", "<", ">", ">", ">"])

    tot = conn.execute("""
        SELECT sucursal, SUM(cuentas), ROUND(SUM(venta), 0)
        FROM v_dia_integro
        WHERE dia BETWEEN ? AND ?
        GROUP BY sucursal ORDER BY 3 DESC
    """, (desde, hasta)).fetchall()
    titulo("Total del periodo")
    tabla([(a, f"{b:,}" if b else "0", f"{c:,.0f}" if c else "0")
           for a, b, c in tot],
          ["Sucursal", "Cuentas", "Venta"], ["<", ">", ">"])
    print("\n  Cifras MEDIDAS, sin escalar. En Valle falta la mayoría del")
    print("  efectivo: el ajuste por canal se hace aparte, contra los cortes.")


def productos(conn, desde, hasta, n=15):
    titulo(f"Los {n} productos que más venden  ({desde} a {hasta})")
    try:
        # Se lee sólo del respaldo íntegro de cada día, y el renglón se ata a
        # su cuenta por `foliodet` (cheqdet NO tiene columna `folio`).
        # Los ids se repiten entre sucursales: todo une por respaldo_id.
        filas = conn.execute("""
            SELECT p.descripcion,
                   ROUND(SUM(d.cantidad), 0)            AS piezas,
                   ROUND(SUM(d.cantidad * d.precio), 0) AS importe
            FROM v_dia_integro v
            JOIN cheques c ON c.respaldo_id = v.respaldo_id
                          AND date(c.fecha, '-4 hours') = v.dia
                          AND c.cancelado = 0
            JOIN cheqdet d ON d.respaldo_id = c.respaldo_id
                          AND d.foliodet = c.folio
            LEFT JOIN productos p ON p.respaldo_id = d.respaldo_id
                                 AND p.idproducto = d.idproducto
            WHERE v.dia BETWEEN ? AND ?
            GROUP BY p.descripcion
            ORDER BY importe DESC LIMIT ?
        """, (desde, hasta, n)).fetchall()
    except sqlite3.OperationalError as e:
        print(f"  (no disponible: {e})")
        return
    tabla([(a or "?", f"{b:,.0f}", f"{c:,.0f}") for a, b, c in filas],
          ["Producto", "Piezas", "Importe"], ["<", ">", ">"])


def cobertura(conn):
    titulo("Cobertura: qué días tenemos")
    filas = conn.execute("SELECT * FROM v_cobertura ORDER BY sucursal").fetchall()
    tabla(filas, ["Sucursal", "Desde", "Hasta", "Días", "Rango", "Faltan"],
          ["<", "<", "<", ">", ">", ">"])
    huecos = [f for f in filas if f[5]]
    if huecos:
        print("\n  Un día que falte en Cervecería, Brisas o Solares SÍ se")
        print("  recupera pidiendo respaldo nuevo. Uno de Valle NO: se reescribe.")


def reescritura(conn):
    titulo("Días que encogieron entre un respaldo y el siguiente")
    filas = conn.execute("""
        SELECT sucursal, dia_cubierto, veces_respaldado,
               cheques_max, cheques_min, cuentas_desaparecidas,
               ROUND(venta_max - venta_min, 0)
        FROM v_reescritura
        ORDER BY cuentas_desaparecidas DESC, dia_cubierto DESC LIMIT 25
    """).fetchall()
    tabla([(a, b, c, d, e, f, f"{g:,.0f}" if g else "0")
           for a, b, c, d, e, f, g in filas],
          ["Sucursal", "Día", "Veces", "Máx", "Mín", "Perdidas", "Dinero"],
          ["<", "<", ">", ">", ">", ">", ">"])
    if filas:
        print("\n  Cervecería, Brisas y Solares deben salir en cero aquí.")
        print("  Si aparecen, algo cambió y hay que revisarlo.")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", default=str(BASE))
    ap.add_argument("--desde")
    ap.add_argument("--hasta")
    ap.add_argument("--cobertura", action="store_true")
    ap.add_argument("--reescritura", action="store_true")
    args = ap.parse_args()

    p = Path(args.base).expanduser()
    if not p.exists():
        raise SystemExit(f"no existe la base: {p}\nCorre destilar.py primero.")
    conn = sqlite3.connect(f"file:{p}?mode=ro", uri=True)

    if args.cobertura:
        cobertura(conn)
        return
    if args.reescritura:
        reescritura(conn)
        return

    desde = args.desde
    hasta = args.hasta
    if not (desde and hasta):
        desde, hasta = rango_por_defecto(conn)

    venta(conn, desde, hasta)
    productos(conn, desde, hasta)
    cobertura(conn)
    reescritura(conn)
    print()


if __name__ == "__main__":
    main()
