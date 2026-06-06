# Welcome to your Lovable project

## Project info

**URL**: https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID

## How can I edit this code?

There are several ways of editing your application.

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## Módulo de Pedidos por Sucursal (Operaciones)

Sistema de pedidos para las 4 sucursales (**Valle, Rodeo, Cervecería, Solares**),
diseñado para personal con baja digitalización.

- **Encargado** (`/centro-de-operaciones`): fija su sucursal una vez por dispositivo
  (gate con PIN opcional), hace el pedido del día con controles +/− grandes y pedido
  sugerido (`nivel_par − existencia`), y luego registra lo que llegó. Borrador
  autoguardado en el dispositivo (tolerante a cortes de conexión).
- **Admin** (`/admin/pedidos`): analítica de compras — consolidado del día (insumo ×
  sucursal), semáforo de estados, tendencia, sugerido vs pedido, pedido vs recibido
  (fill rate), consumo estimado, anomalías y gasto. Configuración del catálogo (ABM de
  insumos, asignación por sucursal, `nivel_par`/`costo`/`orden`). Exportación a Excel.
- **PWA instalable** (`vite-plugin-pwa`): ícono en el teléfono y caché offline de lecturas.

Ciclo de vida del pedido: `borrador → enviado → recibido` (o `recibido_parcial`) `→ cerrado`.
Un pedido abierto por (sucursal, fecha).

### Tradeoff de seguridad (RLS)

Las tablas de operaciones (`pedidos`, `pedidos_detalle`, `recepciones`,
`recepciones_detalle`) mantienen políticas **permisivas** (`USING (true)`): el personal
de sucursal opera sin login, igual que el resto del Centro de Operaciones. La lista por
sucursal (`insumo_sucursal`) es de **lectura pública** pero **solo el admin** la gestiona
(`has_role(auth.uid(), 'admin')`). Es decir, cualquiera con la liga puede registrar
pedidos/recepciones, pero solo el admin cambia catálogo, niveles par y costos. Si se
requiere endurecer, agregar PIN por sucursal (columna `sucursales.pin`, ya soportada) o
migrar operaciones a usuarios autenticados.

### Pendientes de negocio (no bloquean)

1. Lista definitiva de **Solares** (hoy = copia de Valle).
2. **Unidades** reales por insumo y si se permiten medios kilos.
3. **Niveles par** por insumo/sucursal (capturar en `/admin/pedidos` → Configuración).
4. **Costos** unitarios (para el módulo de Gasto).
5. ¿PIN por sucursal? (soporte ya presente, opcional).
6. Confirmar diferencias de catálogo Valle/Rodeo/Cervecería.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and click on Share -> Publish.

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)
