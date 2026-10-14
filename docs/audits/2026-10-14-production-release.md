# Publicación de las extensiones de Natalia / Cita Suite

El usuario autorizó publicar la entrega completa el 14/10/2026. Este registro complementa,
sin reemplazar, la [auditoría local](2026-10-14-implementation-ledger.md) y el
[contrato funcional y de operación](2026-10-14-booking-extensions-contract.md).

## Destinos y alcance

- GitHub: `Juan4787/dashboard`, rama `main`, base `a480dbbe319e1a5dfc4f34e6d771828831b90b29`.
- Cita Suite: `https://app.cita-suite.workers.dev`, Worker `app`, cuenta Cloudflare
  `52b358653379c162b5a07b10ae5e84b3`, despliegue conectado a GitHub. La sesión OAuth local
  pertenece a otra cuenta y no se usará para desplegar en ella.
- Supabase: proyecto vinculado `yjzferwuzbtgpmdnzlcb`; sólo las cuatro migraciones del
  14/10 revisadas. Sin seeds, cambios de Vault, borrados de documentos ni configuración falsa.
- Natalia: reemplazo del sitio `https://natalia-frutos.vercel.app`, proyecto Vercel
  `natalia-frutos`. Publicación de las 14 páginas y sus assets desde el artefacto estático
  completo; no se sube el workspace ni adjuntos/credenciales.

Se publican código, pruebas, migraciones, documentación y evidencia resumida de esta entrega.
Backups, credenciales, tokens, capturas históricas y materiales antiguos quedan fuera de Git.
No se activan servicios, tarifas, horarios, cuestionarios o contacto inventados para Natalia.
Las nuevas opciones requieren configuración desde el panel. Cursos y noticias continúan
postergados; no se incorporan notificaciones WhatsApp ni procesamiento asíncrono de PDFs.

## Evidencia previa a la publicación

La fuente y la documentación coinciden con sus manifiestos SHA-256 auditados. Las suites
anteriores están aprobadas: 958 tests de lógica/servidor, 74 de componentes, reconstrucción
de 97 migraciones y diez contratos SQL, y comprobaciones locales de navegador. El último
arreglo visual fue puntuado como resuelto. Todos los procesos pesados se ejecutan secuencialmente.

Preflight remoto de sólo lectura: PostgreSQL 17.6; 93 migraciones ya aplicadas y exactamente
cuatro pendientes; 62 tablas existentes con huellas privadas de sus columnas originales;
base de 28.454.035 bytes; 32 objetos de Storage, 15.675.483 bytes; objeto clínico mayor de
2.630.421 bytes; metadata mayor de 213 bytes; sin documentos incompatibles con la nueva
restricción; privilegio TRIGGER disponible. El dry-run confirma únicamente esas cuatro
migraciones y ningún seed/rol adicional. Las huellas y el respaldo contienen información
protegida y no se incluyen en esta documentación ni en Git.

El `migration list --linked` inicial falló por timeout en la conexión directa. Se verificó
el destino y se emplea la conexión existente del proyecto; el dry-run por esa ruta pasó.
Los intentos de `pg_dump` no completaron por problemas de permisos/ruta de Snap y de
conexión; no constituyen un respaldo válido. Se cambió a una exportación nativa SQL COPY
en una transacción de sólo lectura/repeatable read, con metadata exacta del esquema
afectado. El respaldo privado contiene 66 tablas y 3.225 filas; todos sus bloques y
recuentos se validaron. Datos: 1.581.793 bytes, SHA-256
`bb596ce2ebe540718f881b52364c98dc3388145411e51cbc9944aee93215bacc`.
Metadata: 932.710 bytes, SHA-256
`8e97f5b5d7c707f12a7d64a6fe8f3c8663d14203fcdf61b7ac693d54f9f17894`.
Se conservaron las 93 migraciones previas. No se ejecutó una restauración; esta exportación
cubre datos public/private, historia de migraciones y metadata de Storage, sin exportar
Auth del proveedor ni binarios de archivos, que esta entrega no modifica.

Las cuatro migraciones se aplicaron realmente: la historia remota ahora contiene 97 y
coincide con la fuente. De las 62 tablas existentes, 60 coinciden con el preflight inicial;
dos cambiaron durante la preparación, antes de migrar. Ambas coinciden exactamente con
el respaldo inmediatamente anterior a las migraciones, sin columnas o filas alteradas
por el despliegue. Se conservan separados el primer resultado y su investigación: no se
presenta el preflight antiguo como una captura simultánea al respaldo.

