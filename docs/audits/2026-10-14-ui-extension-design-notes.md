# Documentación visual de la extensión Natalia / Cita Suite

Fecha: 14/10/2026. Alcance: cierre documental independiente de una **extensión ordinaria** ya implementada y revisada. Modo de las superficies nuevas: Operate. Se compararon fuentes, capturas y resultados persistidos; este pase no ejecutó navegador, detector, tests, builds ni servicios. No modifica código, estilos, pruebas, datos ni despliegues.

Se actualizaron únicamente [PRODUCT.md](../../apps/natalia/PRODUCT.md) y este informe. No se creó ni regeneró un sistema visual. [DESIGN.md](../../apps/natalia/DESIGN.md) y [su sidecar](../../apps/natalia/.impeccable/design.json) se preservan; la ausencia de documentos equivalentes en Cita Suite no convierte su interfaz en un proyecto sin identidad.

## Autoridad y fuentes contrastadas

La autorización vigente del usuario y el [contrato funcional](2026-10-14-booking-extensions-contract.md) resuelven el alcance. PRODUCT.md recoge esa verdad del producto. DESIGN.md conserva decisiones visuales duraderas, pero sus restricciones antiguas de alcance no anulan una autorización posterior. Estas notas registran diferencias y evidencia; no sustituyen los archivos incumbentes ni agregan decisiones de marca.

| Superficie | Fuente incumbente | Comparación con la extensión |
| --- | --- | --- |
| Web pública Natalia | PRODUCT.md, DESIGN.md, `.impeccable/design.json`, `apps/natalia/src/styles/public.css` | Mantiene papel/tinta/terracota, Newsreader/Hanken Grotesk, fotografía y composición existentes. Contacto reutiliza las variantes crema; no introduce otra identidad. |
| Reserva e información pública | `apps/web/src/lib/booking/BookingAppearance.svelte` y `apps/web/src/app.css` | Conserva tema configurable. El adaptador Natalia mantiene papel claro u oscuro marrón, títulos Newsreader, controles Hanken, bordes contextuales y contenedores de 14 px. |
| Panel autenticado Cita Suite | `apps/web/src/app.css`, `apps/web/tailwind.config.js` y componentes `ux-*` | Mantiene superficies oscuras, acento púrpura, Inter y densidad operativa. El formulario público de Natalia no reemplaza el tema privado. |

Muestreo de implementación: `PricePolicyEditor.svelte`, `PatientDocumentUpload.svelte`, `PublicBookingFlow.svelte`, `apps/natalia/src/scripts/public.ts` y la ruta del editor de profesionales. Se revisaron también el [registro de implementación](2026-10-14-implementation-ledger.md), [checks.json](evidence/2026-10-14-booking-extensions/checks.json), la [revisión visual completa](evidence/2026-10-14-booking-extensions/full-visual-review.md) y el [veredicto de la corrección](evidence/2026-10-14-booking-extensions/visual-fix-verdict.md). El muestreo documental no constituye una segunda auditoría integral del backend.

## Sistema observado: continuidad visual

| Regla o material existente | Evidencia en fuentes terminadas | Resultado |
| --- | --- | --- |
| Papel, tinta y terracota Natalia | `public.css`: papel `#F3EEE5`, tinta `#1E1A16`, acento `#A94B22`; variantes oscuras `#1A1612`, `#EFE8DC`, `#E07A4F` | Coincide con los roles claros/oscuros de DESIGN.md. No se igualan los fondos editoriales y operativos: el adaptador tiene superficies propias ya documentadas. |
| Pareja tipográfica | `public.css`: Newsreader variable 300–600 para títulos; Hanken Grotesk 400–700 para lectura y controles. BookingAppearance conserva esas familias | Coincide. Astro sirve WOFF2 locales; el adaptador público conserva su hoja Google Fonts existente. Las cifras del artefacto Astro no describen las dependencias de fuentes del motor compartido. |
| Jerarquía editorial y operativa | Natalia mantiene sus escalas fluidas de titular y sección. Cita Suite conserva `ux-title` y `ux-section-title`; el adaptador usa Newsreader 500 | Coincide con la separación entre hero editorial y formulario de tarea. No se traslada la escala del hero al panel. |
| Contacto terracota y crema | `public.css`: `.btn-cream`, `.btn-outline-cream` y foco local; `public.ts` elige la variante delineada crema en la sección y la secundaria en el destino de contacto | Coincide con la regla de legibilidad de contacto. El enlace de WhatsApp agrega una acción dentro de los controles existentes. |
| Tema privado y profundidad | `app.css`: fondo `#0b1626`, superficies azules oscuras y acento `#8b5cf6` / `#7c3aed`; tarjetas y controles `ux-*` | Coincide en las capturas de aranceles, documentos, configuración y horarios. La sombra cálida del adaptador sigue limitada al ámbito Natalia. |
| Forma y estados | Píldoras editoriales; controles compartidos de `1rem`, altura mínima `2.75rem`, foco/acento y disabled existentes; adaptador con tarjetas de 14 px | Herencia preservada. Se utilizan inputs de mes, selects, checkboxes, file picker y progress nativos; no se crea una biblioteca de controles paralela. |

