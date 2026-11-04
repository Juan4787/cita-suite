# Estado vigente del repositorio y de producción

**Este es el registro único de qué historia y qué cambios están vigentes.** Se actualiza en el mismo paso de trabajo que cambia cualquiera de estos datos, nunca después. Eso incluye publicar, cambiar de rama, integrar, o dejar código distinto de producción. `node scripts/check-repo-sync.mjs`, desde la raíz, lo compara con Git, con GitHub y con la revisión que sirve producción, y falla ante cualquier diferencia.

Última actualización: 4 de noviembre de 2026. E sigue en implementación/verificación, sin publicación ni SQL productivo; autorización íntegra y regla de continuidad vigentes.

## Datos verificables

```estado
rama_de_trabajo: main
produccion_revision: 771fac5950c532b1123f11d4dde93eef9b42ceba
produccion_version_cloudflare: 277d332d-1794-4367-8ef0-567ced159f1b
produccion_repositorio: github-secundaria:Juan4787/cita-suite-verificacion.git
```

- **Producción** sirve V12b en `https://app.cita-suite.com.ar` y en `app.cita-suite.workers.dev`: el modo claro con el fondo `#f6f5f3`.
- **La revisión publicada es antecesora de `main`.** Todo lo que corre en producción está en la historia de `main`.

## Etapa E — ejecución al 4 de noviembre

