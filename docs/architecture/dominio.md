# Dominio y direcciones públicas de Cita Suite

## Decisión del 1 de noviembre de 2026: dominios oficiales

Juan, literal (plan de señas y avisos, 12.16): «de ahora en mas el dominio oficial es el que compre https://app.cita-suite.com.ar/ para la app y https://cita-suite.com.ar/ para la landing, workers.dev no».

- **Dominios oficiales:** `https://app.cita-suite.com.ar` para la aplicación y `https://cita-suite.com.ar` para la landing.
- **`app.cita-suite.workers.dev`:** es el mismo Worker y sigue respondiendo, pero no es oficial. Nada que vea un paciente o un consultorio debe usarlo.
- **Web de Natalia:** desde el 1 de noviembre a las 10:18 UTC reserva por `app.cita-suite.com.ar` (V10b, commit `8ac6dfee` en `juan-altamira/web-natalia`).
- **Google Calendar:** vuelve al dominio oficial desde el 28 de octubre (punto 6 de «Pendientes» de esta guía).
- **Restos técnicos de workers.dev:** las verificaciones lo comprueban como origen técnico. La constante `PUBLIC_SITE_URL_FALLBACK` todavía lo nombra (sólo se usa si falta `PUBLIC_SITE_URL`) y se cambia en la próxima versión (`docs/plans/pendientes-vigentes.md`).

## Estado vigente — 27 de octubre de 2026, 08:20 UTC (05:20 en Argentina)

Decisiones literales del usuario, 27 de octubre:

- «la web publica de presentacion es https://cita-suite.vercel.app/ inicialmente la iba a dejar en cita-suite.com.ar y la app dejarla en cita-suite.com.ar/app. pero me olvide. creo que lo mejor seria: cita-suite.com.ar sea la landing y app.cita-suite.com.ar sea la aplicación. Necesito que avances en todo lo que puedas hacer por tu cuenta».
- Después de apuntar él mismo el dominio principal a Vercel: «la dejamos en vercel si no molesta». La landing queda en Vercel.

| Dirección | Qué muestra | Dónde se sirve | Estado comprobado (`.verification/dominio-landing-20261027/estado-20261027T0814Z.txt` y sondas) |
|---|---|---|---|
| `https://cita-suite.com.ar` | Landing | Vercel, proyecto `landing-cita-suite` (equipo `juanaltamiras-projects`), repositorio `juan-altamira/landing-cita-suite`. Publica solo cada cambio de `main`. | Fuente `ab3a2e0`, el mismo HTML que `cita-suite.vercel.app`. `/login`, `/privacidad` y `/terminos` redirigen (308) a la aplicación. HTTP redirige a HTTPS (308). Certificado de Let's Encrypt hasta el 25-ene-2027. HSTS de Vercel `max-age=63072000`. |
| `https://app.cita-suite.com.ar` | Aplicación | Worker `app` de Cloudflare, producción (dominio de Worker `dede6f55…`) | Desde el 27-oct a las 14:19 UTC, revisión `95b2596`, versión `8b41ec56…` (entrega de origen): es `PUBLIC_SITE_URL`. HTTP redirige a HTTPS (301, por «Always Use HTTPS» de la zona). Certificado de Google Trust Services hasta el 25-ene-2027. |
| `https://app.cita-suite.workers.dev` | Aplicación | El mismo Worker | Sigue habilitado para los enlaces ya enviados; desde el 1 de noviembre no es oficial y la web de Natalia ya no lo usa. El retorno de Calendar pasó al subdominio el 28-oct (secreto `GOOGLE_CALENDAR_REDIRECT_URI` borrado); el de workers.dev sigue registrado en Google para una vuelta atrás. Desde la entrega de origen, la propia aplicación responde 308 a HTTPS por HTTP (antes aceptaba HTTP sin redirigir). |
| `https://cita-suite.vercel.app` | Copia de la landing | El mismo proyecto Vercel | Idéntica al dominio. |
| `www.cita-suite.com.ar` | — | Sin registro DNS | No resuelve (opcional, ver pendientes). |

