# Traspaso exacto: release y publicación de la recuperación y del panel — 26 y 27 de octubre de 2026

## Punto exacto

**Superado el 27 de octubre a las 08:30 UTC por [el traspaso del dominio y la entrega de origen](traspaso-dominio-origen-20261027.md).** Desde abajo se conserva el estado de su fecha: la landing ya no está en Cloudflare sino en Vercel, y las acciones del usuario 0, 1 y 2 están hechas y comprobadas.

Última actualización anterior: **27 de octubre, 04:20 UTC**. Leer primero `AGENTS.md`, el plan original completo (`docs/plans/refactorizacion-cita-suite.md`, 697 líneas, `5fef6e28…`) y el final del registro. El plan no se modificó.

**Producción publicada y verificada:** sirve `b108c1912e2c3bc57403b006bcf33b71cdb91c23` (versión `d0ac2bcf-7e6a-4786-b2fb-5ff14687d643`) en `https://app.cita-suite.workers.dev` y en `https://app.cita-suite.com.ar`. Por decisión del usuario del 27 de octubre, `https://cita-suite.com.ar` sirve la landing (Worker `cita-suite-landing`, versión `36d23a93…`, fuente `juan-altamira/landing-cita-suite` `4afd19d`) y ya no la aplicación: ver [dominio](../architecture/dominio.md). El programador `f105c4ff-160b-4e00-8b5d-14deb9f33b84` corre con los cinco cron; se observaron eventos reales de las cinco categorías. **Siguiente:** acciones del usuario listadas abajo; después, la entrega de cambio de origen (`PUBLIC_SITE_URL` = `https://app.cita-suite.com.ar`).

## Qué se hizo

1. Auditoría `40373057375` fallida por un clic perdido al abrir el panel de nuevo turno: defecto preexistente demostrado con rojos deterministas y corregido con `clipped-slide.ts` (`overflow: clip`). También se corrigieron el `SQLITE_BUSY` de los diagnósticos (identidad de verificación exportada más control de estado compartido) y dos defectos propios encontrados en el camino.
2. Auditoría completa **`40434124045` aprobada** para `b108c19`: 20/20 pasos; 47/47 en desarrollo, en el artefacto `40410601000` y en la reversión `dbd69d2` (`40406135670`); 0 omitidos ni reintentos. Staging con dos reversiones alojadas aprobadas.
3. Con la VPN apagada (causa del preflight fallido confirmada): preflight productivo aprobado; copia actual `40440297166` verificada desde Drive. Programador sin cron a las 02:50:15; margen hasta 03:05:35. App `b108c19` publicada y verificada; ensayo compatible `dbd69d2` (`e3af637d`) verificado; retorno nativo a `d0ac2bcf` verificado; cinco cron restituidos a las 03:11:13 y eventos reales observados hasta las 03:26:40.

## Recursos

| Elemento | Estado |
|---|---|
| Producción | `b108c19`, versión `d0ac2bcf…`, deployment `4b8f88de-5e74-470c-b65d-9ccf3eb9307d`, 33 enlaces, base 126 / 19 / 121 / 107 / 1 / 1 |
| Reversión | Compatible `e3af637d-a115-4f06-a89a-ba64583f5e9c` (`dbd69d2`) por `wrangler rollback`; anterior `70f0cdc0…` (`0851`, sin la corrección de recuperación) |
| Programador | `f105c4ff…`, cinco cron; staging 0 |
| Staging | `b108c19`, versión `4ac26115-f9d4-420a-8501-61671a79d312` |
| Dominio | Zona `906c882ca449e11dfe94061b9f1ad82c` en la cuenta `52b358…`. `cita-suite.com.ar` → Worker `cita-suite-landing`; `app.cita-suite.com.ar` → Worker `app` (dominio `dede6f55…`); certificados hasta el 25-ene-2027; `www` sin registro. HTTP sin redirección hasta que el usuario active «Always Use HTTPS» |
| Respaldo | Copia `40440297166`, Drive `165mCNIUyCHpqBesaqjTmtAvHjCW-TkFl`, manifiesto `9607bccc…` |
| Evidencia | `.verification/wizard-click-20261026/` |

