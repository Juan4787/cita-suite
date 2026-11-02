# Traspaso exacto: dominio y entrega de origen — 27 de octubre de 2026

## Punto exacto

Última actualización: **27 de octubre, 15:00 UTC** (12:00 en Argentina). Antes de ejecutar nada, leer:

- `AGENTS.md`.
- El plan original completo (`docs/plans/refactorizacion-cita-suite.md`, 697 líneas, `5fef6e28…`), que no se modificó.
- El final del [registro](registro-refactorizacion-cita-suite.md).
- [Dominio](../architecture/dominio.md), que tiene el estado vigente, procedimientos y comprobaciones.

**Producción, desde la entrega de origen (publicada el 27-oct, 14:03–14:57 UTC, con autorización expresa del usuario):**

- Aplicación: `95b2596a9b4f24d8ae50d78a94e3f1c9f95b811a` (versión `8b41ec56-5df3-4050-94f2-8b0f40347365`, deployment `69c43cc9-d0cd-48e5-aa35-724b558ffd73`), en `https://app.cita-suite.com.ar` y en `https://app.cita-suite.workers.dev`. `PUBLIC_SITE_URL` es el subdominio.
- Programador: `cae02746-2b69-4481-b9b6-d6441b512f10`, con cinco cron y eventos reales observados.
- Recuperación: vuelta atrás nativa a `d0ac2bcf-7e6a-4786-b2fb-5ff14687d643` (`b108c19`), ensayada a las 14:22 UTC ([publicación y reversión](../architecture/publicacion-y-reversion.md)).

**Landing:** `https://cita-suite.com.ar`, servida por Vercel (fuente `ab3a2e0`) por decisión del usuario: «la dejamos en vercel si no molesta».

**Configuración externa, comprobada el 27-oct:**

- Google: los retornos de los dos clientes están bien, según la sonda `calendar-redirects-7.json`, y la información de la marca apunta a la landing y a las páginas legales de la aplicación.
- Supabase: Site URL `https://app.cita-suite.com.ar`, con los retornos del subdominio permitidos.
- Cloudflare: «Always Use HTTPS» activado.

**Carpetas (reorganizadas por el usuario el 27-oct, antes de las 09:20 UTC):** la aplicación está en `/home/usuario/CascadeProjects/CITA SUITE/Cita Suite App`, la landing en `/home/usuario/CascadeProjects/CITA SUITE/Landing Cita Suite` y Natalia en `/home/usuario/CascadeProjects/CITA SUITE/Web Natalia`. `/home/usuario/CascadeProjects/Cita Suite` ya no existe. Efectos corregidos en el [registro](registro-refactorizacion-cita-suite.md).

**Correo de recuperación: activado y comprobado** el 27-oct a las 22:29 hora de Argentina (01:29 UTC del 28), con la cuenta dedicada `citasuite@gmail.com` ([estado vigente](../architecture/correo-de-recuperacion.md)).

**Siguiente:** el retorno de Calendar al subdominio con un turno sintético de la cuenta de prueba, y la entrega de las horas de la agenda (más abajo).

## Entrega de origen: publicada (lo que sigue es la secuencia ejecutada)

