# Cita Suite

Monorepo con la aplicación SvelteKit, la web Astro de Natalia y Supabase: agenda, reservas, pacientes, historia clínica, documentos e integraciones.

La campaña actual se rige por el [plan aprobado íntegro](docs/plans/refactorizacion-cita-suite.md). Su [registro de ejecución](docs/plans/registro-refactorizacion-cita-suite.md) distingue avances, pruebas, resultados y pendientes. Las notificaciones por WhatsApp están descartadas; cursos y noticias siguen pospuestos.

Repositorio principal: [Juan4787/cita-suite](https://github.com/Juan4787/cita-suite). La app está en `CITA SUITE/Cita Suite App`; se trabaja en `main`, sincronizada con GitHub y con la historia de producción. El registro siguiente distingue la revisión servida de los cambios de herramientas/documentación posteriores.

**Qué historia y qué cambios están vigentes:** [estado vigente](docs/ESTADO-VIGENTE.md), el registro único; lo comprueba `node scripts/check-repo-sync.mjs`.

**Etapa E, estado al 6 de noviembre:** publicada en producción; el encargo sigue abierto hasta terminar las comprobaciones reales. [Mandato](docs/plans/mandato-integral-avisos-20261105.md), [plan canónico y checkpoint](docs/plans/plan-integral-avisos-20261105.md), [índice](docs/plans/indice-etapa-e.md).

**Vigente desde el 6 de noviembre a las 11:34 UTC:** segunda versión de E, `36d8fe9cc1d191f684f8ebd80f99eecf40eba293`, Worker `app`; la versión de Cloudflare y los interruptores están en el [estado vigente](docs/ESTADO-VIGENTE.md).

**Antes, desde el 2 de noviembre a las 15:33 UTC:** V12b `771fac5950c532b1123f11d4dde93eef9b42ceba`, versión `277d332d-1794-4367-8ef0-567ced159f1b`. Ya no es una vuelta atrás válida.
- Es V12 con el fondo general del modo claro apenas más cálido (`#f6f5f3`), a pedido de Juan.
- V12 (`c21a19839c814a8a5f476cb522a13273a10f89c4`, versión `f18a80f2-fd65-4ffc-b92f-fc0101d4f85f`, 14:46 UTC) es la entrega del modo claro que V12b ajusta.
- **Qué agrega:** V11f más el **modo claro predeterminado**, conservando el oscuro.
  - Selector Claro, Oscuro y Automático en el menú de cuenta.
  - La preferencia queda en cada dispositivo, en la cookie `cita-theme`.
  - La reserva de Natalia sigue el modo de su web y se ve igual que antes.
- **Documentos:**
  - [plan](docs/plans/modo-claro-20261102.md), [registro](docs/plans/registro-modo-claro-20261102.md) y [traspaso](docs/plans/traspaso-modo-claro-20261102.md);
  - las reglas de color están en [DESIGN.md](apps/web/DESIGN.md);
  - la vuelta atrás a V11f (versión `986cf666-ae09-423b-ae05-1928007dccde`, nunca `59f81e89…`) está en [publicación y reversión](docs/architecture/publicacion-y-reversion.md).
- **V11f** (`72d59ab00db67a8502ca560c762c61e6cfac1923`, 2 de noviembre a las 02:12 UTC) es la entrega anterior.

**Entrega anterior a V11f, 1 de noviembre a las 10:15 UTC:** V10b `68f31741f6ff7f2253c036800b1369f1eda16510`, versión `1d2b4acd-7dd8-4cb7-81e3-a205bafe9f8d`, Worker `app`: V9 más la vista de consultorios archivados del panel maestro, el rubro «medicina», preguntas de hasta 40 opciones y la web de Natalia reservando en su consultorio real por `app.cita-suite.com.ar` (plan de señas y avisos, 12.16). V9 `a3c707f368736da90d2adf5850d291460f657af0` (31 de octubre) es la V8 descripta a continuación más el registro de las fallas al comprobar el enlace de confirmación. La recuperación, que antes de volver a V9 exige un paso de datos, está en [publicación y reversión](docs/architecture/publicacion-y-reversion.md); todo lo pendiente en [pendientes vigentes](docs/plans/pendientes-vigentes.md).

**Entrega anterior, 31 de octubre a las 20:22 UTC:** confirmación de correo V8 `408ca04d9e6750e4657dc087264644665a63fb37`, Worker `app`, versión `a1844665-447e-40bb-b9e5-ce7c03ed29d7`. Alta pendiente en pantalla propia, reenvío y confirmación verificados en producción. [Estado y evidencias](docs/plans/traspaso-confirmacion-email-20261030.md), [índice documental](docs/README.md). La recepción de la confirmación en un buzón externo no se observó; el enlace recorrido fue generado por Auth real. En esa entrega Natalia/D/E estaban en pausa; el alcance actual de E está en el plan 12.18. No se altera el acceso de Natalia.

Rige el criterio inicial de [AGENTS.md](AGENTS.md): auditoría rigurosa, controles según riesgos concretos y pruebas productivas autorizadas. No exigir por rutina staging, renovación de backup por horas ni conservación exacta de turnos ficticios para una UI/Auth sin migraciones. Las comprobaciones históricas de capacidad conservan sus resultados y la desviación de latencia aceptada por el usuario sólo para el primer consultorio; esta entrega no las convierte en aprobadas ni reabre el lanzamiento general.

## Estructura

```text
apps/web              App SvelteKit existente
apps/natalia          Web pública Astro de Natalia
apps/scheduler        Programador Cloudflare con Service Binding
packages/shared       Tipos, constantes y helpers compartidos
supabase/migrations   SQL versionado
supabase/functions    Edge Functions futuras
```

## Comandos

```sh
pnpm install
pnpm dev
pnpm check
pnpm test
pnpm test:e2e
pnpm build
pnpm verify:fast
pnpm verify:full
pnpm verify:release
```

Usar Node de `.node-version` y pnpm de `packageManager`. Las verificaciones ejecutan una sola tarea a la vez y fallan si una suite obligatoria no se ejecuta. `full` y `release` corren exclusivamente en GitHub Actions: reconstruyen contenedores descartables propios y ejecutan navegador y compilaciones secuencialmente. No ejecutar bases, navegadores ni builds en esta máquina durante la campaña. `fast` comprueba la memoria disponible antes de cada proceso. `release` exige el paquete de su revisión exacta y comprueba el artefacto compilado y el staging; no despliega. Ver [verificación](docs/architecture/verificacion.md) y [traspaso vigente](docs/plans/traspaso-refactorizacion-cita-suite.md).

## Supabase

```sh
pnpm supabase:start
pnpm supabase:types
pnpm supabase:db:reset
pnpm supabase:stop
```

Las variables de entorno viven en la raíz. `apps/web/vite.config.ts` usa `envDir: '../..'` para que SvelteKit las cargue desde el workspace root.

## Despliegues

Cloudflare Workers es el destino de la app (`app`) y del programador (`cita-suite-scheduler`). Natalia conserva `natalia-frutos.vercel.app`. Staging tiene destinos separados. El lanzamiento inicial autorizado es para un consultorio sobre Workers Free y Supabase Free; no se contratan servicios ni se cambian planes sin autorización.

La [publicación y reversión](docs/architecture/publicacion-y-reversion.md) es el procedimiento operativo. CI empaqueta el release una sola vez, con manifiesto y hashes; staging, `verify:release` y producción usan esos archivos exactos. No compilar de nuevo para publicar ni ejecutar `pnpm deploy:cloudflare` como atajo de la campaña. Los controles se eligen según el cambio y el criterio vigente de AGENTS.md. Desconectar tareas automáticas corresponde cuando la operación o su recuperación lo necesitan; no es un requisito universal para publicar la UI.

La candidata aprobada se publica con los scripts de destino explícito:

```sh
node scripts/deploy-staging-workers.mjs app <release-descargado>
node scripts/deploy-production-workers.mjs app <release-descargado>
```

Son comandos para destinos distintos, no una secuencia obligatoria. Reutilizar paquetes y evidencia aprobados; aplicar migraciones, copias, staging o ensayos de recuperación cuando el cambio concreto lo justifique. El programador y Natalia tienen su propia publicación y no se despliegan por una corrección de UI/Auth.

No copies valores privados al repositorio ni a `wrangler.jsonc`. Cargá en
Cloudflare, en **Settings → Variables and Secrets**, las mismas variables de
producción que necesita el servidor (incluidas las claves de Supabase,
integraciones de calendario y VAPID). `DEMO_MODE` debe permanecer
sin definir o con valor distinto de `true` en producción. Definí también
`PUBLIC_SITE_URL` con el dominio final de Cloudflare y agregalo a las Redirect
URLs de Supabase y a los redirect URIs de las integraciones externas que estén
habilitadas.

`keep_vars: true` en `apps/web/wrangler.jsonc` evita que un despliegue
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
de Wrangler elegida para los despliegues existentes. La versión Node de compilación
es independiente de esa fecha de compatibilidad. La revisión servida se comprueba contra
el artefacto publicado; no se deduce de la versión local de Node.

## Estado actual

La app operativa es el panel SvelteKit de `apps/web`, con rutas `/odonto` protegidas, login Supabase, modo demo, modelo multi-tenant, agenda, turnos, ficha clínica y archivos privados en Supabase Storage.