E conserva autorización íntegra de implementación/pruebas/publicación: [plan 12.18–12.26](plans/propuesta-senas-avisos-natalia.md#ejecucion-e-autorizada), [especificación](plans/etapa-e-correo-autogestion.md) y [registro activo](plans/ejecucion-etapa-e-20261103.md). Dieciocho migraciones aprobadas en SQL **41825879784** (vista 22 grupos, 41 carreras/dos contraejemplos FK, doce esperas y regresiones/limpieza), tipos oficiales/digest cotejados. Push fast **41823253513** aprobado (1837 servidor/280 cliente, cero errores/avisos); clínica conserva browser 41793557725 y personal 41757455635 con sus alcances. Disponibilidad auxiliar UI con 41/55 dirigidas; fast/browser ampliados pendientes. Frontera OAuth aprobada en ese SQL; consumidores originales cifrados/canales escritos, 54 dirigidas aprobadas y fast/browser integrado pendientes (E1.78). No hay implementación E publicada, migraciones E productivas ni correo nuevo. Zoho OAuth administrativo persiste localmente; envío/webhook/recepción/integración pendientes. P1/P2/P3 pospuestas por 12.26, sin iniciarlas al cerrar E; D celular está reemplazada por futura P3 interna. No hay otra espera de permiso.

## Código que difiere de producción

El chequeo compara esta lista con `git diff --name-status <produccion_revision> HEAD` sobre el código (`apps`, `packages`, `scripts`, `supabase` y los archivos de configuración de la raíz, sin `apps/web/output`). Tiene que coincidir exactamente.

```codigo-distinto-de-produccion
A	apps/web/.impeccable/surfaces/gestion-del-turno.md
M	apps/web/DESIGN.md
M	apps/web/e2e/helpers/owned-appointment-fixture.ts
A	apps/web/e2e/patient-management-clinical.spec.ts
A	apps/web/e2e/patient-management.spec.ts
A	apps/web/e2e/staff-management.spec.ts
M	apps/web/src/hooks.server.test.ts
M	apps/web/src/hooks.server.ts
M	apps/web/src/lib/availability/contracts.test.ts
M	apps/web/src/lib/availability/contracts.ts
M	apps/web/src/lib/booking/PatientDocumentUpload.svelte
A	apps/web/src/lib/booking/PublicInformationPage.svelte
A	apps/web/src/lib/components/appointments/PatientManagementPanel.client.test.ts
A	apps/web/src/lib/components/appointments/PatientManagementPanel.svelte
A	apps/web/src/lib/components/appointments/PublicAppointmentPage.svelte
A	apps/web/src/lib/patients/public-booking-information.ts
A	apps/web/src/lib/scheduling/patient-action-context.test.ts
A	apps/web/src/lib/scheduling/patient-action-context.ts
A	apps/web/src/lib/scheduling/patient-management-page.ts
A	apps/web/src/lib/scheduling/public-appointment.ts
A	apps/web/src/lib/scheduling/reschedule-terms.test.ts
A	apps/web/src/lib/scheduling/reschedule-terms.ts
A	apps/web/src/lib/scheduling/staff-management.ts
M	apps/web/src/lib/server/integrations/public/google-calendar.test.ts
M	apps/web/src/lib/server/integrations/public/google-calendar.ts
A	apps/web/src/lib/server/integrations/public/patient-google-calendar.ts
A	apps/web/src/lib/server/integrations/public/patient-push.ts
M	apps/web/src/lib/server/integrations/public/push.test.ts
M	apps/web/src/lib/server/integrations/public/push.ts
A	apps/web/src/lib/server/patients/public/booking-documents.test.ts
A	apps/web/src/lib/server/patients/public/booking-documents.ts
A	apps/web/src/lib/server/patients/public/booking-information-page.test.ts
A	apps/web/src/lib/server/patients/public/booking-information-page.ts
M	apps/web/src/lib/server/patients/public/booking-information.ts
M	apps/web/src/lib/server/patients/public/clinical-files.ts
A	apps/web/src/lib/server/scheduling/internal/management-contract.ts
A	apps/web/src/lib/server/scheduling/public/appointment-token.test.ts
M	apps/web/src/lib/server/scheduling/public/appointment-token.ts
M	apps/web/src/lib/server/scheduling/public/appointments.test.ts
M	apps/web/src/lib/server/scheduling/public/appointments.ts
M	apps/web/src/lib/server/scheduling/public/availability.test.ts
M	apps/web/src/lib/server/scheduling/public/availability.ts
A	apps/web/src/lib/server/scheduling/public/patient-management-flow.test.ts
A	apps/web/src/lib/server/scheduling/public/patient-management-flow.ts
A	apps/web/src/lib/server/scheduling/public/patient-management-page.test.ts
A	apps/web/src/lib/server/scheduling/public/patient-management-page.ts
A	apps/web/src/lib/server/scheduling/public/patient-management.test.ts
A	apps/web/src/lib/server/scheduling/public/patient-management.ts
M	apps/web/src/lib/server/scheduling/public/public-appointments.test.ts
M	apps/web/src/lib/server/scheduling/public/public-appointments.ts
A	apps/web/src/lib/server/scheduling/public/staff-management-flow.test.ts
A	apps/web/src/lib/server/scheduling/public/staff-management-flow.ts
A	apps/web/src/lib/server/scheduling/public/staff-management.test.ts
A	apps/web/src/lib/server/scheduling/public/staff-management.ts
A	apps/web/src/routes/gestion/[token]/+page.server.ts
A	apps/web/src/routes/gestion/[token]/+page.svelte
A	apps/web/src/routes/gestion/[token]/documentos/+server.ts
A	apps/web/src/routes/gestion/[token]/documentos/[fileId]/complete/+server.ts
A	apps/web/src/routes/gestion/[token]/google-calendar/connect/+server.ts
A	apps/web/src/routes/gestion/[token]/informacion/+page.server.ts
A	apps/web/src/routes/gestion/[token]/informacion/+page.svelte
A	apps/web/src/routes/gestion/[token]/push/+server.ts
M	apps/web/src/routes/oauth/google-calendar/callback/+server.ts
M	apps/web/src/routes/oauth/google-calendar/callback/callback.server.test.ts
M	apps/web/src/routes/odonto/agenda/+page.server.ts
M	apps/web/src/routes/odonto/agenda/agenda-day.server.test.ts
M	apps/web/src/routes/odonto/turnos/[appointmentId]/+page.server.ts
M	apps/web/src/routes/odonto/turnos/[appointmentId]/+page.svelte
M	apps/web/src/routes/odonto/turnos/[appointmentId]/appointment-detail.server.test.ts
M	apps/web/src/routes/odonto/turnos/[appointmentId]/page.client.test.ts
M	apps/web/src/routes/odonto/turnos/[appointmentId]/reschedule.server.test.ts
M	apps/web/src/routes/odonto/turnos/[appointmentId]/slots/+server.ts
M	apps/web/src/routes/turno/[token]/+page.server.ts
M	apps/web/src/routes/turno/[token]/+page.svelte
M	apps/web/src/routes/turno/[token]/documentos/+server.ts
M	apps/web/src/routes/turno/[token]/documentos/[fileId]/complete/+server.ts
M	apps/web/src/routes/turno/[token]/google-calendar/connect/+server.ts
M	apps/web/src/routes/turno/[token]/google-calendar/connect/connect.server.test.ts
M	apps/web/src/routes/turno/[token]/informacion/+page.server.ts
M	apps/web/src/routes/turno/[token]/informacion/+page.svelte
M	apps/web/src/routes/turno/[token]/page.client.test.ts
M	apps/web/src/routes/turno/[token]/push/+server.ts
M	apps/web/src/routes/turno/[token]/push/push.server.test.ts
M	packages/shared/src/database.types.ts
A	scripts/check-repo-sync.mjs
M	scripts/package-verification-evidence.py
M	scripts/test-booking-foundation.mjs
M	scripts/test-verification-evidence.py
A	scripts/verify-production-auth-ux.mjs
A	scripts/zoho-cpaas.py
A	supabase/migrations/20261103010000_appointment_management_foundation.sql
A	supabase/migrations/20261103020000_appointment_management_capabilities.sql
A	supabase/migrations/20261103030000_appointment_reschedule_financial_terms.sql
A	supabase/migrations/20261103040000_patient_appointment_management_commands.sql
A	supabase/migrations/20261103050000_patient_appointment_management_view.sql
A	supabase/migrations/20261103060000_appointment_creation_replay_identity.sql
A	supabase/migrations/20261103070000_patient_appointment_management_recovery.sql
A	supabase/migrations/20261103080000_staff_operation_authorization.sql
A	supabase/migrations/20261103090000_staff_appointment_management.sql
A	supabase/migrations/20261103100000_close_staff_appointment_direct_updates.sql
A	supabase/migrations/20261103110000_staff_creation_and_identity_authorization.sql
A	supabase/migrations/20261103120000_patient_email_contact_authority.sql
A	supabase/migrations/20261103130000_patient_contact_editor_authority.sql
A	supabase/migrations/20261104010000_patient_management_information_access.sql
A	supabase/migrations/20261104020000_patient_management_document_access.sql
A	supabase/migrations/20261104030000_patient_management_push_access.sql
A	supabase/migrations/20261104040000_patient_management_auxiliary_presentation.sql
A	supabase/migrations/20261104050000_patient_management_google_calendar_authority.sql
M	supabase/templates/recovery.html
M	supabase/tests/appointment_actor_revalidation.sql
M	supabase/tests/appointment_deposits.sql
A	supabase/tests/appointment_management_capabilities.sql
A	supabase/tests/appointment_management_foundation.sql
A	supabase/tests/appointment_management_staff_authorization.sql
M	supabase/tests/appointment_patient_reassignment.sql
A	supabase/tests/appointment_reschedule_financial_terms.sql
M	supabase/tests/clinical_provenance_triggers.sql
A	supabase/tests/migrations/20261103010000_appointment_management_foundation.sql.after.sql
A	supabase/tests/migrations/20261103010000_appointment_management_foundation.sql.before.sql
A	supabase/tests/patient_appointment_management_commands.sql
A	supabase/tests/patient_appointment_management_recovery.sql
A	supabase/tests/patient_appointment_management_view.sql
M	supabase/tests/patient_change_history_atomic.sql
M	supabase/tests/patient_identity_atomicity.sql
A	supabase/tests/patient_management_document_access.sql
A	supabase/tests/patient_management_google_calendar_access.sql
A	supabase/tests/patient_management_information_access.sql
A	supabase/tests/patient_management_push_access.sql
M	supabase/tests/run_deposit_expiry_concurrency.sh
M	supabase/tests/run_patient_identity_idempotency_concurrency.sh
A	supabase/tests/run_patient_management_concurrency.sh
A	supabase/tests/run_patient_management_view_concurrency.sh
A	supabase/tests/run_staff_authorization_concurrency.sh
A	supabase/tests/staff_appointment_management.sql
```

| Archivo | Qué es | ¿Afecta a producción? |
|---|---|---|
| `apps/web/src/lib/scheduling/patient-action-context.ts` y su prueba | Contrato E1 de acciones/contexto para turno vigente y cancelación, todavía sin consumidores | No: desarrollo sin publicar |
| `scripts/check-repo-sync.mjs` | Este chequeo | No: es una herramienta local |
| Fixture `owned-appointment-fixture.ts` y empaquetador/prueba de evidencia | Diagnóstico SQL limitado a metadatos y ocultación de enlaces de capacidad; fast 41707570026 y preparación browser 41708652093 aprobados | No: sólo CI |
| `scripts/test-booking-foundation.mjs` | Conservar diagnósticos SQL/carreras con salida acotada y limitar cada script de carreras a 120 s | No: sólo la base descartable de CI |
| `scripts/zoho-cpaas.py` | Administración local de Zoho por OAuth, con credenciales fuera de Git | No: no se despliega ni configura el correo de la app |
| `scripts/verify-production-auth-ux.mjs` | Lectura de la pantalla de ingreso en producción, de otro trabajo (flujo manual `production-auth-ux.yml`) | No: no se despliega |
| Migración `20261103010000`, contrato SQL y fixtures de actualización E1 | Preferencias, revisión semántica e historia de señas; helper de reloj comercial y conjunto aprobados en CI SQL 41660810130 | No: no se aplicó en producción; sólo CI descartable |
| `supabase/tests/run_deposit_expiry_concurrency.sh` | Limpieza ordenada de sus turnos sintéticos antes del consultorio, compatible con la historia de dinero | No: sólo la base descartable de CI |
| Migración `20261103020000` y `supabase/tests/appointment_management_capabilities.sql` | Enlaces revocables y recibo idempotente; comprobados en CI SQL `41600939474` | No: rutas integradas sólo en candidata/CI descartable, sin aplicar ni publicar en producción |
| `packages/shared/src/database.types.ts` | Tipos oficiales, dos generaciones iguales en CI y digest de las migraciones locales cotejado antes de importar | No: todavía sin publicar |
| Migración `20261103030000` y `supabase/tests/appointment_reschedule_financial_terms.sql` | Resumen económico de reprogramación sólo lectura, suite aprobada; consumido por comando/lectura y adaptador/UI iniciales, sin publicar | No: conectado a rutas sólo en candidata/CI descartable, sin aplicar ni publicar en producción |
| Migración `20261103040000` y `patient_appointment_management_commands.sql` | Comandos del paciente/eventos atómicos, Comando ampliado 35/35 y doce carreras aprobados en CI `41616550006`; contrato 37 grupos aprobado en 41660810130; siete migraciones y reloj comercial verificados en CI 41660810130 | No: sólo CI descartable, interruptores apagados al instalar |
| `availability.ts` y su prueba | Contrato y calculador compartido con revisiones de catálogo/reserva y duración de la misma lectura; contrato anterior de slots conservado, 19/19 locales junto con ventanas | No: todavía sin publicar |
| `run_patient_management_concurrency.sh` | Trece carreras, incluida espera real con vencimiento comercial, aprobadas en 41660810130; sólo loopback descartable | No: sólo CI |
| `reschedule-terms.ts` y su prueba | Validación/formato preciso de condiciones SQL, 20/20 locales; consumido por adaptador y panel iniciales, sin publicar | No: desarrollo sin publicar |
| Migración .060 y prueba de reasignación ampliada | Rechazar recuperación con identidad reasignada, suite completa aprobada 41653421061 | No: sólo CI descartable |
| `patient-management.ts` y su prueba | Adaptador mínimo, disponibilidad y comando; fast 41710295801 aprobado. Respuesta inválida posterior al comando/recibo conserva operación incierta, 50/50 dirigidos con flujo/ruta y regresiones generales aprobadas | No: desarrollo sin publicar |
| `patient_appointment_management_recovery.sql` | Siete grupos del lookup de recibo .070, suite completa aprobada 41653421061 | No: sólo CI |
| `patient_appointment_management_view.sql` | Lectura mínima con migración `20261103050000`, 16 grupos/lectura coherente y reloj comercial explícito comprobados en 41660810130 | No: sólo CI descartable |
| `run_patient_management_view_concurrency.sh` | Carrera de lectura con modificación simultánea entre autorización/presentación aprobada en CI 41650084150 | No: sólo CI descartable |
| Rutas `/turno`/`gestion`, hooks, componentes y flujos nuevos | Integración E2 compartida, mutación antigua retirada; fast 41710295801 (1783/277), browser 41708652093 (dos recorridos, prioridad/foco y día elegido) aprobados; sin paquete ni cierre integral | No: todavía sin publicar |
| `apps/web/DESIGN.md` y superficie de gestión | Dirección de extensión/contexto; matriz browser y cuatro capturas inspeccionadas en 41708652093, sin cierre visual integral de E | No: documentación de desarrollo |
| `patient-management.spec.ts` | Dos recorridos aislados aprobados 41708652093, matriz de ambas apariencias/claro-oscuro/cinco anchos; sin prueba de proveedor/correo ni aceptación integral | No: sólo CI |
| Migración .090 y `staff_appointment_management.sql` | Comando backend, autoridad compartida y campo calculado: suite de nueve migraciones aprobada en 41715645324; 21 grupos personal/38 paciente, 21 carreras y ocho esperas. Consumidores escritos, integración HTTP pendiente | No: sin aplicar ni publicar |
| `supabase/templates/recovery.html` | Plantilla del correo de recuperación, modificada en otro trabajo | No se despliega con la app: se carga aparte en Supabase. **No está verificado** si la versión de Supabase coincide con este archivo |

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

- Actualización E1.48: SQL 41715645324 aprobó las nueve migraciones y carreras ampliadas; tipos oficiales reproducibles importados con digest cotejado. Parser de resultados compartido, 50/50 dirigidos del paciente. Integración del personal y HTTP pendientes; producción sigue en V12b.

- E1.49: detalle/slots y exports del personal consumen el comando atómico, revisión observada y recuperación original; 79/79 dirigidos servidor. Interfaz escrita; tipos y HTTP pendientes, privilegios UPDATE autenticados aún conservados.

- E1.50: .100 y cuatro grupos SQL adicionales escritos para cerrar UPDATE autenticado, sin aplicar; el alta con Ayuda tiene dos pruebas nuevas de contrato pendientes. Fast 41755701125 se detuvo en cuatro errores de tipos de pruebas, corregidos. La suite de nueve sigue como evidencia anterior; no acredita diez migraciones.

- E1.51: fast 41756406163 aprobado (1808 servidor/280 cliente), fuente 7b8bd4ef. SQL 41756409931 reprodujo rechazo incorrecto del alta con Ayuda activa. .110 y pruebas/esperas ampliadas escritos, once migraciones pendientes. Browser nuevo escrito y foco/reintento ajustados después del fast; aún sin prueba HTTP del personal.

- E1.52: SQL 41757452769 aprobó los 18 grupos de Ayuda y luego se detuvo por precondición comercial faltante del fixture de reasignación. Tres fixtures internos corregidos y negativas comerciales explícitas añadidas, once migraciones siguen pendientes. Browser 41757455635 en curso, sólo tipado e2e ya confirmado; foco/reintento 32/32 cliente.

- E1.53: browser 41757455635 aprobado con HTTP/SQL reales, conflicto concurrente y recuperación después de commit; matriz de cinco anchos/dos modos con paneles cerrados. SQL 41758176583 se detuvo por expectativa antigua de privilegio del arnés clínico: adaptación conserva denegación autenticada y guardia profesional privilegiada, pendiente rerun integral. P1/P2/P3 pospuestas por 12.26, no iniciarlas al cerrar E. Producción sigue V12b.

- E1.55: SQL 41759448286 aprobó once migraciones, diez esperas de Ayuda y 21 carreras paciente/personal; tipos oficiales idénticos y digest cotejado. Roja de contacto 41759878304 reproducida; .120 y contratos/carreras escritos, doce migraciones aún sin verde. No aplicado ni publicado, sin envíos nuevos.

- E1.56: SQL 41760657679 instaló doce migraciones y aprobó revocación/legado/ABA/familiares; se detuvo en END duplicado de una prueba nueva de rollback, corregido sin cambios del producto. Rerun integral/tipos pendientes.

- E1.58: SQL 41761097542 aprobó doce migraciones, capacidades 33/comandos 40 y 24 carreras; tipos oficiales importados con digest cotejado. Roja del editor de contacto 41761295231 reproducida; .130 y nueve grupos/doce esperas escritos, trece migraciones pendientes. Producción intacta, sin correo nuevo.

- E1.59: SQL 41762069407 aprobó trece migraciones, nueve grupos del editor/historia y doce esperas; tipos/digest cotejados. Fast 41762158350 aprobado (1808 servidor/280 cliente, sin errores/avisos). Nuevo contrato clínico auxiliar escrito, sin ejecutar; producción V12b, sin SQL aplicado ni envío nuevo.