Candidata v2 `95b2596a9b4f24d8ae50d78a94e3f1c9f95b811a`, rama auxiliar `verify/origen-candidate-v2-20261027`, 16 archivos contra `b108c19`. Pruebas rápidas `40451313177` aprobadas y empaquetado `40451368816` aprobado. Detalle del contenido en [dominio](../architecture/dominio.md#entrega-de-origen-candidata-v2-lista-para-staging-las-precondiciones-del-usuario-se-cumplieron-el-27-oct).

1. **Hecho.** Artefacto descargado y validado (`fetch-artifact.mjs 40451368816 95b2596…`): 217 archivos, huella `1aa57a19…`, en `.verification/releases/95b2596/`.
2. **Hecho.** Candidata en staging, versión `f6879ca5-ebe7-4a30-9903-036bbdfa40ba`. Medición real limpia: siete rutas por HTTP responden 308 a HTTPS (`staging-candidate-v2-transport-2.json`). La primera medición, tomada unos 30 s después de instalar, recibió la versión anterior en una ruta: hay que esperar el reparto y exigir dos mediciones limpias.
3. **Decidido.** Staging no tiene secretos de Calendar, así que no se puede ensayar ahí, y la documentación no aclara qué hace una vuelta atrás con los secretos. En producción se **borra** `GOOGLE_CALENDAR_REDIRECT_URI` después de instalar la candidata: el retorno pasa a salir del `PUBLIC_SITE_URL` de cada versión. Se comprueba con `probe-calendar-start.mjs` antes, después y en la vuelta atrás.
4. **Hecho.** Staging pasó a la compatible `4ac26115` (`b108c19`) a las 08:35:06.
5. **Aprobado.** Reversión alojada `40474553664` (job `122089460645`): 130/35/61, reserva nativa completa, `transport` registrado (200).
6. **Hecho.** Staging volvió a la candidata `f6879ca5` a las 08:37:58, con dos mediciones 308.
7. **Aprobado.** Auditoría completa `40474924663` (terminó a las 08:54:59 UTC):
   - 20/20 pasos.
   - Navegador 47/47 en desarrollo, en la candidata compilada y en la reversión, con 0 omitidos, 0 inesperados y 0 intermitentes.
   - Servidor 1411/1411 y cliente 186/186.
   - Staging con `transport` 308.
   - Evidencia recuperada en `release-origen-evidence/` (SHA-256 `04fb6f3e…`).

**Publicación hecha el 27-oct, 14:03–14:57 UTC.** Detalle, horas y recibos en el registro («Publicación productiva de `95b2596`»):

- Copia `40516167872` certificada y descargada de Drive; tercera lectura previa aprobada (14:02:50).
- Programador sin cron (`5880c53b…`, 14:03:28) y margen cumplido (14:19:01).
- App `8b41ec56…` (14:19:59): dos mediciones limpias (workers.dev 308, `redirects: true`) y lectura posterior aprobada.
- Vuelta atrás nativa a `d0ac2bcf…` y retorno nativo a `8b41ec56…`, ambos verificados. La lectura posterior al retorno falló una vez por el límite de 5 ingresos en 15 minutos de la cuenta de prueba (comprobado en la base; no es una regresión) y se aprobó al repetirla a las 14:39:03.
- Programador `cae02746…` con los cinco cron (14:39:51) y eventos reales de los cinco tipos, 20 en total, todos `ok`, entre las 14:50:33 y las 15:21:11. Estado final comprobado a las 15:21:39 (`crons-final.json`).

Antecedente: la pausa de la mañana. Qué se había hecho entonces:

- Primera lectura previa aprobada, 08:56 UTC (`production-before-20261027T0856Z.json`; se llamaba `production-before.json`).
- Copia manual `40477404643` certificada y descargada de Drive, 08:59 UTC (`manual-backup{,-readback}.json`).
- **Segunda lectura previa aprobada, 09:27:32 UTC** (`production-before.json`):
  - Preservación: HEAD, índice, lock y plan iguales.
  - App `d0ac2bcf…` (`b108c19`) con 33 enlaces; programador `f105c4ff…` con los cinco cron; staging sin cron.
  - Base: 126 migraciones, entrada heredada apagada, 19 negocios, 122 pacientes, 107 turnos, 1 conexión y 1 evento de Calendar. Igual que a las 08:56.
  - Autenticación interna 401/410; agenda autenticada 200 por `app.cita-suite.com.ar` y por workers.dev.

Por qué se pausó:

- 09:06 UTC: el control de permisos respondió varias veces «sin veredicto», una falla transitoria suya.
- **09:29 UTC: el control de permisos rechazó explícitamente** `deploy-production-workers.mjs scheduler-without-crons`, con el motivo «Production Deploy». No es una falla transitoria: no se reintentó ni se buscó otro camino.
- La orden no llegó a ejecutarse: no existe `production-scheduler-without-crons.log`. Producción sigue sirviendo `b108c19` (`d0ac2bcf…`), con el programador `f105c4ff…` y sus cinco cron.
- Hace falta que el usuario autorice el despliegue, en la conversación o con una regla de permisos.

Cómo se retomó, después de la autorización y en este orden (ya ejecutado):

1. Copia nueva, porque ya pasó más de una hora desde la de las 08:59 UTC. Antes, agregar `-20261027T0859Z` al nombre de `manual-backup.json`, `manual-backup.log`, `manual-backup-readback.json` y `manual-backup-dispatch.json`: el certificador se niega si existen. Después, `gh workflow run backup.yml --repo Juan4787/cita-suite-respaldos --ref main -f mode=backup` y `python3 -I .verification/dominio-landing-20261027/check-manual-backup.py <corrida>`.
2. Repetir la lectura previa. Antes, mover `production-before.json` a `production-before-20261027T0927Z.json`, por la misma razón.
3. Seguir con el punto 8, desde «Programador sin cron».

**Secreto de Calendar: no se borra en esta publicación.** No hay turnos futuros sintéticos para comprobarlo; los únicos son del consultorio propio del usuario. Calendar sigue con el retorno de workers.dev, que está registrado y funciona.
8. **Publicación productiva**, según [publicación y reversión](../architecture/publicacion-y-reversion.md), con las herramientas de `.verification/dominio-landing-20261027/` (`production-state-v3.mjs`, `production-readback.mjs`, `production-crons-read.mjs`, `check-manual-backup.py`, `probe-calendar-start.mjs`):
   - `node .verification/dominio-landing-20261027/production-state-v3.mjs --capture-before`, la lectura previa, sólo de lectura.
   - Copia actual: `backup.yml` del ejecutor privado, en modo `backup`, y `python3 -I .verification/dominio-landing-20261027/check-manual-backup.py <corrida>`.
   - Programador sin cron (`deploy-production-workers.mjs scheduler-without-crons`) y margen de 15 minutos.
   - Aplicación candidata (`deploy-production-workers.mjs app .verification/releases/95b2596`) y `verify-production-release.mjs`, que debe mostrar `redirects: true` en workers.dev con dos mediciones limpias. Lectura posterior en las dos direcciones.
   - El secreto de Calendar no se toca en esta publicación (ver arriba).
   - Ensayo compatible con vuelta atrás nativa a `d0ac2bcf`; después, retorno nativo a la versión candidata.
   - Programador con cron y observación de eventos reales.
9. **Después:** el usuario prueba el ingreso con Google y la recuperación desde el subdominio.

**Plazo:** el artefacto de la base compatible (`40410601000`) se guarda tres días desde el 26-oct a las 22:12 UTC, así que vence alrededor del 29-oct a las 22:12 UTC. Para la recuperación no hace falta: la vuelta atrás nativa usa la versión `d0ac2bcf…`, que Cloudflare conserva, y sus bytes están en `.verification/releases/b108c19/`.

## Siguiente entrega: retorno de Calendar al subdominio

`GOOGLE_CALENDAR_REDIRECT_URI` sigue apuntando a `https://app.cita-suite.workers.dev/oauth/google-calendar/callback`. Plan decidido: borrar el secreto para que el retorno salga del `PUBLIC_SITE_URL` de cada versión, y comprobarlo con `probe-calendar-start.mjs` antes, después y en una vuelta atrás, sobre un turno sintético futuro de la cuenta de prueba (`cuentaprueba3-855fc174`) creado y retirado para eso. No se usan los turnos del consultorio propio del usuario. Detalle en [dominio](../architecture/dominio.md), punto 6.

## Estado al 28-oct, 05:10 UTC (02:10 de Argentina): publicado

- **Producción sirve `aacba5b`** (versión `4e29aba6`, sin el secreto de Calendar), programador `ba7b746d` con cinco cron. Recuperación: `wrangler rollback 8b41ec56…` (`95b2596`), ensayada. Detalle en [publicación y reversión](../architecture/publicacion-y-reversion.md).
- **Calendar en el subdominio**, medido; el turno sintético se canceló a las 05:06.
- **Mantenimiento confirmado:** el evento `17 */3` de las 06:17:28 UTC terminó `ok`, sin excepciones, en `ba7b746d`; los cinco cron quedaron vistos en ejecución real.
- **Siguiente:** no quedan entregas de código planificadas en este traspaso. Pendientes del usuario: abajo.

## Estado al 28-oct, 03:41 UTC (antecedente)

- **Horas de la agenda: candidata v3 `aacba5b10ff6030ac061e20ce0cccdf28126c180` aprobada** por la auditoría completa `40626283483` (empaquetado `40624836873`, vuelta atrás `40626088681`), en staging (`642c21ef`). Falta publicarla en producción con la secuencia de [publicación y reversión](../architecture/publicacion-y-reversion.md): copia, programador sin cron y margen, instalación desde `.verification/releases/aacba5b`, dos mediciones y lectura, ensayo `wrangler rollback 8b41ec56-5df3-4050-94f2-8b0f40347365` y retorno, programador con cron. **Necesita autorización expresa del usuario.** Herramientas de producción: adaptar las de `.verification/dominio-landing-20261027/` a `aacba5b` con `95b2596` como compatible. Detalle en el [registro](registro-refactorizacion-cita-suite.md).
- **Calendar al subdominio:** preparado (turno sintético del 6-nov en la cuenta de prueba, medición previa). El borrado de `GOOGLE_CALENDAR_REDIRECT_URI` lo rechazó el control de permisos («Secret-Store Writes»): necesita autorización expresa. Conviene hacerlo en la misma ventana que la publicación de `aacba5b`, después de instalarla.

## Siguiente entrega: horas de la agenda (antecedente; resuelta en `aacba5b`)

En `routes/odonto/agenda/+page.svelte` hay cuatro cosas que usan la zona horaria del navegador y no la del consultorio:

- `timeOnly`: la hora de cada turno.
- `shortDayLabel`: la etiqueta del día.
- `localDateOf`: el día de cada turno.
- `todayStr` / `isToday`: qué día es hoy.

Reproducción conservada: con el navegador de CI en UTC, un turno de las 09:00 de Córdoba se listó «12:00». La corrección usa `business.timezone`; el layout ya entrega `timezone` y `todayISO`. Hace falta antes una prueba de navegador que falle con otra `timezoneId`. Se deja fuera de la entrega de origen para no repetir la candidata ya verificada.

## Pendientes del usuario

1. ~~Cargar en Supabase la contraseña de aplicación de Gmail~~: hecho el 27-oct con `citasuite@gmail.com` y comprobado con un correo real.
2. ~~Probar el ingreso con Google~~ desde `https://app.cita-suite.com.ar/login`: hecho por el usuario el 27-oct, funciona bien.
3. Supabase: **producción ya se llama «Cita Suite»** (comprobado el 27-oct a las 09:3x UTC con `supabase projects list`; ref `yjzferwuzbtgpmdnzlcb`, sana). Falta staging: «Staging 455» → «Cita Suite Staging» (ref `ikaudqoilclfnztkxubz`, organización `waoipxhhnbpnpjhbdssn`, de la cuenta del hermano del usuario: hace falta rol de dueño o administrador). Es sólo el nombre visible.
4. ~~Archivo de la entrega del correo~~: `~/.config/cita-suite/private/gmail-smtp-entregado-20261027.txt` borrado el 29-oct a pedido del usuario.
5. No enviar todavía la verificación de marca de Google: el dominio de Supabase no se puede verificar.
6. Comprobar que los avisos de falla de GitHub le llegan por correo (cuenta `Juan4787`): es lo único no certificado de la vigilancia de las copias ([registro](registro-refactorizacion-cita-suite.md)).
7. Opcionales: los de [dominio](../architecture/dominio.md#pendientes).
8. **Verificación de Google: poner la web a nombre del usuario ante Google.** Es el último requisito que falta para que pase la verificación de marca. Hay que verificar la propiedad de `cita-suite.com.ar` en Google Search Console con la cuenta de Google dueña del proyecto OAuth (registro TXT en el DNS). Cuando esté hecho, recién ahí enviar la verificación (punto 5).

Estado al 29-oct: quedan pendientes los puntos 3, 5, 6 y 8; el usuario los termina después.

Resueltos el 27-oct: el paciente nuevo (122) lo creó el usuario; la landing local pasó a `main` (`ab3a2e0`); la carpeta se abre ahora desde `/home/usuario/CascadeProjects/CITA SUITE`; la publicación productiva se autorizó y se hizo.

## Preservación

HEAD `80268e2a501198243996e1bdb0048ce066434727`, índice `55cd8f79…` y plan `5fef6e28…`, sin cambios, comprobados también después de la reorganización de carpetas. Las fuentes se arman con índices temporales y se empujan sólo al repositorio auxiliar; usar `GIT_OPTIONAL_LOCKS=0` en el repositorio de la app para que Git no reescriba el índice. La copia local de la landing está en `main` (`ab3a2e0`, igual a GitHub), con sus dos PNG sin seguimiento; la rama `codex/interactive-diagnostic-flow` se conserva y todos sus commits están en `main`. Los siete *worktrees* de Codex y Cursor se repararon con `git worktree repair` (copias previas en `.verification/reorganizacion-carpetas-20261027/worktrees-before/`) y el enlace `Base de Datos Sabrina` apunta a `CITA SUITE/Cita Suite App`. No quedan procesos locales propios.
