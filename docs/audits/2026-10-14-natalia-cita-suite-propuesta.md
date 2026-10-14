# Auditoría de la propuesta de Natalia y Cita Suite

Fecha: 14 de octubre de 2026. Revisión del commit `a480dbbe319e1a5dfc4f34e6d771828831b90b29`.

La propuesta reconoce correctamente varios módulos reutilizables, pero necesita cambios en precios, permisos de archivos, actualización de horarios y criterios de verificación. La presencia de una pantalla o una migración no demuestra que Natalia pueda usar el flujo publicado con sus datos reales.

## Alcance confirmado

- Los aumentos se calculan con porcentajes definidos por el consultorio, sin integración con índices oficiales. El usuario precisó que debe existir un porcentaje mensual recurrente, por ejemplo 2%, y porcentajes específicos para meses concretos. El arancel aplicable se muestra en el turnero inmediatamente después de elegir la fecha.
- Profesional y paciente deben poder cargar PDFs.
- El botón de WhatsApp es un canal de contacto público. No implica implementar notificaciones automáticas por WhatsApp.
- Noticias y cursos quedan postergados; no se modifican en esta etapa.
- Los cursos deberán evolucionar, más adelante, hacia una plataforma completa de cursos en línea al estilo Udemy. Su alcance futuro requiere un diseño propio.
- No se inventan teléfonos, profesionales, prestaciones, preguntas, precios ni datos clínicos. El usuario no proporcionará esos datos ahora.
- Esta entrega es una auditoría y una propuesta de implementación. No cambia el código funcional, la base de producción ni los despliegues.

## Estado comprobado

| Pedido                                                          | Estado actual                                                                                                                                           | Trabajo necesario                                                                                                                |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Actualizar aranceles por porcentaje y advertir el precio futuro | Falta. Las prestaciones guardan `price_label` como texto.                                                                                               | Importes numéricos, vigencias, cálculo por porcentaje, cotización por fecha y constancia del precio mostrado al reservar.        |
| Cargar PDF y descargarlo con nombre y apellido                  | Falta. Cliente, servidor y contratos de almacenamiento aceptan JPG/PNG.                                                                                 | Extender el módulo privado; agregar una vía de carga para pacientes; generar el nombre de descarga.                              |
| Historia médica                                                 | Existe una historia clínica general con consultas, diagnóstico, evolución, indicaciones, fechas y autoría; también alergias, medicación y antecedentes. | Verificar los flujos y ajustar las referencias odontológicas visibles cuando corresponda. No crear una segunda historia clínica. |
| Cuestionarios configurables y datos en la ficha                 | Implementado y probado localmente. Existe editor por profesional, validación, persistencia y registro de cambios.                                       | Configuración real y comprobación integrada con el perfil que se habilite para Natalia.                                          |
| Franjas exclusivas para seguimiento                             | Falta. La disponibilidad no distingue prestaciones permitidas por franja.                                                                               | Restricciones por profesional, fecha o día semanal y prestación, aplicadas en consulta y confirmación.                           |
| Noticias administrables                                         | Postergado. La web muestra artículos estáticos; no encontré un CMS de noticias operativo en Cita Suite.                                                 | Diseño y ejecución futura.                                                                                                       |
| Cursos completos                                                | Postergado. Catálogo y aula de presentación; inscripción, cobros y acceso de alumnos pendientes.                                                        | Plataforma futura independiente de esta etapa.                                                                                   |
| Botón de WhatsApp                                               | Falta en el sitio publicado. No hay número confirmado para activar el enlace.                                                                           | Configuración explícita del canal, enlace accesible y pruebas de navegación.                                                     |
| Descripción opcional en notificaciones                          | Los avisos push actuales tienen texto general de fecha y hora. No hay un campo dedicado a esa descripción.                                              | Texto destinado al paciente, separado de notas internas, con su publicación controlada en avisos y confirmación.                 |
| Bloquear varios días separados                                  | Parcial. Se puede bloquear una fecha o un rango continuo; varios días separados requieren operaciones individuales.                                     | Selección múltiple y guardado conjunto, con motivo y alcance explícito.                                                          |

## Evidencia y sus límites

Se ejecutaron 194 pruebas existentes, en 15 archivos y tres ejecuciones secuenciales: 170 de disponibilidad, reservas, cuestionarios, archivos y push; 21 de acciones y contratos de la ficha; y 3 del componente de reserva pública. Todas pasaron. Son pruebas locales; buena parte de las pruebas de rutas usan sustitutos de sus servicios externos.

