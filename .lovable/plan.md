
# Carga Masiva de Datos Historicos de Ventas

## Objetivo
Crear una herramienta dentro del panel de admin que permita subir los archivos Excel mensuales (uno por mes de 2025) y cargar automaticamente los datos historicos como cortes de cierre en la base de datos.

## Como funciona

1. El admin sube un archivo Excel (.xlsx) desde el Dashboard
2. El sistema lee el archivo en el navegador, identifica las 4 sucursales por su codigo (V.161, R.955, A.233, S.1639)
3. Extrae por cada dia: efectivo, tarjetas y total de cada sucursal
4. Inserta los registros como cortes de tipo "cierre" en la tabla `cortes_caja`
5. Muestra un resumen de cuantos registros se cargaron y si hubo errores

## Flujo del usuario

1. Ir a Dashboard admin
2. Hacer clic en "Carga Historica" (nuevo boton)
3. Seleccionar archivo Excel
4. Ver preview de los datos detectados (mes, cantidad de dias, sucursales)
5. Confirmar la carga
6. Ver resultado (exito o errores)

---

## Detalles Tecnicos

### Dependencia nueva
- `xlsx` (SheetJS) - libreria para leer archivos Excel en el navegador, sin necesidad de backend

### Mapeo de codigos a sucursales
```text
V.161  -> Del Valle   (f9ef883d-88dc-47e1-945d-af145905a955)
R.955  -> Las Brisas  (dc600e86-cfd8-466a-b0e1-319a836d3af8)
A.233  -> Cerveceria  (79324e7b-c8ef-4355-b2b1-6965346a0ab1)
S.1639 -> Solares     (757d25e0-ce84-4d6f-a68a-d4639d3e409f)
```

### Logica de parseo del Excel
- Leer la hoja 1 del archivo
- Identificar las columnas de cada sucursal por los encabezados (V.161, R.955, etc.)
- Para cada fila con fecha valida, extraer: fecha, efectivo, tarjeta, total por sucursal
- Ignorar la fila de totales al final (sin fecha)
- Limpiar valores monetarios (quitar $, comas)

### Insercion en `cortes_caja`
Por cada dia y sucursal, se crea un registro con:
- `sucursal_id`: segun mapeo
- `tipo_corte`: "cierre"
- `efectivo`: valor de la columna efectivo
- `tarjetas`: valor de la columna tarjeta
- `total`: valor de la columna total
- `fecha_venta`: la fecha del dia
- `corte_x`: 0
- `cobradas`: 0
- `por_cobrar`: 0
- Campos opcionales (proveedores, salarios, etc.): 0

### Validaciones antes de insertar
- Verificar que no existan ya cortes de cierre para ese mes/sucursal (evitar duplicados)
- Mostrar advertencia si ya hay datos en ese periodo
- Permitir al usuario decidir si reemplazar o cancelar

### Archivos a crear/modificar
1. **Nuevo:** `src/components/admin/CargaHistorica.tsx` - Componente principal con upload, preview y carga
2. **Modificar:** `src/pages/admin/Dashboard.tsx` - Agregar boton/tab para acceder a la carga historica
3. **Instalar:** paquete `xlsx` para parsear Excel en el navegador