## Acciones del usuario (orden seguro)

0. **Cloudflare → `cita-suite.com.ar` → SSL/TLS → Edge Certificates:** activar «Always Use HTTPS». Hoy el dominio y el subdominio responden también por HTTP sin redirección (hallazgo de seguridad en [dominio](../architecture/dominio.md)).
1. **Supabase → Authentication → URL Configuration → Redirect URLs:** agregar `https://app.cita-suite.com.ar/**` **sin quitar** los existentes. Sin esto, el ingreso con Google desde el subdominio muy probablemente falle. Ya no hace falta `https://cita-suite.com.ar/**`: el dominio principal sirve la landing.
2. **Google Cloud → Credenciales → «Cita Suite - Google Calendar - Producción»:** deben quedar exactamente `https://app.cita-suite.workers.dev/oauth/google-calendar/callback` y `https://app.cita-suite.com.ar/oauth/google-calendar/callback`. **Urgente:** la sonda de las 07:08 UTC (`.verification/dominio-landing-20261027/calendar-redirects-2.json`) muestra que el usuario reemplazó el de workers.dev por uno con doble barra (`…com.ar//oauth/…`): Calendar está roto en producción hasta que se corrija. Repetir la sonda después.
3. **Supabase → Settings → General → Project name:** «Odontologia» → «Cita Suite» y, en el proyecto de staging, «Staging 455» → «Cita Suite Staging». No cambia ref, URLs ni datos.
4. **Contraseña de aplicación de Gmail** (`https://myaccount.google.com/apppasswords`, con verificación en dos pasos): 16 letras. Pegarla directo en Supabase → Authentication → Emails → SMTP según [la guía](../architecture/correo-de-recuperacion.md). El archivo entregado contenía `contraseña=` y 10 dígitos, que no es una contraseña de aplicación; está en `~/.config/cita-suite/private/gmail-smtp-entregado-20261027.txt` (600), fuera del repositorio. Borrarlo si era la contraseña real de la cuenta.
5. **Editor:** reabrir la carpeta `/home/usuario/CascadeProjects/Cita Suite` (hoy está abierta por el alias `Base de Datos Sabrina`).

## Siguiente trabajo de la campaña

- Con 1 y 2 hechos: entrega `PUBLIC_SITE_URL` y `PRODUCTION_APP_ORIGIN` = `https://app.cita-suite.com.ar`, secreto `GOOGLE_CALENDAR_REDIRECT_URI` al callback del subdominio, redirección HTTP→HTTPS en la app (prueba roja primero; exceptuar localhost y comprobar las llamadas del programador) y el subdominio en la configuración versionada (candidata, auditoría, publicación con reversión). Después, el usuario pone Site URL = `https://app.cita-suite.com.ar`, conservando workers.dev en los retornos.
- Prueba real de recuperación por correo cuando SMTP esté configurado (buzón controlado por el usuario).
- Verificación de marca de Google: inicio `https://cita-suite.com.ar` (landing), privacidad y términos en `https://app.cita-suite.com.ar/privacidad` y `/terminos`, TXT de dominio en Cloudflare (usuario).
- Landing: publicar a mano cada cambio de `main` hasta que el usuario conecte Cloudflare Builds; `www` (propuesta no publicada, el clasificador pidió aprobación del usuario).
- Hallazgo abierto: la lista de la agenda formatea horas con la zona del navegador. Observación: `sslmode=require` sin verificación en las conexiones productivas locales.
- Opcional: Natalia con base en el dominio, redirección `www`, *worktrees* viejos de Codex (`Base-de-Datos-Sabrina-*`, ramas de agosto, dos con cambios sin confirmar) a decidir por el usuario.

## Preservación

HEAD `80268e2a501198243996e1bdb0048ce066434727`, índice `55cd8f79…`, lock `98ce4b17…` y plan `5fef6e28…` sin cambios. Fuentes armadas con índices temporales y empujadas sólo al auxiliar. Copias previas en `.verification/wizard-click-20261026/before/` y `worktrees-before/`. No quedan procesos locales propios.
