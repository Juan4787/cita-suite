# Estado vigente del repositorio y de producción

**Este es el registro único de qué historia y qué cambios están vigentes.** Se actualiza en el mismo paso de trabajo que cambia cualquiera de estos datos, nunca después. Eso incluye publicar, cambiar de rama, integrar, o dejar código distinto de producción. `node scripts/check-repo-sync.mjs`, desde la raíz, lo compara con Git, con GitHub y con la revisión que sirve producción, y falla ante cualquier diferencia.

Última actualización: 6 de noviembre de 2026, 18:05 hora argentina. Quinta versión de E publicada: lee las formas reales de los eventos de Zoho, según el [mandato integral](plans/mandato-integral-avisos-20261105.md). [Plan canónico y checkpoint](plans/plan-integral-avisos-20261105.md).

## Datos verificables

```estado
rama_de_trabajo: main
produccion_revision: 93b711a13fd107ef1d4cd5ecfde064fe37c52259
produccion_version_cloudflare: eb1e8cf8-a8bd-4964-bfc0-66bd6c63a1f2
produccion_repositorio: github-secundaria:Juan4787/cita-suite-verificacion.git
```

- **Producción** sirve la quinta versión de E en `https://app.cita-suite.com.ar` y en `app.cita-suite.workers.dev`: la instantánea `93b711a1` de `main` `f459b95c`, con las 164 migraciones aplicadas.
- **La revisión publicada es antecesora de `main`.** Todo lo que corre en producción está en la historia de `main`.
- **V12b dejó de ser una vuelta atrás válida** desde las 07:39 UTC del 6 de noviembre, cuando se confirmaron las migraciones. Nunca usar `wrangler rollback` a una versión anterior a E. Recuperación vigente: [guía de publicación](architecture/publicacion-y-reversion.md#e--publicación-y-recuperación-compatible-5-de-noviembre).

## Etapa E — publicada el 6 de noviembre

Autorización de implementación, pruebas y publicación vigente: [plan 12.32](plans/propuesta-senas-avisos-natalia.md#mandato-integral-20261105). Seguimiento en el [plan canónico](plans/plan-integral-avisos-20261105.md), evidencia en el [registro activo](plans/ejecucion-etapa-e-20261103.md). El [traspaso del 5 de noviembre](plans/traspaso-etapa-e-20261105.md) queda como historia.

| Dato | Valor comprobado en el destino |
|---|---|
| Worker `app` | Versión `eb1e8cf8-a8bd-4964-bfc0-66bd6c63a1f2`. Vuelta atrás válida: `a8e1bea1-7aab-47fe-ba2d-e60176c702f3`, código de la cuarta versión con la clave vigente del webhook; su lector no reconoce entregas ni quejas reales. No se ensayó |
| Worker `cita-suite-scheduler` | Versión `853b9020-5738-4a66-be5e-acf1b1d6cb09`, cinco cron: `*/5`, `1-59/5`, `2-59/5`, `3-59/5` y `17 */3` |
| Migraciones | 164 en la historia de producción: las 32 de E entraron en una transacción de 18 s, y la correctiva `20261106030000` en otra de 1 s |
| Interruptores | `reschedule_enabled` y `email_producer_enabled` encendidos; `GOOGLE_CALENDAR_MANAGED_ENABLED=true`; tope diario de correo 100, reserva 10; `private.deposit_automation` sin cambios |
| Crédito de Zoho registrado | 9.997 correos desde el 6 de noviembre, vencimiento 3 de diciembre de 2026 |
| Cloudflare | Configuration Rule activa «Webhook de Zoho»: apaga Browser Integrity Check sólo en `/api/zoho/webhook`. No fue la causa del fallo de verificación y, medido desde esta máquina, el agente `Webhook` de Zoho pasa sin ella. Se conserva por precaución y puede retirarse |
| Webhook de Zoho | Creado el 6 de noviembre en `agent_1`, verificado por el panel, con entregado, devoluciones temporales y permanentes y bucle de retroalimentación. Clave cargada. Entrega real comprobada: ZH10 acreditado. Sin un rebote ni una queja reales |
| Remitente de Natalia | Sin configurar por decisión de Juan: no salen correos de su consultorio |

## Código que difiere de producción

El chequeo compara esta lista con `git diff --name-status <produccion_revision> HEAD` sobre el código (`apps`, `packages`, `scripts`, `supabase` y los archivos de configuración de la raíz, sin `apps/web/output`). Tiene que coincidir exactamente.

```codigo-distinto-de-produccion
M	apps/web/.impeccable/surfaces/gestion-del-turno.md
M	apps/web/DESIGN.md
M	apps/web/e2e/agenda-business-timezone.spec.ts
M	apps/web/e2e/appointment-deposits.spec.ts
M	apps/web/e2e/appointment-slot-releases.spec.ts
M	apps/web/e2e/booking-embed.spec.ts
M	apps/web/e2e/booking-reschedule-policy.spec.ts
M	apps/web/e2e/clinical-entry-date.spec.ts
M	apps/web/e2e/clinical-files.spec.ts
M	apps/web/e2e/email-preferences.spec.ts
M	apps/web/e2e/helpers/browser-diagnostics.ts
A	apps/web/e2e/helpers/engine.ts
M	apps/web/e2e/helpers/layout-usability.ts
M	apps/web/e2e/helpers/realtime-diagnostics.ts
M	apps/web/e2e/helpers/render-health.ts
M	apps/web/e2e/helpers/shared-auth.ts
A	apps/web/e2e/helpers/whatsapp-draft.ts
M	apps/web/e2e/patient-management-clinical.spec.ts
M	apps/web/e2e/patient-management.spec.ts
M	apps/web/e2e/patient-structure-ux.spec.ts
A	apps/web/e2e/reception-cancel.spec.ts
M	apps/web/e2e/reception-email.spec.ts
M	apps/web/e2e/render-health.spec.ts
M	apps/web/e2e/request-transport.spec.ts
A	apps/web/e2e/resolutions.spec.ts
M	apps/web/e2e/staff-delivery.spec.ts
M	apps/web/e2e/staff-management.spec.ts
M	apps/web/e2e/theme-modes.spec.ts
M	apps/web/playwright.config.ts
M	apps/web/src/app.css
M	apps/web/src/hooks.server.ts
M	apps/web/src/lib/booking/BookingShareLink.svelte
M	apps/web/src/lib/booking/PatientDocumentUpload.svelte
M	apps/web/src/lib/booking/PublicBookingConfirmation.svelte
M	apps/web/src/lib/booking/PublicBookingFlow.client.test.ts
M	apps/web/src/lib/booking/PublicBookingFlow.svelte
M	apps/web/src/lib/booking/PublicBookingProfessionals.svelte
M	apps/web/src/lib/booking/PublicInformationPage.svelte
M	apps/web/src/lib/components/DatePartsInput.svelte
M	apps/web/src/lib/components/DateTimePartsInput.svelte
M	apps/web/src/lib/components/Modal.svelte
M	apps/web/src/lib/components/agenda/ManualAppointmentWizard.svelte
M	apps/web/src/lib/components/agenda/SlotReleaseAlerts.client.test.ts
M	apps/web/src/lib/components/agenda/SlotReleaseAlerts.svelte
A	apps/web/src/lib/components/agenda/SlotReleasesNotice.client.test.ts
A	apps/web/src/lib/components/agenda/SlotReleasesNotice.svelte
M	apps/web/src/lib/components/appointments/PatientManagementPanel.client.test.ts
M	apps/web/src/lib/components/appointments/PatientManagementPanel.svelte
M	apps/web/src/lib/components/appointments/PublicAppointmentPage.svelte
A	apps/web/src/lib/components/appointments/StaffCancelPanel.svelte
M	apps/web/src/lib/components/notices/DismissibleNotice.svelte
M	apps/web/src/lib/components/patient-export/PatientExportPanel.svelte
M	apps/web/src/lib/components/patients/ClinicalEntryDialog.client.test.ts
M	apps/web/src/lib/components/patients/ClinicalEntryDialog.svelte
M	apps/web/src/lib/components/patients/ClinicalImageViewer.svelte
M	apps/web/src/lib/components/patients/PatientHistoryPanel.svelte
M	apps/web/src/lib/components/patients/PatientProfileDialog.svelte
M	apps/web/src/lib/components/patients/PatientProfilePanel.svelte
M	apps/web/src/lib/components/patients/RadiographsPanel.svelte
M	apps/web/src/lib/components/seguimientos/FollowUpComposer.svelte
M	apps/web/src/lib/components/seguimientos/FollowUpsNotice.svelte
M	apps/web/src/lib/components/team/ProfessionalSchedulePanel.svelte
M	apps/web/src/lib/components/team/TeamMemberWizard.svelte
M	apps/web/src/lib/scheduling/slot-releases.ts
M	apps/web/src/lib/server/patients/public/booking-information-page.test.ts
M	apps/web/src/lib/server/patients/public/booking-information-page.ts
M	apps/web/src/lib/server/patients/public/booking-information.ts
M	apps/web/src/lib/server/patients/public/follow-ups.ts
M	apps/web/src/lib/server/scheduling/public/appointments.ts
M	apps/web/src/lib/server/scheduling/public/patient-management-page.ts
M	apps/web/src/lib/server/scheduling/public/slot-releases.ts
M	apps/web/src/lib/server/scheduling/public/staff-management-flow.test.ts
M	apps/web/src/lib/server/scheduling/public/staff-management-flow.ts
M	apps/web/src/lib/theme/palette.js
A	apps/web/src/lib/ui/dialog-focus.client.test.ts
A	apps/web/src/lib/ui/dialog-focus.ts
A	apps/web/src/lib/ui/field-validation.client.test.ts
A	apps/web/src/lib/ui/field-validation.ts
A	apps/web/src/lib/ui/reveal-notice.client.test.ts
A	apps/web/src/lib/ui/reveal-notice.ts
M	apps/web/src/lib/utils/agenda-dates.ts
M	apps/web/src/lib/utils/appointment-visibility.test.ts
M	apps/web/src/lib/utils/appointment-visibility.ts
M	apps/web/src/lib/utils/notice-dismissal.ts
M	apps/web/src/routes/+error.svelte
M	apps/web/src/routes/+layout.svelte
M	apps/web/src/routes/api/zoho/webhook/+server.ts
M	apps/web/src/routes/api/zoho/webhook/webhook.server.test.ts
M	apps/web/src/routes/odonto/+layout.server.ts
M	apps/web/src/routes/odonto/+layout.svelte
M	apps/web/src/routes/odonto/agenda/+page.svelte
M	apps/web/src/routes/odonto/agenda/page.client.test.ts
M	apps/web/src/routes/odonto/agenda/semana/+page.svelte
M	apps/web/src/routes/odonto/configuracion/ayuda/+page.svelte
M	apps/web/src/routes/odonto/configuracion/correo/+page.svelte
M	apps/web/src/routes/odonto/configuracion/documentos/+page.svelte
M	apps/web/src/routes/odonto/configuracion/negocio/+page.svelte
M	apps/web/src/routes/odonto/configuracion/negocio/contacto/+page.svelte
M	apps/web/src/routes/odonto/configuracion/resena-google/+page.svelte
M	apps/web/src/routes/odonto/configuracion/reserva-online/webs/+page.svelte
M	apps/web/src/routes/odonto/configuracion/senas/+page.svelte
M	apps/web/src/routes/odonto/configuracion/suscripcion/+page.svelte
M	apps/web/src/routes/odonto/configuracion/usuarios/+page.svelte
M	apps/web/src/routes/odonto/layout-notices.server.test.ts
M	apps/web/src/routes/odonto/maestro/+page.svelte
M	apps/web/src/routes/odonto/maestro/correo/+page.svelte
M	apps/web/src/routes/odonto/maestro/correo/page.client.test.ts
M	apps/web/src/routes/odonto/mis-turnos/+page.server.ts
M	apps/web/src/routes/odonto/mis-turnos/+page.svelte
M	apps/web/src/routes/odonto/pacientes/+page.svelte
M	apps/web/src/routes/odonto/pacientes/[id]/+page.svelte
M	apps/web/src/routes/odonto/pacientes/papelera/+page.svelte
M	apps/web/src/routes/odonto/profesionales/[professionalId]/aranceles/+page.svelte
M	apps/web/src/routes/odonto/profesionales/[professionalId]/historial/+page.server.ts
M	apps/web/src/routes/odonto/profesionales/[professionalId]/historial/+page.svelte
M	apps/web/src/routes/odonto/profesionales/[professionalId]/preguntas/+page.svelte
M	apps/web/src/routes/odonto/recordatorios/+page.svelte
M	apps/web/src/routes/odonto/seguimientos/+page.svelte
M	apps/web/src/routes/odonto/turnos/[appointmentId]/+page.svelte
M	apps/web/src/routes/odonto/turnos/[appointmentId]/page.client.test.ts
M	apps/web/src/routes/terminos/+page.svelte
M	apps/web/src/routes/turno/[token]/page.client.test.ts
A	scripts/lib/native-controls.test.mjs
M	scripts/serve-booking-fixture.mjs
A	supabase/migrations/20261106040000_staff_cancel_before_start.sql
M	supabase/tests/staff_appointment_management.sql
```

`supabase/templates/recovery.html` no se despliega con la app: se carga aparte en Supabase. **No está verificado** si la versión de Supabase coincide con ese archivo.

Estos cuatro archivos sólo cambian comentarios o documentación, sin efecto en lo que corre. Entran en la próxima publicación.

## Historia

- **El 2 de noviembre se unieron en `main` las historias que habían divergido.** Ningún commit se perdió.

  | Historia | Revisión |
  |---|---|
  | `origin/main` | `4352f8a` |
  | Rama local `refactor/maintainability-20261015` | `80268e2` |
  | Línea publicada en producción | `771fac5`, V12b |
  | Ramas de GitHub `refactor/targeted-performance-20261025` y `refactor/targeted-performance-origin-20261025` | `5930f73` |

  - Las ramas de rendimiento tienen su código idéntico al actual.
  - Lo único que no aparece literal es un «Punto vigente» intermedio del 25 de octubre, cuyo resultado final está en `939b4dd` y en los documentos actuales.

- **Cómo se había llegado a la divergencia:**
  - la línea de producción nació el 15 de octubre de una copia de `c4a2417`, el primer commit local, y siguió en el repositorio de verificación, con 352 commits;
  - `origin/main` recibió el 24 y el 25 de octubre una foto de ese trabajo y sus registros de capacidad;
  - la rama local quedó congelada, con el trabajo posterior sin commitear.
- **No había dos planes en conflicto.** De los 1.568 archivos de `origin/main`:
  - 1.374 eran idénticos al estado actual;
  - en 189, la versión de `main` era una anterior que pasó por producción y fue reemplazada;
  - 5 eran documentos con estados viejos, que se conservan en los actuales como «Antecedente»;
  - ninguno faltaba.

  El plan vigente es `docs/plans/refactorizacion-cita-suite.md`, en `main`.
- **Respaldo de los estados anteriores:** ramas locales `archivo/local-20261015` (`80268e2`) y `archivo/origin-main-20261102` (`4352f8a`). Las dos están en la historia de `main`.

## Ramas fuera de `main`

El chequeo falla si una rama local o de GitHub no está en la historia de `main` y tampoco está en esta lista.

```ramas-fuera-de-main
codex/pending-session-recovery
codex/role-authorization-security
```

| Rama | Dónde | Commits fuera de `main` | Lo agregado que está hoy | Estado |
|---|---|---|---|---|
| `codex/pending-session-recovery` | Sólo local | 1, del 22 de agosto («estabilizar activación y enlaces de WhatsApp») | 92 % de las líneas | No incorporada. No está verificado si lo que falta se reemplazó por otra implementación. |
| `codex/role-authorization-security` | Local y GitHub | 5, del 1 al 4 de junio (autorización por roles, acceso maestro guiado, seguridad de reservas) | 45 % de las líneas | No incorporada. Es anterior a la refactorización, que reestructuró ese código; no está verificado qué parte quedó reemplazada. |

## Lo que queda sólo en esta computadora, a propósito

Lo ignora `.gitignore` y no se publica nunca: el repositorio es público.

- `docs/clientes/`: datos personales de Natalia.
- `.audit-backup-*/`: volcados de la base de datos.
- `.verification/`: evidencia de corridas y producción.
- `audit-evidence/` y `apps/web/output/`: evidencia y capturas nuevas. Lo que ya estaba publicado en `main` sigue versionado.
- `.impeccable/` y `.agents/` de la raíz: herramientas del entorno de trabajo.
- `walkthrough.md`: un informe de agosto.
- Restos de compilación (`*-repro.manifest`) y los archivos `.env`.

## Cómo se mantiene sin divergir

1. **Al empezar a trabajar:** correr `node scripts/check-repo-sync.mjs`. Si falla, se resuelve eso antes que cualquier otra cosa.
2. **Las candidatas se arman sobre `main`**, no sobre una revisión publicada aparte.
3. **Al publicar,** en el mismo paso:
   - la revisión publicada entra a `main`;
   - se actualizan `produccion_revision`, `produccion_version_cloudflare` y la lista de código distinto;
   - se sube a GitHub.
4. **El chequeo falla si:**
   - una rama, local o de GitHub, queda fuera de la historia de `main` sin estar declarada;
   - producción sirve una revisión distinta de la registrada;
   - esa revisión no está en la historia de `main`;
   - el código difiere de producción sin estar declarado;
   - la copia local difiere de GitHub;
   - hay trabajo fuera de Git.

Las notas E1.48 a E3.1 que estaban acá se quitaron al publicar: su detalle sigue en el [registro activo](plans/ejecucion-etapa-e-20261103.md).
