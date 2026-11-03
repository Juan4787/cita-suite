# Publicación y recuperación de señas y horarios liberados

**Alcance histórico de este documento:** conserva la entrega A/B/C del 30 de octubre. La versión productiva y la recuperación actuales están en [estado vigente](../ESTADO-VIGENTE.md) y [publicación/reversión](../architecture/publicacion-y-reversion.md). No instalar C9/B11 desde estos comandos: no conservan el flujo de correo publicado después. El criterio contextual de [AGENTS.md](../../AGENTS.md) sustituye las obligaciones históricas automáticas de staging, backup por horas, hashes de turnos ficticios y ensayos de reversión. Ese cierre no implementó D/E. El alcance posterior de E está en [12.18](propuesta-senas-avisos-natalia.md#etapa-e-vigente) y la [especificación](etapa-e-correo-autogestion.md); D sigue en pausa y E espera instrucción de implementación.

Procedimiento aplicado el **30 de octubre de 2026**. C9 y las dos migraciones están publicadas; B11 y el retorno nativo C9 fueron ensayados. Los resultados exactos, la limpieza y los límites se contrastan en el [cierre](cierre-senas-avisos-natalia.md); el [traspaso](traspaso-senas-avisos-natalia.md) fija el estado final y las decisiones de configuración pendientes. **No repetir esta instalación leyendo los comandos históricos.** Autorización expresa vigente en12.8 del plan; no volver a pedirla. D/E y las decisiones de configuración de Natalia siguen aparte.

## Precondiciones

- Candidata `deb74b023431e4f173eed85d6651c5073ad44557` (C9); artefacto41081146798. El release41082416537 debe terminar exitosamente, con comprobantes recuperados y todas sus fases completas. Un diagnóstico dirigido no lo sustituye.
- Recuperación compatible `bf0fd1892b1adc769d93c8ac369c533ee80a58b7` (B11); artefacto41049721655. Conserva resolver señas pendientes. Global apagado primero; no volver a una aplicación sin esos controles ni exceptuar obligaciones en masa.
- Ambos paquetes verificados en `.verification/senas-avisos-20261029/` (`release-c9`, `release-recuperacion-b11`), con copias privadas fuera del workspace. No recompilar localmente.
- Copia productiva41081864440, snapshot15:37:23.655UTC, restaurada y recuperada independientemente. Carpeta privada `/home/usuario/.local/share/cita-suite/backups/production-senas-20261030T154244Z`. Verificar edad menor a6h e historial126 antes de aplicar. El manifiestoSHA es `5e2d2acf53acf129ded955cf5f9500d7a26fca280bb63f812758a46d38a522d6`.
- Estado previo: appaac/versión4e29aba6/32bindings; schedulerba7b746d/cinco crons; staging0crons; DB126/legacyoff. Releer antes de mutar y detenerse ante deriva desconocida. HEAD80268e2/índice55cd8f79 se conservan. No tocar DNS, landingVercel, secretos ni main antiguo.

## Orden de ejecución

1. Conservar `.verification/ci-source.json` (puntero histórico95b) en un recibo propio y seleccionar el certificado `ci-source-c9.json`, cuyo runtime/scripts/migraciones ya se compararon byte por byte con el commit C9. No fabricar otra fuente mediante el armador general ni cambiar HEAD/índice.
2. Detener sólo el scheduler productivo con el comando versionado:

   ```bash
   NODE_OPTIONS=--max-old-space-size=192 node scripts/deploy-production-workers.mjs scheduler-without-crons
   ```

   Comprobar por API ambos schedulers con0crons y su bindingAPP correcto. Registrar la hora de esa confirmación; esperar **15minutos+20segundos** desde ella. No afirmar observación directa de ejecuciones en vuelo. Durante la espera no hay otra publicación.
3. Capturar integridad de todos los consultorios/pacientes/turnos (conteos y SHA de todas sus filas, sin valores), con la fixture propia ausente:

   ```bash
   NODE_OPTIONS=--max-old-space-size=192 node .verification/senas-avisos-20261029/core-integrity.mjs production-core-before
   ```

4. Aplicar las dos migraciones como una transacción, con la copia elegida:

   ```bash
   NODE_OPTIONS=--max-old-space-size=192 node scripts/apply-production-migrations.mjs /home/usuario/.local/share/cita-suite/backups/production-senas-20261030T154244Z
   NODE_OPTIONS=--max-old-space-size=192 node .verification/senas-avisos-20261029/feature-state.mjs production-features-installed
   ```

   Exigir128/globaloff/ambosjobs exactos activos y0políticas/0señas/0huecos: los turnos anteriores no reciben señas retroactivas. El ensayo DDL previo ya hizo rollback y comparó todos los catálogos con staging; no equivale a esta aplicación comprometida.
5. Publicar únicamente los bytes C9 y verificar destinos/permisos:

   ```bash
   NODE_OPTIONS=--max-old-space-size=192 node scripts/deploy-production-workers.mjs app .verification/senas-avisos-20261029/release-c9
   NODE_OPTIONS=--max-old-space-size=192 node scripts/verify-production-release.mjs .verification/senas-avisos-20261029/release-c9 --natalia
   ```

   Comprobar el marcador en ambos orígenes, deployment100%,32bindings idénticos, archivos cliente exactos, CSP sólo del proyecto productivo y ninguna relación expuesta. Natalia conserva su sitio actual si sus35archivos coinciden; no publicar Vercel por inercia.
6. Ensayo propio acotado: `production-owned-deposit.mjs seed` crea exclusivamente consultorio/dueña/paciente/prestaciones propios. Su ON existe sólo en la transacción de semilla y se confirmaOFF; no usar Juan ni Natalia ni enviar mensajes. Conservar estado de filas/bindings después de semilla para comparar B11 y retorno C9. Instalar B11 sólo con globaloff comprobado; comprobar sus bytes y `production-owned-deposit.mjs check <B11 SHA>` (HTTP autenticado real y lectura SQL de pendiente/recibida/exceptuada, registrar y deshacer). La cuenta configurada sólo lee agenda; no usarla como fixture.
7. Volver nativamente a la **versión C9 leída de la API después del paso5**, no a un ID histórico. Si no está disponible, reinstalar los mismos bytes C9. Repetir bytes/orígenes/bindings/Auth/agenda y `production-owned-deposit.mjs check <C9 SHA>`. Máximo dos lecturas de la cuenta configurada por15minutos (dos ingresos cada una); el correo propio del ensayo tiene su límite separado.
8. Si se hace copia posterior con nuevas tablas pobladas, terminar su exportación/ensayo antes de borrar la fixture. Distinguir esa copia128 de la previa126. La recuperación de los dos nuevos trabajos después de restaurar se hace con la operación versionada `supabase/operations/recover-deposit-automation.sql`, siempre en el destino restaurado y globaloff antes de servirlo; el ensayo staging128 ya lo comprobó.
9. Limpiar únicamente el ensayo propio con `production-owned-deposit.mjs cleanup`; exige identidad/documentos/membresías antes de borrar y0filas por consultorio/0dueña después. Capturar huellas completas otra vez y exigir igualdad:

   ```bash
   NODE_OPTIONS=--max-old-space-size=192 node .verification/senas-avisos-20261029/core-integrity.mjs production-core-after production-core-before
   NODE_OPTIONS=--max-old-space-size=192 node .verification/senas-avisos-20261029/feature-state.mjs production-features-final
   ```

   Exigir globaloff,0políticas/0señas/0huecos después de limpiar y trabajos exactos. Conservar prueba de ejecución natural del trabajo pg_cron con0cancelaciones enOFF. No dejar la política sintética ni activar el consultorio de Natalia.

   En esta entrega se eligió la copia posterior **después de limpiar**, para conservar una instantánea128 sin el ensayo propio. La restauración con las cinco tablas nuevas **no vacías** ya está probada separadamente por staging41050555719. Se pidió `gh workflow run backup.yml -R Juan4787/cita-suite-respaldos --ref main -f mode=rehearsal`, ejecutor742e5de; corrida41092046966. No lanzar otra por una demora de visibilidad. Al completar éxito, recuperar sus recibos una sola vez:

   ```bash
   python3 -I .verification/senas-avisos-20261029/check-backup-posterior.py 41092046966
   python3 -I .verification/senas-avisos-20261029/recover-reviewed-backup.py respaldo-productivo-posterior
   ```

   Son nombres de salida exclusivos: no sobrescribirlos. Validar128migraciones, cinco tablas nuevas presentes, global1/resto0, huellas SQL/objetos, destino privado y restauración aislada sin diferencias. La descarga/descifrado local es independiente; la restauración SQL corresponde a esa misma corridaCI. La operación de los dos trabajos cron sigue siendo un paso obligatorio sobre un destino nuevo, no una capacidad implícita del ejecutor privado.
10. Sólo después de comprobar candidata y autenticación restaurar los cinco crons con `deploy-production-workers.mjs scheduler`. Verificar5productivos/0staging y observar eventos reales con `observe-scheduler.mjs`, que conserva sólo metadatos saneados. No desplegar mientras el tail esté activo. Distinguir ejecuciones naturales y cualquier invocación manual; no llamar observado a un trabajo sólo por estar configurado.

## Ante una falla

Conservar el recibo fallido; no sobrescribirlo ni repetir una mutación porque falte su salida. Leer estado real antes de decidir. El primer paso de recuperación es globalOFF; detener el scheduler y conservar márgenes. Volver a B11 si hace falta, con las señas existentes operables. No restaurar toda la base sobre datos posteriores para ensayar una reversión de código.

Para apagar global antes de revertir, desde la raíz y con el acceso productivo privado existente, sin imprimir credenciales:

```bash
NODE_OPTIONS=--max-old-space-size=192 node --input-type=module <<'JS'
import { productionEnvironment, productionPsql } from './scripts/lib/production-database.mjs';
const { database } = productionEnvironment(process.cwd());
productionPsql(database, `begin;
 set local lock_timeout='5s'; set local statement_timeout='30s';
 update private.deposit_automation set enabled=false where singleton;
 do $$begin
  if (select enabled is false from private.deposit_automation where singleton) is not true
   then raise exception 'DEPOSIT_AUTOMATION_NOT_STOPPED'; end if;
 end $$;
 commit;`, { application: 'cita_suite_deposit_emergency_stop' });
console.log({globalOff:true});
JS
```

Conservar una lectura independiente posterior con nombre nuevo (`feature-state.mjs <etiqueta-nueva>`). Si hay un tail, terminarlo antes de usar Wrangler. Detener el scheduler, comprobar0crons y respetar15min20s; luego usar la versión **B11 `0fbe672e-607c-4358-b335-3b047642ff09`**, o reinstalar su paquete íntegro si ese ID ya no está disponible. El `wrangler rollback` nativo exige `--name app --message '<motivo concreto>' --yes`; después comprobar marcador B11,32bindings,esquema128/Auth/agenda y operabilidad de señas existentes. No recuperar hacia las versiones históricas sin controles de seña. Para volver a C9, leer y confirmar su versión `e5dddd3c-90e2-423c-8ce9-fc9ed4b9be15`, repetir esas verificaciones y sólo entonces restaurar los cinco crons.

Los scripts bajo `.verification` son herramientas operativas revisadas en esta sesión y sus resultados se conservan allí; no forman parte del producto ni autorizan nuevos destinos. El cierre exige versión final exacta, comprobaciones completas, limpieza y registro; una preparación o un comando iniciado no son un resultado.

## Resultado de esta ejecución

Control `cierre-productivo.json` aprobado17:04:43UTC: release20/20, C9 servida y B11 recuperable,128migraciones, globaloff/fixtureeliminada, huellas completas deconsultorios/pacientes/turnos idénticas, Auth/agenda final en ambos orígenes, cinco cronsCF/0staging y ocho eventos naturales de cuatro categorías frecuentes sin excepciones. Mantenimiento cada3h no observado y retención diaria ensayada manualmente conrollback: no se atribuyen ejecuciones naturales. Copias previa41081864440 y posterior41092046966 restauradas enCI y recuperadas independientemente. La entrega A/B/C queda cerrada en este alcance; configuración deNatalia yD/E siguen aparte.
