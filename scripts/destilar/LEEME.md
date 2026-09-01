# Destilador semanal de La Ola

Convierte los respaldos del POS que bajas cada semana en una base histórica que
pesa megas en vez de gigas, y deja el crudo comprimido.

El problema que resuelve: **hasta ahora el único lugar donde vivía el detalle
eran los `.bak`.** Por eso daba miedo borrarlos, y por eso el disco vivía al
95%. Julio quedó destilado en una base; agosto no, y sus tres semanas de
respaldos ocupaban 8.5 GB nada más porque no había dónde más guardarlos.

---

## El martes, en dos comandos

```bash
cd ~/laola/scripts/destilar

# 1. destilar lo que bajaste
./destilar.py ~/Downloads/"La Ola - 1 de septiembre"

# 2. las cifras de la junta
./junta.py
```

Al terminar, el script **borra la máquina virtual solo**. Ese paso es el que no
se hizo el 18 de agosto y costó 14 GB de disco durante dos semanas.

Después ya puedes archivar el crudo:

```bash
mv ~/Downloads/"La Ola - 1 de septiembre" ~/Desktop/LA-OLA-DATOS/crudo/
```

En el Escritorio iCloud lo sube y, cuando no lo uses, suelta la copia local:
el archivo sigue ahí y ocupa cero bytes en tu disco.

---

## Qué hace por dentro

1. **Revisa que quepa.** Si hay menos de 12 GB libres se detiene antes de
   empezar, en vez de morir a la mitad.
2. **Levanta Colima + SQL Server 2022** (amd64 bajo Rosetta; es la única forma
   de abrir un `.bak` en esta Mac).
3. **Por cada zip:** descomprime, `docker cp` al contenedor, restaura,
   **identifica**, extrae las tablas, suelta la base y borra el `.bak`.
4. **Apaga y borra la VM**, incluido el disco huérfano que `colima delete` deja
   atrás.

Los zips **no se tocan nunca**. Si algo sale mal, se vuelve a correr.

---

## Las tres reglas que este script protege

Costaron semanas de descubrir. Están metidas en el código para no volver a
tropezar con ellas.

### 1. El nombre del archivo miente

`SR11-22-8` tomado a las 00:10 es la noche del **21**. El respaldo corre cerca
de la medianoche y si se pasa queda con la fecha del día siguiente.

El script **nunca** usa el nombre para fechar. Usa `control.ini` y sobre todo
`MAX(fecha) FROM cheques`, y si los dos no coinciden lo avisa en pantalla.
Además resta 4 horas, porque el día del POS rueda a las 4 AM.

### 2. Hay dos respaldos distintos con el mismo nombre

`SR11-<día>-8` puede ser **Valle** (~227 MB, el nocturno) o **Las Brisas**
(~132 MB, el manual de la mañana). Mismo nombre de carpeta, contenido distinto.

La sucursal se resuelve leyendo `SELECT DISTINCT idestacion FROM turnos` y
cruzándolo contra la tabla `sucursales`:

| Estación | Sucursal | |
|---|---|---|
| `CAJA`, `COMANDERO` | Cervecería | sale limpia, 98-100% de folios |
| `SERVIDOR`, `COMANDERO3` | Valle | **reescribe** |
| `DESKTOP-TD1FME9` | Las Brisas | cortado al día anterior |
| `DESKTOP-GAHNHUM` | Solares | entrega desde ago-2026 |

Si aparece una estación desconocida, lo dice y te pide añadirla. No adivina.

### 3. Nada se sobreescribe

**Valle reescribe sus respaldos en menos de 24 horas.** El mismo día visto
desde el respaldo de esa noche y desde el de tres días después no trae lo
mismo: desaparecen cuentas enteras y el efectivo se va a cero.

Por eso cada respaldo entra como una **observación** con su propio
`respaldo_id`. Que un día encoja entre un respaldo y el siguiente **es el
hallazgo**, no un error que corregir.

- `v_dia_integro` — el respaldo más temprano de cada día. **De aquí salen las
  cifras que se publican.**
- `v_reescritura` — cuánto encogió cada día. Cervecería, Brisas y Solares deben
  dar cero aquí; si aparecen, algo cambió.
- `v_cobertura` — qué días tenemos y cuáles faltan.

---

## La ventana: por qué la base no crece sin control

**Cada respaldo trae toda la historia, no la semana.** Medido: un solo `.bak` de
Solares trae 1,064 días (sep-2023 a ago-2026) y pesa 53 MB ya destilado.
Guardarlo completo en cada respaldo daría ~22 GB al año — peor que el problema
que veníamos a resolver.

