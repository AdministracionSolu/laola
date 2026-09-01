#!/usr/bin/env python3
"""Destila los respaldos semanales de La Ola a una base histórica.

Convierte una carpeta de zips de Soft Restaurant en filas dentro de
~/Desktop/LA-OLA-DATOS/laola-historico.db, y deja el crudo comprimido.

Uso:
    ./destilar.py ~/Downloads/"La Ola - 1 de septiembre"
    ./destilar.py <carpeta> --perfil nucleo     # sólo dinero + forense
    ./destilar.py <carpeta> --conservar-vm      # no borrar Colima al final
    ./destilar.py <carpeta> --solo-inventario   # no restaura nada, sólo lista

Lo que hace, en orden:
  1. Revisa que quepa en disco.
  2. Levanta Colima + SQL Server 2022 (bajo Rosetta).
  3. Por cada zip: restaura, IDENTIFICA la sucursal y el día real, extrae.
  4. Borra el .bak descomprimido y suelta la base del contenedor.
  5. Apaga y BORRA la VM. Ese último paso es el que costó 14 GB por no hacerlo.

Reglas que este script respeta y que costó caro descubrir:
  - El nombre del archivo MIENTE. `SR11-22-8` tomado a las 00:10 es la noche
    del 21. La fecha real sale de control.ini y de MAX(fecha) en cheques.
  - Hay DOS respaldos distintos llamados `SR11-<día>-8`: Valle (~227 MB) y
    Las Brisas (~132 MB). Se distinguen por idestacion, nunca por nombre.
  - Nada se sobreescribe: cada respaldo es una observación. Que Valle encoja
    entre un respaldo y el siguiente es el hallazgo, no un error a corregir.
"""

import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import zipfile
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
import mssql  # noqa: E402
import tablas as T  # noqa: E402

RAIZ = Path(__file__).resolve().parent
BASE_DESTINO = Path.home() / "Desktop" / "LA-OLA-DATOS" / "laola-historico.db"
ESQUEMA = RAIZ / "esquema.sql"
IMAGEN = "mcr.microsoft.com/mssql/server:2022-latest"
LOTE = 5000
ESPACIO_MINIMO_GB = 12


# ---------------------------------------------------------------- utilidades
def log(msg, nivel="·"):
    print(f"  {nivel} {msg}", flush=True)


def paso(msg):
    print(f"\n\033[1m{msg}\033[0m", flush=True)


def sh(args, timeout=1800, check=True, silencioso=True):
    p = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if check and p.returncode != 0:
        raise RuntimeError(f"falló {' '.join(args[:3])}: "
                           f"{(p.stderr or p.stdout or '')[:400]}")
    if not silencioso and p.stdout:
        print(p.stdout)
    return p


EN_MAC = sys.platform == "darwin"


def gb_libres():
    # En la Mac el volumen de datos va aparte del de sistema; en Linux basta /.
    ruta = "/System/Volumes/Data" if EN_MAC else "/"
    st = os.statvfs(ruta)
    return st.f_bavail * st.f_frsize / 1e9


def md5_de(ruta, tope=None):
    h = hashlib.md5()
    with open(ruta, "rb") as f:
        while True:
            d = f.read(8 * 1024 * 1024)
            if not d:
                break
            h.update(d)
    return h.hexdigest()


# ------------------------------------------------------------------- entorno
def colima_arriba():
    # OJO: `colima status` escribe "colima is not running", así que buscar la
    # subcadena "running" da verdadero justo cuando está apagada. Manda el
    # código de salida, que es 0 sólo si la instancia está viva.
    p = sh(["colima", "status"], check=False)
    txt = ((p.stdout or "") + (p.stderr or "")).lower()
    return p.returncode == 0 and "not running" not in txt


