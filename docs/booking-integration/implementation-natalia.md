# Implementación de Natalia y datos exigibles por profesional

La maqueta se convirtió en una aplicación estática en `apps/natalia`, con Astro, TypeScript y Tailwind. Abre el motor común de Cita Suite; los horarios, bloqueos, identidad del paciente y reservas pertenecen a Cita Suite. Se agregó configuración por profesional para exigir datos al reservar y guardarlos automáticamente en el perfil, conservando las declaraciones y los valores anteriores.

La entrega es código y comprobaciones locales con datos ficticios. No contiene agendas, aranceles, preguntas clínicas ni datos públicos reales inventados. No se publicó ni se aplicaron migraciones a producción. Toda carga de estudios por el paciente quedó postergada, incluyendo imágenes y PDFs. WhatsApp quedó descartado. Señas, vencimientos por falta de pago, paquetes y nuevas reglas de recordatorios requieren decisiones posteriores y no están simulados como disponibles.

## Comportamiento y alcance

| Pedido | Implementación |
| --- | --- |
| Turnero de cada profesional | Perfil de enlace con profesionales y prestaciones permitidas, URL individual y el mismo creador de reservas. Los horarios se configuran en las agendas existentes. |
| Duración exacta y arancel | Se leen de las prestaciones de Cita Suite. Si las profesionales usan tiempos o aranceles distintos, configurar prestaciones distintas y asignarlas a quien corresponda. El arancel actual es un texto público; no se incorporó cobro al paciente. |
| Web funcional | Botones con URL real del turnero y apertura diferida del SDK. Catálogo público del mismo enlace, con duración/arancel y contacto configurado. Sin clave, muestra que las reservas todavía no están habilitadas. |
| Formulario exigible | Hasta 24 preguntas por profesional: respuesta corta/extensa, opciones o Sí/No para datos adicionales; cada pregunta puede ser obligatoria. Se aplica a sus enlaces individuales y al turnero general. |
| Guardado automático | Obra social, plan, fecha de nacimiento, DNI y domicilio van a la ficha demográfica; medicación, antecedentes y alergias al perfil clínico. Edad se conserva como edad declarada con fecha, sin inventar nacimiento. Otros datos van al perfil clínico como campos adicionales. |
| Consulta previa e historial | Información aportada al reservar → ficha del paciente y turno. Conserva pregunta, respuesta, comentario, antes/después y origen paciente. Una ampliación guarda un nuevo envío y conserva los anteriores. |
| Datos y turno consistentes | Los campos requeridos se validan en servidor y SQL. Reserva, declaración y actualización del perfil se confirman juntas; una validación fallida no deja paciente o reserva parciales. |
| Cambios de configuración | Nuevas reservas usan nuevas preguntas; las existentes conservan su formulario original. Revisión esperada impide pisar la configuración guardada por otra persona. |
| Recordatorios | Cita Suite ya contiene recordatorios push de 24 h/2 h y alternativas de calendario. Se verificó su existencia en el código y se ejecutó la suite existente; esta entrega no define una nueva regla para el consultorio ni acredita entrega real a dispositivos. |
| Estudios del paciente y WhatsApp | Carga de archivos completamente postergada; no se crearon rutas, buckets ni tablas para estudios del paciente. No se agregó una integración de WhatsApp. |
| Señas, preparación previa y paquetes | No se agregaron cobros, cancelación por impago, paquetes ni un cobro separado por preparación. Primera consulta/seguimiento pueden representarse como prestaciones existentes cuando se definan sus tiempos y precios. Un cuestionario diferente por prestación integral requeriría ampliar el alcance actual, que es por profesional. |
| Página conjunta futura | Los enlaces y el motor admiten reutilización desde otra web. La página del consultorio no se desarrolló en esta entrega. |

Las preguntas antiguas específicas de un enlace se conservan por compatibilidad y se muestran como tales. Los nuevos datos del perfil se configuran en **Datos que pedís al reservar**, por profesional. No hay un segundo constructor de reservas en Natalia.

El dueño/administrador configura los enlaces y formularios. Cada profesional puede configurar su propio formulario con el consultorio operativo; recepción y profesionales ajenos no pueden modificarlo. Los permisos clínicos existentes controlan la lectura de declaraciones e historial. El enlace de gestión del paciente permite consultar sus propios envíos, sin devolver los datos clínicos actuales aportados por el equipo.

Las preguntas de una reserva conjunta se combinan: una exigencia de cualquiera de los profesionales se conserva; los límites de texto se restringen al menor; las opciones se intersectan. Configuraciones incompatibles fallan explícitamente, sin descartar obligaciones. El formulario combinado admite hasta 64 preguntas y 16 KB de definición/respuestas. Los comentarios admiten 2.000 caracteres. No se borran datos del perfil por omitir campos opcionales; para informar ausencia de medicación/alergias se debe responder explícitamente.

