# Traspaso: confirmación de correo — entrega terminada

> **Nota del 2 de noviembre de 2026:** las instrucciones de este documento de preservar el `HEAD` `80268e2` y el índice `55cd8f79…` quedaron superadas. Esa regla dejó divergir la copia local de GitHub y de producción. Ahora la rama de trabajo es `main`, que contiene la historia completa. El estado vigente está en [el registro único](../ESTADO-VIGENTE.md) y se comprueba con `node scripts/check-repo-sync.mjs`.

**Nota del 1 de noviembre de 2026:** producción sirve **V10b** `68f31741f6ff7f2253c036800b1369f1eda16510` (versión `1d2b4acd-7dd8-4cb7-81e3-a205bafe9f8d`), que no cambia la confirmación de correo y se comprobó después de publicar. La recuperación vigente, que antes de volver a V9 exige un paso de datos, está en `docs/architecture/publicacion-y-reversion.md`. Lo que sigue describe V9 y su recuperación de entonces.

## Estado de V9 — 31 de octubre de 2026, 21:58 UTC

**V9 publicada y comprobada.** Fuente `a3c707f368736da90d2adf5850d291460f657af0` (V8 más el registro de las fallas al comprobar el enlace), Worker `app`, versión de Cloudflare `2ef53723-0a46-4879-bf6e-4af5ed5320c9`, en los dos orígenes. Sin migraciones.

- Origen del cambio: hallazgo 4 de la revisión del 31 de octubre. Autorización: plan de señas y avisos, sección 12.15.
- Evidencia: `.verification/confirmacion-email-v9-20261031/`:
  - prueba roja (2 fallas) y verde (18 de 18);
  - tres mutaciones detectadas;
  - `fast` 41244933261;
  - paquete 41244945074 (manifiesto `3a604dc3…`);
  - navegador sobre el programa exacto 41245436407 (12 de 12);
  - registro del despliegue;
  - `comprobacion-publicacion-a3c707f3.json`;
  - recibo `.verification/production-release-2026-10-31T21-58-33-794Z.json`.
- Puntero `.verification/ci-source.json` en V9. El de V8 se conserva en `.verification/confirmacion-email-v9-20261031/ci-source-before-production-v9-20261031.json`.
- **Recuperación inmediata:** `NODE_OPTIONS=--max-old-space-size=192 pnpm --filter web exec wrangler rollback a1844665-447e-40bb-b9e5-ce7c03ed29d7 --name app --message "<motivo>" --yes` (V8, conserva `/confirmar-correo`). Si hiciera falta algo anterior, el paquete compatible `c195b1e` y su comando están en `docs/architecture/publicacion-y-reversion.md`.
- Comportamiento del registro en producción: `logServerFailure` conserva sólo el estado HTTP y el estado SQL, nunca otros datos. Por eso las líneas nuevas muestran su etiqueta («No se pudo comprobar el enlace de confirmación de correo», con el estado 5xx o 429, y «No se pudo conectar para comprobar el enlace de confirmación») sin el código de Auth. La falla deja de ser silenciosa, que es el objetivo.
- HEAD `80268e2a501198243996e1bdb0048ce066434727` e índice `55cd8f79…` sin cambios.
- Lo que queda pendiente en general está en `docs/plans/pendientes-vigentes.md`.

## Estado anterior (V8) — 31 de octubre de 2026, 20:22 UTC

**Publicada y comprobada en producción. No queda pendiente publicar esta corrección.** El usuario pidió terminarla y luego continuar exactamente desde el punto pendiente, con máximo rigor. Se utilizó el paquete ya aprobado, directamente en producción, según su corrección metodológica. No se repitieron staging, builds, release completo, renovación de backup ni ensayos de reversión.

- Fuente publicada: **V8 `408ca04d9e6750e4657dc087264644665a63fb37`**.
- Worker `app`: versión Cloudflare **`a1844665-447e-40bb-b9e5-ce7c03ed29d7`**; despliegue `4c74d295-cf1b-4ada-b856-fb1a6ae82890`.
- Orígenes comprobados: `https://app.cita-suite.com.ar` y `https://app.cita-suite.workers.dev`.
- Confirmación obligatoria de correo y registro continúan habilitados. Sin migraciones; 128 aplicadas. Scheduler, crons, bindings, configuración comercial e integraciones conservados.
- Puntero operativo `.verification/ci-source.json` actualizado a V8. Fuente anterior preservada en `ci-source-before-production-v8-20261031.json`.
- HEAD sigue `80268e2a501198243996e1bdb0048ce066434727`; índice SHA-256 `55cd8f7975542b806308d3e067f81660fe107ed1c5cdbed88962dbe614a1faba`. No reset/clean/add-A. Árbol grande con trabajo del usuario: conservarlo.