def levantar_entorno():
    paso("1. Preparando el entorno")

    libres = gb_libres()
    log(f"disco libre: {libres:.1f} GB")
    if libres < ESPACIO_MINIMO_GB:
        raise SystemExit(
            f"\n  ALTO: sólo {libres:.1f} GB libres, se necesitan "
            f"{ESPACIO_MINIMO_GB}.\n  Libera espacio antes de seguir "
            f"(la VM sola pide ~5 GB y cada respaldo restaurado otro tanto).")

    # Colima sólo existe en la Mac: es la VM que le da un Linux a Docker. En un
    # servidor Linux (el droplet del martes) Docker corre nativo y además SQL
    # Server es amd64 de verdad, sin Rosetta, así que va bastante más rápido.
    if not EN_MAC:
        log("Linux: Docker nativo, sin Colima")
    elif colima_arriba():
        log("Colima ya estaba corriendo")
    else:
        log("levantando Colima (toma 1-3 min)...")
        sh(["colima", "start", "--cpu", "4", "--memory", "6", "--disk", "40",
            "--vm-type", "vz", "--vz-rosetta"], timeout=900)
        log("Colima arriba")

    p = sh(["docker", "ps", "-a", "--filter", f"name={mssql.CONTENEDOR}",
            "--format", "{{.Names}} {{.State}}"], check=False)
    estado = (p.stdout or "").strip()

    if estado.startswith(mssql.CONTENEDOR):
        if "running" not in estado:
            log("contenedor existía apagado, encendiéndolo")
            sh(["docker", "start", mssql.CONTENEDOR])
        else:
            log("SQL Server ya estaba corriendo")
    else:
        log("bajando y arrancando SQL Server 2022 (la primera vez tarda)...")
        args = ["docker", "run", "-d", "--name", mssql.CONTENEDOR]
        if EN_MAC:
            # Apple Silicon: la imagen es amd64 y corre bajo Rosetta.
            args += ["--platform", "linux/amd64"]
        args += ["-e", "ACCEPT_EULA=Y",
                 "-e", f"MSSQL_SA_PASSWORD={mssql.SA_PASS}",
                 "-e", "MSSQL_PID=Developer",
                 "-p", "1433:1433", IMAGEN]
        sh(args, timeout=1800)

    log("esperando a que SQL Server acepte conexiones...")
    ultimo = ""
    for i in range(120):  # 10 min: el primer arranque bajo Rosetta es lento
        try:
            if mssql.escalar("SELECT 1"):
                log("SQL Server listo")
                return
        except Exception as e:
            ultimo = str(e)[:200]
        time.sleep(5)
    raise SystemExit(f"  SQL Server no respondió en 10 minutos.\n  Último error: {ultimo}")


def cerrar_entorno(conservar):
    paso("5. Cerrando")
    if conservar:
        log("--conservar-vm: la VM se queda. Acuérdate de `colima delete -f`.",
            "!")
        return
    try:
        sh(["docker", "rm", "-f", mssql.CONTENEDOR], check=False)
        log("contenedor eliminado")
    except Exception:
        pass
    if not EN_MAC:
        # En el droplet no hay VM que borrar: la máquina entera se destruye
        # al terminar, que es la versión buena de este mismo cuidado.
        log("Linux: no hay VM local que borrar")
        return
    sh(["colima", "stop"], check=False, timeout=300)
    sh(["colima", "delete", "-f"], check=False, timeout=300)
    # colima delete deja huérfano el disco de datos: eso fue lo que ocupó 13 GB
    huerfano = Path.home() / ".colima" / "_lima" / "_disks"
    if huerfano.exists():
        for d in huerfano.iterdir():
            shutil.rmtree(d, ignore_errors=True)
    log(f"VM borrada. Disco libre ahora: {gb_libres():.1f} GB")


# ---------------------------------------------------------------- identidad
def leer_control_ini(zf):
    for n in zf.namelist():
        if n.lower().endswith("control.ini"):
            txt = zf.read(n).decode("latin-1", "replace")
            for linea in txt.splitlines():
                if linea.lower().startswith("fecha"):
                    return linea.split("=", 1)[-1].strip()
    return None