La reserva pública nueva utiliza una referencia idempotente. Un reintento confirmado no duplica el turno ni vuelve a aplicar declaraciones antiguas al perfil. Los nuevos envíos tienen una secuencia inequívoca y control de versión para evitar guardar sobre una ventana desactualizada. El tema de la ampliación se hereda de la apariencia histórica del turno, conservando Natalia o Cita Suite según su origen.

## Orden de activación

1. Revisar el diff de esta entrega junto con la integración preexistente. El repositorio tenía cambios previos y evidencias ajenas: no subir todo el directorio, `.env`, respaldos ni `WEB NATALIA/Credenciales cita suite`.
2. Aplicar primero las migraciones aditivas pendientes de la fundación de integración y `20261013010000_booking_patient_information.sql`, siguiendo el procedimiento de migración del proyecto. Mantener las funciones apagadas mientras el código servido no sea compatible. La ejecución de pruebas usa una base desechable, nunca la URL remota.
3. Servir Cita Suite compatible y habilitar `BOOKING_CONTEXTS_AVAILABLE=true`, `BOOKING_INTEGRATIONS_ENABLED=true` y `BOOKING_INFORMATION_ENABLED=true` en el entorno elegido. La información previa permanece apagada por defecto en `.env.example`.
4. Desde Cita Suite configurar datos públicos confirmados, profesionales, prestaciones, duración, arancel, asignaciones y horarios. Crear formularios por profesional y revisar qué campos se exigirán. No se incluyen valores reales en esta entrega.
5. Crear un enlace por profesional en **Configuración → Reserva online**, con sus prestaciones, dominio exacto permitido y modalidades realmente habilitadas. Un único perfil puede ser general. Para activar un enlace se requieren profesionales/prestaciones públicas y disponibilidad configurada; una modalidad virtual necesita indicaciones de acceso.
6. Compilar Natalia con `PUBLIC_CITA_BASE_URL` y `PUBLIC_NATALIA_INTEGRATION_KEY` del enlace público seleccionado. La clave pública identifica el enlace; no es una credencial de Supabase. La excepción de compilación `NATALIA_LOCAL_FIXTURE=true` admite HTTP únicamente en loopback para pruebas aisladas; no habilita HTTP de Internet.
7. Revisar los textos editoriales con Natalia y configurar los datos reales que faltan antes de publicar. Se retiraron matrícula, historial de certificaciones, antigüedad y dirección heredados de la demo sin confirmación.
8. Verificar en el destino real: versión de Cita Suite, migraciones, Auth real y roles, CORS/CSP, catálogo, exclusión de horarios, reserva/ampliación, recuperación, acceso privado y artefacto de Natalia servido. Las comprobaciones locales no sustituyen este paso. Publicación, credenciales/dominio y datos operativos reales quedan pendientes de esa activación.

Para volver atrás, apagar la entrada integrada y la información previa. Conservar las tablas, snapshots y reservas; no eliminar declaraciones ni reescribir turnos históricos. El sitio sin configuración conserva una salida clara y el motor anterior mantiene su ruta habitual.

## Rendimiento

Se comparó la maqueta y el artefacto estático en el mismo navegador Chromium, con viewport 390×844, caché fría, 150 ms de latencia, 200.000 bytes/s de descarga, 100.000 de subida y CPU ralentizada ×4. Tres ejecuciones por versión, con observación hasta 1,5 segundos después de `load`. Son pruebas sintéticas locales, no métricas de pacientes ni INP de campo.

| Mediana | Maqueta | Nueva web |
| --- | ---: | ---: |
| Transferencia inicial, documento y recursos | 3.011.857 bytes | 211.796 bytes |
| LCP observado | 3.460 ms | 1.120 ms |
| Tiempo total observado en tareas largas | 1.110 ms | 353 ms |
| Nodos del documento | 1.455 | 256 |
| Suma de movimientos de layout sin interacción | 0,0314 | 0 |

La suma de movimientos observada no implementa las ventanas de sesión del CLS de campo. El tiempo de tareas largas no es INP ni TBT de Lighthouse. La mejora de transferencia es aproximadamente 93%; la de LCP sintético, 68%. El sitio inicial no carga el SDK/iframe. El catálogo consulta al aproximarse a la sección, sin polling. Las fuentes locales y fotografías WebP tienen variantes responsivas; las imágenes inferiores usan carga diferida. En el flujo embebido, las fuentes y el turnero dentro de Cita Suite se cargan después de la intención de reservar y no forman parte de la medición institucional inicial. El acceso directo a una página pública del turno carga las fuentes del adaptador al abrir esa página.

`apps/natalia/scripts/check-build.mjs` verifica límites de HTML, JavaScript inicial, CSS, fuentes y fotografías, además de ausencia de iframe/SDK inicial y fuentes externas en el artefacto institucional. El build lo ejecuta automáticamente. En el artefacto medido: HTML 18.556 bytes, JS inline 3.146, CSS 23.470 y fuentes 157.308. El catálogo usa una respuesta JSON agregada en un único snapshot para evitar recortes por límites ordinarios de filas; la respuesta pública marca caché de 60 segundos y varía por Origin. Sólo se verificó esa cabecera en el servidor local, no el comportamiento del CDN real. Disponibilidad, tokens y declaraciones conservan no-store.

