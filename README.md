# Cita Suite

Monorepo con el panel multiempresa SvelteKit/Supabase y el sitio público de Natalia en Astro. El mapa vigente de funciones, reglas y fronteras está en [arquitectura actual](docs/architecture/current-system.md). Los documentos de auditorías anteriores conservan su contexto histórico y no sustituyen ese punto de entrada.

## Estructura

```text
apps/web              App SvelteKit existente
apps/natalia          Sitio público Astro y enlaces nativos a Cita Suite
packages/shared       Tipos, constantes y helpers compartidos
supabase/migrations   SQL versionado
supabase/tests        Contratos SQL y concurrencia
docs/architecture     Mapa vigente y verificación reproducible
```

## Comandos

```sh
pnpm install
pnpm dev
pnpm check
pnpm test
pnpm test:e2e
pnpm build
pnpm verify:baseline
```

`pnpm check` comprueba tipos de shared, web y Natalia. `pnpm test` ejecuta servidor y componentes secuencialmente. La [baseline local completa](docs/architecture/baseline.md) agrega builds, contratos SQL y recorridos públicos en navegador con fixtures aislados; requiere las imágenes y Chromium instalados. Ninguno de esos comandos publica la aplicación.

## Supabase

```sh
pnpm supabase:start
pnpm supabase:types
pnpm supabase:db:reset
pnpm supabase:stop
```

Las variables de entorno viven en la raíz. `apps/web/vite.config.ts` usa `envDir: '../..'` para que SvelteKit las cargue desde el workspace root.

## Despliegues

Cloudflare Workers es el único destino de publicación del candidato comercial.
El Worker se
llama `app` y usa el artefacto de SvelteKit generado exclusivamente por
el adaptador de Cloudflare.

Antes del primer despliegue, configurá el proyecto de Workers con **Root
Directory** en `apps/web` y Node 20.3 o superior. En **Settings → Builds** usá
estos comandos:

```text
Build command: pnpm run build
Deploy command: pnpm exec wrangler deploy
Non-production branch deploy command: pnpm exec wrangler versions upload
```

El nombre del Worker creado en el panel debe ser exactamente `app`, como
en `apps/web/wrangler.jsonc`. Para un despliegue desde una máquina autorizada:

```sh
pnpm deploy:cloudflare
```

No copies valores privados al repositorio ni a `wrangler.jsonc`. Cargá en
Cloudflare, en **Settings → Variables and Secrets**, las mismas variables de
producción que necesita el servidor (incluidas las claves de Supabase,
integraciones de calendario, mensajería y VAPID). `DEMO_MODE` debe permanecer
sin definir o con valor distinto de `true` en producción. Definí también
`PUBLIC_SITE_URL` con el dominio final de Cloudflare y agregalo a las Redirect
URLs de Supabase y a los redirect URIs de las integraciones externas que estén
habilitadas.

`keep_vars: true` en `apps/web/wrangler.jsonc` evita que un despliegue automático
borre los bindings cargados desde el panel. No lo elimines mientras las variables
y los secretos de producción se administren fuera del repositorio.

El Worker fija su ejecución dinámica cerca de `aws:sa-east-1` (São Paulo), donde
reside Supabase. Cloudflare sigue entregando los assets estáticos desde el borde
más cercano a cada persona; la ubicación dirigida reduce los viajes de las rutas
server-side a la base de datos.

Las variables y los secretos pertenecen al Worker, no al repositorio. Cambiar
`name` en `wrangler.jsonc` apunta a otro Worker y **no** copia su configuración.
Después de cualquier cambio de nombre, cargá y verificá como mínimo
`ODONTO_SUPABASE_URL`, `ODONTO_SUPABASE_ANON_KEY` y
`ODONTO_SUPABASE_SERVICE_ROLE_KEY` en el nuevo destino antes de dirigir tráfico.

Para una vista previa de Workers desde la terminal, tras cargar secretos locales
en un archivo no versionado `.dev.vars`, ejecutá:

```sh
pnpm dev:cloudflare
```

Los secretos locales no se incluyen en Git. El Worker usa la compatibilidad de
Node de Cloudflare para mantener los módulos de servidor existentes. El
`compatibility_date` queda fijado a la última fecha compatible con la versión
de Wrangler que conserva soporte para Node 20.3, el mínimo ya documentado para
los despliegues existentes.

## Estado actual

La app operativa es el panel SvelteKit de `apps/web`, con rutas `/odonto` protegidas, login Supabase, modo demo, modelo multi-tenant, agenda, turnos, ficha clínica y archivos privados en Supabase Storage.