def identificar(base, conn):
    """Quién es este respaldo, según sus datos y no según su nombre."""
    info = {}

    est = []
    try:
        out = mssql.sqlcmd(
            "SET NOCOUNT ON; SELECT DISTINCT LTRIM(RTRIM(idestacion)) "
            "FROM turnos WHERE idestacion IS NOT NULL", base=base)
        for l in out.splitlines():
            t = l.strip()
            if t and not t.startswith("(") and t != "NULL":
                est.append(t)
    except Exception as e:
        log(f"no se pudieron leer estaciones: {e}", "!")
    info["estaciones"] = ",".join(sorted(set(est)))

    # La sucursal se resuelve por estación contra el diccionario de la base.
    suc = None
    if est:
        mapa = dict(conn.execute(
            "SELECT estacion, sucursal FROM sucursales").fetchall())
        votos = [mapa[e] for e in est if e in mapa]
        if votos:
            suc = max(set(votos), key=votos.count)
    info["sucursal"] = suc

    info["fecha_max_cheque"] = mssql.escalar(
        "SET NOCOUNT ON; SELECT CONVERT(varchar(19), MAX(fecha), 120) FROM cheques",
        base=base)
    try:
        info["cheques_totales"] = int(mssql.escalar(
            "SET NOCOUNT ON; SELECT COUNT(*) FROM cheques WHERE cancelado=0",
            base=base) or 0)
    except (TypeError, ValueError):
        info["cheques_totales"] = None
    try:
        info["venta_total"] = float(mssql.escalar(
            "SET NOCOUNT ON; SELECT ISNULL(SUM(total),0) FROM cheques "
            "WHERE cancelado=0", base=base) or 0)
    except (TypeError, ValueError):
        info["venta_total"] = None

    # El día de negocio rueda a las 4 AM: un cheque de las 02:00 pertenece al
    # día anterior. Por eso el día cubierto se calcula restando 4 horas.
    dia = mssql.escalar(
        "SET NOCOUNT ON; SELECT CONVERT(varchar(10), "
        "DATEADD(hour,-4,MAX(fecha)), 120) FROM cheques", base=base)
    info["dia_cubierto"] = dia
    return info


# --------------------------------------------------------------- extracción
def asegurar_tabla(conn, nombre, columnas):
    """Crea la tabla si no existe; si aparecieron columnas nuevas, las añade.

    Soft Restaurant cambia columnas entre SR10, SR11 y SR12. La tabla local es
    la unión de todo lo visto, para que un respaldo viejo no tumbe uno nuevo.
    """
    cur = conn.execute(f"PRAGMA table_info([{nombre}])")
    existentes = {r[1].lower() for r in cur.fetchall()}
    if not existentes:
        cols = ", ".join(f"[{c}]" for c in columnas)
        conn.execute(
            f"CREATE TABLE [{nombre}] (respaldo_id INTEGER NOT NULL, "
            f"sucursal TEXT, {cols})")
        conn.execute(
            f"CREATE INDEX [ix_{nombre}_resp] ON [{nombre}](respaldo_id)")
        return
    for c in columnas:
        if c.lower() not in existentes:
            conn.execute(f"ALTER TABLE [{nombre}] ADD COLUMN [{c}]")


def extraer_tabla(conn, base, tabla, respaldo_id, sucursal, corte=None):
    if tabla in T.LISTA_NEGRA:
        return ("omitida", 0, 0, "en lista negra")

    cols = mssql.columnas_de(tabla, base)
    if not cols:
        return ("ausente", 0, 0, "no existe en esta versión")

    donde = T.filtro(tabla, corte) if corte else None
    total = mssql.contar(tabla, base, donde=donde)
    if total == 0:
        asegurar_tabla(conn, tabla, cols)
        return ("vacia", 0, len(cols), "ventana sin filas" if donde else None)

    aviso = None
    if not donde and total > T.AVISAR_SI_PASA_DE:
        aviso = (f"{total:,} filas sin filtro de ventana: ponle uno en "
                 f"FILTRO_VENTANA o la base va a crecer de más")

    asegurar_tabla(conn, tabla, cols)
    sel = "SELECT " + ", ".join(f"[{c}]" for c in cols) + f" FROM [{tabla}]"
    if donde:
        sel += f" WHERE {donde}"

    puestas = 0
    offset = 0
    while offset < total:
        filas = mssql.json_lote(sel, base, offset, LOTE)
        if not filas:
            break
        destino = ["respaldo_id", "sucursal"] + cols
        marcas = ",".join("?" * len(destino))
        sql = (f"INSERT INTO [{tabla}] "
               f"({','.join('[' + c + ']' for c in destino)}) VALUES ({marcas})")
        datos = []
        for f in filas:
            fila = [respaldo_id, sucursal]
            for c in cols:
                v = f.get(c)
                if isinstance(v, (dict, list)):
                    v = json.dumps(v, ensure_ascii=False)
                fila.append(v)
            datos.append(fila)
        conn.executemany(sql, datos)
        puestas += len(datos)
        offset += LOTE
    conn.commit()
    return ("ok", puestas, len(cols), aviso)