### DNS y certificados (zona de Cloudflare)

- **Zona:** `906c882ca449e11dfe94061b9f1ad82c`, plan Free, cuenta `52b358653379c162b5a07b10ae5e84b3`.
- **Servidores de nombres:** `nicolas` y `summer.ns.cloudflare.com`.
- **Registro:** NIC Argentina hasta el 26-oct-2027.

Registros (captura del usuario, 27-oct):

- `cita-suite.com.ar`: CNAME a `9984297ff6dc7901.vercel-dns-017.com`, sin proxy («DNS only»). Resuelve a las direcciones de Vercel `216.198.79.1` y `64.29.17.1`.
- `app.cita-suite.com.ar`: tipo Worker, hacia `app`, con proxy. Lo crea y administra el dominio de Worker: no se edita a mano.

Opciones de la zona (capturas del usuario):

- «Always Use HTTPS» activado el 27-oct.
- HSTS de zona apagado.
- Versión mínima de TLS: 1.0, la predeterminada.
- TLS 1.3, cifrado oportunista y reescrituras automáticas a HTTPS activados.

Certificados de borde, los dos activos y administrados por Cloudflare:

- Universal: `cita-suite.com.ar` y `*.cita-suite.com.ar`.
- Avanzado del Worker: `cita-suite.com.ar`, `app.cita-suite.com.ar` y `*.app.cita-suite.com.ar`.

Como el dominio principal ya no pasa por Cloudflare, su certificado lo emite Vercel.

El token de `wrangler` de esta máquina puede adjuntar y quitar dominios de Worker, pero no tiene permiso de DNS ni de configuración de zona (responde 403): esas tareas son del usuario. El control de permisos denegó publicar un Worker para `www` porque tocaba DNS; no se reintentó.

### Google Cloud (proyecto «Dashboard Odontologia»), comprobado el 27-oct a las 08:03 UTC

**Desde el 2 de noviembre (03:03 UTC)** Calendar usa el proyecto propio «Cita Suite Calendar» ([accesos Google](accesos-google.md)). Lo que sigue sobre el cliente de Calendar describe el **anterior**.

- **Información de la marca** (captura del usuario):
  - Inicio `https://cita-suite.com.ar/`.
  - Privacidad `https://app.cita-suite.com.ar/privacidad` y términos `https://app.cita-suite.com.ar/terminos`; las dos páginas responden 200.
  - Dominios autorizados: `yjzferwuzbtgpmdnzlcb.supabase.co`, `cita-suite.com.ar` y `cita-suite.workers.dev`. Este último lo agregó Google por el retorno de Calendar.
  - La verificación de marca **no se envió**. El aviso «No se está mostrando la información de tu marca» es el esperado sin verificación.
- **Cliente de Calendar** «Cita Suite - Google Calendar - Producción» (`372761266416-54ln2gg48n8imdnfesljm57ojk0mvian`). Retornos:
  - `https://app.cita-suite.workers.dev/oauth/google-calendar/callback`, el que usa producción.
  - `https://app.cita-suite.com.ar/oauth/google-calendar/callback`, el de la entrega de origen.
  - En la sonda `calendar-redirects-7.json` los dos quedaron aceptados y el retorno inventado de control, rechazado.
- **Cliente de ingreso** «Cita Suite - Auth - Produccion» (`372761266416-6pt6cuh73a5s4uttv31co0jc43ifrmtc`, el que usa Supabase):
  - Retorno `https://yjzferwuzbtgpmdnzlcb.supabase.co/auth/v1/callback`, aceptado en la misma sonda.
  - Orígenes JavaScript `http://localhost:5173`, `https://cita-suite.com.ar` y `https://app.cita-suite.com.ar`. El flujo del servidor no los usa; no molestan.
