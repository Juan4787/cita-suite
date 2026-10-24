# Auditoría final punto por punto

Contraste del [plan aprobado](../plans/refactorizacion-cita-suite.md) con la evidencia, como exige su instrucción de ejecución: «antes de declarar terminada la campaña, verificá punto por punto el cumplimiento del documento original utilizando evidencia comprobable». Las corridas y su detalle están en el [registro](../plans/registro-refactorizacion-cita-suite.md).

**Estado al 24 de octubre,13:27 UTC: campaña abierta, lanzamiento no aprobado.** Producción sirve `0851de59ed7971debe2514e6d6851d142bbc5766` (versión70f0cdc0). Release40096001763 aprobó20/20 controles y44/44 casos en cada uno de tres perfiles. Recuperación compatible83278ad/2b9609ae instalada y comprobada, con retorno nativo a70f0cdc0. Hashes130cliente/35Natalia,70relaciones sin exposición,33bindings, agenda autenticada y conteos iguales. DB126 y secretos preservados; programador94bed118 restaurado con cinco cron. Respaldo fresco126 verificado; no se afirma restauración de ese dump exacto.

Calendar completó actualización porcron246.403ms, lectura y borrado externo en Google. Samsung recibió/mostró tres avisos, clic y confirmación persistidos. El nuevo defecto de activación sobre turnos inactivos falló en3pruebas rojas y en el Samsung antes del arreglo;175cliente/1395servidor aprobaron después. En candidata, recuperación y retorno productivos:0peticiones inactivas y0errores. Natalia está publicada desdeGit y su último recorridoSamsungv3 aprobó reserva persistida, recuperación sin duplicación, comprobante anterior y cancelaciónUI+DB,0consola.

Todos los fixtures propios de capacidad, humo, proveedores y las dos reservas de Natalia se limpiaron, preservando datos ajenos y el vínculo históricoCalendar1/1. Los errores de arnés y limpieza se conservan fallidos, con causa y corrección; no se reescriben como verdes. Sólo la pestaña y el forward propios del Samsung se cerraron. La carpeta física ya es `Cita Suite` con enlace compatible desde la anterior; repositorio principal aún pendiente de promoción/renombre.

**Capacidad2 sigue fallida:**40078561771, rep2 lecturas1024/3809ms y rep3 escrituras2763/3810ms (p95/p99);0errores técnicos y0violaciones de integridad. Pública y abuso aprobaron. CorrelaciónI/O/swap sincausalidad exclusiva; no se descarta efecto del observador/red y no hubo cortesCPU en esa carga. El nuevo arreglo de interfaz no se presenta como corrección de los percentiles. [Capacidad](capacidad.md) conserva números y límites. Informes corregidos: desconocidos/reset sonnull e identificadoresSQL exactos;3deltas ambiguos excluidos.

La [continuación](../plans/traspaso-refactorizacion-cita-suite.md) conserva revisiones, rutas y operaciones exactas. Evidencia versionada en [fase1](../archive/production-verification-20261024/phase1/README.md) y [fase2](../archive/production-verification-20261024/phase2/README.md); [fase3](../archive/production-verification-20261024/phase3/README.md) registra publicación, recuperación y limpiezas posteriores. Dominio, SMTP y etiquetasSupabase siguen pendientes por sus dependencias explícitas; ninguna contratación ni pregunta intermedia.

Estados:
- **Cumplido:** con su evidencia.
- **Pendiente:** trabajo que sigue, con su puerta.
- **Decisión del usuario:** requiere gasto o un compromiso suyo.
- **Impedimento:** límite demostrado del proveedor, informado con alternativas.
- **Postergado:** con su riesgo documentado.

## 1. Decisiones fijadas

