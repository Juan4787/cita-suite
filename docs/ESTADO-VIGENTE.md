# Estado vigente del repositorio y de producción

**Este es el registro único de qué historia y qué cambios están vigentes.** Se actualiza en el mismo paso de trabajo que cambia cualquiera de estos datos, nunca después. Eso incluye publicar, cambiar de rama, integrar, o dejar código distinto de producción. `node scripts/check-repo-sync.mjs`, desde la raíz, lo compara con Git, con GitHub y con la revisión que sirve producción, y falla ante cualquier diferencia.

Última actualización: 6 de noviembre de 2026, 09:15 hora argentina. Tercera versión de E publicada y comprobada en producción, según el [mandato integral](plans/mandato-integral-avisos-20261105.md). [Plan canónico y checkpoint](plans/plan-integral-avisos-20261105.md).

## Datos verificables

```estado
rama_de_trabajo: main
produccion_revision: fed61f5d9d81f821df180486c73aa07d04408f56
produccion_version_cloudflare: 50c8570c-149d-43ea-8f42-f0d2e1496d1b
produccion_repositorio: github-secundaria:Juan4787/cita-suite-verificacion.git
```

- **Producción** sirve la tercera versión de E en `https://app.cita-suite.com.ar` y en `app.cita-suite.workers.dev`: la instantánea `fed61f5d` de `main` `83b8155e`, con las 164 migraciones aplicadas.
- **La revisión publicada es antecesora de `main`.** Todo lo que corre en producción está en la historia de `main`.
- **V12b dejó de ser una vuelta atrás válida** desde las 07:39 UTC del 6 de noviembre, cuando se confirmaron las migraciones. Nunca usar `wrangler rollback` a una versión anterior a E. Recuperación vigente: [guía de publicación](architecture/publicacion-y-reversion.md#e--publicación-y-recuperación-compatible-5-de-noviembre).

## Etapa E — publicada el 6 de noviembre

Autorización de implementación, pruebas y publicación vigente: [plan 12.32](plans/propuesta-senas-avisos-natalia.md#mandato-integral-20261105). Seguimiento en el [plan canónico](plans/plan-integral-avisos-20261105.md), evidencia en el [registro activo](plans/ejecucion-etapa-e-20261103.md). El [traspaso del 5 de noviembre](plans/traspaso-etapa-e-20261105.md) queda como historia.

| Dato | Valor comprobado en el destino |
|---|---|
| Worker `app` | Versión `50c8570c-149d-43ea-8f42-f0d2e1496d1b`. Vuelta atrás válida: `5a05383b-cb99-49e4-bdaa-01aeb83c5490`, la segunda versión de E, con el mismo código de la app |
| Worker `cita-suite-scheduler` | Versión `853b9020-5738-4a66-be5e-acf1b1d6cb09`, cinco cron: `*/5`, `1-59/5`, `2-59/5`, `3-59/5` y `17 */3` |
| Migraciones | 164 en la historia de producción: las 32 de E entraron en una transacción de 18 s, y la correctiva `20261106030000` en otra de 1 s |
| Interruptores | `reschedule_enabled` y `email_producer_enabled` encendidos; `GOOGLE_CALENDAR_MANAGED_ENABLED=true`; tope diario de correo 100, reserva 10; `private.deposit_automation` sin cambios |
| Crédito de Zoho registrado | 9.997 correos desde el 6 de noviembre, vencimiento 3 de diciembre de 2026 |
| Remitente de Natalia | Sin configurar por decisión de Juan: no salen correos de su consultorio |

## Código que difiere de producción

El chequeo compara esta lista con `git diff --name-status <produccion_revision> HEAD` sobre el código (`apps`, `packages`, `scripts`, `supabase` y los archivos de configuración de la raíz, sin `apps/web/output`). Tiene que coincidir exactamente.

```codigo-distinto-de-produccion
M	scripts/production-email-practice.mjs
M	scripts/zoho-cpaas.py
```

`scripts/zoho-cpaas.py` agrega la consulta por referencia y `scripts/production-email-practice.mjs` completa su limpieza. Ninguno se despliega: son herramientas locales.

`supabase/templates/recovery.html` no se despliega con la app: se carga aparte en Supabase. **No está verificado** si la versión de Supabase coincide con ese archivo.

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