- **Estados intermedios:** entre las 07:08 y las 08:01 UTC hubo configuraciones rotas. Primero un retorno con doble barra, después el de workers.dev reemplazado y por último el de Supabase cargado en el cliente de Calendar. Las sondas 2 a 6 documentan cada estado; la 7 es la vigente. La sonda 1 no vale: usaba el cliente de Calendar reemplazado el 23-oct.

### Supabase (proyecto `yjzferwuzbtgpmdnzlcb`), captura del usuario del 27-oct

- **Site URL:** `https://app.cita-suite.com.ar`.
- **Redirect URLs (13):**
  - `http://localhost:5173/reset/callback` y `http://localhost:5173/auth/callback`.
  - `https://app.cita-suite.workers.dev`, con `/reset`, `/reset/callback` y `/auth/callback`.
  - `https://cita-suite.com.ar/`, con `/reset/callback` y `/auth/callback`. Ya no sirven, porque el dominio principal es la landing; no molestan.
  - `https://app.cita-suite.com.ar`, con `/auth/callback`, `/reset` y `/reset/callback`.
  - La aplicación usa exactamente `/auth/callback` (ingreso con Google, sobre el origen de la página) y `/reset/callback` (recuperación, sobre `PUBLIC_SITE_URL`). Los dos orígenes de la aplicación están cubiertos.
- **Nombres de los proyectos:** siguen «Odontologia» y «Staging 455», según la lectura de la herramienta de Supabase del 27-oct, después de las 08:14 UTC. Renombrarlos le corresponde al usuario.
- **Correo (SMTP):** activado con `citasuite@gmail.com` y comprobado de punta a punta el 27-oct (correo recibido en Recibidos, enlace al subdominio, cambio de contraseña, un solo uso y vencimiento); el remitente sigue siendo Gmail, no `@cita-suite.com.ar` ([correo de recuperación](correo-de-recuperacion.md)).

### Riesgo aceptado: la landing en el plan gratuito de Vercel