| Requisito | Evidencia | Estado |
|---|---|---|
| Seis áreas con subdivisiones útiles | [áreas y fronteras](areas-y-fronteras.md); reglas de `dependency-cruiser` en `verify:fast` | Cumplido |
| Calculador TS común y lecturas SQL acotadas | [disponibilidad y aranceles](disponibilidad-y-aranceles.md), [evidencia de etapa 4](evidencia-etapa4-agenda.md) | Cumplido |
| SQL confirma el importe, TS previsualiza, paridad comprobada | Vectores comunes y pruebas de paridad (etapa 4) | Cumplido |
| Presupuesto global de 700 MB y cuota base de 100 MB | [contabilidad de documentos](contabilidad-documentos.md), [evidencia de etapa 3](evidencia-etapa3-documentos.md) | Cumplido |
| Cuotas como máximos, no espacio reservado | Ídem | Cumplido |
| Programación nativa de Cloudflare con presupuestos medidos | [tareas automáticas](tareas-automaticas.md); staging con los cinco cron | Cumplido funcionalmente en staging y ciclo productivo, recuperación y cinco tipos decron comprobados. AptitudFree no aprobada; comercial manual se distingue del cron no observado. |
| Push y calendario cada cinco minutos, inicio dentro de diez | Etapa 6: escenario del plan y entrega real por FCM a un Samsung | Cumplido funcionalmente en staging y ciclo productivo, recuperación y cinco tipos decron comprobados. AptitudFree no aprobada; comercial manual se distingue del cron no observado. |
| Pruebas pesadas en CI descartable, sin cargar la computadora | [verificación](verificacion.md) | Cumplido |
| Natalia navega al turnero real | Release 39901784288: dos recorridos por perfil de CI y dos en staging alojado, con persistencia, recuperación y cancelación. Previews de archivos Vercel aprobados; producción requiere recorrido propio. | Cumplido en CI/staging; producción y Samsungv3 aprobados tras corrección de avisos inactivos; los recibos previos fallidos se conservan. |
| Cursos y noticias fuera; sin WhatsApp | Medición de Natalia; secciones intactas en `check-public.mjs` | Cumplido |

## 2. Arquitectura y contratos

| Requisito | Evidencia | Estado |
|---|---|---|
| Importaciones sólo entre interfaces públicas, sin ciclos ni código de servidor en el navegador | `dependency-cruiser` fijado, sin excepciones permanentes | Cumplido |
| Propiedad de las reglas | [contratos funcionales](functional-contracts.md) | Cumplido |
| Fábricas Supabase y consumidores tipados; tipos reproducibles | Doble generación con igualdad exacta en cada full; guarda `type-escapes` | Cumplido |
| JSON validados en ejecución | Contratos `readRecord` y `InvalidDataContractError`; objeto/null Calendar reproducido en rojo, corregido y probado en release40075434652 y lote productivo07:21UTC. | Cumplido para los contratos y caso corregido; no garantiza ausencia universal de defectos. |
| Contexto común sin caché global de permisos | [tipado, contexto y aislamiento](tipado-contexto-aislamiento.md) | Cumplido |
| Cuatro cuestiones de capacidades | [permisos y capacidades](permisos-y-capacidades.md) | Cumplido |
| Rutas públicas y enlaces de gestión conservados; RPC con transición explícita | Reserva nativa con recuperación y comprobante anterior compatible | Cumplido |
| `/odonto` histórica; el módulo administrativo inactivo no se activa | [identidad](identidad-cita-suite.md); archivo en `docs/archive/administrativo-inactivo` | Cumplido |

## 3. Etapas

| Etapa | Cierre exigido | Evidencia | Estado |
|---|---|---|---|
| 0 | Base identificada, cambios preservados y alcance trazable | [base de campaña](base-de-campana.md) | Cumplido |
| 1 | Los comandos detectan una falla deliberada y no informan éxito si omiten una suite | Registro, etapa 1: pruebas adversarias del ejecutor | Cumplido |
| 2 | Clientes tipados, JSON comprobados, contexto común, negativas entre consultorios y tras revocar | Suites `tenant_*`; [matriz de regresiones](matriz-regresiones.md), puntos 1 y 2 | Cumplido |
| 3 | Carreras, expiración, repetición, reconciliación, descarga correcta y ampliación de cuotas | [Evidencia de etapa 3](evidencia-etapa3-documentos.md); el ensayo de ampliación también sobre el paquete del release | Cumplido |
| 4 | Equivalencia pública e interna, paridad, reservas simultáneas, reprogramación, excepciones, márgenes, cambios de política y respuestas perdidas | [Evidencia de etapa 4](evidencia-etapa4-agenda.md) | Cumplido |
| 5 | Equivalencia funcional y visual, capturas y recorridos | [Evidencia de etapa 5](evidencia-etapa5-estructura.md); full 39276578152; dictamen independiente `ship` | Cumplido |
| 6 | Recuperación y trabajo ordinario dentro de diez minutos | [Tareas automáticas](tareas-automaticas.md); fulls 39364962358 y 39366010644; recuperación en staging | Cumplido funcionalmente en staging y ciclo productivo, recuperación y cinco tipos decron comprobados. AptitudFree no aprobada; comercial manual se distingue del cron no observado. |

