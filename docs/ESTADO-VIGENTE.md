# Estado vigente del repositorio y de producción

**Este es el registro único de qué historia y qué cambios están vigentes.** Se actualiza en el mismo paso de trabajo que cambia cualquiera de estos datos, nunca después. Eso incluye publicar, cambiar de rama, integrar, o dejar código distinto de producción. `node scripts/check-repo-sync.mjs`, desde la raíz, lo compara con Git, con GitHub y con la revisión que sirve producción, y falla ante cualquier diferencia.

Última actualización: 3 de noviembre de 2026, autorización de ejecución íntegra de E y regla de continuidad. Decisiones iniciales resueltas; E1 en implementación y verificación SQL; producción y código servido sin cambios.

## Datos verificables

```estado
rama_de_trabajo: main
produccion_revision: 771fac5950c532b1123f11d4dde93eef9b42ceba
produccion_version_cloudflare: 277d332d-1794-4367-8ef0-567ced159f1b
produccion_repositorio: github-secundaria:Juan4787/cita-suite-verificacion.git
```

- **Producción** sirve V12b en `https://app.cita-suite.com.ar` y en `app.cita-suite.workers.dev`: el modo claro con el fondo `#f6f5f3`.
- **La revisión publicada es antecesora de `main`.** Todo lo que corre en producción está en la historia de `main`.

## Actualización documental de E — 2 de noviembre

Se revisó E contra el código de main 45ad4dad3259386b445d3306ca66bb16bf51f285 y se incorporó al [plan 12.18](plans/propuesta-senas-avisos-natalia.md#etapa-e-vigente) su [especificación](plans/etapa-e-correo-autogestion.md), con Zoho y autogestión. Sólo documentación: no cambia el código distinto de producción listado abajo, la revisión servida ni su recuperación. El 3 de noviembre Juan indicó conectar Zoho desde la terminal y guardar el acceso para reinicios: [plan 12.19](plans/propuesta-senas-avisos-natalia.md#zoho-terminal-vigente) y [guía de operación](architecture/zoho-cpaas-terminal.md). OAuth local, consultas y renovación comprobados; herramienta guardada en Git y credenciales privadas persistentes fuera del repositorio. Juan autorizó después implementar/auditar/probar/publicar E íntegra: [plan 12.20](plans/propuesta-senas-avisos-natalia.md#ejecucion-e-autorizada). El [registro activo](plans/ejecucion-etapa-e-20261103.md) contiene continuidad y los 97 casos; decisiones iniciales resueltas (subdominio por consultorio, correo activo por defecto y acciones contextuales), contrato de contexto E1 implementado y probado localmente, con integración inicial de rutas en fast 41707570026 (1779 servidor/277 cliente) y browser 41708652093 (dos recorridos, día elegido, prioridad/foco). La revisión metodológica posterior 12.24 precede a nuevas funciones; corrección de respuesta inválida comprobada en 50/50 dirigidos, CI general posterior pendiente. Ocho migraciones y .080 de permisos aprobadas en 41705610343 (773 pgTAP/18 scripts); tipos oficiales/digest cotejados. Sin envíos ni otra espera de autorización. La D celular quedó reemplazada por avisos internos, a ejecutar después de E/P1/P2; [cola separada](plans/tareas-posteriores-a-e-20261103.md).

## Código que difiere de producción

El chequeo compara esta lista con `git diff --name-status <produccion_revision> HEAD` sobre el código (`apps`, `packages`, `scripts`, `supabase` y los archivos de configuración de la raíz, sin `apps/web/output`). Tiene que coincidir exactamente.

```codigo-distinto-de-produccion
A	apps/web/.impeccable/surfaces/gestion-del-turno.md
M	apps/web/DESIGN.md
M	apps/web/e2e/helpers/owned-appointment-fixture.ts
A	apps/web/e2e/patient-management.spec.ts
M	apps/web/src/hooks.server.test.ts
M	apps/web/src/hooks.server.ts
M	apps/web/src/lib/availability/contracts.test.ts
M	apps/web/src/lib/availability/contracts.ts
A	apps/web/src/lib/components/appointments/PatientManagementPanel.client.test.ts
A	apps/web/src/lib/components/appointments/PatientManagementPanel.svelte
A	apps/web/src/lib/components/appointments/PublicAppointmentPage.svelte
A	apps/web/src/lib/scheduling/patient-action-context.test.ts
A	apps/web/src/lib/scheduling/patient-action-context.ts
A	apps/web/src/lib/scheduling/patient-management-page.ts
A	apps/web/src/lib/scheduling/public-appointment.ts
A	apps/web/src/lib/scheduling/reschedule-terms.test.ts
A	apps/web/src/lib/scheduling/reschedule-terms.ts
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
A	apps/web/src/routes/gestion/[token]/+page.server.ts
A	apps/web/src/routes/gestion/[token]/+page.svelte
M	apps/web/src/routes/turno/[token]/+page.server.ts
M	apps/web/src/routes/turno/[token]/+page.svelte
M	apps/web/src/routes/turno/[token]/page.client.test.ts
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
M	supabase/templates/recovery.html
A	supabase/tests/appointment_management_capabilities.sql
A	supabase/tests/appointment_management_foundation.sql
A	supabase/tests/appointment_management_staff_authorization.sql
M	supabase/tests/appointment_patient_reassignment.sql
A	supabase/tests/appointment_reschedule_financial_terms.sql
A	supabase/tests/migrations/20261103010000_appointment_management_foundation.sql.after.sql
A	supabase/tests/migrations/20261103010000_appointment_management_foundation.sql.before.sql
A	supabase/tests/patient_appointment_management_commands.sql
A	supabase/tests/patient_appointment_management_recovery.sql
A	supabase/tests/patient_appointment_management_view.sql
M	supabase/tests/run_deposit_expiry_concurrency.sh
A	supabase/tests/run_patient_management_concurrency.sh
A	supabase/tests/run_patient_management_view_concurrency.sh
A	supabase/tests/run_staff_authorization_concurrency.sh
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
| `patient-management.ts` y su prueba | Adaptador mínimo, disponibilidad y comando; fast 41707570026 aprobado. Respuesta inválida posterior al comando/recibo conserva operación incierta, 50/50 dirigidos con flujo/ruta; CI posterior pendiente | No: desarrollo sin publicar |
| `patient_appointment_management_recovery.sql` | Siete grupos del lookup de recibo .070, suite completa aprobada 41653421061 | No: sólo CI |
| `patient_appointment_management_view.sql` | Lectura mínima con migración `20261103050000`, 16 grupos/lectura coherente y reloj comercial explícito comprobados en 41660810130 | No: sólo CI descartable |
| `run_patient_management_view_concurrency.sh` | Carrera de lectura con modificación simultánea entre autorización/presentación aprobada en CI 41650084150 | No: sólo CI descartable |
| Rutas `/turno`/`gestion`, hooks, componentes y flujos nuevos | Integración E2 compartida, mutación antigua retirada; fast 41707570026 (1779/277), browser 41708652093 (dos recorridos, prioridad/foco y día elegido) aprobados; sin paquete ni cierre integral | No: todavía sin publicar |
| `apps/web/DESIGN.md` y superficie de gestión | Dirección de extensión/contexto; matriz browser y cuatro capturas inspeccionadas en 41708652093, sin cierre visual integral de E | No: documentación de desarrollo |
| `patient-management.spec.ts` | Dos recorridos aislados aprobados 41708652093, matriz de ambas apariencias/claro-oscuro/cinco anchos; sin prueba de proveedor/correo ni aceptación integral | No: sólo CI |
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
