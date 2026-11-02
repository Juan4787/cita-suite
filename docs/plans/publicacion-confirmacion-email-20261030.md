# Publicación: confirmación de correo

## Método vigente tras la corrección del usuario

El usuario mantiene el máximo rigor de auditoría y exige cubrir inconsistencias. Confirmó que actualmente no hay pacientes reales y rechazó la sobreingeniería para conservar turnos ficticios. La autorización de escrituras y pruebas en producción sigue vigente. Este procedimiento reemplaza la secuencia anterior que exigía staging, renovación de backup por antigüedad y ensayos de reversión como pasos automáticos.

La seguridad de cuentas, secretos, permisos, aislamiento, código, configuración comercial e infraestructura sigue siendo necesaria. Los pacientes y turnos ficticios pueden modificarse, eliminarse o regenerarse para probar. Elegir los controles por el riesgo concreto y por la evidencia que agregan.

## Estado y material disponibles

La V8 `408ca04d9e6750e4657dc087264644665a63fb37` quedó publicada y comprobada en producción el 31 de octubre, versión Cloudflare `a1844665-447e-40bb-b9e5-ce7c03ed29d7`. Tiene release completo 20/20 aprobado y prueba de navegador contra producción `41238345216` aprobada. Staging conserva la recuperación compatible por decisión previa; no bloquea esta entrega. Los recibos y rutas exactos están en el [traspaso](traspaso-confirmacion-email-20261030.md). La ruta siguiente describe el procedimiento utilizado: no volver a desplegar ni repetirlo porque figure aquí.

Esta entrega no necesita migraciones ni cambios de SMTP, plantillas, DNS o scheduler. No cambia el acceso de Natalia ni reanuda D/E.

## Ruta de continuación

1. Comprobar que se va a publicar el paquete aprobado en el Worker correcto y que no se pisa una publicación posterior. Aprovechar la evidencia existente; no repetir suites o construir nuevas versiones sin una razón técnica.
2. Publicar directamente la candidata en producción con el script ya preparado:

   ```bash
   NODE_OPTIONS=--max-old-space-size=192 node scripts/deploy-production-workers.mjs app .verification/confirmacion-email-20261030/release-candidate-v8
   ```

3. Comprobar a fondo el comportamiento real: alta pendiente sin error rojo, reenvío, confirmación, ingreso, invitaciones/permisos, sesión ajena y enlaces inválidos/usados. Usar destinatarios de prueba apropiados y cuidar las cuentas reales. Investigar cualquier inconsistencia, incluyendo flujos relacionados cuando la evidencia o el cambio lo justifiquen.
4. Elegir pruebas de navegador, HTTP, datos o CI que puedan demostrar o refutar lo investigado. Se puede probar primero en producción. Usar aislamiento o staging si resuelve un riesgo o una limitación específicos, sin duplicar automáticamente el mismo trabajo en ambos entornos. Las pruebas pesadas permanecen fuera del equipo con poca RAM; los chequeos remotos puntuales no requieren reconstruir un laboratorio.
5. Mantener el paquete de recuperación compatible ya disponible. Si aparece una regresión que requiere volver atrás, usar una versión que conserve `/confirmar-correo`, porque puede haber enlaces emitidos hacia esa ruta. No instalar un checkpoint ni ejecutar candidata→rollback→candidata sólo para cumplir un rito; ensayar algo adicional cuando el cambio concreto lo requiera.
6. Cerrar con la revisión publicada, las pruebas efectivamente realizadas, hallazgos/correcciones y pendientes honestos. No exigir que las filas ficticias conserven sus hashes iniciales ni un backup menor a seis horas para esta entrega de UI/Auth sin migraciones. El respaldo existente queda como recurso; una operación que afecte activos reales puede necesitar otra protección, justificada por esa operación.

## Límites que sí importan

- Conservar la obligación de confirmar email, las validaciones de identidad y el aislamiento entre cuentas.
- No exponer credenciales ni atribuir entrega externa a una captura SMTP o a un enlace generado administrativamente.
- No modificar dominios, configuración comercial o cuentas reales por accidente. La landing permanece en Vercel y el sitio de Natalia no necesita una nueva publicación por esta corrección.
- Respetar cuotas y RAM. No repetir logins sin necesidad ni borrar sus contadores para obtener un resultado favorable.
- Conservar el código y el trabajo del usuario; no resetear su árbol ni sobrescribir evidencias históricas.

El script operativo `predeploy-gate.mjs` contiene la condición antigua de antigüedad del backup. No es una puerta obligatoria vigente: su código no prevalece sobre la decisión posterior del usuario. Si se reutiliza, ajustar esa precondición y conservar las verificaciones que sí aportan seguridad o certeza sobre el destino.

Restaurar la candidata en staging es opcional si se quiere volver a usar ese entorno. Su estado de recuperación no bloquea publicar ni probar la candidata en producción.