# ------------------------------------------------------------------ proceso
def restaurar(bak_local, base):
    destino = f"/tmp/{base}.bak"
    # TRAMPA: el -v de Colima no llega desde fuera de $HOME. Va por docker cp.
    sh(["docker", "cp", str(bak_local), f"{mssql.CONTENEDOR}:{destino}"],
       timeout=3600)

    out = mssql.sqlcmd(f"RESTORE FILELISTONLY FROM DISK='{destino}'")
    logicos = []
    for l in out.splitlines():
        t = l.strip()
        if not t or t.startswith("(") or t.startswith("-"):
            continue
        primero = t.split()[0]
        if primero and primero.lower() not in ("logicalname",):
            logicos.append(primero)
    if len(logicos) < 2:
        raise RuntimeError(f"no pude leer los nombres lógicos: {out[:300]}")

    mueve = (f"MOVE '{logicos[0]}' TO '/var/opt/mssql/data/{base}.mdf', "
             f"MOVE '{logicos[1]}' TO '/var/opt/mssql/data/{base}.ldf'")
    mssql.sqlcmd(
        f"RESTORE DATABASE [{base}] FROM DISK='{destino}' WITH REPLACE, {mueve}",
        timeout=3600)
    sh(["docker", "exec", mssql.CONTENEDOR, "rm", "-f", destino], check=False)


def soltar(base):
    try:
        mssql.sqlcmd(f"ALTER DATABASE [{base}] SET SINGLE_USER WITH ROLLBACK "
                     f"IMMEDIATE; DROP DATABASE [{base}]")
    except Exception:
        pass


