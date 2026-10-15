# Verificación local secuencial

Comando de entrada: `pnpm verify:baseline`.

La baseline fija el comportamiento actual antes de refactorizar. No publica, no migra producción, no usa cuentas reales y no certifica capacidad para 25 consultorios. Sus recibos deben conservar la revisión y la huella de fuentes de la ejecución concreta.

## Requisitos

- Dependencias pnpm ya instaladas, Node y `prlimit` de util-linux en Linux.
- Chromium ya instalado para la versión de Playwright del monorepo.
- Docker accesible e imágenes ya descargadas: `public.ecr.aws/supabase/postgres:17.6.1.166` y `public.ecr.aws/supabase/postgrest:v16.1`.
- Ningún supervisor de fixtures usando `/tmp/cita-booking-runtime.json` o `/tmp/cita-booking-storage.json`; el ejecutor no borra los recursos de otra sesión.

No descarga imágenes ni navegadores implícitamente. La máquina tiene RAM limitada: las suites se ejecutan de a una y Vitest/Playwright usan un trabajador. La comprobación de tipos tiene límite de heap de 1 GB; los demás subprocesos de la baseline, 768 MB. Los volcados de memoria de subprocesos se deshabilitan. No iniciar otros builds mientras corre.

## Etapas obligatorias

1. Inventario de código/configuración y precondiciones.
2. Tipos de `shared`, web y Natalia.
3. Todas las pruebas de servidor de web, con informe JSON y comprobación de que realmente corrieron sin casos pendientes.
4. Todas las pruebas de componentes, con la misma comprobación.
5. Build de Cloudflare.
6. Build estático de Natalia con clave pública sintética, contrato de assets/fidelidad y escenarios de navegador interceptados.
7. Reconstrucción de todas las migraciones en PostgreSQL descartable y ejecución de todos los contratos `supabase/tests/*.sql`.
8. Inventario de funciones, firmas, retornos, contexto de seguridad y tablas del esquema efectivo reconstruido.
9. App local real con PostgreSQL/PostgREST, Auth simulado y Chromium: reserva desde el sitio estático, formulario, creación, gestión completa, recuperación sin duplicado y enlace histórico, en escritorio y móvil. Modo del sitio opuesto al sistema y conservación tras recarga.
10. Limpieza de recursos propios y comprobación de que las fuentes no cambiaron durante la ejecución.

Los informes y logs se guardan en una carpeta privada `/tmp/cita-baseline-…`, impresa al terminar. `result.json` distingue cada etapa, conteos y errores. `source-inventory.json` fija la huella del código probado y `effective-database-contract.json` registra lo que reconstruyeron las migraciones. Los tokens sintéticos del runtime temporal no se incorporan al recibo y se eliminan con su supervisor.

El build de Natalia de esta verificación utiliza una clave sintética. Es un artefacto de pruebas; una publicación posterior debe reconstruirse con la configuración pública autorizada del destino real.

## Comandos parciales

- `pnpm check`: tipos de los tres paquetes, secuencialmente.
- `pnpm test`: suites de servidor y componentes, secuencialmente. No incluye SQL ni navegador.
- `pnpm --filter web test <archivo>` o `pnpm --filter web test:client <archivo>`: una suite focalizada.
- `node scripts/test-booking-foundation.mjs --all-contracts`: reconstrucción y contratos SQL; elimina su base al terminar.
- `pnpm inventory:architecture`: inventario sin acceder a base, env privados o servicios remotos.

Un comando parcial no reemplaza el recibo de la baseline completa. Una prueba fallida debe quedar registrada; no convertir un resultado en aprobado eliminando una suite o permitiendo cero pruebas. La utilidad histórica `preflight:staging` tiene otro alcance y no sustituye esta verificación.

Esta etapa no modifica los checks requeridos de GitHub ni las reglas del despliegue automático de Cloudflare. Un recibo local no demuestra que cada push esté bloqueado hasta completar la verificación. La promoción debe asociarse a la misma huella de fuente comprobada y completar su control de publicación antes del lanzamiento.

## Medición de crecimiento en el paso 7

El contenedor SQL de esta baseline usa 384 MB y una CPU. Permite comprobar contratos y comportamiento bajo recursos acotados; sus tiempos no representan automáticamente al proveedor real. Las pruebas de planes deben usar datos representativos, estadísticas actualizadas y el rol/configuración correspondientes. No ejecutar `EXPLAIN ANALYZE` de escrituras en producción como prueba: ejecuta la sentencia.

No exigir cero `Sequential Scans`: una tabla pequeña o una lectura amplia puede justificarlos. Evaluar filas y buffers visitados, selectividad, estimaciones, índices y trabajo repetido, sin forzar `enable_seqscan=off` para obtener un aprobado. [PostgreSQL: EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html).

El número de viajes externos de una operación local de un consultorio debe estar acotado y no aumentar por cada consultorio ajeno. Eso no significa tiempo SQL `O(1)`: una sola RPC puede leer demasiadas filas. Para trabajos globales, el volumen total crece con el trabajo, pero cada ejecución debe respetar su presupuesto y repartirlo de manera justa. Registrar también payload, CPU, memoria, filas/buffers y espera pendiente; validar latencia/capacidad en infraestructura representativa antes de prometerla.
