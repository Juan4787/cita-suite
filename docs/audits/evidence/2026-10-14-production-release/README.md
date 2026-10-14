# Comprobantes de publicación — 14/10/2026

Complementan la auditoría local y el [registro de publicación](../../2026-10-14-production-release.md).
No contienen datos de pacientes, tokens, URLs firmadas, credenciales ni el respaldo privado.

- `database-application.json`: historia de 97 migraciones y conservación de datos. La comparación
  inicial refleja dos tablas que cambiaron antes de migrar; la investigación posterior
  demuestra que ambas coinciden con el respaldo previo. `preservation_verified` registra el cierre.
- `data-change-investigation.json`: resultado de esa comparación, sin filas ni valores clínicos.
- `database-post-release.json`: límites, contabilidad, triggers y permisos realmente consultados.
- `backup-summary.json`: formato, alcance, hashes y límites del respaldo; restauración no ejecutada.
- `reproducibility.json` y `cloudflare-fixed-build.sha256`: dos builds iguales de la implementación.
- `natalia-served.json`: los 35 recursos publicados coinciden con el build auditado, incluidas 14 páginas.
- `cloudflare-served.json`: versión y respuestas HTTP actuales; incluye tres recursos anteriores
  que responden 404. No los contabiliza como recursos actuales correctos.
- `deployments.json`: destinos e identificadores reales de despliegue del commit de implementación.

Los checks HTTP son de sólo lectura para datos clínicos: no crean pacientes, turnos ni archivos.
Auth/push físico y operación real de Natalia con datos confirmados permanecen fuera de esta evidencia.
El commit posterior de documentación se distingue de la implementación; no cambia funcionalidad.