Las reglas nombradas incumbentes **Continuidad**, **Legibilidad de Contacto**, **Pareja Tipográfica** y **Ámbito de Reserva** siguen siendo aplicables. No se canonizan nuevos rótulos, ornamentos, sombras o prohibiciones para justificar esta extensión. Los rótulos y materiales históricos se conservan por la dirección autorizada; esa conservación no exige que cada superficie futura los replique.

## Dirección de cinco secciones y comportamiento observado

| Sección | Dirección vigente | Evidencia terminada y alcance |
| --- | --- | --- |
| THESIS | El paciente comprende el precio y contexto de su fecha; el consultorio controla aranceles, disponibilidad y límites | PublicBookingFlow muestra el importe cotizado antes de los horarios. La operación de reserva valida el hash y guarda el snapshot. Configuración explica archivo, cuota por turno y espacio global como controles distintos. |
| OWN-WORLD | Conservar Natalia y Cita Suite en sus respectivos ámbitos | Las capturas públicas usan papel/terracota o marrón oscuro; las privadas usan `ux-*` oscuro/púrpura. Contacto permanece en su sección incumbente. No hubo comp, nueva identidad ni reemplazo autorizado. |
| STORY | Prestación → fecha → costo actualizado → horario → formulario → reserva → información/documentos | `booking-mobile.png` muestra la cotización del día encima de los horarios. La aceptación se valida al confirmar la reserva mediante la cotización enviada; no se documenta un checkbox o una pantalla independiente de aceptación que la fuente no implementa. La información posterior explica que el turno ya existe y se conserva si falla un envío. |
| FIRST VIEWPORT | Tarea, contexto y acción claros, dentro de la composición heredada | Aranceles identifica el profesional y explica los ajustes; configuración identifica documentos/contacto; la información posterior distingue reserva existente, datos y adjuntos. La navegación y ayuda incumbentes se mantienen. La revisión completa registra esta herencia como adaptación, sin una promesa de rediseño de la cabecera. |
| FORM | Controles nativos etiquetados, errores humanos, borradores, pesos enteros, reflujo y temas | PricePolicyEditor conserva campos y vista previa; los importes son tabulares y no se parten. Configuración mantiene el teléfono inválido y el borrador de indicaciones ante error. La carga usa file picker nativo, progreso y mensajes de recuperación. El formulario de información puede guardarse sin JavaScript; los adjuntos requieren JavaScript y lo explican. |

## Decisiones funcionales que explican la interfaz