La [política de uso justo de Vercel](https://vercel.com/docs/limits/fair-use-guidelines) limita el plan Hobby a uso personal no comercial, y promocionar un producto en venta cuenta como uso comercial. Vercel puede pedir el plan Pro (pago mensual, fuera de la [restricción económica](control-de-consumo.md)) o pausar el proyecto. El usuario lo sabía y decidió dejarla en Vercel.

Alternativa gratuita, lista por si hiciera falta:

- El Worker `cita-suite-landing` existe sin dominio, sólo con archivos estáticos, que en Cloudflare son gratuitos e ilimitados.
- Versiones: `91369f9a-050a-4e9a-ad84-f8ecfb9912d9` (`fc177a8`), `36d23a93-cf2e-4bde-b744-864d4e1d6de8` y `243642f3-f1ce-47fe-9726-ac66cdec96bc`.
- Su configuración está en el historial del repositorio de la landing (`fc177a8`).
- Volver a usarlo exige que el usuario quite antes el CNAME hacia Vercel.

## Dependencias del origen de la aplicación

**Desde la entrega de origen (publicada el 27-oct a las 14:19 UTC, versión `8b41ec56…`):** `PUBLIC_SITE_URL` (`apps/web/wrangler.jsonc`) y `PRODUCTION_APP_ORIGIN` (`scripts/lib/production-deploy.mjs`) son `https://app.cita-suite.com.ar`; `PUBLIC_SITE_URL_FALLBACK` sigue en `https://app.cita-suite.workers.dev`. Lo que sigue describe el estado anterior a esa publicación, cuando los tres estaban en workers.dev. De ese valor dependen:

- El retorno del correo de recuperación.
- El retorno de Google Calendar. Hasta el 28-oct el secreto productivo `GOOGLE_CALENDAR_REDIRECT_URI` lo reemplazaba; se borró a las 04:18 UTC.
- Los enlaces de instalación de reserva y los de los mensajes.
- Los hosts de imagen pública.
- La base de Natalia.

El ingreso con Google usa `${url.origin}/auth/callback`, es decir, el origen de la página donde está la persona.

Hoy, en `app.cita-suite.com.ar`:

- Funcionan el correo y la contraseña.
- El ingreso con Google tiene su retorno permitido en Supabase y en Google, y **el usuario lo probó con su cuenta real en `app.cita-suite.com.ar` el 27-oct (avisado después de las 01:29 UTC del 28): funciona bien**.
- Hasta la entrega de origen, la recuperación y Calendar llevaban a workers.dev. Desde las 14:19 UTC del 27-oct, la recuperación, los enlaces de reserva y los mensajes llevan al subdominio; Calendar pasó al subdominio el 28-oct a las 04:18 UTC, al borrarse su secreto (punto 6).
- La sesión se guarda por dirección: la de workers.dev no vale en el subdominio.

### Entrega de origen (candidata v2 lista para staging; las precondiciones del usuario se cumplieron el 27-oct)

Diferencia exacta contra `b108c19` en `apps/`, `packages/`, `supabase/` y `scripts/` (16 archivos):

- Candidata v2 `95b2596a9b4f24d8ae50d78a94e3f1c9f95b811a`, rama auxiliar `verify/origen-candidate-v2-20261027`.
- Pruebas rápidas (`fast`) **40451313177 aprobadas** y empaquetado **40451368816 aprobado**.
- La v1 `e064ccf…` (14 archivos, `fast` 40450852020 aprobado) quedó superada por el punto 7.

1. **Origen:** `PUBLIC_SITE_URL` y `PRODUCTION_APP_ORIGIN` pasan a `https://app.cita-suite.com.ar`. `PUBLIC_SITE_URL_FALLBACK` sigue en workers.dev, así que ese host sigue en la lista de imágenes públicas.
2. **Natalia no cambia:**
   - Se agrega `PRODUCTION_WORKERS_DEV_ORIGIN`, y `PRODUCTION_NATALIA_APP_BASE` es igual a él.
   - El artefacto `natalia-production`, `prepare-natalia-publication.mjs` y `verify-production-release.mjs --natalia` siguen comparando con el sitio publicado, que reserva por workers.dev.
   - Moverla es una entrega aparte, desde su propio repositorio.
3. **Guardia de staging:** la lista de hosts productivos prohibidos para staging omitía el dominio nuevo. Una prueba roja lo demostró (`https://app.cita-suite.com.ar is not refused`). Ahora la lista sale de las propias constantes productivas (`PRODUCTION_HOSTS`).
4. **HTTP→HTTPS en la aplicación:**
   - Prueba roja: por HTTP la aplicación leía cookies e intentaba autenticar.
   - Ahora `hooks.server.ts` responde 308 al mismo camino por HTTPS, sin puerto y con `no-store`, antes de leer cookies o resolver la ruta.
   - Excepciones: `127.0.0.1`, `localhost`, `[::1]` y el modo `dev`.
   - El programador entra por *service binding* a `https://scheduler.cita-suite.internal`, y los arneses de prueba usan `http://127.0.0.1`. No hay rutas prerenderizadas, así que todo HTML pasa por el *hook*.
5. **Comprobación desplegada:**
   - `httpsRedirect(origin)` (`served-release.mjs`) pide `/login` por HTTP sin seguir redirecciones y exige 301 o 308 a la misma dirección por HTTPS.
   - `verify-campaign-staging.mjs` lo **exige** a la candidata y lo registra para la reversión.
   - `verify-production-release.mjs` lo registra para el dominio (ahí el borde puede responder primero) y para workers.dev (la respuesta propia de la aplicación).
   - En la publicación, el recibo de la candidata debe mostrar `redirects: true` en workers.dev.
6. **`GOOGLE_CALENDAR_REDIRECT_URI`: borrado el 28-oct a las 04:18 UTC, con autorización expresa del usuario, en la publicación de `aacba5b`.** Medido con un turno sintético de la cuenta de prueba (6-nov, cancelado después): con el secreto, workers.dev; sin él, `https://app.cita-suite.com.ar/oauth/google-calendar/callback`, tanto empezando en el subdominio como en workers.dev (el intento se guarda en la base y no depende de cookies). **Una vuelta atrás restaura los secretos de la versión de destino:** con `8b41ec56` volvió a pedir workers.dev (33 enlaces) y al regresar a `4e29aba6` volvió al subdominio (32). Los dos retornos están registrados en Google, así que funciona en cualquier caso. Recibos `.verification/calendar-subdominio-20261028/` y `.verification/publicacion-agenda-20261028/`. Lo que sigue es el antecedente de la decisión:
   - Sigue apuntando al retorno de workers.dev, que funciona y está registrado en Google.
   - La documentación oficial no dice qué hace una vuelta atrás con los secretos ([reversiones](https://developers.cloudflare.com/workers/versions-and-deployments/rollbacks/), [secretos](https://developers.cloudflare.com/workers/configuration/secrets/)). Staging no tiene Calendar, así que no se puede ensayar ahí.
   - El camino elegido es borrarlo, para que el retorno siga al `PUBLIC_SITE_URL` de cada versión, que viaja dentro de la versión. Así funciona en cualquier caso, porque los dos retornos están registrados.
   - Hace falta comprobarlo con un caso real. El 27-oct no había turnos futuros sintéticos: `capacity-01` ya no existe, y los únicos son del consultorio propio del usuario. Queda pendiente para cuando haya un turno sintético de la cuenta de prueba.
7. **Identificador de los eventos `.ics`:**
   - Se derivaba del host de `PUBLIC_SITE_URL`: cambiar el origen habría impedido que un evento ya importado se actualizara o cancelara.
   - Prueba roja: con el origen nuevo, el identificador cambiaba.
   - Ahora usa el dominio fijo `app.cita-suite.workers.dev`, el de todos los identificadores emitidos desde Cloudflare, y los enlaces del evento siguen al origen público. La sincronización de Google Calendar no usa ese identificador.

Comprobado en local antes de despachar: 161/161 guardias de Node (49 archivos), 25/25 de *hooks* y CSP, 89/89 de las pruebas que dependen del origen y 29/29 de calendario.

Publicación: la secuencia de [publicación y reversión](publicacion-y-reversion.md), con la base compatible `b108c19` (`d0ac2bcf…`) más el secreto del punto 6. Hace falta una auditoría completa aprobada para esta candidata. Después, el usuario prueba el ingreso con Google y la recuperación desde el subdominio. Workers.dev sigue habilitado para los enlaces ya emitidos y para Natalia.

## Hallazgos

1. **HTTP sin redirección (seguridad).**
   - El 27-oct, antes de las 08:00 UTC, `http://cita-suite.com.ar/` y `http://app.cita-suite.com.ar/login` respondían 200 por HTTP. Un ingreso por `http://` habría enviado la contraseña en claro.
   - Estado actual: el subdominio redirige en el borde (301) y Vercel redirige el dominio (308).
   - `http://app.cita-suite.workers.dev/login` respondía 200 hasta la entrega de origen. Desde las 14:19 UTC del 27-oct responde 308 a HTTPS (cuatro mediciones limpias en producción, registro).
2. **robots.txt administrado por Cloudflare.**
   - La zona antepone un bloque «Content Signals» y bloqueos de rastreadores de entrenamiento de inteligencia artificial, y conserva al final el archivo propio.
   - Afecta sólo a lo que pasa por el proxy de Cloudflare: hoy, el subdominio de la aplicación (2739 B contra 63 B en workers.dev).
   - El dominio principal sirve el archivo propio de la landing (44 B, `Disallow: /789798494`).
   - Se puede desactivar desde el panel de Cloudflare (AI Crawl Control) si el usuario lo prefiere.
3. **Resolución local.** Esta máquina no tiene ruta IPv6, y su resolvedor (systemd-resolved hacia 8.8.8.8) devolvió sólo AAAA o «no existe» para un nombre recién creado. Para verificar, usar `dig @1.1.1.1` y `curl -4 --resolve <host>:443:<ip>`.
4. **La landing usa la base productiva.**
   - El seguimiento de visitas y el panel comercial (`/789798494`) llaman funciones de `yjzferwuzbtgpmdnzlcb` con la clave anónima.
   - Sus objetos (`database/landing-crm.sql` del repositorio de la landing) no están en las migraciones de Cita Suite, aunque los respaldos los incluyen por estar en la misma base.
   - No dependen del origen.
5. **Archivos de Cloudflare en la landing.**
   - Vercel mostraba públicamente `/_headers` y `/_redirects`.
   - Además, `wrangler.jsonc` declaraba el dominio principal: publicarlo habría vuelto a enganchar el dominio al Worker y pisado el CNAME hacia Vercel.
   - Se quitaron en `ab3a2e0`; `vercel.json` ya tiene los mismos encabezados y redirecciones. Comprobado: los dos archivos dan 404 y la página de inicio es idéntica byte a byte.

## Procedimientos

Herramientas en `.verification/dominio-landing-20261027/` (carpeta local, ignorada por Git):

- `cf-domains.mjs` (`list`, `detach <host> <servicio-esperado>`, `attach <host> <servicio>`): deja un recibo, que nunca se sobrescribe, por cada cambio.
- `verify-landing.mjs`: compara una landing servida con su compilación.
- `probe-calendar-redirects.mjs`: comprueba los retornos de Google, con controles positivo y negativo.

Cambiar dominios altera el DNS: el control de permisos puede exigir la aprobación del usuario.

**Comprobar el estado:**

```sh
dig +short @1.1.1.1 cita-suite.com.ar A                                  # direcciones de Vercel
curl -4 -sSI https://cita-suite.com.ar/ | grep -i '^server'               # Vercel
curl -4 -sS https://app.cita-suite.com.ar/_app/version.json               # revisión publicada
curl -4 -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' http://app.cita-suite.com.ar/login   # 301 a https
node .verification/dominio-landing-20261027/cf-domains.mjs list           # sólo app.cita-suite.com.ar → app
node --dns-result-order=ipv4first .verification/dominio-landing-20261027/probe-calendar-redirects.mjs <recibo-nuevo>
```

**Publicar la landing:** empujar a `main` de `juan-altamira/landing-cita-suite`; Vercel compila y publica. Esa cuenta es la única con permiso de escritura: las dos claves SSH y la cuenta activa de `gh` son `Juan4787`, que sólo puede leer. Se usa un ayudante de credenciales de una sola orden, que no toca `~/.git-credentials`:

```sh
GH_TOKEN="$(gh auth token --user juan-altamira)" git -c credential.helper= \
  -c credential.https://github.com.helper= \
  -c 'credential.https://github.com.helper=!f() { test "$1" = get || exit 0; echo username=x-access-token; echo "password=$GH_TOKEN"; }; f' \
  push origin <commit>:refs/heads/main
```

**Volver atrás la landing:** desde el panel de Vercel, promover el despliegue de producción anterior, o `git revert` del commit y empujar a `main`.

**Cuidado con `wrangler deploy` y los dominios:**

- Con rutas `custom_domain`, `wrangler deploy` reemplaza el conjunto de dominios del Worker (`override_scope: true`).
- Sin terminal interactiva, además reasigna dominios de otros Workers y pisa registros DNS en conflicto (`override_existing_origin` y `override_existing_dns_record`; `publishCustomDomains` de wrangler 4.86.0).
- Por eso `apps/web/wrangler.jsonc` no declara `routes`: los dominios de la aplicación se administran con `cf-domains.mjs`.
- Para cambiar sólo el contenido de un Worker sin tocar dominios ni DNS: `wrangler versions upload` y después `wrangler versions deploy <versión>@100% --yes`.

**Dominio de la aplicación:** `node .verification/dominio-landing-20261027/cf-domains.mjs detach app.cita-suite.com.ar app` lo quita, y `attach app.cita-suite.com.ar app` lo vuelve a poner. Workers.dev siempre queda como respaldo.

## Pendientes

Del usuario:

1. ~~Probar el ingreso con Google~~ desde `https://app.cita-suite.com.ar/login`: hecho por el usuario el 27-oct, funciona bien.
2. **Renombrar los proyectos de Supabase:** producción ya se llama «Cita Suite» (lo hizo el usuario; comprobado el 27-oct a las 09:3x UTC con `supabase projects list`). Falta «Staging 455» → «Cita Suite Staging», en Settings → General → Project name, con rol de dueño o administrador de la organización `waoipxhhnbpnpjhbdssn`. No cambia direcciones ni datos.
3. ~~Configurar el correo de recuperación~~ (hecho el 27-oct con `citasuite@gmail.com`; el archivo de la entrega se borró el 29-oct). Antecedente: crear la contraseña de aplicación de Gmail y cargarla en Supabase ([guía](correo-de-recuperacion.md)). El 27-oct el usuario dijo que la cuenta es de prueba y que se ponga «cualquiera»: no es posible, porque Gmail sólo acepta la contraseña de aplicación que Google genera dentro de la cuenta, con verificación en dos pasos.
4. **Verificación de marca de Google, estado al 2 de noviembre** (lo que sigue debajo es el antecedente):
   - **Search Console:** hecho. Juan confirmó que Google ya verificó la web.
   - **Decisión tomada:** Calendar pasa a un proyecto propio, «Cita Suite Calendar» (`cita-suite-calendar-513502`), gratis. La verificación de marca se pide **sobre ese proyecto**, no sobre «Dashboard Odontologia».
   - **Ingreso con Google:** sigue en «Dashboard Odontologia», con su aviso actual.
   - **Pasos:** `docs/plans/pendientes-vigentes.md`, sección 4, punto 1.

   Antecedente: no enviarla todavía.
   - Google exige verificar cada dominio autorizado, y el usuario no puede verificar `yjzferwuzbtgpmdnzlcb.supabase.co`. Es una causa conocida de rechazo ([Supabase](https://supabase.com/docs/guides/auth/social-login/auth-google), [foro de Google](https://discuss.google.dev/t/oauth-branding-verification-stuck-name-mismatch-due-to-supabase-callback-domain-no-trust-safety-email-received/389007)).
   - Hay que decidir entre un dominio propio para Supabase (pago) o separar Calendar en otro proyecto de Google (gratis).
   - Verificar `cita-suite.com.ar` en Search Console requiere un registro TXT en Cloudflare.
   - **Último requisito según el usuario (29-oct): poner la web a su nombre ante Google**, es decir, verificar la propiedad de `cita-suite.com.ar` en Search Console con la cuenta dueña del proyecto OAuth. Pendiente del usuario; recién después enviar la verificación.
6. **Avisos de falla de GitHub:** comprobar que llegan por correo a la cuenta `Juan4787` (https://github.com/settings/notifications).
7. **Opcionales:**
   - `www`: en Vercel, Settings → Domains → agregar `www.cita-suite.com.ar` con redirección a `cita-suite.com.ar`. Vercel indica el CNAME que hay que crear en Cloudflare, sin proxy.
   - Versión mínima de TLS 1.2 en Cloudflare (SSL/TLS → Edge Certificates).
   - Registros que impiden falsificar correo con el dominio mientras no envíe correo: TXT `v=spf1 -all` en `cita-suite.com.ar` y TXT `v=DMARC1; p=reject` en `_dmarc.cita-suite.com.ar`. Si algún día el dominio envía correo, hay que reemplazarlos.
   - Borrar de Supabase las tres entradas `https://cita-suite.com.ar/…`.
   - Borrar el proyecto Vercel `presentacion-cita-suite`, que compila cada cambio y no sirve su dirección (404).
   - Borrar el Worker `cita-suite-landing` (pedírselo al agente).

De la campaña:

- **Entrega de origen: publicada el 27-oct** con la autorización expresa del usuario (13:5x UTC), después de staging, reversión alojada `40474553664` y auditoría completa `40474924663`. Copia `40516167872` certificada; app `8b41ec56…` (`95b2596`) desde las 14:19 UTC; vuelta atrás nativa a `d0ac2bcf…` ensayada y retorno; programador `cae02746…` con los cinco cron desde las 14:39 UTC. Detalle y recibos: registro y [traspaso](../plans/traspaso-dominio-origen-20261027.md).
- **Retorno de Calendar al subdominio:** pendiente de un turno sintético con el cual comprobarlo (punto 6).
- **Copias programadas:** GitHub corrió la copia del 26-oct unas 6 h tarde, y la del 27-oct no había corrido a las 09:34 UTC. El 27-oct el usuario aceptó los atrasos de horas; lo que importa es que se copie y que no haya otro error de fondo. La revisión de ese día lo confirma, salvo la recepción de los avisos por correo, que sigue sin certificar ([registro](../plans/registro-refactorizacion-cita-suite.md)). No se cambian los horarios.
- **Hallazgo abierto:** la lista de la agenda muestra las horas con la zona del navegador. Es la entrega siguiente.

## Historia del 27 de octubre (hora universal; en Argentina, 3 horas menos)

- 03:30: el usuario vinculó el dominio principal al Worker `app`.
- 03:51: subdominio `app.cita-suite.com.ar` → `app` (`app-subdomain-attach.json`).
- 04:14: dominio principal → Worker `cita-suite-landing` (`deploy-apex.log`, `verify-apex-2.json`), con los enlaces de la landing corregidos (`3833d84`, `4afd19d`).
- 07:08–08:03: configuración de Google por el usuario y sondas 2 a 7.
- 07:11: redirecciones de `/login`, `/privacidad` y `/terminos` (`fc177a8`, versión `91369f9a`).
- Entre 07:12 y 08:14: el usuario quitó el dominio principal del Worker y lo apuntó a Vercel; también activó «Always Use HTTPS» y configuró Supabase.
- 08:18: limpieza de la landing para Vercel (`ab3a2e0`).

Detalle de cada paso en el [registro](../plans/registro-refactorizacion-cita-suite.md).

## Correo de pacientes — decisión posterior del 2 de noviembre, pendiente de configurar

[Plan 12.18 y especificación de E](../plans/etapa-e-correo-autogestion.md): proveedor elegido **Zoho CPaaS**, sustituyendo la alternativa histórica Resend. Juan ya creó la cuenta y probó dos envíos; KYC pendiente y cupo inicial informado de 100 diarios. Todavía no se verificaron en esta tarea el dominio/remitente usado, región, DNS, clave API ni la integración con la app. No tomar esos dos envíos como prueba de registros o de recepción integral.

Al iniciar E, comprobar los registros exactos que indique la cuenta real y su compatibilidad con SPF/DKIM/DMARC existentes, retorno de rebotes, MX y cualquier recepción legítima. Las sugerencias anteriores de SPF de no envío y DMARC restrictivo no se aplican a ciegas al incorporar correo. No tocar CNAME de app/landing, cliente de Calendar ni SMTP de Auth. El nombre visible del consultorio no autoriza enviar desde un dominio ajeno sin verificarlo. Sin dominio propio del consultorio, acordar el dominio técnico; marca visual, dirección real y enlaces son conceptos diferentes.

No se aplicó ningún registro DNS en esta revisión. Cuenta Zoho no falta; dominio/remitente efectivos y datos completos del emisor siguen por comprobar/configurar después de la instrucción de inicio.