## Resultado de producto

Crear cuenta o ingresar con correo pendiente abre `/confirmar-correo`, con **Revisá tu correo**, estilo normal y siguientes pasos. Reenvío con espera, corrección de dirección y vuelta al ingreso. Auth verifica realmente la confirmación; los enlaces falsos/usados tienen una salida informativa. Confirmar no crea ni reemplaza sesión y admite otro navegador/dispositivo. La ruta y su guía están en [confirmacion-de-correo.md](../architecture/confirmacion-de-correo.md).

## Evidencia de esta publicación

Todo bajo `.verification/confirmacion-email-20261030/` salvo donde se indica:

1. `production-resume-20261031.json`: destino anterior C9 comprobado antes de publicar; no se pisó una entrega posterior.
2. `production-candidate-v8-20261031.log`: despliegue exacto del paquete aprobado, sin build local.
3. `production-candidate-v8-auth-20261031.json`: ambos orígenes, Supabase alojado real, pendiente, headers no-store/no-referrer, resultado firmado, contexto/token falsos rechazados y ninguna sesión automática. Usuario propio eliminado; no prueba envío de correo.
4. `production-candidate-v8-assets-20261031.json`: 139 archivos cliente exactos en cada origen y CSP del proyecto productivo.
5. `production-v8-agenda-main-20261031.json` y `production-v8-agenda-workers-20261031.json`: ingreso habitual y agenda autenticada, pertenencia al consultorio y cero nodos de error.
6. `production-v8-release-20261031.log` y `.verification/production-release-2026-10-31T20-20-54-638Z.json`: versión, archivos, HTTPS, política y **74 relaciones sin exposición anónima**.
7. **Navegador productivo [41238345216](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41238345216), aprobado**, final 20:21:33 UTC. Commit de pruebas `78a735b4f0767a0a02a75bdff2a685b74893db84`, sobre V8; sólo añade el comprobador y sustituye el workflow en un índice temporal. No se desplegó ese commit ni cambió el workflow local existente. Chromium secuencial externo: sin navegador administrado disponible y RAM local limitada. Sin Docker, build ni clonación de servicios.
   - Alta real desde UI → pantalla pendiente, sin rojo ni sesión; reenvío aceptado por proveedor tras espera; corrección de correo; ingreso no confirmado.
   - Enlace generado por Supabase real → otro navegador → correo confirmado; fragmento retirado y sin sesión automática; enlace falso sobre éxito previo y enlace reutilizado → salida neutral.
   - Cinco anchos: **320/390/768/1280/1600**, sin desbordes; título/contenido/controles correctos; sin errores de consola/ejecución. Capturas móvil/escritorio/confirmado inspeccionadas directamente.
   - `production-browser-evidence-20261031`: **8 archivos**, SHA-256 **`2cb9aee42db2e7fcf3f0536f8c9ebc774b898d78d12946a9efd5f5e56cfd7d0b`**. Recibo `.verification/production-auth-ux/proof.json` dentro de esa carpeta. Metadatos `production-browser-run-20261031.json` y logs ZIP preservados.
8. `production-browser-cleanup-20261031.json`: se comprobó en Auth que el alta real seguía pendiente y el usuario del enlace estaba confirmado; ambos eliminados y ausencia comprobada. Se quitó el secreto temporal de CI. Sin credenciales/tokens en capturas o trazas.
9. `production-source-pointer-20261031.json`: 1142 archivos runtime/scripts/migraciones/config raíz revalidados antes de seleccionar el certificado V8; plantilla local del proveedor preservada, no aplicada.
10. `production-final-v8-20261031.json` y `production-final-comparison-20261031.json`: versión publicada y protección de activos reales comprobadas a las 20:22:18 UTC. No se impuso igualdad de pacientes/turnos ficticios.

