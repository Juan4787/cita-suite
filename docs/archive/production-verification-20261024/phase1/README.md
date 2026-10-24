# Producción: evidencia del 24 de octubre, fase 1

Esta selección conserva recibos concretos, incluidos los fallidos del arnés. No es una certificación del lanzamiento. El código ejecutable es CB; la reversión reparada es 5ee. La matriz final y la medición de capacidad se conservan por separado, cuando terminen.

- El lote Calendar se reprodujo en rojo antes del arreglo. Los verdes locales no reemplazan release ni proveedor.
- La actualización fresca tuvo cron real; la cancelación se comprobó además mediante UI de Google en el Samsung. Los recibos UI anteriores siguen no confirmados.
- El push tiene tres aceptaciones y acuses recibidos/mostrados; sólo dos tuvieron observación directa de la ventana inicial, el tercero es readback durable.
- La recuperación instala 5ee y vuelve mediante rollback nativo a CB, preservando datos, bindings, credenciales y DB126; el respaldo fresco fue verificado y su mecanismo ensayado antes, no se afirma restauración de ese dump exacto.
- HTTP200 no certifica CPUFree: se observaron invocaciones por encima del límite. La API histórica403 no prueba ausencia de ejecuciones. UI_TIMEOUT de Supabase no prueba falta de permisos del usuario.

`manifest.json` identifica la ruta original, tamaño y SHA-256 de cada archivo. No se copian secretos, SQL de respaldo, URLs de gestión, endpoints push ni datos clínicos. Las referencias relativas de los recibos son las del workspace original; no se deben ejecutar operaciones históricas como instrucciones vigentes. Procedimiento actual: `docs/architecture/publicacion-y-reversion.md`.