## 4. Capacidad, regresiones y observabilidad

| Requisito | Evidencia | Estado |
|---|---|---|
| Escenarios de 5 y 25 consultorios en CI | [capacidad](capacidad.md) | Evidencia conservada. Ya no es condición de cierre (decisión del 20 de octubre). |
| Dos consultorios en el despliegue gratuito: lecturas p95 < 1 s y p99 < 2 s | Producción40078561771: rep2 p95/p99 1024/3809ms; otras dos cumplen. Staging histórico conservado. | **Impedimento medido.** Producción falla; correlaciónI/O/swap sincausalidad exclusiva. No rebajar umbrales ni contratar. |
| Escrituras p95 < 1,5 s y p99 < 3 s | Producción40078561771: rep3 p95/p99 2763/3810ms; otras dos cumplen. | **Impedimento medido:** rep3 supera ambos umbrales; atribución no exclusiva. |
| Errores técnicos < 1 % | Ídem: 4 errores de red, ninguno de la aplicación. Sobre el total de cada fase, debajo del 1 % (0,48 %, 0 %, 0,48 % y 0,64 %). | Cumplido en staging |
| Sin violaciones de aislamiento, doble reserva ni cuotas | Integridad antes y después de cada carga: 0 cruces y 0 superposiciones | Cumplido |
| Disponibilidad completa o error explícito | Contratos de la etapa 4 y auditoría transversal (`r2`, `R7`, `r11`) | Cumplido |
| Colas: cinco pendientes por consultorio y escenario desigual | Etapa 6 en staging | Cumplido |
| Planes, índices, bloqueos y crecimiento de consultas | [capacidad](capacidad.md); correcciones `20261020020000` a `20261020050000` | Cumplido |
| Matriz de regresiones | [matriz de regresiones](matriz-regresiones.md): 12 puntos con sus capas | Cumplido |
| Observabilidad: viajes HTTP, proveedores y SQL separados; registros sin datos clínicos | Contadores de trabajos (`databaseRequests`, `providerRequests`); colector corregido con8 pruebas adversarias/funcionales. Los borradores previos y sus fallos se conservan; observador productivo usa el filtro permanente probado. | Filtro comprobado y cron productivo observado; ausencia de acceso a logs históricos se registra como límite, no como ausencia de ejecución. |

## 5. Auditoría, publicación y documentación

