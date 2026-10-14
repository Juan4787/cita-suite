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
El cliente de dump en Docker tuvo problemas de permisos/ruta de Snap y de conexión, sin
DDL ni cambios de datos. Se prepara el cliente PostgreSQL 17 para ejecutarlo en el host.

## Secuencia y compatibilidad

1. Conservar respaldo privado y comprobar su archivo y tabla de contenidos.
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

Preparación y preflight completos. Aplicación de migraciones y publicación pendientes de sus
comprobantes. Esta sección se actualiza únicamente con resultados observados.