- **Aranceles:** el consultorio ingresa porcentaje recurrente y cambios por mes. ARS en pesos enteros; precisión exacta acumulada y redondeo únicamente al final de cada cotización. No hay IPC automático. La cotización aceptada es histórica y no representa un pago ni se modifica al cambiar la política. Se diferencia tarifa individual de predeterminada; los turnos conjuntos no suman importes individuales. El contrato documenta permisos, versiones y rechazo de cotizaciones obsoletas.
- **Cuestionarios:** preguntas configurables y campos asociados actualizan perfil e historia, con procedencia declarada por el paciente, esquema y envíos anteriores conservados. El formulario posterior no sobrescribe el borrador durante la hidratación inicial y conserva la reserva cuando falla un envío.
- **Documentos:** JPG, PNG y PDF de paciente/profesional permanecen en Storage privado. Máximo de 5.000.000 bytes por archivo; para el paciente, 10.000.000 bytes y tres documentos por turno. El presupuesto global de 700.000.000 bytes incluye objetos del proyecto y máximos de leases pendientes. La cuota por turno usa los bytes reales y tamaños declarados pendientes según el contrato; una reserva global de 5 MB no se presenta como un documento real de ese tamaño.
- **PDF:** metadata y lecturas Range acotadas del comienzo/final, sin parser estructural asíncrono, miniatura o apertura automática. Pasar ese chequeo no garantiza integridad de todas las páginas ni ausencia de contenido activo; el Worker no compara el SHA completo. Una descarga autorizada lleva nombre y apellido de la ficha y entrega bytes originales. Los tests locales de descarga compararon esos bytes; ninguna URL firmada se copia a este informe.
- **Horarios:** un único editor mantiene franjas generales o por prestación/seguimiento y bloqueos en fechas no consecutivas. Una franja restringida sin prestaciones queda cerrada. El contrato conserva turnos existentes y exige reconocer el conflicto al bloquear; las comprobaciones compartidas también cubren buffers, cambios y creación manual.
- **Indicaciones:** texto para el paciente y descripción pública corta del recordatorio son campos distintos, con copia por turno. El editor advierte que la descripción pública puede aparecer en pantalla bloqueada. No incorpora automáticamente notas clínicas, medicación o cuestionarios. El pase de contenido no prueba entrega real de push.
- **Contacto:** el número debe estar confirmado y llevar código de país. WhatsApp es un enlace de contacto normal con flag propio, separado de la bandera heredada de mensajería y de la disponibilidad de la reserva. Natalia conserva el contacto aprobado si falla el catálogo. No se enviaron mensajes ni se habilitaron notificaciones automáticas.
- **Contenido postergado:** se conservan noticias, cursos, lectores y destinos suministrados. Su presencia pública no prueba ni autoriza administración de noticias, LMS, inscripción, pago o aula autenticada. Los PDFs ya tienen autorización posterior; no quedan incluidos en el antiguo aplazamiento.

## Evidencia visual y veredicto

Capturas bajo `.impeccable/review/booking-extensions/`, con datos sintéticos. Este documenter abrió directamente `natalia-contact-desktop.png`, `natalia-contact-mobile.png`, `booking-mobile.png`, `information-dark-mobile.png`, `settings-error-mobile.png`, `patient-documents-mobile.png`, `weekly-controls-mobile.png`, `price-320.png` y `price-long-month-320.png`. Muestran las superficies y estados indicados. Las capturas extensas de documentos/configuración se usan para continuidad de estructura; la legibilidad de detalle se contrasta con la fuente y la revisión independiente. No se usaron las capturas gigantes `natalia-desktop.png` ni `natalia-mobile.png` como prueba de contacto o texto.

La revisión completa abrió la matriz requerida: reserva, información clara/oscura/sin JavaScript, configuración y error, horarios, documentos, contacto y aranceles, con 1440/390/320 según superficie. Conservó un único hallazgo material: el icono del mes ocultaba el último dígito del año a 320 px. El informe completo mantiene `disposition: fix` como registro histórico, no como un veredicto nuevo posterior a la corrección.

El [veredicto persistido](evidence/2026-10-14-booking-extensions/visual-fix-verdict.md) puntúa **fix 1: resolved** y devuelve **disposition: ship** sobre esa corrección. Comprueba noviembre de 2026, septiembre de 2027 y la continuidad de fechas/importes en 390 y 1440. La fuente conserva `type="month"`, `font-size: 1rem`, padding móvil de la tarjeta `1rem` y del mes `0.25rem`, con reglas acotadas a menos de 640 px; el veredicto registra la presentación revisada de 16 px/16 px/4 px. El mismo tratamiento alcanza los meses de excepciones. Los importes mantienen `white-space: nowrap`, sin extender esa regla al texto descriptivo de toda la interfaz.

La puntuación final cubre el hallazgo listado y sus cuatro recapturas; no equivale a una segunda revisión completa o a certificación de producción. Este pase documental no reabre una búsqueda de defectos, no ejecuta otro detector y no cambia el veredicto del revisor.

## Evidencia de ejecución y límites

Los resultados siguientes son los **ya ejecutados** y conservados en checks.json y el registro; este documenter los leyó sin repetir suites. Todos fueron secuenciales en el host de RAM limitada.