| Requisito | Evidencia | Estado |
|---|---|---|
| Rutas alternativas, tipos, duplicación, paginación, consultorio nuevo | Auditoría transversal cerrada: full 39667993859 | Cumplido |
| Recorridos cruzados sensibles sobre los artefactos construidos | Release40096001763:44/44 en desarrollo, candidata0851 y baseline reparado832 sobre126migraciones, cero omisiones, reintentos o intermitentes. Incluye privacidad, fecha clínica y transporte autenticado; los fallos previos se conservan. | Cumplido en CI |
| Ampliación de cuota y cambio de recursos conservando datos, permisos y pendientes | `clinical-files.spec.ts` aprobado en los tres perfiles del release 39901784288. Cambiar a Workers Paid no se ensayó alojado sin contratar; sus presupuestos tienen pruebas, sin certificar capacidad de un proveedor no contratado. | Cumplido para cuotas y perfiles; no hubo contratación |
| Respaldo y recuperación ensayados en un entorno aislado | 39859035283 (`48b1c20`): 126/126 migraciones, 96 tablas/76 filas sin diferencias, archivo con huella idéntica y bucket único retirado. 39682517594 conserva por separado el volumen de 83.335 filas/117 migraciones. [Respaldo y recuperación](respaldo-y-recuperacion.md). | Cumplido en pila aislada de CI; no es un proyecto alojado nuevo |
| Migraciones compatibles en staging |126 en ambos entornos; producción contrajo a126 a24-oct03:40:02UTC, con respaldo/preflight y humo14/14. | Cumplido en staging y producción |
| App, Natalia y programador desplegados y comprobados en staging | Release 39901784288: app478 versión `6bde847f-008c-4f9d-ab3b-8fc7b51d61dd`,130 archivos cliente/35Natalia exactos,61 relaciones sin exposición anónima y dos reservas nativas. Programador `49636b6a…` y cron observados previamente; humo y limpieza conservados sin cambios posteriores de runtime/SQL. | Cumplido en staging |
| Auditoría de release |40096001763 aprobado20/20, fuente0851, artefacto40095722950 y reversión40095847239. | Cumplido; no sustituye capacidad ni auditoría de producción |
| Programador anterior detenido | cron-job.org 7795525, deshabilitado; Netlify 404 y Vercel 503 (`check-previous-scheduler.mjs`, 22 de octubre, 12:43 UTC) | Cumplido; se repite en el paso 0 |
| Publicar migraciones y aplicaciones; activar el programador nuevo; versión, permisos, reserva, almacenamiento y tareas | [Publicación y reversión](publicacion-y-reversion.md),14pasos. DB126, appCB, humo14/14, catálogo9secciones, API70/0expuestas y ciclo Calendar/push reales documentados. | En ejecución: recuperación/carga/limpieza/Natalia realizadas con sus límites; carga fallida, defecto push corregido y verificado en producción; identidad principal pendiente. Cinco tipos posteriores observados200; desconexiones acreditadas. |
| Reversión sin restauraciones destructivas | Baseline dfb restaurado por rollback nativo en staging y reservas aprobadas en 39896937395; suite completa44/44 contra126 migraciones en 39901784288. Natalia:35/35 archivos anteriores exactos en preview de reversión, seleccionando el output archivado. | Cumplido en CI/staging/previews y producción: baseline reparado5ee/c0692ad0 y vuelta nativa aCB/F35 comprobados08:33:34UTC, sin restaurarDB ni alterar secretos. |
| Documentación entregable | Áreas, contratos, [permisos y capacidades](permisos-y-capacidades.md), documentos, tareas, verificación, capacidad, [decisiones](decisiones.md), publicación y [guía](guia-nuevas-funciones.md) | Cumplido |

## Base de producción

| Requisito | Evidencia | Estado |
|---|---|---|
| Migraciones exactas y compatibles antes de publicar | Ensayo con `ROLLBACK` sobre el esquema real: 8 sentencias fallaban por deriva manual. Con la reconciliación, cero fallas. | Cumplido como preparación |
| La base publicada es la probada | Comparación del catálogo después del ensayo: idéntico al de staging en las nueve secciones, salvo la deriva aceptada | Cumplido como preparación; se repite después de publicar |
| Rutas alternativas que evitan los contratos (sección 5) | `20261022010000` aplicada en producción, catálogo alineado y APIanónima70/0expuestas | Cumplido en CI y producción |
| Sin pérdida de información clínica | El borrado de un usuario borraba su historia clínica: `20261022000000`, con su prueba que falló primero | Aplicado en producción durante la expansión97→125; sin borrado de datos. |
| Reversión compatible | Publicación en dos tandas; `313355a` sólo sirve antes de contraer. Retorno alojado39896937395 y perfil completo44/44 del baseline dfb/126 en39901784288 aprobados. | Ensayo productivo nuevo aprobado con5ee/c0692ad0 sobre126, 33bindings conservados y retorno nativo aCB/F35. Baseline anterior dfb conserva defecto y no es la referencia funcional vigente. |

## Ampliación: identidad Cita Suite

| Requisito | Evidencia | Estado |
|---|---|---|
| Inventario completo, con excepciones clasificadas | [identidad](identidad-cita-suite.md) | Cumplido |
| Código, paquetes y documentación unificados | Workspace `@cita-suite/shared`, raíz `cita-suite` | Cumplido |
| Renombre ensayado en un recurso descartable | [ensayo en GitHub](identidad-ensayo-github.json) | Cumplido |
| Repositorio `Juan4787/cita-suite`, nombres visibles de Supabase y proveedores conectados | Nombre libre (404) y permisos de administración comprobados | Pendiente: va después de publicar, con los disparadores desconectados |
| Directorio local `Cita Suite` | Intercambio atómico13:24:07, mismo inode/FS y enlace compatible; HEAD/índice/plan/permisos preservados | Cumplido |

