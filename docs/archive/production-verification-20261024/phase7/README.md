# Diagnóstico dirigido de rendimiento — fase 7

La investigación del 25 de octubre separa SQL, HTTP productivo, reproducción Node y perfiles de workerd en CI. El informe legible está en `docs/architecture/diagnostico-rendimiento-20261025.md`. **No certifica capacidad alojada, CPU Free ni lanzamiento.** No se contrató ni desplegó nada.

Producción 0851, un fixture de 6.000 pacientes / 12.000 turnos: 22 pedidos, 24 lecturas REST y 43 planes. Tres creaciones HTTP persistieron, las tres SQL se revirtieron; integridad 0/0. La limpieza retiró únicamente el fixture y su dueño, con conteos previos de negocio, Calendar y Storage restablecidos; secreto temporal retirado. No repetir esos operadores.

El diagnóstico CI 40160488305 falló antes de medir: el cliente WebSocket omitía Origin y Wrangler lo exigía al recibir User-Agent. Se conservan el fallo, fuente y rojo/verde real en loopback. La corrección operativa 5930f73 aprobó fast 40160945501 y la repetición CI queda identificada en el recibo `targeted-performance-ci-20261025.json`. Los tres fallos SQL anteriores también se conservan; sólo V3 completó los 43 planes.

Las fuentes archivadas son copias de procedencia de `.verification/`: sus imports y guardas corresponden a esa ubicación original. **No ejecutarlas desde el archivo histórico ni repetir semillas, limpieza, dispatch o publicación ya completados.** Los ZIP y logs completos quedan privados; esta selección tiene bytes y SHA256 y pasó patrones de secretos y comparación con los secretos reales del entorno en memoria. Los JSON de credenciales Google no se leyeron. El manifiesto no implica que cada archivo fallido haya aprobado: los recibos conservan su estado y alcance.

En Git están las revisiones operativas aisladas; la fuente compilada/productiva sigue siendo 0851. Las fases 1–6 son inmutables. El plan original, HEAD e índice del usuario se conservan. No se atribuye a esta investigación una aprobación de todos los requisitos de la campaña.