## Verificación y auditoría

La evidencia temporal reside en `/tmp/cita-natalia-implementation/`; las credenciales de fixture están fuera del repositorio. Los tests/builds se ejecutan secuencialmente. La prueba SQL reconstruye las migraciones en su propio PostgreSQL limitado a 384 MB y un CPU, sin puerto de base publicado ni destino remoto configurable.

La auditoría cubre: permisos de dueño/profesional propio/recepción/consultorio ajeno; obligatoriedad y validación de edad/nacimiento; rollback completo; declaración falsa booleana y campos adicionales; omisión que conserva datos; valores anteriores y origen; control de versión y orden de envíos; idempotencia tras cambiar formularios/enlaces; preguntas conjuntas incompatibles; token invalidado para paciente archivado; privacidad de comentarios y catálogo; grants/RLS; origen permitido/denegado; navegación móvil/teclado; no desbordamiento y enlace sin JavaScript.

Correcciones derivadas de la auditoría: ordenar envíos por secuencia en lugar de fecha/UUID; conservar la edición durante la inicialización del formulario; no activar botones de configuración antes de estar listos; seguir la modalidad de la navegación pendiente; permitir configuración propia al profesional según acceso operativo; conservar la apariencia histórica y las sombras cálidas al ampliar información; eliminar la animación de espaciado del acordeón; declarar el intervalo variable de Newsreader que usa la maqueta; y corregir la cabecera que anulaba la caché del catálogo.

La prueba E2E hace escrituras reales en PostgreSQL/PostgREST desechables, simula pérdida de respuesta y confirma el mismo turno recuperado, verifica el perfil actualizado e historial privado y configura un nuevo campo obligatorio desde el panel. **Auth es un simulador local con firma y usuarios de fixture**, no una sesión Supabase real. Una segunda prueba abre el sitio Astro compilado configurado y verifica catálogo, SDK, campos exigibles, Escape y alternativa directa sin JS, sin crear pacientes.

| Comprobación final | Resultado y evidencia local |
| --- | --- |
| Base y contratos SQL | Reconstrucción limpia de 93 migraciones; siete scripts aprobados, incluido el harness y los contratos de integración/información. `sql-final.log`. |
| Lógica de Cita Suite | 126 archivos, 932 pruebas aprobadas; `unit-final.log`. |
| Componentes | Ocho archivos, 74 pruebas aprobadas; `client-final.log`. |
| Flujos completos | Una prueba compuesta aprobada en 27 s, contra PostgreSQL/PostgREST aislados con Auth simulado; `e2e-final.log`. |
| Astro conectado | Catálogo real de fixture, origen denegado, cabeceras, reserva compartida, preguntas obligatorias, Escape, alternativa sin JS y ausencia de desbordamiento aprobados; `natalia-connected-evidence.json`. |
| Tipos y diagnósticos | `pnpm check`: shared y web aprobados; Svelte sin errores ni advertencias. Astro sin errores, advertencias ni hints; `check-final.log`, `natalia-build-final.log`. |
| Compilaciones | Astro y adaptador Cloudflare aprobados; presupuestos de recursos incluidos en el build Astro. `natalia-build-final.log`, `cloudflare-build-final.log`. |
| Capturas y revisión independiente | Escritorio/móvil y claro/oscuro; correcciones F1/F2/sombra/F3 resueltas, disposición `ship` limitada a esos hallazgos. `review/independent-review.md`. No equivale a certificación general de la aplicación. |
| Documentación visual | DESIGN.md y sidecar v2 reconciliados con fuente y tokens; revisión de formato terminada. `review/documentation-outcome.md`. |
| Artefactos y secretos configurados | 132 archivos de salida examinados contra cinco valores privados configurados y patrones adicionales, cero coincidencias. Manifiestos SHA-256 y límites de la búsqueda en `final-artifact-audit.json`. |

Identificación del manifiesto ordenado de Natalia: `682ed8b52965dd04b7eb7d3830e76339136a8bd208f90b602d22416eaaf3d887`; Cloudflare: `0f6cfd26a190bd56174e7daa075826c371cc591e261777f5351bcdaa621bd7d9`. Estos hashes identifican las salidas locales comprobadas; no acreditan reproducibilidad entre dos compilaciones ni contenido desplegado. Se preservaron 113 de los 126 archivos capturados al inicio; los otros 13 recibieron cambios de esta implementación, sin archivos iniciales eliminados. El snapshot, diff y recibos quedan fuera del repositorio.

No se realizaron pruebas de carga de producción, Auth real, dispositivos físicos, correo/push reales, proveedores de pago ni carga de estudios. Los procesos, contenedores y redes creados para las pruebas se retiraron; los servicios ajenos del usuario se conservaron. El resultado está implementado y verificado localmente, pendiente del orden de activación anterior.
