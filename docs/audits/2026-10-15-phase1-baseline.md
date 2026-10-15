# Paso 1: inventario, contratos y baseline previa a la refactorización

Resultado: todas las etapas obligatorias de `pnpm verify:baseline` aprobadas sobre la fuente con huella `52b4ecaaf55dd540a82cdcf3a453e10b330b2810387e35f03bc84b33f909ae40`, basada en `313355a4403e850379ace72bb4f37cd1c7952142`. La huella incluye las modificaciones de scripts/configuración de este paso. No se modificaron funciones de negocio ni se publicó.

## Entregables

- [Arquitectura vigente e inventario funcional](../architecture/current-system.md): aplicaciones, reserva nativa, compatibilidad embebida, superficies heredadas y propiedad de reglas.
- [Comando y alcance de la baseline](../architecture/baseline.md): requisitos, etapas, límites de memoria y evidencia.
- `scripts/architecture-inventory.mjs`: inventario sin leer secretos ni acceder a servicios; 167 entradas de rutas/layouts agrupadas, fuentes, pruebas y huellas.
- `scripts/verify-baseline.mjs`: ejecución secuencial, rechazo de suites vacías/pendientes, artefactos privados, recursos descartables propios y limpieza.
- [Recibo conservado](evidence/2026-10-15-phase1/baseline.json), [inventario de fuentes](evidence/2026-10-15-phase1/source-inventory.json) y [catálogo SQL reconstruido](evidence/2026-10-15-phase1/effective-database-contract.json).

## Verificación ejecutada

| Comprobación | Resultado |
|---|---|
| Tipos de shared, web y Natalia | Aprobado |
| Servidor: 135 archivos | 1.008 pruebas aprobadas, cero fallidas o pendientes |
| Componentes: 13 archivos | 100 pruebas aprobadas, cero fallidas o pendientes |
| Build Cloudflare y build Astro | Aprobados |
| Assets y fidelidad pública de Natalia | Aprobados |
| Navegador de Natalia con endpoints interceptados | Once escenarios aprobados |
| Reconstrucción SQL | 97 migraciones aplicadas en base descartable |
| Contratos SQL | Los 24 archivos `.sql` aprobados; hay 27 resultados pgTAP además de comprobaciones internas de los bloques SQL |
| Reserva nativa con app y PostgreSQL/PostgREST locales | Dos recorridos aprobados, 1440×960 y 390×844 |
| Recuperación, gestión completa y enlace histórico | Aprobados sin reservas duplicadas |
| Apariencia opuesta al sistema y recarga | Claro con sistema oscuro y oscuro con sistema claro conservados |
| Salud del navegador | Cero errores de ejecución/consola y cero advertencias de consola en esos recorridos |
| Limpieza | Sin supervisor, Vite, contenedores propios, runtime de credenciales o bloqueo de esta ejecución restantes |

El catálogo SQL se tomó de la base local después de los contratos y puede incluir funciones de plataforma, extensiones y helpers de prueba. No es una inspección del esquema de producción ni un contador de reglas de negocio independientes. Los tiempos del recibo son de esta máquina y no se usan como certificación de latencia comercial.

## Hallazgos y ajustes durante la construcción del ejecutor

1. La primera comprobación completa de tipos agotó un heap de 768 MB. Se fijó 1 GB para esa etapa; se deshabilitaron volcados de memoria de subprocesos. No era un fallo de tipos del código de la app.
2. El primer navegador arrancó antes de que el SSR local estuviera listo. Se reprodujo que la disponibilidad de un archivo estático no garantiza la del formulario. El supervisor emitió READY después del arranque real; esperando esa condición ambos recorridos pasaron. El ejecutor final usa esa señal y no oculta el intento fallido.
3. Se comprobó interrupción durante el arranque del fixture y fallo deliberado del prerrequisito Docker. Ambos terminan con fallo explícito y liberan los recursos/bloqueo correspondientes. La limpieza no depende de que las pruebas hayan llegado al navegador.
4. SvelteKit emitió seis advertencias de desarrollo sobre la vida de `event.fetch` y el `load` del layout de integración. Quedaron registradas para una regresión dirigida de dependencias e invalidación en el paso 4. Los recorridos completaron sin errores de navegador; no se afirma que la advertencia demuestre un incidente en producción.
5. Las capturas de gestión muestran distinto ancho de los paneles iniciales de arancel/indicaciones respecto del contenido central en escritorio. Se conserva como referencia visual anterior a la extracción; evaluar esa consistencia en el paso 5 sin introducir un rediseño accidental durante el movimiento de componentes.

## Lo que este resultado no cierra

- Los pasos 2 a 7 siguen pendientes: clientes/contratos tipados, capacidades y cuotas por consultorio, modularización, calculador de precios único, componentes, tareas y medición de crecimiento.
- Los 14 specs E2E privados y scripts shell especializados de concurrencia están inventariados, no ejecutados ni contados como aprobados. Algunos requieren Auth/Storage reales locales o fixtures distintos; no se apuntan a producción para completar el número.
- No se probó OAuth real, pagos externos, transferencia HTTP con el servidor nativo de Storage ni recepción física de avisos.
- No se prometen tiempos reales ni capacidad para 25 consultorios por pasar en PostgreSQL de 384 MB/una CPU.
- Las políticas externas de publicación automática no cambiaron. La asociación entre promoción, revisión y evidencia sigue siendo requisito del lanzamiento.

Las capturas y logs crudos permanecen en `/tmp/cita-direct-booking-qa/` y `/tmp/cita-baseline-Y7gbSC/`. El recibo y los inventarios sin credenciales se conservan en el repositorio para futuras auditorías; un nuevo `pnpm verify:baseline` genera su propia evidencia.