La verificación remota confirma bucket privado, PDF permitido, límite de 5.000.000 bytes
por archivo, presupuesto global de 700.000.000 bytes, 15.675.483 bytes usados y cero
reservados. El contador coincide con Storage. Ambos triggers están activos; el rol anónimo
no puede ejecutar la función de contacto; los roles de servidor/panel tienen los permisos
previstos. Carga del paciente y contacto público siguen apagados en todos los consultorios;
no se cambió configuración real para habilitarlos.

El commit de implementación es `66c725fc66c044bff6fa99ab087c988d90eb914a`, publicado
en `main`. Dos builds secuenciales con esa versión produjeron los mismos 123 archivos;
SHA-256 del manifiesto: `f5a13d56696211ca457b8daece60e1b91537c9bc23cd78b6b3b955e7739edee0`.
Natalia quedó publicada en Vercel (`dpl_85cKc1N4gYaKGUSUUDpFMSH7np6Z`, estado READY);
las 14 páginas y los 35 recursos servidos por su URL pública coinciden byte a byte con
el artefacto auditado. La clave de integración real de Natalia permanece sin configurar.

## Secuencia y compatibilidad

1. Conservar respaldo privado y comprobar sus bloques, recuentos y metadata de esquema.
2. Confirmar que la fuente sigue revisada y libre de credenciales reales; crear commit exacto.
3. Compilar el Worker con versión fija del commit y comprobar reproducibilidad antes de push.
4. Aplicar las cuatro migraciones, verificar historia, permisos, límites y conservación de
   datos existentes. Registrar resultados reales; no describir dry-run como aplicación.
5. Publicar en `main`, observar el build de Cloudflare de ese commit y verificar versión,
   recursos y respuestas servidas. Publicar el artefacto completo de Natalia en su proyecto.
6. Registrar comprobantes, límites e incidencias. Los permisos de carga/contacto comienzan
   apagados; no se habilitan con datos sintéticos por el hecho de publicar.

Antes de activar políticas, restricciones o documentos nuevos, el backend antiguo conserva
sus operaciones básicas sin esas configuraciones. Una reversión de código después de
configurarlas necesita revisar compatibilidad o cerrar la entrada pública; no eliminar
triggers, columnas de snapshots, historia ni archivos para forzar un rollback. El respaldo
privado se conserva fuera de Git. La publicación no sustituye configuración real de Natalia,
pruebas de Auth/push físico ni métricas de facturación y transferencias del proveedor.

## Estado

Publicado: implementación `66c725fc66c044bff6fa99ab087c988d90eb914a` en GitHub `main`,
cuatro migraciones aplicadas en Supabase, Worker `app` desplegado y Natalia reemplazada
en Vercel. El build conectado de Cloudflare terminó SUCCESS, identificador
`5ccf46b7-949a-488f-bc38-759dfc4a7e4e`; la versión recibida por HTTP coincide con el
commit publicado. Login responde 200 con CSP y sus tres recursos iniciales coinciden
con el build local fijo. El SDK JS/CSS del turnero y el service worker coinciden con la
fuente; contacto inexistente responde JSON de error sin exponer errores internos.

Se comprobaron nueve recursos/respuestas actuales. También se consultaron tres recursos
iniciales del despliegue anterior: responden 404 tras el reemplazo; Cloudflare no conserva
esos nombres antiguos. Las pestañas que permanezcan abiertas durante una publicación
pueden requerir recarga. No se presenta esta comprobación como prueba de continuidad
de una sesión autenticada abierta antes del despliegue.

El [paquete de comprobantes públicos](evidence/2026-10-14-production-release/README.md)
contiene resultados y hashes sin datos de pacientes ni secretos. Este documento y los
comprobantes se publican en un commit posterior que sólo cambia documentación: se distingue
del commit de implementación, y su build conectado se comprueba al cerrar la publicación.
No se afirma una validación de Auth real, push físico, reserva real de Natalia ni descarga
real de documentos de producción. La clave de integración de Natalia y las opciones de
contacto/carga requieren configuración confirmada; la publicación no inventa esos datos.

Limpieza: no quedaron contenedores de cliente de respaldo etiquetados para esta publicación;
se retiró el archivo vacío del intento fallido de `pg_dump`. Se conserva el respaldo válido
fuera del repositorio, con permisos privados; los materiales locales ajenos se preservan.
