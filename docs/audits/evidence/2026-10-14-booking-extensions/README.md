# Evidencia de la extensión del turnero — 14/10/2026

`checks.json` delimita el entorno y las verificaciones aprobadas. `core-browser.json` y
`natalia-browser.json` enumeran los casos reales del entorno aislado. Los datos son sintéticos;
Auth y el transporte loopback están adaptados. La revisión de privilegios de producción fue
sólo lectura y no examinó fichas de pacientes.

`source.sha256` identifica los archivos de implementación y pruebas cambiados. Los manifiestos
`cloudflare-build.sha256` y `natalia-build.sha256`, resumidos en `builds.json`, identifican los
artefactos compilados localmente. No son prueba de un despliegue ni de un hash servido remoto.
La documentación se conserva fuera del manifiesto de fuente para evitar referencias circulares.

`screenshots.sha256` identifica las capturas válidas del directorio
`.impeccable/review/booking-extensions/`; no se copian los PNG grandes a esta carpeta. Se
excluyen las capturas gigantes de homepage que no permiten revisar texto. Los recortes de
componente pueden ocultar navegación fija ajena al componente sólo durante la captura;
las capturas de página completa mantienen esa navegación. `design-detector.json` conserva
el único pase del detector. `full-visual-review.md` conserva la revisión completa y
`visual-fix-verdict.md` la puntuación independiente del único arreglo material como resuelto.

Los comandos secuenciales de reproducción, decisiones, incidentes, riesgos y compatibilidad
están en [el registro de implementación](../../2026-10-14-implementation-ledger.md) y
[el contrato](../../2026-10-14-booking-extensions-contract.md). Las capturas y logs extensos
son evidencia local de esta ejecución; para una auditoría nueva, reconstruir el fixture con
los runners y recapturar la versión bajo revisión. No reutilizar tokens del runtime.

La regresión visual del selector nativo se comprueba también eligiendo septiembre del año
siguiente en «Primer mes con ajuste» sin guardar, a 320 px: deben verse el mes, los cuatro
dígitos del año y el icono. Se conserva `price-long-month-320.png` como prueba complementaria.
Descartar ese borrador antes de seguir con los demás formularios; no alterar una tarifa real
para reproducir un detalle visual.

No hay credenciales, archivos .env, URLs firmadas, tokens ni adjuntos antiguos en este paquete.
