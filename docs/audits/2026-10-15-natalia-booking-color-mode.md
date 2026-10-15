# Continuidad del modo claro y oscuro en la reserva

## Causa y corrección

`BookingAppearance` consultaba `prefers-color-scheme` al abrir la reserva completa. Natalia, en cambio, arranca en claro y sólo usa oscuro cuando se elige en la web. Por eso ambos dominios podían presentar modos diferentes.

Natalia transmite su modo visible con `color_mode=light|dark` en los enlaces nativos, sin interceptar la navegación. Incluye enlaces del catálogo (conservando `service_id`), cambios manuales de tema y `/turnos`. Este último redirige según la elección restaurada y mantiene una redirección inmediata en claro sin JavaScript.

El layout servidor de Cita Suite acepta exclusivamente esos dos valores y guarda una cookie visual propia (`HttpOnly`, `SameSite=Lax`, `Secure` en HTTPS, 30 días). Así conserva el modo en los siguientes pasos y en la gestión e información del turno, aunque ya no lleven ese parámetro. Los valores inválidos se ignoran. Sin elección guardada arranca en claro; la preferencia del sistema no interviene. La superficie se renderiza con el modo desde el servidor y los menús flotantes reciben el mismo modo al hidratar. El puente existente mantiene el control para integraciones dentro de marcos. La apariencia estándar de Cita Suite no utiliza esta preferencia.

No se cambia la configuración del consultorio, la base, las reservas, los cuestionarios ni las notificaciones. La cookie no contiene identificadores o información de pacientes. Si el navegador bloquea todas las cookies, la preferencia no puede persistir entre páginas y se recupera el modo claro predeterminado al perderse el parámetro. El rollback sólo requiere restaurar ambas versiones; una cookie restante no afecta versiones anteriores.

## Verificación y reproducción

- `pnpm --filter web test src/routes/booking-color-mode.test.ts src/lib/server/public-booking-navigation.test.ts --maxWorkers=1 --no-file-parallelism`: elección explícita, precedencia, persistencia, valores inválidos y navegación existente.
- `pnpm --filter web test:client src/lib/booking/BookingAppearance.client.test.ts src/lib/booking/PublicBookingFlow.client.test.ts --maxWorkers=1 --no-file-parallelism`: renderizado claro/oscuro, ausencia de consulta al sistema, apariencia estándar y compatibilidad del marco.
- `pnpm --filter web check` y builds afectados secuenciales, con memoria Node limitada.
- `pnpm --filter natalia test:browser`: once escenarios interceptados, incluyendo sistema oscuro con web clara, sistema claro con web oscura, catálogo, cambio manual, redirección con modo restaurado y sin JavaScript. No escriben en producción.

Publicar Cita Suite antes de Natalia. Verificar versión servida, assets y portada → turnero → formulario en los modos opuestos al sistema, y recarga sin parámetro conservando la cookie. La comprobación remota es de sólo lectura: no se crean reservas ni se activan suscripciones push. Evidencia por revisión en `audit-evidence/`; Chromium con viewports emulados, sin afirmar prueba sobre dispositivo físico.
