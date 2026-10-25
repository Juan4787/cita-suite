# Diagnóstico dirigido de rendimiento — 25 de octubre de 2026

## Estado y alcance

**La aceptación de lanzamiento continúa pendiente.** Esta investigación acotada contrasta disponibilidad, ficha de paciente y creación manual de turnos. No sustituye los dos ensayos alojados de dos consultorios que incumplieron latencia, conservados en [capacidad](capacidad.md). No se modificaron sus umbrales ni se ejecutó una tercera carga idéntica para buscar un resultado favorable.

**Ronda terminada:** diagnóstico productivo, limpieza y perfil del runtime en CI completados. Se corrigió un defecto reproducido del arnés; no apareció una corrección justificada de aplicación o SQL. El lanzamiento sigue sin aprobar.

| Identidad | Revisión / alcance |
|---|---|
| Aplicación productiva | `0851de59ed7971debe2514e6d6851d142bbc5766`; DB con 126 migraciones |
| Principal al comenzar | `bc307f5c8859fe9508ea524780bee52f91d98bfd` |
| Primer arnés | `f2dcb7aafec53914e68700369737e659088c84f7`; fast 40160236590 aprobado; diagnóstico 40160488305 fallido |
| Corrección del inspector | `5930f73ab868ff9956408f04d0c1f102c1044a38`; fast 40160945501 y diagnóstico 40161186500 aprobados; sólo operación y pruebas, sin aplicación ni SQL |

Las fuentes de aplicación, paquetes, migraciones y configuración de ambas revisiones operativas coinciden con 0851. Las únicas diferencias bajo `apps/` son 15 capturas históricas. El SHA del arnés no debe presentarse como versión publicada ni reemplazar `.verification/ci-source.json`.

## Protocolo y preservación

El protocolo se guardó antes de sembrar. Se utilizó un único consultorio propio con la semilla determinista existente: 6.000 pacientes, 12.000 turnos, tres profesionales y cinco prestaciones. Conserva el volumen por consultorio; **no reproduce dos consultorios ni la carga concurrente del plan**. La base antes de sembrar ocupaba 208.276.627 bytes. Se mantuvo la guarda conservadora de sumar 50 MB por consultorio y permanecer por debajo de 300 MB; no se debilitó para insertar dos.

Se hicieron 22 pedidos secuenciales por la aplicación: ocho de disponibilidad, ocho de ficha, tres preparaciones y tres creaciones. Otras 24 lecturas observaron ocho componentes de Auth/PostgREST por separado. Los 43 planes SQL comprenden ocho lecturas repetidas cinco veces y tres creaciones atómicas con `ROLLBACK`. Las lecturas SQL usaron `authenticated` y las claims del dueño sintético; la creación usó `service_role` con actor explícito validado. No hubo cambios de índices, funciones, RLS, configuración global o reinicios de estadísticas.

Las tres creaciones HTTP se persistieron y releyeron dentro del consultorio propio; las tres de SQL se revirtieron. Integridad: cero cruces y cero superposiciones en el fixture. La limpieza a **03:56:08 UTC** eliminó un consultorio, 6.000 pacientes, 12.003 turnos y un dueño. Se comprobaron cero restos y los conteos previos: 19 negocios, 121 pacientes, 107 turnos, Calendar 1 conexión / 1 vínculo, 24 objetos y 11.599.541 bytes almacenados. El secreto temporal local fue retirado; no se creó un secreto de Actions ni se cambiaron credenciales de la app.

La base física quedó en 227.757.203 bytes. Borrar filas no devuelve inmediatamente espacio al sistema; no se presenta como restauración física exacta ni se ejecutó mantenimiento invasivo para forzarla.

## SQL real: observaciones

Tiempos `Execution Time` de PostgreSQL en milisegundos. No incluyen el viaje del cliente ni equivalen a CPU del Worker.

| Operación | Muestras | Mediana | Máximo |
|---|---:|---:|---:|
| Contexto y membresía | 5 | 1,192 | 11,120 |
| Catálogo de disponibilidad | 5 | 1,811 | 13,808 |
| Ventana de un día | 5 | 2,842 | 7,475 |
| Ventana de quince días / tres profesionales | 5 | 11,099 | 95,879 |
| Datos básicos del paciente | 5 | 1,272 | 2,212 |
| Perfil clínico | 5 | 0,034 | 0,770 |
| Entradas clínicas y costos | 5 | 1,566 | 3,157 |
| Próximos turnos del paciente | 5 | 1,341 | 1,604 |
| Creación atómica, revertida | 3 | 20,030 | 139,434 |

Los planes visibles de ficha utilizaron los índices existentes de negocio/paciente, entradas y próximos turnos. La ficha elegida tenía una entrada clínica y su perfil clínico no tenía fila: no es un caso de historia extensa. En los 43 nodos raíz hubo **cero `Shared Read Blocks` y cero bloques temporales**. La muestra no ensaya caché fría ni presión de memoria/disco; los primeros pedidos se conservan, pero no se los llama prueba de arranque frío.

