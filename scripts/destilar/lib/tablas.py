"""Qué se extrae de cada respaldo y por qué.

Cambiar esta lista es la forma de cambiar el alcance de la destilación.
Si una tabla no existe en una versión de Soft Restaurant, se marca 'ausente'
en carga_log y el proceso sigue: SR10, SR11 y SR12 no traen lo mismo.
"""

# El movimiento del dinero. Sin esto no hay análisis.
NUCLEO = [
    "cheques",            # la cuenta. La venta se toma de aquí con cancelado=0
    "cheqdet",            # el renglón. Une por foliodet, NO por folio
    "cheqpag",            # cómo se pagó cada cuenta
    "turnos",             # apertura/cierre. turnos.efectivo va NETO de retiros
    "movtoscaja",         # los retiros que ensucian turnos.efectivo
    "declaracioncajero",  # lo que el cajero declaró contra lo que el sistema dice
]

# El rastro de quién tocó qué. Es lo que permitió el forense de Solares.
FORENSE = [
    "bitacorasistema",    # tabla de oro: borrados, cancelaciones, reaperturas
    "cancela",            # productos borrados con motivo; conserva el original
    "logcambioprecios",
    "movsinvcancelados",
    "folios",
    "foliosfacturados",
]

# Para poder nombrar lo que se vendió.
CATALOGOS = [
    "productos", "grupos", "subgrupos", "grupossubgrupos",
    "meseros", "usuarios", "estaciones", "mesas",
    "formasdepago", "grupoformasdepago",
    "clientes", "descuentos", "conceptos",
]

# Costos y receta. El margen de bebida sale de aquí; el de cocina NO se publica
# porque los costos de insumo del POS están mal capturados.
COSTOS = [
    "costos",                          # la receta con cantidades, 493 productos
    "insumos", "insumosdetalle",
    "insumospresentaciones",
    "insumospresentacionesdetalle",    # de aquí sale el costo real de cerveza
]

# Compras, por si algún día llegan las facturas de proveedor.
COMPRAS = [
    "ordenescompras", "comprasmovtos", "proveedores",
    "cuentasporcobrarpagos", "gastosmovtos",
]

TODAS = NUCLEO + FORENSE + CATALOGOS + COSTOS + COMPRAS

# Tablas que jamás valen el espacio: fotos, huellas, logs de impresión.
LISTA_NEGRA = {
    "huellaclientes", "imagenes", "imagenesproductos", "monitoresproduccion",
    "sysdiagrams", "logimpresiones", "respaldos",
}

# Las que se extraen aunque estén vacías, porque su ausencia ES el dato.
SIEMPRE = set(NUCLEO) | {"bitacorasistema", "cancela"}


def lista(perfil="completo"):
    if perfil == "nucleo":
        return NUCLEO + ["bitacorasistema", "cancela", "productos", "grupos"]
    if perfil == "forense":
        return NUCLEO + FORENSE + CATALOGOS
    return TODAS


# ---------------------------------------------------------------- la ventana
#
# CADA RESPALDO TRAE TODA LA HISTORIA. Medido: un solo .bak de Solares trae
# 1,064 días (sep-2023 a ago-2026) y pesa 53 MB ya destilado. Cargar eso
# completo en cada respaldo daría ~22 GB al año, peor que el problema original.
#
# Por eso: la primera vez que se ve una sucursal se guarda TODA su historia;
# de ahí en adelante sólo los últimos N días, que es donde ocurre la
# reescritura de Valle y donde la comparación entre observaciones sirve de algo.
# Un día viejo ya no cambia, así que basta tenerlo una vez.
#
# La llave de cada filtro es cómo se ata esa tabla a una fecha. Ojo con las
# uniones: `cheqdet` NO tiene columna `folio`, se ata por `foliodet`.

FILTRO_VENTANA = {
    "cheques":            "fecha >= '{corte}'",
    "cheqdet":            "foliodet IN (SELECT folio FROM cheques WHERE fecha >= '{corte}')",
    "cheqpag":            "folio IN (SELECT folio FROM cheques WHERE fecha >= '{corte}')",
    "movtoscaja":         "fecha >= '{corte}'",
    "bitacorasistema":    "fecha >= '{corte}'",
    "cancela":            "fecha >= '{corte}'",
    "logcambioprecios":   "fecha >= '{corte}'",
    "movsinvcancelados":  "fecha >= '{corte}'",
    "turnos":             "apertura >= '{corte}'",
    "declaracioncajero":  "idturno IN (SELECT idturno FROM turnos WHERE apertura >= '{corte}')",
    "foliosfacturados":   "folio IN (SELECT folio FROM cheques WHERE fecha >= '{corte}')",
    "folios":             "folio IN (SELECT folio FROM cheques WHERE fecha >= '{corte}')",
    "comprasmovtos":      "fecha >= '{corte}'",
    "ordenescompras":     "fecha >= '{corte}'",
    "gastosmovtos":       "fecha >= '{corte}'",
}

# Sin filtro se cargan completas. Son catálogos y no crecen: si alguna pasa de
# aquí, el destilador lo avisa para que se le ponga filtro.
AVISAR_SI_PASA_DE = 50_000


def filtro(tabla, corte):
    """WHERE para la ventana, o None si la tabla se carga completa."""
    p = FILTRO_VENTANA.get(tabla)
    return p.format(corte=corte) if p else None