| Comprobación | Resultado registrado | Lo que demuestra |
| --- | --- | --- |
| Lógica/servidor | 129 archivos, 958 tests | Comportamiento local y regresiones cubiertas por esas suites |
| Componentes | 8 archivos, 74 tests | Contratos de componentes en jsdom |
| Base | 97 migraciones, 10 contratos SQL | Schema y operaciones en PostgreSQL aislado, con schema de Storage API 1.70.3 |
| Navegador/backend de Cita Suite | 13 casos | PostgreSQL/PostgREST/Storage API reales locales; backend de archivos; Auth simulado; CSP/CORS adaptados a loopback |
| Natalia/backend vinculados | 5 comprobaciones | SDK/iframe reales locales, contacto independiente y formulario sin JavaScript; ningún envío WhatsApp |
| Regresión pública sintética Natalia | 6 escenarios | SDK/contacto/fallback con respuestas de negocio interceptadas; se distingue de los cinco casos con backend local |
| Tipos y compilación | Svelte check 0 errores/0 advertencias; Cloudflare build aprobado; Astro build de 14 páginas | Validación y compilación local; no ejecución remota de Worker |
| Artefacto Natalia | JavaScript inicial 6.986 bytes; SDK de reserva diferido | Tamaño registrado del build y separación de la carga del SDK |
| Detector | Una ejecución, `[]` | Sin hallazgos del detector en esa ejecución; no sustituye el pase visual |

No quedan certificados despliegue o migraciones en producción, Auth real, Storage S3 físico del proveedor, push recibido en dispositivo, egress facturado, consumo de otros proyectos ni la configuración real de Natalia. El presupuesto global y la estimación de descargas autorizadas no garantizan permanecer indefinidamente en Free. Las banderas optativas empiezan apagadas y no se inventan prestaciones, precios, preguntas, horarios o números reales.

checks.json registra el cierre del fixture: tres contenedores y dos redes propios retirados, proceso Vite y archivos runtime retirados, etiquetas restantes cero y puertos 5177/43021 cerrados. La comparación documental se realizó sobre los archivos/capturas persistidos; no se reabrió ese entorno. La lectura de privilegios remotos registrada en la auditoría no fue una escritura ni una migración de producción.

## Deriva documental previa y preservación

| Deriva detectada | Evidencia concreta | Tratamiento en este pase |
| --- | --- | --- |
| PRODUCT.md conservaba el aplazamiento de todas las cargas y anunciaba aula/administración como próxima etapa, en contradicción con su actualización del 14/10 | Párrafos anteriores de User steering frente al bloque Scope update | Se reconciliaron dentro del límite autorizado: cargas autorizadas, cursos/noticias postergados, ninguna plataforma anunciada como siguiente etapa. |
| DESIGN.md conserva una exclusión histórica de WhatsApp y archivos | DESIGN.md:452 y `narrative.donts` del sidecar:937 | Se informa sin reparar. La autorización actual permite contacto y documentos; esa frase no se adopta como prohibición de la nueva extensión. |
| La descripción de campos todavía afirma que ninguna carga pertenece a esa superficie | DESIGN.md:399 | La web Astro continúa sin formulario clínico propio, pero el motor de información posterior ahora incluye adjuntos. Se registra la diferencia de alcance sin cambiar tokens o prosa incumbente. |
| Contacto se describe como obtenido del catálogo | DESIGN.md:421 frente a `public.ts`:76–123 y `/api/public/contacto/[integrationKey]` | La extensión agrega resolución independiente y conservación ante fallo del catálogo. Se registra como descripción funcional anterior, sin reemplazar la guía visual. |

No se detectó una contradicción material en las familias, paletas, radios y variantes de contacto muestreadas. Esta afirmación se limita a ese muestreo, fuentes y capturas; no afirma que cada token o regla de todo el proyecto fue auditado. La deriva histórica de alcance no se convierte en defecto visual, decisión de marca nueva ni autorización para refrescar el sistema.

SHA-256 de los archivos incumbentes preservados, idénticos antes y después del pase:

```text
cad92f5fac1c729280158e9c4ea4fde3d2d34f95c34dd48135abfbaf387b1fb0  apps/natalia/DESIGN.md
23bfa59f3bd6c9ef45e4e222fca5a53b0aeae832094bb0d105a88e8f252afc46  apps/natalia/.impeccable/design.json
```

La documentación queda enlazada al contrato, al registro y a la evidencia persistente para futuras auditorías. El estado documentado es implementación local revisada; ninguna frase de este cierre anuncia publicación, datos reales ni nuevas etapas autorizadas.
