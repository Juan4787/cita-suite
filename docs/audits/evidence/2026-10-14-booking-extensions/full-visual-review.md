disposition: fix

Extensión incumbente: sin comp nueva, QUALITY BAR card separada ni concept roll/seed; no corresponde exigirlos como un rediseño. Cita Suite carece de PRODUCT.md/DESIGN.md equivalente previo; su autoridad es app.css/ux-* y BookingAppearance.svelte. Fuentes primarias revisadas por muestreo; no se revisó íntegramente el backend ni se ejecutaron navegador, detector, tests o builds. Este informe registra el pase completo anterior a la última corrección del campo de mes; su recorte de evidencia permanece en reviewer-crops/price-month-320.png.

## persistence

pass para la extensión. `apps/natalia/PRODUCT.md` existe y su actualización del 14/10 autoriza documentos y contacto WhatsApp, posterga cursos/noticias y excluye notificaciones automáticas. DESIGN.md y su sidecar existen y describen las identidades observadas. Conservan prohibiciones históricas de WhatsApp/cargas anteriores al nuevo alcance; la autorización actual y el contrato funcional tienen precedencia, sin reparar esa deriva como efecto de esta revisión. Contrato: `docs/audits/2026-10-14-booking-extensions-contract.md`.

Todas las capturas requeridas existen y fueron abiertas, con dimensiones y contenido coherentes. `weekly-controls-mobile.png` muestra completos los dos bloques sin navegación superpuesta. Las capturas de agenda de 7.810/8.732 px se leyeron mediante recortes originales; Natalia se evaluó sólo en `natalia-contact-*`, no desde sus capturas gigantes. Las barras fijas de las páginas completas corresponden a la navegación incumbente.

`detector.json` contiene `[]`. `results.json` y `natalia-results.json` registran 13 y 5 casos locales sin errores ni solicitudes externas inesperadas. Alcance declarado: PostgreSQL/PostgREST/Storage reales aislados, Auth simulado y adaptación CSP/CORS a loopback; no certifica publicación, Auth real ni producción.

## fidelity

| Elemento o promesa | Estado | Evidencia |
| --- | --- | --- |
| TYPE | match | Tipografía operativa Cita incumbente; público Newsreader/Hanken y jerarquía editorial. BookingAppearance y capturas de información/contacto. |
| MATERIAL | match | Superficies, bordes y profundidad incumbentes; sin nuevos materiales simulados ni activos decorativos que sustituyan contenido. |
| GROUND | match | Privado oscuro/púrpura; público papel/tinta/terracota y variante oscura marrón; coinciden con DESIGN.md y BookingAppearance. |
| THESIS | match | Arancel por fecha antes del horario; reserva conserva precio/indicaciones; datos y documentos posteriores separados. `booking-*`, `receipt-mobile`, `information-*`; PublicBookingFlow:720-725,810 y recibo local. |
| OWN-WORLD | match | Se conservan las dos identidades; WhatsApp utiliza la variante crema del cierre terracota. `natalia-contact-*`; public.ts:96. |
| STORY | match | Prestación/fecha/arancel/horario/datos/reserva y posterior información/documentos. La semana identifica la prestación restringida. Capturas y fuentes de reserva, agenda e información. |
| FIRST VIEWPORT | adaptation | Se conserva navegación y ayuda incumbente por instrucción expresa de extender sin rediseñar. Título, propósito y contexto siguen visibles. |
| FORM: importes y acciones | match | Pesos completos, sin centavos, en 1440/390/320; cifras tabulares y nowrap. Quitar/Eliminar íntegros. PricePolicyEditor:162,168-170; `price-*`, `schedule-*`. |
| FORM: mes/año a 320 | contradicted | El pase completo mostró el último dígito de «noviembre de 2026» tapado por el icono en «Primer mes con ajuste». Recorte original conservado: `/tmp/cita-extensions-qa/reviewer-crops/price-month-320.png`; PricePolicyEditor:148,170 en esa revisión. |
| FORM: estados y recuperación | match | Límites 5 MB, 3 documentos/10 MB y 700 MB explicados; guardado, carga, error, éxito, deshabilitado y ausencia de JS con mensajes humanos. PatientDocumentUpload:108-119; `settings-error-mobile`, `information-nojs-mobile`. Recibo local confirma borradores e historia. |
| Seguimiento y fechas separadas | match | Bloques por prestación, control Fechas separadas y dos bloqueos no consecutivos. `weekly-controls-mobile`, `schedule-*`; ruta profesional:1322,1504-1508,1565-1568 y disponibilidad local registrada. |
| PDF profesional/paciente | adaptation | PDF sin miniatura ni apertura automática es decisión del contrato:17-18. Ficha con procedencia, tipo/tamaño y Descargar PDF. `patient-documents-mobile`; RadiographsPanel:333,436,631-663. No se infiere autorización de producción. |
| Contacto y verdad | match | Enlaces wa.me, fixtures reconocibles, datos no confirmados marcados pendientes y contacto independiente del catálogo. `contact-*`, `natalia-contact-*`; public.ts:76-96,101-123 y recibo Natalia. |

## ceiling

El acabado conserva el techo de esta extensión operativa: jerarquía legible, etiquetas explícitas, foco/selección/caret/scrollbar heredados del adaptador público, cifras tabulares y reflujo de controles. Los estados no dependen sólo del color. Craft floor: sin nuevos kickers, glyph icons, halos decorativos, sombras duras o materiales fingidos dentro de las extensiones; rótulos y contenedores incumbentes se conservan por la dirección autorizada. No corresponde añadir efectos u ornamento a estos formularios. El techo no se alcanza aún en la integridad visible del mes/año a 320 px. Contraste y foco se evaluaron en fuentes/capturas, sin certificar una matriz computada ni interacción de teclado real.

## material_fixes

1. FORM/craft floor, texto real en cada ancho: asegurar mes y año íntegros en «Primer mes con ajuste» a 320 px, sin que el icono tape el último dígito (PricePolicyEditor:148,170 y recorte original citado). Reducir espacio horizontal o presentar además el valor completo mediante texto asociado; mantener input nativo e identidad. Aplicar coherentemente a los meses de excepciones. Verificar sólo price-320 con noviembre de 2026 completo y un mes largo como septiembre, conservando importes íntegros y comparación de 390; sin repetir detector ni una suite funcional completa por este ajuste visual.

## keep

Conservar ambas identidades, pesos enteros/snapshots, borradores, cuestionarios/historia, privacidad/límites/procedencia de documentos, bloques por prestación y contacto independiente; sin notificaciones WhatsApp, cambios a noticias/cursos ni fixtures convertidas en datos reales.