## Alcance y límites honestos

La prueba productiva envió alta/reenvío a un alias propio del buzón dedicado autorizado. **No se observó la llegada al buzón externo ni se extrajo su enlace.** El enlace recorrido en el navegador fue generado administrativamente por el Auth productivo, no recibido por SMTP. La evidencia SMTP con apertura del correo capturado corresponde al release aislado previo, no a recepción externa. Este límite no se convierte en una afirmación de entrega ni en una razón para seguir reconstruyendo entornos.

Las suites completas exactas ya aprobadas cubren los flujos relacionados: release **41137595117, 20/20**, fuente **58/58**, candidata compilada **58/58**, recuperación **51/51**; diagnóstico **41136359990, 7/7** incluye confirmación y roles/invitaciones. No se repitieron por inercia. Evidencias y fallos históricos permanecen en el [registro](registro-confirmacion-email-20261030.md).

Sin JavaScript hay confirmación en Auth e ingreso manual; el retiro del fragmento y el resultado verificado en pantalla requieren JavaScript. No se contrató nada, cambió SMTP/plantillas/DNS ni se desplegó la landing o el sitio de Natalia.

## Recuperación disponible y contexto para una próxima tarea

- Paquete publicado: `release-candidate-v8` (225 entradas), manifiesto SHA-256 `91eaa5a4019e06121444c3965bed188d9f5f4a360256218db7afd68f225cabd8`, run **41136548057**.
- Recuperación compatible: `release-recovery-v7`, fuente **`c195b1e388f3acc947464363514ae99f94c413da`**, manifiesto `961ffbdb1c3e61e5cbb38aed9f3f887a5b7eb57126e06064c1a0ddf5e9c6a0fb`, run **41136024072**. Ambos preservados también en `~/.local/share/cita-suite/releases/<SHA>`.
- Recuperar sólo si aparece una regresión real. **C9 puro no sirve**: carece de `/confirmar-correo` para enlaces ya emitidos. La recuperación compatible ya fue ensayada; no repetir ciclos como condición administrativa.
- Staging conserva recuperación `c195b1e…`, versión `806eb3a2-1dba-43ac-88d1-c57eb9f54625`. Restaurar candidata allí es opcional si se vuelve a usar; no es pendiente de esta entrega productiva.
- Respaldo privado **41131024848**, restauración SQL/Storage aislada sin diferencias, copia local independiente en `~/.local/share/cita-suite/backups/production-confirmacion-email-20261030T213416Z`. Esta UI/Auth no migra la base; no exigir renovación por seis horas.
- No hay pacientes reales, según el usuario. Los datos ficticios son material de prueba. Proteger cuentas de personas, secretos, permisos, aislamiento, configuración comercial, código y dominios. Mantener auditoría rigurosa y ampliar investigaciones pertinentes, con controles que respondan a riesgos concretos.
- **Alcance histórico de este cierre:** Natalia/D/E estaban en pausa. El alcance posterior de E es [plan 12.18](propuesta-senas-avisos-natalia.md#etapa-e-vigente) y su [especificación](etapa-e-correo-autogestion.md); definición revisada y ejecución por iniciar cuando Juan lo indique. D y los datos de Natalia faltantes conservan sus pendientes; no modificar su acceso por esta tarea. La landing sigue en Vercel. La autorización productiva persiste; no hace falta volver a pedir permiso para lo ya autorizado.
- El traspaso anterior completo está preservado en `.verification/confirmacion-email-20261030/traspaso-antes-publicacion-20261031.md` como historia, no como instrucciones pendientes.


## Revisión de consistencia documental posterior

El 31 de octubre se corrigieron referencias generales que todavía presentaban revisiones/procedimientos anteriores como actuales. README, [índice documental](../README.md), [publicación general](../architecture/publicacion-y-reversion.md), traspasos relacionados, auditoría, respaldo/verificación y contratos/matriz remiten ahora al cierre V8 o identifican expresamente su contenido histórico. No se reabre la entrega ni se modifican recibos antiguos. Se comprobaron 204 destinos internos de archivos en 17 documentos y la conservación de los 1142 archivos certificados de runtime, HEAD e índice. Detalle y límites de esa comprobación en el registro.