def procesar(zip_path, conn, perfil, tmpdir, ventana):
    nombre = zip_path.name
    paso(f"→ {nombre}")

    with zipfile.ZipFile(zip_path) as zf:
        baks = [i for i in zf.infolist() if i.filename.lower().endswith(".bak")]
        if not baks:
            log("el zip no trae .bak, se salta", "!")
            return None
        entrada = max(baks, key=lambda i: i.file_size)
        fecha_ini = leer_control_ini(zf)

        log(f"control.ini dice: {fecha_ini or 'sin fecha'}")
        log(f"descomprimiendo {entrada.file_size/1e6:.0f} MB...")
        bak_local = Path(tmpdir) / f"{zip_path.stem}.bak"
        with zf.open(entrada) as src, open(bak_local, "wb") as dst:
            shutil.copyfileobj(src, dst, 8 * 1024 * 1024)

    md5 = md5_de(bak_local)
    ya = conn.execute("SELECT respaldo_id, sucursal, dia_cubierto FROM respaldos "
                      "WHERE md5=?", (md5,)).fetchone()
    if ya:
        log(f"ya estaba cargado (respaldo #{ya[0]}, {ya[1]} {ya[2]}). Se salta.",
            "=")
        bak_local.unlink(missing_ok=True)
        return None

    base = "sr_" + md5[:10]
    try:
        log("restaurando en SQL Server...")
        restaurar(bak_local, base)

        info = identificar(base, conn)
        log(f"identificado: \033[1m{info['sucursal'] or 'SUCURSAL DESCONOCIDA'}\033[0m"
            f"  ·  día {info['dia_cubierto']}  ·  "
            f"{info['cheques_totales'] or 0} cuentas  ·  "
            f"${info['venta_total'] or 0:,.0f}")
        if info["sucursal"] is None:
            log(f"estaciones no reconocidas: {info['estaciones']}. "
                f"Añádelas a la tabla `sucursales`.", "!")
        if fecha_ini and info["dia_cubierto"]:
            d = info["dia_cubierto"]
            if fecha_ini.replace("/", "-") not in d:
                log(f"OJO: control.ini dice {fecha_ini} pero el último cheque "
                    f"es del {d}. Manda el cheque.", "!")

        cur = conn.execute(
            "INSERT INTO respaldos (md5, archivo, ruta_origen, version_sr, "
            " sucursal, estaciones, fecha_control_ini, fecha_max_cheque, "
            " dia_cubierto, cheques_totales, venta_total, bytes_bak) "
            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
            (md5, nombre, str(zip_path.parent),
             next((v for v in ("SR10", "SR11", "SR12") if v in nombre.upper()), None),
             info["sucursal"], info["estaciones"], fecha_ini,
             info["fecha_max_cheque"], info["dia_cubierto"],
             info["cheques_totales"], info["venta_total"],
             entrada.file_size))
        respaldo_id = cur.lastrowid
        conn.commit()

        # Primera vez de esta sucursal: se guarda TODA su historia. Después,
        # sólo la ventana: un día viejo ya no cambia y basta tenerlo una vez.
        corte = None
        if info["sucursal"]:
            visto = conn.execute(
                "SELECT COUNT(*) FROM respaldos WHERE sucursal=? AND "
                "respaldo_id<>?", (info["sucursal"], respaldo_id)).fetchone()[0]
            if visto and info["dia_cubierto"]:
                corte = conn.execute(
                    "SELECT date(?, ?)",
                    (info["dia_cubierto"], f"-{ventana} days")).fetchone()[0]

        lista = T.lista(perfil)
        if corte:
            log(f"ventana: sólo desde {corte} "
                f"(la historia de {info['sucursal']} ya está guardada)")
        else:
            log(f"primera carga de {info['sucursal'] or 'esta sucursal'}: "
                f"se guarda la historia completa")
        log(f"extrayendo {len(lista)} tablas...")
        resumen = {"ok": 0, "vacia": 0, "ausente": 0, "error": 0, "omitida": 0}
        filas_tot = 0
        for t in lista:
            try:
                estado, filas, ncols, det = extraer_tabla(
                    conn, base, t, respaldo_id, info["sucursal"], corte)
            except Exception as e:
                estado, filas, ncols, det = "error", 0, 0, str(e)[:300]
            resumen[estado] = resumen.get(estado, 0) + 1
            filas_tot += filas
            conn.execute(
                "INSERT OR REPLACE INTO carga_log "
                "(respaldo_id, tabla, filas, columnas, estado, detalle) "
                "VALUES (?,?,?,?,?,?)",
                (respaldo_id, t, filas, ncols, estado, det))
            if estado == "error":
                log(f"error en {t}: {det}", "!")
        conn.commit()
        log(f"{filas_tot:,} filas · {resumen['ok']} tablas con datos · "
            f"{resumen['vacia']} vacías · {resumen['ausente']} no existen"
            + (f" · \033[31m{resumen['error']} con error\033[0m"
               if resumen["error"] else ""))
        return respaldo_id
    finally:
        soltar(base)
        bak_local.unlink(missing_ok=True)