Los RPC muestran tiempo total incluyendo trabajo interno. No se obtuvieron sus planes anidados: el rol no es superusuario y carece de permiso para modificar los siete ajustes de `auto_explain` inspeccionados. No se intentó eludir esa restricción. El marcador independiente de `pg_stat_statements` fue válido e igual antes/después; no se atribuye un delta global exclusivamente al diagnóstico. `pg_stat_database.stats_reset` seguía siendo nulo.

## HTTP productivo: observaciones

| Recorrido | Muestras | Cliente mediana / máximo (ms) | Pared servidor mediana / máximo (ms) | Viajes HTTP a Auth/PostgREST |
|---|---:|---:|---:|---:|
| Disponibilidad | 8 | 232,7 / 818,3 | 127 / 703 | 4 |
| Ficha | 8 | 257,9 / 905,5 | 129 / 784 | 9 |
| Preparación de creación | 3 | 232,8 / 255,5 | 118 / 139 | 4 |
| Creación manual | 3 | 431,9 / 529,5 | 327 / 441 | 7 |

Todos respondieron correctamente; el clasificador rechaza un HTTP 200 con un nodo de error. La ficha exige identidad del paciente y del consultorio, y las creaciones exigen redirección canónica y persistencia propia. No se guardaron cuerpos clínicos, cookies ni tokens.

Se utilizó el `Server-Timing` existente, sin publicar instrumentación nueva. `auth + load` es tiempo de pared del hook. `db` suma intervalos de fetch hasta encabezados que pueden solaparse e incluye Auth: **no es tiempo SQL, CPU ni camino crítico**. Por ejemplo, en la primera ficha suma 3.458 ms frente a 784 ms de pared del servidor; esa diferencia no es CPU negativa ni un dato que deba descartarse. Los componentes REST separados tuvieron medianas alrededor de 67–73 ms desde este host, pero son pedidos diferentes: no se restan a los planes SQL para atribuir una demora exacta al proveedor.

La lectura compartida de membresía ya existe para GET dentro del mismo pedido. Las escrituras revalidan permisos. No se encontró evidencia para eliminar controles, agregar caché global de autorización o fusionar lecturas sensibles sólo por reducir un contador.

## Calculador y runtime

La reproducción liviana del parser y calculador reales en Node utilizó JSON del fixture exclusivamente en memoria. Treinta iteraciones: 6 opciones / 12 bloques; primera CPU de proceso 7,408 ms, mediana de las 29 calientes 1,815 ms. Tres mutaciones rechazaron negocio ajeno, ventana incompleta y conteo incorrecto. **No es una medición de CPU de Cloudflare.**