Por eso:

- La **primera vez** que se ve una sucursal se guarda **toda su historia**.
- De ahí en adelante, sólo los **últimos 21 días** (`--ventana N`).

Un día viejo ya no cambia, así que basta tenerlo una vez. La excepción es la
ventana reciente, que es justo donde Valle reescribe y donde comparar
observaciones del mismo día sirve de algo.

Resultado: ~220 MB una sola vez por la historia de las cuatro sucursales, y unos
8 MB por semana. **Del orden de 600 MB al año.**

Los catálogos (productos, grupos, meseros) se cargan completos siempre: son
chicos. Si alguna tabla sin filtro pasa de 50,000 filas, el destilador lo avisa
para que se le ponga uno en `FILTRO_VENTANA`.

---

## Qué se extrae

Definido en `lib/tablas.py`. Si una tabla no existe en esa versión de Soft
Restaurant se marca `ausente` en `carga_log` y el proceso sigue: SR10, SR11 y
SR12 no traen lo mismo.

- **Núcleo** — `cheques`, `cheqdet`, `cheqpag`, `turnos`, `movtoscaja`,
  `declaracioncajero`. El movimiento del dinero.
- **Forense** — `bitacorasistema` (la tabla de oro: borrados, cancelaciones,
  reaperturas), `cancela`, `logcambioprecios`, `folios`.
- **Catálogos** — para poder nombrar lo que se vendió.
- **Costos** — `costos` trae la receta con cantidades; el costo real de bebida
  sale de `insumospresentacionesdetalle`.

Perfiles: `--perfil nucleo` (rápido, sólo dinero) · `forense` · `completo` (por
defecto).

Las columnas **no están escritas a mano**: se leen del esquema de cada base y
la tabla local es la unión de todo lo visto. Así un cambio de versión de Soft
Restaurant no tumba la carga.

---

## Trampas de lectura

Ya están aplicadas en `junta.py`. Si escribes consultas propias, respétalas:

- La venta sale de **`cheques.total` con `cancelado=0`**. Nunca de sumar
  renglones.
- El renglón une por **`cheqdet.foliodet`**, no por `folio`.
- El turno une por **`idturno`**, no por `idturnointerno`.
- **`cheqdet.descuento` es PORCENTAJE, no importe.** Leerlo como importe
  duplica el descuento.
- **`turnos.efectivo` no es el efectivo cobrado**: va neto de los retiros de
  `movtoscaja`.
- `cheqdet.precio` trae IVA; `cheques.subtotal` no.
- **Los ids se repiten entre sucursales.** Toda unión necesita `respaldo_id`
  además de la llave, o los importes salen por tres.
- **`cheqdet` no tiene columna `folio`.** Se ata `cheques.folio = cheqdet.foliodet`.
  Escribirlo como `folio = folio` no falla: devuelve cero filas o basura.

---

## Consultar a mano

```bash
sqlite3 -header -column ~/Desktop/LA-OLA-DATOS/laola-historico.db "
  select sucursal, dia_cubierto, cheques_totales, round(venta_total) venta
  from respaldos r join v_dia_integro v using (respaldo_id)
  order by dia_cubierto desc limit 20;"
```

---

## Si algo falla

- **"sólo X GB libres"** — libera espacio. La VM pide ~5 GB y cada respaldo
  restaurado otro tanto.
- **Un respaldo falla y los demás siguen.** El script no aborta: lo reporta al
  final. Vuelve a correrlo, lo ya cargado se salta por MD5.
- **Se cortó a la mitad.** Corre `colima delete -f` a mano y verifica que
  `~/.colima/_lima/_disks` quede vacío. Ahí es donde se esconden los 13 GB.
- **Cargaste dos veces el mismo zip.** No pasa nada: el MD5 es candado.

---

## Lo que este script NO hace

- **No escala por canal.** Las cifras que entrega son **medidas**. El ajuste
  por canal (Cervecería 0.91 efvo / 0.94 tarj, Valle 28.10 / 1.36, Brisas
  3.64 / 1.01) se aplica aparte y contra los cortes, no aquí.
- **No publica margen de comida.** Los costos de insumo del POS están mal
  capturados. Sólo bebida, contra las listas de proveedor.
- **No reemplaza los cortes.** El POS no es la operación completa: en Valle
  falta la mayoría del efectivo.