Dos reconstrucciones desechables aplicaron las 93 migraciones, con PostgreSQL limitado a 384 MB y una CPU. Se aprobaron los contratos SQL de identidad/reserva atómica, política de reserva pública, turnos conjuntos, integración pública, información previa, archivos clínicos y procedencia clínica. Se reutilizó el ejecutor existente; para los dos contratos clínicos adicionales se preparó una copia temporal cambiando únicamente la ubicación del repositorio y la lista de pruebas. Los contenedores se eliminaron al terminar. El ejecutor simula las tablas de Storage y parte de Auth/Realtime: no demuestra una transferencia real de archivos ni entrega de notificaciones.

La inspección remota fue de solo lectura: la base vinculada tiene las mismas 93 migraciones, sin migraciones locales pendientes. Las seis tablas nuevas de integración e información previa tienen RLS, y se comprobaron los permisos de las siete funciones del módulo. No se consultaron fichas reales de pacientes.

Las lecturas HTTP de producción comprobaron que Natalia responde, no tiene una clave de integración de reserva configurada en el HTML y muestra el aviso de agenda pendiente en `/turnos/`. No hay enlace de WhatsApp. Cita Suite responde y sirve la versión `a480dbbe319e1a5dfc4f34e6d771828831b90b29`. Esto comprueba versión y respuestas públicas, no una reserva real de Natalia.

No se realizó en esta auditoría un nuevo recorrido completo de navegador con sesiones reales ni se enviaron notificaciones. Las prestaciones propuestas que todavía faltan no pueden declararse verificadas de extremo a extremo.

## Correcciones necesarias a la propuesta recibida

1. **No presentar el cuestionario como una mera activación de `.env`.** Hay implementación, migraciones remotas y pruebas de persistencia. En la configuración del Worker los tres indicadores relacionados figuran en `true`; editar un archivo local no prueba su valor efectivo en el servicio publicado. La integración concreta de Natalia sigue pendiente de datos y configuración. No se pueden escribir supuestas preguntas de nutrición de Natalia sin que el consultorio las defina.

2. **Los endpoints de historial y datos no guardan la historia.** Ambos exportan `GET`. Las altas y modificaciones reales están en las acciones de la ficha y utilizan funciones seguras de base de datos. Los tipos de entrada ya son generales; el campo visible `Dientes / zona` es la referencia odontológica que requiere adaptación contextual. Cambiar etiquetas no constituye por sí solo una verificación del guardado.

3. **El PDF no es una ampliación encapsulada del módulo interno.** La propuesta omitía la carga del paciente, que ahora está confirmada. El módulo actual exige sesión y permisos del consultorio. Debe reutilizarse almacenamiento privado y ciclo de estados, pero con una autorización pública distinta y limitada. No se encontró una columna de ancho/alto en el contrato actual: no corresponde planificar una alteración de columnas supuestas.

4. **La carga actual va directamente a Storage.** El endpoint interno prepara la autorización y las rutas; el navegador transfiere el archivo mediante una URL firmada y luego solicita completar la operación. No conviene redirigir el PDF completo a través de SvelteKit. Hay que extender los checks de MIME y ruta `.pdf`, la validación del objeto almacenado, el tratamiento de miniaturas y el panel, además del formulario.

5. **Los horarios se guardan por un camino distinto al que describe el plan.** `replaceProfessionalScheduleBlocks` borra todas las reglas del profesional y luego inserta las nuevas en otra operación. Existe riesgo de quedarse sin reglas si falla la inserción; no se reprodujo un incidente en producción. Modificar solamente `replace_professional_availability_rules` no corrige el camino utilizado por el editor de bloques.

6. **La restricción de seguimiento no termina en el calculador.** Debe cubrir ventanas semanales y fechas concretas, reserva pública, integración de Natalia, agenda interna, turnos conjuntos y reprogramación. Un arreglo de identificadores sin integridad referencial requiere controles adicionales; es preferible una relación explícita de prestaciones permitidas. Tampoco debe elegirse una prestación buscando la palabra “seguimiento” en su nombre.

7. **`next_month_price_amount` no resuelve los precios futuros.** Limita el modelo a un solo mes y no conserva la historia. Comparar el mes del navegador con el mes del turno no determina el arancel: lo determina la fecha de vigencia en la zona horaria del consultorio. El precio actual es compartido por prestación; si se necesitan honorarios distintos por profesional hay que representar ese alcance expresamente.