[CI 40161186500](https://github.com/Juan4787/cita-suite/actions/runs/40161186500) terminó a 04:18:11 UTC sobre 5930f73. Diez evidencias recuperadas; paquete SHA256 `c39718ad8eeebaf405246a422f8fc6da354e60e65476abad70b65d2b3334509c`. Se comprobaron los 22 pedidos, tres creaciones propias persistidas, cero cruces/superposiciones, los dos rechazos del limpiador y su retiro final de 6.000 pacientes / 12.003 turnos / un consultorio / un dueño. Cero restos, cuatro contenedores sanos, cero OOM/deadlocks/errores Auth en el diagnóstico de plataforma. El fast previo aprobó 13 controles, 1.395 pruebas servidor, 175 cliente, 152 guardas Node y 11 del programador, sin fallos, cancelaciones, omisiones ni pendientes.

| Recorrido en CI | Muestras | Cliente mediana / máximo (ms) | Pared servidor mediana / máximo (ms) |
|---|---:|---:|---:|
| Disponibilidad | 8 | 36,552 / 73,271 | 29 / 62 |
| Ficha | 8 | 50,860 / 89,061 | 35,5 / 75 |
| Preparación | 3 | 42,486 / 50,531 | 35 / 43 |
| Creación | 3 | 76,293 / 95,396 | 69 / 81 |

No son pedidos emparejados con producción: difieren máquina, red, servicios, orden y estado de calentamiento. La diferencia no cuantifica una penalidad exclusiva de Supabase o Cloudflare.

Los tres perfiles contienen 8, 8 y 6 pedidos; el tercero incluye las tres preparaciones y las tres creaciones. El perfil de disponibilidad muestra validación de configuración, parseo de negocio, SDK, fetch y cookies. La validación recorre el catálogo una vez; no apareció una segunda validación completa por cada ventana. La ficha y la creación también tienen frames anónimos sin localización independiente, que **no se atribuyen por conjetura** a una función o proveedor. Un solo formateador para validar una zona no equivale al antiguo defecto de construir uno por franja.

No hay en este muestreo un trabajo redundante concreto que justifique quitar validaciones o reescribir el calculador. Los totales aproximados `busyMs` de las fases son 256,46 / 181,94 / 236,48 ms; se conservan con su definición y no se dividen por pedido para presentarlos como CPU contractual. El muestreo sólo conserva nombres de funciones, archivos y líneas. `busyMs` del resumidor existente excluye idle, program y GC y utiliza atribución aproximada entre muestras: no es CPU facturable ni certifica los 10 ms de Workers Free. [Límite oficial de CPU](https://developers.cloudflare.com/workers/platform/limits/), [contrato del perfil de DevTools](https://chromedevtools.github.io/devtools-protocol/tot/Profiler/#type-Profile).

## Fallos del diagnóstico y correcciones

Los fallos se conservan; no se reetiquetan como resultados aprobados de la aplicación.

1. Preflight SQL con `limit1`: falló antes de los planes. Después, JavaScript consumió el separador de `\gset`; otra revisión pegó UUID y `limit`. Hubo lecturas parciales antes del tercer fallo, sin creaciones. Se corrigieron los separadores y se eliminó el metacomando interpolado; V3 completó los 43 planes. Los tres intentos previos y sus fuentes quedan identificados.
2. CI 40160488305: build y reconstrucción de 126 migraciones aprobados, `/login` respondió 200 y los cuatro servicios seguían sanos. Falló el handshake del inspector antes de los 22 pedidos; no hubo perfil. El `finally` terminó sin error adicional de limpieza de recursos descartables.
3. Causa reproducida: `InspectorProxyWorker.ts` de Wrangler 4.86.0 exige Origin si hay User-Agent; el WebSocket nativo de Node envía User-Agent sin Origin. Prueba real de handshake en loopback: **rojo 3/1 antes de corregir**, luego Origin derivado del endpoint: **verde 10/10** con pruebas de CPU/diagnóstico. Se mantuvo el rechazo sin Origin y con Origin ajeno, sin desactivar la guarda ni agregar dependencias. Sólo cambió el cliente operativo del inspector.

## Decisión y siguiente condición de avance

No hay evidencia en esta muestra para agregar índices, reescribir el calculador, quitar RLS, cachear permisos entre pedidos ni desplegar otra versión de la aplicación. Eso no demuestra que toda consulta o todo recorrido sea óptimo. Se conserva el fallo de latencia alojada y el riesgo independiente de CPU Free.

La hipótesis de esperas compartidas del backend sigue siendo compatible con las observaciones históricas, pero no tiene atribución causal exclusiva. Esta muestra breve sin presión no la confirma ni la refuta. Cambiar de infraestructura exigiría un presupuesto autorizado compatible y repetir la aceptación con los mismos criterios: no se contrató ni migró nada y pagar no se presenta como garantía.

Un próximo ensayo de aceptación necesita una corrección concreta o un cambio controlado y justificado. Si se retoma únicamente la atribución, debe emparejar los pedidos lentos con sus componentes durante la pausa, mediante una ventana acotada y sin muestrear agresivamente la instancia. No repetir una carga de 48 minutos sin hipótesis nueva ni convertir este diagnóstico de un consultorio en aprobación de dos.

## Reproducción, evidencias y reversión

El [archivo de la fase 7](../archive/production-verification-20261024/phase7/README.md) conserva la selección saneada y su manifiesto de bytes/SHA256, incluidos los fallos. Los ZIP completos, planes/logs privados y archivos originales siguen bajo `.verification/`; los JSON de credenciales Google no se leyeron ni se incorporan. Los operadores archivados son procedencia, **no instrucciones para repetir las semillas o limpiezas terminadas**.

Para un diagnóstico nuevo autorizado: confirmar plan, SHA, recursos y exclusión mutua; usar una rama aislada comprobada y el workflow manual `refactoring-verification.yml` con `level=capacity-targeted`. El ejecutor exige CI con recursos suficientes, compila y reconstruye servicios descartables, usa un consultorio propio y prueba dos rechazos del limpiador antes de retirarlo. No usar este modo en producción ni ejecutarlo localmente en esta máquina. Guardar la respuesta al dispatch y recuperar su único run antes de considerar otro intento. Recuperar la evidencia con `scripts/collect-verification-evidence.py` y contrastar resumen, perfiles, persistencia, integridad, limpieza y diagnóstico de plataforma; el éxito del job por sí solo no basta.

Pruebas livianas secuenciales de los mecanismos nuevos:

```bash
node --test --test-concurrency=1 scripts/lib/cpu-profile.test.mjs scripts/lib/targeted-performance.test.mjs
```

No se desplegó la aplicación ni se modificó el esquema: no corresponde ejecutar una reversión productiva por este trabajo. Para retirar la herramienta, preparar un commit que restaure los archivos operativos previos desde bc307f5, elimine sólo los dos helpers nuevos, conserve evidencias/documentación y pase fast antes de promoverlo. No restaurar el árbol del usuario ni una base completa. La publicación de estos cambios operativos no habilita despliegues automáticos.