## Decisión del 20 de octubre: lanzamiento

| Requisito | Estado |
|---|---|
| Ninguna contratación ni cobro variable sin tope | Cumplido: Workers Free y Supabase Free, nada contratado |
| Protecciones de consumo decididas por mérito | Cumplido: [control de consumo](control-de-consumo.md) |
| Defectos propios de eficiencia corregidos y separados de los límites del proveedor | Cumplido: [capacidad](capacidad.md) |
| Dos consultorios cumplen los criterios en el despliegue gratuito antes de publicar para clientes reales | **Impedimento** (p99 de lecturas). Hay que medir producción y decidir el plan. |
| Correo de Auth para restablecer contraseñas | Incompleto confirmado por el usuario: activó el interruptor SMTP pero no configuró datos. Falta proveedor/remitente y entrega real de recuperación. No enviar correo a un destino ajeno. |
| Destino de los respaldos de datos reales | Decisión del usuario |


Antecedente histórico23-oct15:34UTC, reemplazado por el estado24-oct de arriba: la versión de app es a5b21dfd y el baseline658d3ae3 conserva la habilitación actual de Calendar además del secreto interno. Se verificaron en orden metadata/auth/130archivos/70relaciones; no cambió binario ni SQL. Ventana rutinaria y Storage15:17 comprobados; CPUFree y commercial18:17 abiertos. Calendar cron configuredtrue, pero el retorno del cliente dedicado falla redirect_uri_mismatch con control negativo válido. El cliente diferente usado por accesoGoogle sí llega al acceso; falta completar el regreso a app y confirmar URL Configuration actual. Usuario confirmó pruebas históricas de ambos recorridos y eliminación de URLs también en Supabase. Estos hechos no se sustituyen por inferencias desde.env ni por dos redirecciones iniciales correctas.


## Acciones externas pendientes: continuar una por vez

1. **Rendimiento de lanzamiento:** la configuración actual no demostró los umbrales de dos consultorios. La siguiente comparación debe distinguir costo SQL propio, contención de Nano, red e impacto del observador. Un cambio de cómputo requiere decisión explícita, tope de costo compatible y repetir la misma carga; no se contrató ni se promete que pagar resuelva todos los percentiles.
2. **Correo de recuperación:** en Supabase, proyecto `yjzferwuzbtgpmdnzlcb` → Authentication → Emails → SMTP Settings, falta un proveedor y su servidor/puerto/usuario/contraseña/remitente. El interruptor activado no constituye configuración. Guardar allí los valores, nunca en conversación; después probar recepción de recuperación y acceso con la contraseña nueva en una cuenta sintética acordada. No hay proveedor contratado por esta campaña.
3. **Dominio y Google:** el usuario compra el dominio cuando lo decida. Al comunicar el nombre, continuar [la guía](acceso-google-calendar.md#retomar-cuando-el-usuario-comunique-la-compra-del-dominio): propiedadDNS, presentación pública sinlogin, privacidad/términos, marca, retornos compatibles y recorridosAuth/Calendar separados. La compra sola no elimina los avisos de aplicación no verificada.
4. **Etiquetas Supabase:** abrir únicamente los ajustes generales de los proyectos `yjzferwuzbtgpmdnzlcb` y `ikaudqoilclfnztkxubz`; cambiar sólo Project Name a `Cita Suite` y `Cita Suite Staging`, respectivamente. No crear proyectos, cambiar ref/región, rotar claves ni tocar datos. La CLI instalada no tiene rename y no se confirmó una sesión administrativa normal accesible; no se extrajeron tokens de sus almacenes. Los intentosUI fallidos no prueban falta de permisos del usuario.
5. **Custodia de respaldos antes de datos clínicos reales:** ya existen copias locales verificadas. Falta elegir una copia independiente y su retención; no se inventó ni contrató almacenamiento externo.

Estas dependencias no invalidan las pruebas funcionales aprobadas, pero tampoco se convierten en tareas terminadas. El lanzamiento y el cierre íntegro de campaña permanecen sin aprobación.