# -------------------------------------------------------------------- salida
def reporte(conn):
    paso("Cobertura de la base histórica")
    filas = conn.execute(
        "SELECT sucursal, desde, hasta, dias_con_dato, dias_del_rango, "
        "dias_faltantes FROM v_cobertura ORDER BY sucursal").fetchall()
    if not filas:
        print("  (base vacía)")
        return
    print(f"  {'Sucursal':<12} {'Desde':<11} {'Hasta':<11} {'Días':>5} "
          f"{'Rango':>6} {'Faltan':>7}")
    for s, d, h, dd, dr, df in filas:
        alerta = "  <-- Valle no se recupera" if (df and s == "Valle") else ""
        print(f"  {s or '?':<12} {d or '':<11} {h or '':<11} {dd:>5} "
              f"{dr:>6} {df:>7}{alerta}")

    reesc = conn.execute(
        "SELECT sucursal, dia, veces_respaldado, cuentas_desaparecidas,"
        " dinero_desaparecido FROM v_reescritura "
        "WHERE cuentas_desaparecidas > 0 ORDER BY dia DESC LIMIT 12"
    ).fetchall()
    if reesc:
        paso("Días que encogieron entre un respaldo y otro")
        print(f"  {'Sucursal':<12} {'Día':<12} {'Veces':>6} {'Cuentas':>8} "
              f"{'Dinero':>14}")
        for s, d, v, c, m in reesc:
            print(f"  {s:<12} {d:<12} {v:>6} {c:>8} {m or 0:>13,.0f}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("carpeta", help="carpeta con los zips de la semana")
    ap.add_argument("--perfil", default="completo",
                    choices=["nucleo", "forense", "completo"])
    ap.add_argument("--base", default=str(BASE_DESTINO))
    ap.add_argument("--ventana", type=int, default=21,
                    help="días hacia atrás que se recargan en cada respaldo "
                         "después del primero de esa sucursal (default 21). "
                         "La primera carga siempre trae la historia completa.")
    ap.add_argument("--conservar-vm", action="store_true")
    ap.add_argument("--solo-inventario", action="store_true")
    args = ap.parse_args()

    carpeta = Path(args.carpeta).expanduser()
    if not carpeta.is_dir():
        raise SystemExit(f"no existe la carpeta: {carpeta}")

    zips = sorted(p for p in carpeta.rglob("*.zip")
                  if any(k in p.name.upper() for k in ("SR10", "SR11", "SR12")))
    if not zips:
        raise SystemExit(f"no encontré zips de Soft Restaurant en {carpeta}")

    paso(f"Respaldos encontrados en {carpeta.name}")
    for z in zips:
        print(f"  {z.stat().st_size/1e6:7.0f} MB  {z.relative_to(carpeta)}")
    print(f"\n  {len(zips)} respaldos · "
          f"{sum(z.stat().st_size for z in zips)/1e9:.2f} GB comprimidos")

    if args.solo_inventario:
        return

    destino = Path(args.base).expanduser()
    destino.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(destino)
    # Las vistas se recrean siempre: así se pueden corregir en esquema.sql sin
    # migrar la base ni volver a destilar nada.
    for v in ("v_dia_por_respaldo", "v_dia_integro", "v_reescritura",
              "v_cobertura"):
        conn.execute(f"DROP VIEW IF EXISTS {v}")
    conn.executescript(ESQUEMA.read_text())
    conn.commit()

    t0 = time.time()
    levantar_entorno()
    nuevos = []
    try:
        paso(f"2-4. Destilando {len(zips)} respaldos")
        with tempfile.TemporaryDirectory(
                dir=str(destino.parent)) as tmp:
            for z in zips:
                try:
                    r = procesar(z, conn, args.perfil, tmp, args.ventana)
                    if r:
                        nuevos.append(r)
                except Exception as e:
                    log(f"FALLÓ {z.name}: {str(e)[:400]}", "!")
    finally:
        cerrar_entorno(args.conservar_vm)

    conn.execute("VACUUM")
    conn.commit()
    reporte(conn)
    conn.close()

    paso("Listo")
    mb = destino.stat().st_size / 1e6
    print(f"  {len(nuevos)} respaldos nuevos en la base")
    print(f"  base: {destino}  ({mb:.1f} MB)")
    print(f"  tiempo: {(time.time()-t0)/60:.1f} min")
    print(f"  disco libre: {gb_libres():.1f} GB")
    print(f"\n  Los zips NO se tocaron. Ya puedes archivarlos:")
    print(f"    mv {carpeta} ~/Desktop/LA-OLA-DATOS/crudo/")


if __name__ == "__main__":
    main()
