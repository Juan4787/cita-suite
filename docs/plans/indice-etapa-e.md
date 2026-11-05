# Documentación de la fase E

**Estado al 5 de noviembre de 2026: en implementación y verificación; todavía sin publicar.** Este índice permite revisar el trabajo y encontrar su detalle. No acredita el cierre de E ni sustituye las fuentes enlazadas. El estado exacto de producción y las diferencias de código se mantienen únicamente en el [estado vigente](../ESTADO-VIGENTE.md).

Juan pidió entregar, al terminar E, la ubicación exacta y enlaces directos desde la interfaz a toda la documentación detallada. Este índice se conserva durante el trabajo y se actualizará para la entrega final. P1, P2 y P3 continúan pospuestas.

## Por dónde empezar

| Para revisar | Documento y contenido |
|---|---|
| Qué se acordó y qué instrucciones prevalecen | [Plan aprobado, sección 12](propuesta-senas-avisos-natalia.md#12-aprobación-y-ajustes-posteriores). Conserva las decisiones originales y los ajustes posteriores, incluidos Zoho, identidad del consultorio, valores iniciales, coherencia contextual, autorización y condiciones informadas. |
| Qué debe hacer el producto | [Especificación de E](etapa-e-correo-autogestion.md). Alcance, reglas transaccionales y 97 casos EM/AC/RP/SN/RM/ZH/UI/OP. La matriz es requisito; sus filas no equivalen a pruebas aprobadas. |
| Qué se implementó y cómo se comprobó | [Registro activo de ejecución](ejecucion-etapa-e-20261103.md). Cambios, garantías, decisiones, fallas, causas, correcciones, revisiones, corridas y rutas de evidencia. Su matriz distingue aceptación parcial de pendiente. |
| Dónde continuar | [Checkpoint del registro](ejecucion-etapa-e-20261103.md#checkpoint-y-siguiente-acción), [traspaso](traspaso-senas-avisos-natalia.md#etapa-e-punto) y [pendientes vigentes](pendientes-vigentes.md#etapa-e-pendientes). |
| Qué está publicado realmente | [Estado vigente](../ESTADO-VIGENTE.md). Revisión y versión efectivas de producción, rama e inventario exacto del código que todavía difiere. |

## Detalle por parte de la implementación

Los siguientes documentos describen los contratos de las áreas afectadas. Sus apartados de E se leen junto con la evidencia y los límites del registro activo: describir un contrato no demuestra que todas sus integraciones estén terminadas.

| Parte | Dónde está explicado |
|---|---|
| Agenda, cancelación, movimiento autónomo y recuperación de operaciones | [Contratos funcionales](../architecture/functional-contracts.md), [disponibilidad y aranceles](../architecture/disponibilidad-y-aranceles.md), [registro E](ejecucion-etapa-e-20261103.md). |
| Señas, pagos registrados, crédito, pérdida y proyección vigente | [Especificación, reglas y casos SN](etapa-e-correo-autogestion.md#44-señas-y-dinero), [contratos funcionales](../architecture/functional-contracts.md) y registro E. El sistema registra hechos; no integra cobro bancario ni una contabilidad general. |
| Dinero recibido después de cancelar (SN14) | [Garantías y diseño](ejecucion-etapa-e-20261103.md#e335--garantías-de-sn14-antes-de-implementar), [detalle y límites de prueba](ejecucion-etapa-e-20261103.md#e339--detalle-conectado-segunda-corrida-sql-detenida-en-sintaxis-del-arnés). Registra hechos/correcciones sin reactivar ni prometer devoluciones; aceptación integral pendiente. |
| Identidad del paciente, cambio de contacto y revocación de enlaces | [Contratos funcionales](../architecture/functional-contracts.md), [permisos y capacidades](../architecture/permisos-y-capacidades.md), [tipado y aislamiento](../architecture/tipado-contexto-aislamiento.md). |
| Formularios públicos, email obligatorio y excepción de recepción | [Especificación, alcance](etapa-e-correo-autogestion.md#1-alcance-y-decisiones-del-usuario), [contratos funcionales](../architecture/functional-contracts.md), checkpoints E3 del registro. |
| Condiciones económicas informadas al reservar | [Plan 12.29 y 12.30](propuesta-senas-avisos-natalia.md#1229-condiciones-informadas-en-la-nueva-reserva-pública-5-de-noviembre), checkpoints E3.11–E3.21 del registro. Diferencia la confirmación pública y la declaración expresa del personal; no aplica penalidades por inferencia. |
| Documentos clínicos, acceso y cuotas | [Contabilidad de documentos](../architecture/contabilidad-documentos.md), [contratos funcionales](../architecture/functional-contracts.md), evidencia y límites de enlaces de almacenamiento en el registro E. |
| Calendario, notificaciones del paciente y tareas | [Tareas automáticas](../architecture/tareas-automaticas.md), [contratos funcionales](../architecture/functional-contracts.md) y registro E. Push/ICS conservan sus tiempos propios; no se confunden con email 72/24 h. |
| Configuración de correo y botones según contexto | [Especificación](etapa-e-correo-autogestion.md), [permisos y capacidades](../architecture/permisos-y-capacidades.md), [contratos funcionales](../architecture/functional-contracts.md). El comprobante de cancelación no ofrece cancelar ni reprogramar. |
| Zoho: conexión persistente, administración y secretos | [Guía de Zoho por terminal](../architecture/zoho-cpaas-terminal.md). Comandos, custodia, renovación, respuestas reales observadas y límites. No contiene credenciales. El acceso administrativo comprobado no acredita integración de envío publicada. |
| Aspecto y criterios de interfaz | [Diseño de la app](../../apps/web/DESIGN.md), [superficie de gestión del turno](../../apps/web/.impeccable/surfaces/gestion-del-turno.md), capturas y corridas del registro E. No inicia P2 global. |

## Pruebas, evidencia y límites

El [registro activo](ejecucion-etapa-e-20261103.md) conserva para cada corrida su revisión, resultado y alcance. Incluye fallas, no sólo resultados aprobados. Las evidencias privadas se conservan bajo `.verification/etapa-e-20261103/`; cada colección recuperada tiene su huella. No se publican secretos, cuerpos privados de correo ni respuestas completas del proveedor.

| Capa | Qué permite afirmar y qué no |
|---|---|
| Pruebas de funciones y componentes | Ejercitan sus contratos con los colaboradores indicados; los dobles de prueba no prueban entrega externa ni contención real de PostgreSQL. |
| SQL y carreras en base descartable | Verifican permisos, estados persistidos, fallas parciales, reintentos y esperas reales observadas. No prueban por sí solas la interfaz ni el correo. |
| Navegador con servicios de prueba | Verifica el recorrido, respuestas y persistencia del entorno de esa corrida. Las capturas tienen revisión, ancho y tema concretos. No equivalen a publicación productiva. |
| API de Zoho | La aceptación por API es distinta de entrega al servidor receptor. Ninguna demuestra recepción en la bandeja del usuario. |
| Buzón acordado | La lectura de un mensaje real acredita la recepción de ese mensaje. Abrir el enlace y verificar la base corresponde a otra comprobación integral. |
| Producción | Sólo se acredita con la revisión desplegada y comprobaciones registradas de ese destino. Un commit subido a GitHub no es prueba de publicación. |

Procedimientos compartidos: [verificación](../architecture/verificacion.md), [matriz de regresiones](../architecture/matriz-regresiones.md), [áreas y fronteras](../architecture/areas-y-fronteras.md), [control de consumo](../architecture/control-de-consumo.md).

## Publicación, recuperación y asuntos todavía abiertos

La entrega final debe enlazar la revisión exacta, migraciones aplicadas, configuración e interruptores, pruebas del destino, integración real de correo y recuperación compatible. Se documenta en [publicación y reversión](../architecture/publicacion-y-reversion.md), [respaldo y recuperación](../architecture/respaldo-y-recuperacion.md), estado vigente y registro E. **La publicación de E todavía está pendiente; las instrucciones históricas de volver a una aplicación anterior no son una recuperación compatible con E demostrada.**

Los pendientes de implementación y verificación se mantienen en el checkpoint/matriz del registro y en la lista única de pendientes. No se ocultan en una conclusión de auditoría ni se presentan pruebas parciales como garantías integrales. Los datos comerciales faltantes de Natalia conservan su tratamiento separado y no se inventan para completar una prueba.

Las [tres tareas posteriores](tareas-posteriores-a-e-20261103.md) conservan sus alcances y orden, pero están **pospuestas por Juan**. No se ejecutan al terminar E. El [registro histórico de señas y avisos](registro-senas-avisos-natalia.md) conserva A/B/C y las decisiones previas; las pausas o proveedores anteriores sustituidos no gobiernan la ejecución actual.