8. **El nombre de descarga no requiere renombrar el objeto almacenado.** La función local de URLs firmadas ya admite una opción de descarga. El nombre y apellido se toman de la ficha autorizada, conservando los bytes originales y la ruta interna estable. El SDK oficial contempla un nombre de descarga personalizado en `createSignedUrl`. [Referencia de Supabase](https://github.com/supabase/storage-js/blob/main/src/packages/StorageFileApi.ts).

9. **La descripción de notificación necesita un campo propio.** No debe tomarse de las notas internas ni de antecedentes o diagnósticos. Puede existir un texto breve expresamente destinado al aviso público y unas indicaciones más completas en la página protegida del turno. El botón de contacto de WhatsApp no autoriza el flujo de confirmación por WhatsApp de cursos que sugiere el documento.

10. **Noticias y cursos quedan fuera del trabajo actual.** Para el diseño futuro, una noticia nueva no aparece automáticamente al guardar su registro si la ruta Astro se genera con `getStaticPaths` durante la compilación. Habrá que elegir recompilación al publicar o renderizado bajo demanda con caché. Un respaldo a los artículos de la demo puede volver a mostrar contenido retirado y no debe utilizarse para ocultar fallos de publicación. [Referencia de Astro](https://docs.astro.build/en/guides/on-demand-rendering/). Convertir los cursos en una plataforma completa supera ampliamente sustituir un modal por un enlace de inscripción.

## Orden propuesto de implementación actual

Las fases siguientes son incrementales. Cada cambio conserva el motor de Cita Suite y su contrato público; Natalia mantiene Astro, Tailwind y TypeScript. Las migraciones se separan por capacidad y riesgo para poder verificar y recuperar cada entrega. No se agrupan precios, horarios y notificaciones solo para regenerar los tipos una vez.

### 1. Cerrar la verificación de cuestionarios

Reutilizar el editor por profesional en Configuración → Reserva online. Mantener preguntas de texto, texto largo, opciones y sí/no, con obligatoriedad y límites; usar los mapeos existentes para obra social, plan, edad/fecha de nacimiento, medicación, antecedentes, alergias y otros datos. Los ejemplos de prueba siguen siendo sintéticos.

Comprobar el recorrido completo desde selección de profesional hasta creación del turno, ficha e historial de información previa. También el envío posterior desde el enlace de la reserva. Mantener las versiones del formulario, las respuestas históricas, la distinción entre datos declarados por paciente y registros profesionales, y el tratamiento de formularios de equipos.

**Aceptación:** un dato obligatorio no puede omitirse enviando la petición manualmente; se conserva una sola reserva y respuesta al reintentar; los campos omitidos no borran información previa; un profesional ajeno o recepción no pueden leer datos clínicos; un cambio concurrente del formulario produce una instrucción comprensible para actualizarlo.

### 2. Cerrar la verificación de historia clínica y adaptar su presentación

Mantener ficha y entradas existentes. Comprobar creación, lectura posterior, edición permitida, bloqueo de edición, autoría, fechas y aislamiento de profesional/consultorio. La historia de respuestas del paciente complementa la evolución clínica y conserva su procedencia.

Para el contexto médico general, adaptar `Dientes / zona` y títulos de radiografías a referencias apropiadas, preservando el contexto odontológico de otros usuarios. No asumir que todo el consultorio es de nutrición ni alterar registros antiguos.

**Aceptación:** una consulta guardada aparece al recargar y conserva autoría; la ficha muestra alergias, medicación y antecedentes; las restricciones de edición siguen vigentes; Natalia y Yari no ganan acceso a información ajena por compartir agenda.

### 3. Aranceles por fecha con porcentaje mensual recurrente y excepciones

Introducir tarifas con importe calculable, moneda, prestación, alcance profesional cuando corresponda y fecha de vigencia. Conservar el texto de presentación por compatibilidad. Los valores de texto existentes que no tienen importe confirmado quedan sin convertir; no extraer precios de la maqueta ni interpretar “a convenir” como cero.

El usuario confirmó el ajuste mensual recurrente como opción: el consultorio puede fijar, por ejemplo, un 2% para todos los meses y revisar esa decisión posteriormente. No depende de la publicación del IPC. La configuración identifica prestaciones/profesionales afectados, importe y mes de referencia, primer mes de ajuste, porcentaje mensual predeterminado y modificaciones de meses concretos. El panel presenta una vista previa de los aranceles resultantes antes de guardar.

Propuesta de semántica: acumular los porcentajes mensuales con precisión exacta, sin reutilizar un importe previamente redondeado. Guardar el arancel de referencia y las cotizaciones en pesos enteros; redondear sólo el valor final de cada fecha, al peso o al múltiplo entero configurado, con mitades hacia arriba. Un porcentaje específico para un mes sustituye el predeterminado de ese mes; no se suma a él. Un 0% explícito congela ese mes, mientras que un mes sin excepción conserva el porcentaje recurrente. Cambiar únicamente un mes y cambiar el porcentaje predeterminado desde un mes en adelante son acciones distintas. Las excepciones posteriores no se eliminan silenciosamente al cambiar el predeterminado.

Ejemplo sintético, sin establecer un arancel real de Natalia: base de $20.000 en octubre de 2026; noviembre al 2% resulta $20.400; diciembre al 2% resulta $20.808; enero de 2027 con excepción del 1% resulta $21.016; febrero con excepción del 0% conserva $21.016. Los porcentajes se acumulan sobre la serie precisa, conservando internamente la fracción aunque una cotización se muestre como peso entero. No se encadena el importe que ya se redondeó para mostrarlo. La política de redondeo se mantiene explícita; si el consultorio configura un redondeo a pesos o a múltiplos, la vista previa debe reflejarlo.

Guardar políticas versionadas y excepciones mensuales, con vigencia explícita de cada modificación, operación atómica y prevención de aplicaciones duplicadas. No hace falta un cron que incremente repetidamente el precio textual de la prestación ni generar tarifas de todos los meses futuros sin límite. Resolver la cotización en servidor para la fecha consultada, dentro del horizonte real de reservas, y conservar el resultado en la reserva. Volver a consultar una fecha no vuelve a aplicar el porcentaje al importe ya calculado.

El recorrido principal es el turnero: elegir prestación con su arancel vigente, elegir profesional cuando corresponda y elegir fecha. Inmediatamente después de elegir el día, antes de confirmar y sin esperar a seleccionar una hora, mostrar la cotización para esa fecha. Si difiere del arancel inicial, informar el importe actualizado y que incorpora los ajustes mensuales configurados. Repetir el importe en el resumen de confirmación. Resolver los meses por el calendario y zona horaria del consultorio, sin prorratear por cantidad de días o por meses transcurridos desde el navegador. Cambiar servicio, profesional o fecha recalcula la cotización; mientras está pendiente no se confirma con el importe anterior. Sin ajuste configurado no inventar un precio futuro.

Guardar en la reserva el importe, moneda y versión de tarifa mostrados. Si la tarifa cambia entre consulta y confirmación, volver a mostrar el precio antes de aceptar. No modificar retroactivamente turnos ni importes clínicos. La política para reservas existentes y reprogramaciones debe quedar explícita; mientras no se defina, preservar lo confirmado y evitar recálculos silenciosos. En turnos conjuntos no sumar honorarios por suposición.

**Aceptación:** probar porcentaje recurrente, excepción de un mes, 0% explícito, retorno al porcentaje predeterminado, modificación del predeterminado desde un mes y conservación de excepciones posteriores. Cubrir meses omitidos, cambios de año, redondeo, cambio de profesional, fecha y prestación, reintentos del guardado, consultas repetidas sin aplicar aumentos dos veces, concurrencia con una reserva y reprogramación. La cotización aparece tras elegir la fecha y coincide con el importe guardado. Un mes actual sin ajuste mantiene el arancel de referencia. Ninguna tarifa de otro consultorio entra en el cálculo.

### 4. Bloqueos de fechas separadas

Ampliar el editor existente con selección de varias fechas, motivo y alcance: profesional actual, profesionales elegidos o consultorio completo de manera explícita. Conservar bloqueo de una fecha y rango continuo. Cada día completo se calcula de medianoche local a la medianoche siguiente.

Validar todos los elementos y guardar el lote en una transacción; deduplicar fechas y controlar reintentos. Antes de aplicar, mostrar qué fechas contienen turnos existentes. Bloquear disponibilidad no cancela esos turnos: deben seguir visibles y poder gestionarse por su flujo habitual.

**Aceptación:** seleccionar tres fechas no contiguas bloquea únicamente esas fechas; una fecha inválida no deja un lote parcialmente guardado; repetir una operación no duplica bloqueos; no cambia la agenda de profesionales fuera del alcance seleccionado.

### 5. Franjas reservadas para seguimiento

Primero sustituir el borrado e inserción separados del editor de bloques por un guardado transaccional del conjunto completo, con control de versión. Una validación fallida conserva los horarios anteriores.

Representar las restricciones como ventanas por profesional y día semanal o fecha concreta, relacionadas con las prestaciones permitidas mediante claves del mismo consultorio. La disponibilidad base indica cuándo se trabaja; la restricción indica qué prestaciones pueden ocupar una ventana. Esa separación permite reservar una parte de una jornada y evita que otra regla general vuelva a abrirla para primera consulta.

La interfaz mantiene un único panel de horarios. Cada franja permite elegir todas las prestaciones habilitadas o una selección explícita; los cambios de una fecha concreta se aplican desde ese mismo panel. La separación de datos no obliga al profesional a trabajar con dos grillas. Un martes puede tener una franja de 14 a 17 general y otra de 17 a 19 exclusiva para seguimiento.

La revisión posterior encontró que el editor actual quita un día de otros bloques al asignarlo a uno nuevo, y que `validateScheduleBlocks` prohíbe repetirlo. Para esa interfaz hay que permitir varias franjas no superpuestas del mismo día, conservar sus prestaciones al reconstruir y serializar los bloques y revisar esa validación. Agregar solo un selector de prestaciones no alcanza.

Aplicar las restricciones al intervalo completo que ocupa el turno, incluyendo buffers y profesionales participantes. El servidor vuelve a comprobarlas al confirmar y reprogramar. Actualizar también el snapshot SQL de disponibilidad y la revisión de agenda cuando cambian las restricciones; limitarse a TypeScript dejaría la integración incompleta.

No establecer una nueva condición de elegibilidad clínica del paciente por suposición. Seleccionar una prestación de seguimiento y exigir una consulta previa son decisiones diferentes.

**Aceptación:** seguimiento puede ocupar la ventana y primera consulta no; la misma prohibición vale al modificar la petición, reprogramar y crear desde agenda interna; otra disponibilidad superpuesta no elimina la exclusividad; si se elimina la última prestación permitida, la ventana no se transforma silenciosamente en “todas”.

### 6. PDFs profesionales y de pacientes

Antes de habilitar las cargas nuevas, aplicar los límites y la reserva de espacio de la condición adicional sobre Supabase Free. La protección de volumen es un requisito de esta fase, no un control que se añade después de publicar. Conservar los archivos existentes aunque superen un nuevo tope de carga; no eliminarlos ni invalidarlos retroactivamente.

Extender el módulo de archivos existentes, conservando bucket privado, estados de carga, integridad, cuotas, papelera y permisos actuales. Agregar PDF a los contratos de MIME y rutas y ramificar el tratamiento del archivo: un PDF no pasa por el canvas ni requiere una miniatura de imagen. La lista de estudios/documentos distingue formato, fecha, descripción, origen y estado de carga.

Para el profesional, reutilizar sesión, vínculo clínico y permisos. Para el paciente, crear una autorización limitada a una reserva válida y al destino derivado por el servidor. Un nombre y teléfono no prueban identidad; el enlace de reserva es una capacidad de acceso a esa reserva, no una autorización a toda la ficha. El paciente no envía un identificador arbitrario de ficha y no puede enumerar historias, archivos anteriores ni documentos de otros pacientes. Registrar que el archivo fue aportado por el paciente.

El navegador carga directamente el objeto autorizado en Storage. La finalización verifica el objeto realmente almacenado mediante metadatos y lecturas parciales limitadas. Reutilizar `storage.info(path)` para comprobar tamaño y MIME. Leer la cabecera y el tramo final con peticiones Range, límites de bytes y tiempo, sin cargar ni parsear todo el PDF en el Worker. Comprobar respuestas parciales y Content-Range; si Storage ignora Range no descargar el objeto completo para recuperar la cola. Aceptar respuestas completas únicamente si el objeto entero cabe en el límite comprobado. Admitir las versiones PDF soportadas, incluyendo PDF 2.0.

Estas comprobaciones son validación básica de formato y consistencia de metadatos, no validación estructural, revisión de contenido ni garantía de ausencia de truncamiento. `%PDF-` y `%%EOF` pueden estar presentes en un archivo cuyo árbol de páginas no se puede leer. En una prueba sintética de esta revisión, un archivo de 103 bytes cumplió ambos marcadores y `pdf-lib` no pudo recorrer sus páginas. Esa prueba no utilizó datos de pacientes ni Storage real.

Alcance definitivo confirmado: comprobación básica síncrona y acceso privado. Se descarta el proceso asíncrono de validación estructural; no se construye una cola ni se deja como entrega pendiente. Un documento puede estar dañado internamente aunque supere estas comprobaciones. En ese caso la profesional solicita otra copia. Una carga fallida no borra ni impide una reserva ya creada.

Cloudflare documenta 128 MB por isolate, compartidos entre solicitudes concurrentes; el presupuesto de CPU depende del plan. Un archivo de 10 MB no excede automáticamente ese límite, pero su procesamiento puede consumir recursos adicionales y no debe introducirse sin medirlo. [Límites de Workers](https://developers.cloudflare.com/workers/platform/limits/). HTTP permite ignorar Range, por lo que el límite debe imponerse también en el lector. [RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110#section-14.2). La cabecera no debe limitarse a PDF 1.x. [PDF Association](https://pdfa.org/glossary-of-pdf-terms/).

Agregar una descarga autorizada con URL firmada de corta duración y un nombre generado en servidor a partir del nombre completo de la ficha, fecha y título seguro. Conservar apellidos compuestos y normalizar caracteres incompatibles con nombres de archivos. Ejemplo sintético: `Ana_Perez_2026-11-03_estudio.pdf`. Cambia el nombre descargado, no el contenido ni la ubicación interna. La descarga del paciente, si se expone en este flujo, se limita a su propio aporte; acceso a otros estudios queda fuera de esa capacidad.

**Aceptación:** profesional y paciente cargan, el documento terminado aparece en la ficha autorizada, la descarga conserva exactamente los bytes del original y usa el nombre esperado; un archivo demasiado grande o que incumple las comprobaciones básicas no queda disponible; permisos y papelera de JPG/PNG siguen funcionando; otra reserva/consultorio no puede leer ni completar el archivo. Probar falta de soporte de Range, respuestas parciales incorrectas, cargas incompletas y PDF 2.0. Verificar el circuito real de Storage en un entorno de prueba, además de contratos SQL y sustitutos locales. La validez estructural y el análisis de contenido están fuera del alcance definitivo; el criterio anterior de rechazar cualquier PDF inválido era demasiado amplio para la validación básica.

### 7. Descripción e indicaciones del turno

Crear un campo destinado al paciente, con texto predeterminado por prestación y posibilidad de ajuste en el turno por un usuario autorizado. Conservar en cada reserva lo comunicado; editar la prestación no cambia silenciosamente indicaciones anteriores.

Separar indicaciones completas de la descripción breve que el consultorio destina expresamente al aviso público. El recordatorio puede incluir esa descripción opcional; las indicaciones completas aparecen en la confirmación y página protegida del turno. Las notas internas y los datos clínicos no se copian a notificaciones. Si no hay texto configurado, el aviso actual sigue funcionando.

**Aceptación:** texto con saltos de línea y caracteres especiales se muestra correctamente; un turno sin descripción conserva sus avisos; el flujo público y el integrado coinciden; una edición posterior tiene efecto y registro explícitos; reintentos no envían duplicados. Las pruebas de contenido no sustituyen una prueba de recepción push autorizada en un dispositivo.

### 8. Botón de contacto de WhatsApp

Añadir configuración de número para WhatsApp y habilitación explícita desde el perfil público del consultorio. No asumir que cualquier teléfono publicado admite WhatsApp. Preparar el enlace sin un número real hasta que se configure uno confirmado.

Usar un enlace normal y un icono ligero en las ubicaciones de contacto coherentes con la maqueta. No incorporar un widget, SDK ni rastreador. No incluir respuestas clínicas ni datos del paciente en el mensaje inicial. El contacto público aprobado debe poder seguir disponible aunque la reserva online esté deshabilitada.

Actualizar el contrato de `check-public.mjs`, que actualmente prohíbe `wa.me`, para permitir únicamente el contacto aprobado y mantener las demás comprobaciones de conservación de la web. No borrar una comprobación entera para obtener un resultado verde.

**Aceptación:** enlace correcto en móvil y escritorio, navegación por teclado y etiqueta accesible, ausencia de botón roto cuando no hay número, ninguna obstrucción sobre agenda o contenido y conservación de secciones, diálogos y rendimiento de Natalia.

## Cierre de cada entrega

### Condición adicional: proteger el plan gratuito frente a archivos

El usuario indicó que inicialmente usará el sistema un solo consultorio y quiere evitar pasar a Supabase pago por PDFs o imágenes. Esta condición requiere controles de volumen acumulado, además de límites por archivo.

El archivo binario se guarda en Storage; Postgres conserva sus referencias, permisos y metadatos. El plan Free publica 500 MB de base por proyecto, 1 GB de Storage y cuotas separadas de 5 GB de transferencia sin caché y 5 GB con caché. El almacenamiento se contabiliza para la organización y su uso facturable se promedia durante el período, no corresponde únicamente a una foto del espacio actual. [Facturación de Supabase](https://supabase.com/docs/guides/platform/billing-on-supabase), [Storage](https://supabase.com/docs/guides/platform/manage-your-usage/storage-size), [Transferencia](https://supabase.com/docs/guides/platform/manage-your-usage/egress).

La lectura agregada de la base vinculada, sin consultar fichas ni abrir archivos, encontró 28.454.035 bytes de base y 15.675.483 bytes en los metadatos de 32 objetos de Storage. Todos los objetos tenían un tamaño utilizable en sus metadatos. El bucket clínico es privado y mantiene un máximo de 26.214.400 bytes por objeto. Estos datos describen el proyecto inspeccionado en ese momento; no son el consumo mensual facturable ni incluyen otros proyectos de la organización. Evidencia temporal: `/tmp/cita-natalia-storage-budget-20261014.json`.

Actualmente hay controles de frecuencia, máximo de tres cargas recientes pendientes por usuario y observabilidad estimada de transferencia. No hay una cuota acumulada de bytes que impida llenar el almacenamiento. Los umbrales diarios de observabilidad no equivalen a la cuota mensual de transferencia del plan.

Configuración inicial propuesta, todavía sin aplicar: máximo de 5 MB por archivo, 10 MB y tres documentos por reserva del paciente, y un presupuesto conjunto provisional de 700 MB para archivos del proyecto. Estos valores usan MB decimales y se expresarán en bytes exactos en todos los controles. El presupuesto definitivo debe descontar el consumo de otros archivos y proyectos de la misma organización; no corresponde multiplicar esa cuota por cada consultorio. Son parámetros operativos propuestos, no requisitos clínicos confirmados.

El presupuesto debe incluir originales, miniaturas, papelera, objetos pendientes y objetos huérfanos. Antes de emitir una autorización de carga hay que reservar espacio en una transacción compartida por todos los usuarios; dos cargas simultáneas no pueden sobrepasar el presupuesto. Una URL firmada no limita necesariamente la carga al tamaño declarado por el cliente: reservar su máximo realmente permitido por Storage mientras siga válida y ajustar la ocupación tras comprobar el objeto. No liberar esa reserva solo por un tiempo de interfaz si la autorización de Storage todavía permite subir bytes. Reconciliar periódicamente los objetos realmente almacenados y las reservas expiradas. La reserva pesimista de 5 MB corresponde al presupuesto global de 700 MB. Para el límite de 10 MB de una reserva del paciente se contabilizan los objetos reales; al preparar cargas se revisan también los tamaños declarados de las pendientes. Storage vuelve a imponer el máximo real por reserva de forma atómica, aun si el archivo subido pesa más que lo declarado. Dos archivos de 3,5 MB más uno de 200 KB son admitidos: 7,2 MB reales por turno, mientras el tercer enlace reserva 5 MB del presupuesto global. No se aumenta el tope por turno a 15 MB.

Aplicar límites en cliente, servidor, funciones SQL y bucket. Mostrar consumo y advertencias al alcanzar el 70% y el 85% del presupuesto configurado. Al alcanzar el presupuesto detener nuevas cargas, conservando consultas, turnos y acceso a archivos existentes. No borrar documentos clínicos terminados automáticamente para ganar espacio. La depuración de cargas abandonadas requiere una política específica y no debe tratarse como eliminación de historia clínica.

La cuota de transferencia requiere seguimiento aparte: no precargar originales ni PDFs al abrir la ficha; descargar bajo demanda y generar URLs breves. Los contadores de acceso de Cita Suite son estimaciones, porque una misma URL puede descargarse varias veces. No prometer un límite exacto de transferencia a partir de esos contadores; contrastar con el uso real informado por el proveedor.

No comprimir ni reducir automáticamente documentos clínicos originales con pérdida de detalle. Una copia reducida para navegación debe identificarse como tal y también contar en el presupuesto. Rechazar un archivo demasiado grande con una instrucción comprensible para obtener una copia adecuada.

Los límites evitan crecimiento sin control, pero no crean capacidad indefinida. Si se necesita conservar un archivo creciente sin usar Storage de Supabase, considerar un proveedor privado separado, manteniendo ficha, permisos y referencias en Cita Suite. R2 Standard publica 10 GB-mes gratuitos, cuotas gratuitas de operaciones y transferencia directa sin cargo; superar las cuotas de espacio u operaciones puede generar costos. No es almacenamiento ilimitado ni una garantía de gratuidad permanente. Su adopción y cualquier traslado de archivos existentes requieren una implementación y verificación propias. [Precios de R2](https://developers.cloudflare.com/r2/pricing/).

Ejecutar pruebas de la capacidad nueva y sus flujos relacionados, siempre secuencialmente. Antes de publicar, contrastar cambios con agenda individual/conjunta, reprogramación, ficha, permisos y contrato público. En Natalia verificar que siguen presentes los contenidos y navegaciones de la maqueta, sin recortes para mejorar métricas.

La portada continúa estática y los módulos se cargan cuando se necesitan. Formularios, precios y permisos permanecen en Cita Suite. No añadir lectores PDF, editores de noticias o código de aula al paquete inicial de Natalia.

Separar evidencia local, servicios simulados, entorno de prueba y producción. La configuración real de Natalia/Yari no queda reemplazada por un ejemplo de prueba. La futura implementación puede quedar preparada y comprobada sin inventar esa configuración, pero su activación real necesita los valores confirmados.

## Fuentes principales del repositorio

- Cuestionario/configuración: `apps/web/src/routes/odonto/configuracion/reserva-online/+page.server.ts`, `apps/web/src/lib/server/booking-information.ts`, `supabase/migrations/20261013010000_booking_patient_information.sql`, `supabase/tests/booking_patient_information.sql`.
- Ficha/historia: `apps/web/src/routes/odonto/pacientes/[id]/+page.server.ts`, `+page.svelte`, `historial/+server.ts`, `datos/+server.ts`, `apps/web/src/lib/constants.ts`, `supabase/tests/clinical_provenance_triggers.sql`.
- Archivos: `apps/web/src/lib/client/clinical-files.ts`, `apps/web/src/lib/server/clinical-files.ts`, rutas bajo `apps/web/src/routes/odonto/pacientes/[id]/radiografias/`, `supabase/migrations/20260820020000_supabase_clinical_files_phase1.sql`, `supabase/tests/clinical_files_phase1.sql`.
- Agenda: `apps/web/src/lib/server/availability-rules.ts`, `availability-exceptions.ts`, `integrated-availability.ts`, `apps/web/src/lib/availability/calculate.ts`, `apps/web/src/routes/odonto/profesionales/[professionalId]/+page.server.ts`, `supabase/migrations/20261013000000_booking_integration_foundation.sql`.
- Precios: `supabase/migrations/20260513010000_agenda_core.sql`, acciones de prestaciones en `apps/web/src/routes/odonto/profesionales/[professionalId]/+page.server.ts`, `apps/web/src/lib/booking/PublicBookingFlow.svelte`.
- Avisos: `apps/web/src/lib/server/push.ts`, confirmación pública y recibo integrado bajo `apps/web/src/routes/turno/[token]/` y `apps/web/src/lib/booking/`.
- Web pública: `apps/natalia/astro.config.mjs`, `src/components/ContactChannels.astro`, `CourseDetail.astro`, `ClassroomPreview.astro`, `src/lib/courses.ts`, `src/lib/reference-content.ts`, `src/pages/notas/[id].astro`, `scripts/check-public.mjs`.
- Propuesta recibida: `/home/usuario/.codex/attachments/eb34d5bc-c393-43aa-a876-c5f97ebb5c52/pasted-text.txt`.

Evidencia SQL de esta sesión: `/tmp/cita-natalia-audit-20261014-sql.log` y `/tmp/cita-natalia-audit-20261014-clinical.log`. Son archivos temporales, no parte del producto.
