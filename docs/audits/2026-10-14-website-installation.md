# Conexión del sitio y turnero de Natalia

## Causa comprobada

La web publicada respondía correctamente, pero su atributo `data-booking-key` estaba vacío. El enlace público mostrado por el usuario sí respondía con catálogo y seis servicios; Cita Suite permitía el origen exacto de Natalia. El bloqueo era la ausencia de configuración en la publicación de la web, no una ausencia de servicios ni un rechazo del dominio.

Guardar una URL en Cita Suite autoriza ese origen para mostrar el marco y consultar la información pública. No puede insertar código en un sitio externo ni modificar su publicación. El panel anterior no daba un paso concreto de instalación y llamaba «conectados» a registros cuya instalación no había comprobado.

## Reparación

- Guardar conduce al paso de instalación; el editor se pliega y sigue accesible. Los mensajes distinguen configuración, autorización e instalación.
- Se puede copiar una agenda integrada o un enlace de reserva. El código se puede seleccionar manualmente si el portapapeles no está disponible. La prueba del sitio es explícitamente manual; no se inventa una verificación automática.
- El SDK v1 acepta el bloque declarativo copiado. Conserva `mount`, el contrato de mensajes, origen/ventana/instancia, idempotencia y recuperación. Repetir la instalación del mismo bloque no duplica el calendario. Si JavaScript no carga, queda un enlace utilizable.
- Una selección explícita de profesionales o servicios vacía se rechaza; nunca se convierte silenciosamente en acceso a todos. La clave pública y el resto de la configuración se conservan al guardar.
- El recuento administrativo dice «configurados» y excluye registros sin orígenes, sin afirmar que una web esté instalada.
- Natalia usa la clave pública del enlace configurado por el usuario. Se guardaron `PUBLIC_CITA_BASE_URL` y `PUBLIC_NATALIA_INTEGRATION_KEY` en el proyecto de Vercel. No son credenciales de Supabase. Los builds de producción rechazan la ausencia de clave y una página de turnos sin configurar.
- `/turnos` carga la agenda dentro de la página y conserva una salida directa si el SDK falla. La página principal mantiene la carga del SDK al intentar reservar, junto con sus temas y destinos existentes.

No se modificaron datos clínicos ni configuración de profesionales/servicios de producción. No hay migraciones, cambios de Storage, cursos ni noticias.

## Validación

| Evidencia | Alcance y resultado |
| --- | --- |
| 65 pruebas de integración/SDK/generación de código | Secuenciales; origen, privacidad, recuperación, compatibilidad y validación de código |
| Svelte/TypeScript | Fuente final sin errores ni advertencias |
| Contratos SQL locales | Base descartable reconstruida con 97 migraciones existentes |
| 6 comprobaciones Chromium locales | Auth simulado y PostgreSQL/PostgREST reales locales; guardas de selecciones vacías, conservación de configuración, portapapeles, permisos, código copiado y enlace sin JavaScript |
| Instalación copiada | Un servidor HTTP local sirve exactamente el código entregado por el panel; carga el SDK y calendario reales de la app y llega hasta el formulario del paciente, sin reservar |
| 8 escenarios de Natalia | Tráfico de Cita Suite interceptado; carga por intención, contacto/catálogo, datos inválidos, SDK fallido, página de turnos integrada y su alternativa en caso de error |
| Capturas | Escritorio 1440, móvil 390 y 320 sin desborde horizontal, más web sintética con el calendario real local |
| Presupuesto de Natalia | HTML principal 67.136 bytes; JavaScript inicial 7.261; CSS 46.354; fuentes 157.308; sin widget inicial en portada |

La revisión independiente indicó `ship` sobre el panel administrativo y el bloque instalado, con evidencia local. No certifica por sí sola el despliegue de Natalia ni una reserva en producción. El detector se ejecutó una vez: dos avisos de documentación tipográfica sobre `0.85rem`, sin defectos visuales materiales en las capturas.

Durante la preparación, una página servida mediante interceptación del navegador recibió el bloqueo de acceso a direcciones loopback de Chromium. Se corrigió el entorno usando un servidor HTTP real; no se desactivaron controles de seguridad. Una comprobación inicial de permisos omitía la cookie de renovación y seguía la redirección a login: se corrigió la sesión simulada y se verificó la prohibición sin seguir redirecciones. Ninguno de esos dos resultados se atribuye a un defecto de producción.

Evidencia versionada: [resultados](evidence/2026-10-14-website-installation/results.json), [código copiado](evidence/2026-10-14-website-installation/copied-code.html), [escritorio](evidence/2026-10-14-website-installation/desktop.png), [móvil](evidence/2026-10-14-website-installation/mobile.png), [320 px](evidence/2026-10-14-website-installation/user-320.png) y [calendario instalado local](evidence/2026-10-14-website-installation/installed-site-mobile.png). Las direcciones y datos de estas capturas son sintéticos.

## Reproducir y publicar

Ejecutar siempre secuencialmente. Las pruebas focalizadas son `pnpm --filter web test src/lib/booking/embed-sdk.test.ts src/lib/booking/booking-installation.test.ts src/lib/server/booking-integrations.test.ts src/lib/server/booking-integration-request.test.ts --maxWorkers=1 --no-file-parallelism` y `pnpm --filter web check`.

Para el navegador, crear una base descartable con `node scripts/test-booking-foundation.mjs --keep`; iniciar `node scripts/serve-booking-fixture.mjs <contenedor>` y ejecutar `node scripts/qa-booking-installation.mjs`. El script sólo acepta loopback y la clínica sintética; usa RPC de propietario para autorizar el sitio de prueba y comprueba el flujo con el código copiado. No imprimir ni versionar `/tmp/cita-booking-runtime.json`. Detener el supervisor para limpiar servidor, base, redes y credenciales sintéticas.

Natalia se compila con las dos variables públicas del proyecto y se verifica con `pnpm --filter natalia test:browser`. Las pruebas reemplazan la clave publicada por una sintética e interceptan todo el tráfico hacia Cita Suite. No ejecutar esos escenarios contra una base real.

La publicación de Cita Suite usa GitHub `main` y el build conectado de Cloudflare; Natalia mantiene el proyecto Vercel `natalia-frutos`. Verificar el commit servido, los archivos publicados y después la navegación real de lectura en Natalia hasta el formulario, sin enviar una reserva. Guardar los recibos de publicación separados en `audit-evidence/`, asociados al commit. Una futura publicación estática debe volver a usar las variables públicas guardadas y comprobar que el HTML contiene la misma clave; no usar un build vacío ni copiar datos reales de profesionales a una maqueta.

Para otra web, registrar su origen exacto y colocar allí el código entregado. Cambiar el dominio no reescribe una web; cambiar la selección del enlace conserva su clave y se refleja desde Cita Suite. Una clave nueva requiere actualizar la instalación de esa web.
