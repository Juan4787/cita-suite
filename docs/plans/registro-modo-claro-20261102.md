# Registro de la campaña de modo claro (2 de noviembre de 2026)

Plan aprobado: [modo-claro-20261102.md](modo-claro-20261102.md). Traspaso: [traspaso-modo-claro-20261102.md](traspaso-modo-claro-20261102.md). Evidencia: `.verification/modo-claro-20261102/`.

Formato:
- cada entrada lleva la hora en UTC;
- las decisiones propias llevan su fundamento;
- las fallas se conservan, no se borran.

## E0. Documentación y punto de partida

### 04:26 UTC — Estado verificado antes de tocar nada

- **Producción** sirve V11f:
  - revisión `72d59ab00db67a8502ca560c762c61e6cfac1923`;
  - Worker `app`, versión `986cf666-ae09-423b-ae05-1928007dccde`, que es V11f con el cliente nuevo de Google Calendar instalado el 2 de noviembre a las 03:03 UTC.

  Fuente: `traspaso-senas-avisos-natalia.md` y `pendientes-vigentes.md`, sección 4.
- **La carpeta de trabajo es idéntica a V11f en `apps/web`.** Se comparó con un índice temporal, sin tocar el del repositorio, incluyendo los archivos sin rastrear. En `apps`, `packages`, `scripts` y `supabase` sólo difieren:
  - capturas y archivos temporales;
  - `scripts/verify-production-auth-ux.mjs`, un programa nuevo sin rastrear;
  - un salto de línea final en `supabase/templates/recovery.html`.

  Ninguno toca la interfaz.
- **Los «15 archivos en curso» del análisis previo** (medidos contra V10b) son V11, ya publicada. No hay trabajo a medio hacer que se cruce con esta campaña.
- **Repositorio:**
  - `HEAD` `80268e2a501198243996e1bdb0048ce066434727`;
  - índice con SHA-256 `55cd8f7975542b80…` y fecha del 23 de octubre: intactos.
- **Descuido propio, sin consecuencias.** En un comando de lectura se incluyó `git write-tree`, que no hacía falta: escribe un objeto de árbol a partir del índice. Se comprobó que el archivo del índice conserva su huella y su fecha. Desde entonces toda lectura de git usa `GIT_OPTIONAL_LOCKS=0`.
- **Pendientes heredados de V11** (no son de esta campaña; se resuelven al documentar la publicación siguiente):
  - el certificado de la fuente V11f;
  - el puntero `.verification/ci-source.json`, que sigue en V10b;
  - `publicacion-y-reversion.md`, `AGENTS.md` y el README, que todavía nombran a V10b como vigente.

### 04:26 UTC — Hallazgos que condicionan el diseño

1. **La apariencia de Natalia depende de los nombres de clase actuales.** `lib/booking/BookingAppearance.svelte` reescribe colores con selectores como `.booking-natalia .text-white`, `[class*='bg-white/']`, `[class*='bg-[#7c3aed]']` y `[class*='text-[#c4b5fd]']`. Renombrar esas clases sin trasladar sus reglas cambiaría la reserva de la única clienta real. Su ámbito ya redefine `--text`, `--surface`, `--accent`, `--border` y otras: las variables nuevas que usen los componentes de reserva también deben definirse allí (plan, 6.3).
2. **Cinco pruebas de navegador exigen el tema único** (clase `dark` y `color-scheme: dark` aunque el navegador prefiera claro): `patient-structure-ux`, `roles-agenda-regression`, `booking-embed`, `appointment-deposits` y `appointment-slot-releases` (plan, 6.5).
3. **Sólo una variante `dark:` no es de color** (`dark:border`, ancho de borde), y ningún código lee la clase `dark`. El único que la escribe es `app.html`.
4. **La política de privacidad ya menciona las «preferencias de tema»** entre las cookies (`routes/privacidad/+page.svelte`, línea 32). La cookie nueva no exige cambiar textos legales.
5. **No hay páginas pre-renderizadas, y toda página HTML sale con `cache-control: private, no-store`** (`hooks.server.ts`, líneas 242 a 246). La caché no puede servir el modo equivocado.
6. **Referencia del «antes»:** la corrida de navegador 41368132842 de V11f dejó 239 capturas en `.verification/ayuda-duraciones-20261101/ci-41368132842/`, entre ellas la reserva de Natalia en sus dos modos y pantallas de la app en oscuro.
7. **Vocabulario:**
   - 2.862 usos de clases de color, con 361 clases base distintas y 430 contando variantes;
   - casi todas las variantes son `dark:` (591);
   - le siguen `hover:` (131) y `dark:hover:` (51).
8. **Memoria disponible:** 11,9 GB en total y unos 4 GB libres, con 4 núcleos. Las suites y el navegador completo corren en CI; en local, pruebas unitarias de a una y un único servidor en modo demostración.

### 04:26 UTC — Documentos de la campaña

- Plan aprobado, este registro y el traspaso creados.
- Carpeta de evidencia `.verification/modo-claro-20261102/` creada con permiso 700.

## E1. Herramientas, inventario y reemplazo de clases

### 04:35 a 04:50 UTC

- **Inventario** `scripts/lib/theme-colors.mjs` (biblioteca de la prueba guardiana). Medición inicial: 3.004 colores escritos a mano en 84 archivos de `apps/web/src`:
  - 2.844 clases;
  - 148 literales en estilos;
  - 7 en cadenas de código;
  - 4 dentro de imágenes codificadas;
  - 1 variante `dark:` que no es de color.

  Los literales que no son clases se revisaron uno por uno: todos son colores reales, sin falsos positivos.
- **Análisis de pares** (`analizar-pares.mjs`, recibo `analisis-pares-inicial.json`):
  - 2.200 clases que hoy se ven en oscuro, con 314 distintas; 644 de ellas son la mitad `dark:` de un par;
  - 644 mitades claras que no se ven;
  - 67 casos dudosos: pares repartidos entre ramas de una condición.
- **Distancias perceptuales** (`distancias-oscuro.py`): son la base del ajuste 12.1 del plan.
- **Generador** (`generar-variables.mjs`, salida `variables-v4/`):
  - toma la paleta exacta de Tailwind 3.4.19 instalada y las paletas propias `primary` y `neutral`;
  - 295 colores efectivos quedan en 251 variables;
  - ΔE2000 máximo de 2,0 sin contar las excepciones aprobadas;
  - excepciones aplicadas: borde `#1f3554` → `line-strong` (ΔE 3,81, 113 usos), `#152642` → `raised` (2,66, 35 usos), blanco al 45 %, 42 % y 40 % → texto terciario corregido (89 usos).
- **Reemplazo** (`reemplazar-clases.mjs`):
  - el ensayo detectó ediciones superpuestas en `DatePartsInput.svelte` (dos borrados contiguos que reclamaban el mismo espacio); se agregó la unión de borrados y la protección se mantuvo para todo lo demás;
  - aplicado (recibo `reemplazo-aplicado.json`) en 75 archivos: 2.123 clases reemplazadas y 625 mitades claras borradas;
  - quedan sin tocar los 67 casos dudosos y ninguna clase sin equivalencia;
  - inventario después: 237 colores escritos a mano.
- **Copia del código original:** `apps-web-src-antes.tar.gz` (SHA-256 `bc701343fd3a23c51ef7ae3d4fa38adc64a7d3f25a9777bf0a812bbf0addf627`).

## E2 y E3. Base, migración manual, Natalia y pruebas (05:00 a 07:25 UTC)

### Base

- **Paleta única** `apps/web/src/lib/theme/palette.js`: fuente de las clases de Tailwind por utilidad y de las variables CSS.
  - `tailwind.config.js` inyecta las variables en tres bloques: `:root` (claro), `:root.dark` y `:root.theme-system` dentro de `@media (prefers-color-scheme: dark)`.
  - Los dos bloques oscuros son idénticos por construcción: salen de la misma función.
  - Se quitaron las paletas viejas `primary` y `neutral`.
- **Hallazgo 1:** el bloque automático no se generaba. Tailwind descarta una regla de base cuya clase no aparece en el código, y `theme-system` todavía no estaba escrito. Se corrigió con `safelist` para las clases que pone el servidor (`dark`, `theme-system`, `booking-natalia` y `booking-control-menu-natalia`); hipótesis confirmada compilando antes y después.
- **Preferencia** (`apps/web/src/lib/theme/preference.ts`):
  - cookie `cita-theme`, con los valores `light`, `dark` y `system`; cualquier otro valor da claro;
  - `hooks.server.ts` completa los marcadores de `app.html` (`%cita.theme.class%` y `%cita.theme.meta%`) en cada documento;
  - el reemplazo se limita al encabezado de la plantilla, para que un texto escrito por una persona que contenga un marcador no se altere (defecto propio encontrado al escribir la prueba);
  - se eliminó el script que forzaba `dark`.
- **Selector** `ThemeSelector.svelte`:
  - en el menú de cuenta de computadora, como `menuitemradio`;
  - en el menú del celular, como botones de opción nativos en un `fieldset`;
  - en los dos casos son filas, porque en una grilla de tres columnas «Automático» no entraba a 320 px.
- **Página de servicio no disponible:** tiene los dos modos en su estilo constante, así que su resumen criptográfico de seguridad no cambia, y recibe la clase del modo.

### Migración manual

- **Literales de estilo:**
  - `app.css` (50 reemplazos);
  - el panel maestro (33, con 6 variables propias);
  - el formulario del paciente: pasó a la paleta, con la corrección del borde de campo, de 2,85:1 a `#647899`.
- **Casos dudosos:**
  - los 67 se resolvieron a mano;
  - **error propio corregido:** el reemplazo automático había puesto `text-fg` (azul marino en claro) sobre fondos violeta, azul o verde sólidos en 37 cadenas de 16 archivos; pasaron a `text-on-accent`.
- **Pastillas invariables:**
  - tres botones ámbar con texto casi negro quedan ámbar en los dos modos;
  - el botón «Salir» del menú del celular usa el par invertido nuevo `inverse` / `on-inverse`.
- **Visor clínico:** excepción de archivo completo, con motivo. Es autónomo y no usa variables del modo.

### Correcciones del oscuro según el ajuste 12.1

| Caso | Antes | Después |
|---|---|---|
| Textos de ejemplo en campos (17) | gris 500, 3,84:1 | texto terciario, 5,7:1 |
| Valores vacíos de la ficha del paciente (8) y `Timeline` (1, sin uso) | 3,84:1 | 5,7:1 |
| «Archivado» y «Últ. visita» en pacientes | 3,84:1 | 5,7:1 |
| «Cancelar» del alta de paciente | `#383e54`, 1,8:1 | texto secundario |
| «Abrir agenda» | violeta `#7c3aed`, 3,4:1 | texto violeta accesible |
| Separador «o» del ingreso, «(opcional)» y dirección corta en el maestro, «Sin atención», iniciales de días (filtro y calendario), días tomados por otro bloque | blanco al 35 % o 30 %, 3,2 o 2,7:1 | texto terciario |
| Error de los campos de fecha | rojo 600, 3,7:1 | texto de error (más de 12:1) |
| Botones de WhatsApp de la página del turno | esmeralda 500, 2,56:1 | esmeralda 700, 5,48:1; con el puntero, esmeralda 800 |
| Botón verde azulado del aviso comercial, con el puntero | 3,74:1 | 7,6:1 |

**Quedan tenues a propósito** (WCAG exime la decoración y los controles inactivos): los íconos con `aria-hidden` (se agregó `aria-hidden` a 5 chevrones que no lo tenían), los separadores «/», «Equipo de profesionales» con `aria-disabled` y los días pasados deshabilitados.

### Natalia

- Las 144 cadenas que activaban sus reglas en V11f llevan marcas `bk-*` (172 en 8 archivos), verificadas cadena por cadena (`natalia-reglas.mjs` y `natalia-marcas.mjs`).
- Sus reglas apuntan a las marcas, con el mismo orden, especificidad y valores.
- Las variables de la app quedan congeladas en el oscuro dentro de su ámbito, con `:where()` (especificidad 0, así ganan las suyas).

### Pruebas locales (todas de a una)

| Prueba | Resultado |
|---|---|
| `scripts/lib/theme-colors.test.mjs` | 8 de 8. Mutaciones detectadas: `text-white` en un componente, `var(--inexistente)` y una variable sobrante. |
| `scripts/lib/theme-palette.test.mjs` | 9 de 9. Mutaciones detectadas: texto terciario oscuro al 42 % y gris claro en una variable de texto. Encontró el paso del puntero verde azulado (3,74:1). |
| `apps/web/src/lib/theme/preference.test.ts` | 6 de 6 |
| `ThemeSelector.client.test.ts` | 5 de 5. Encontró que la propiedad `meta.media` no existe en todos los entornos; se cambió a `setAttribute`. |
| `auth-unavailable.test.ts` | 3 de 3 |
| `hooks.server.test.ts` | 26 de 26 (4 casos nuevos) |
| `ManualAppointmentWizard`, página del turno interno, página del turno del paciente y confirmación de correo | 9, 21, 50 y 7. Se actualizaron nombres de clase (ámbar → `warning`, esmeralda → `success`, violeta → `accent`) y el campo `themePreference` en los datos de prueba. |
| `svelte-check` | 1.444 archivos, 0 errores y 0 advertencias (`svelte-check-2.txt`). La primera corrida dio 9 errores de tipos propios (JSDoc de la paleta y el campo nuevo en una prueba), corregidos. |

## Revisión visual local y E4 (07:25 a 08:20 UTC)

### Revisión visual local en modo demostración

Un solo servidor de desarrollo en modo demostración (`DEMO_MODE=true`), con las direcciones de Supabase apuntando a `127.0.0.1:1`, como el programa oficial de demo. Programas: `revisar.mjs` y `selector.mjs`, en la carpeta temporal de la sesión.

- **26 rutas en los dos modos, a 1280 y 390 px:**
  - el modo se aplicó en todas: sin cookie, sin clase y esquema claro; con `dark`, clase y esquema oscuros;
  - medidor propio de contraste: en claro, 0 textos bajo el mínimo; en oscuro, 1 («Creado: … • Última actualización» en la ficha, `#7b8aa5`, 4,29:1), corregido al texto terciario según el ajuste 12.1.
- **Limitación del medidor propio:** salta los textos sobre degradados, y por eso mide menos textos en oscuro. Por eso la verificación formal usa axe.
- **Selector, 19 comprobaciones aprobadas:**
  - primer pintado del servidor con cada combinación de cookie y preferencia del dispositivo;
  - el cambio instantáneo;
  - el color de la barra;
  - la cookie de 365 días con `SameSite Lax`;
  - la persistencia al recargar;
  - el modo automático en vivo.
- **Hallazgo de la revisión:** al cambiar de modo, los elementos con transición de color cambiaban en 150 ms y los demás al instante. Se agregó la clase `theme-switching`, que apaga las transiciones durante el cambio (práctica establecida), con prueba de cliente.

### Pruebas de navegador (E4)

- **Contrato del tema único:** de las cinco pruebas señaladas en el plan (6.5), sólo tres lo afirmaban de verdad: `patient-structure-ux`, `roles-agenda-regression` y `booking-embed` (tres bloques).
  - `appointment-deposits` y `appointment-slot-releases` sólo usan el `color_mode` de la apariencia de Natalia, cuyo contrato no cambia; quedan igual.
  - En las tres que cambian, la prueba fija el modo con la cookie, simula la preferencia contraria en el dispositivo y afirma el modo pintado. En `booking-embed`, la reserva de Natalia se prueba con la cookie de la app en el modo contrario y se exige su color de papel exacto (`#f3eee5` en claro y `#1a1612` en oscuro).
- **Prueba nueva** `e2e/theme-modes.spec.ts`:
  1. primer pintado del servidor y páginas públicas con contraste;
  2. selector en los dos menús con persistencia y modo automático en vivo;
  3. recorrido de contraste con axe y de diseño (`layoutIssues`) por 40 rutas de la app y del paciente, en los dos modos, a 390 y 1280 px, con paciente y turno sintéticos propios y limpieza verificada.
- **Ayudante** `e2e/helpers/theme.ts`: evalúa axe por el protocolo del navegador, así la página conserva su política de seguridad.
- **Dependencia nueva de desarrollo:** `axe-core` 4.14.0, exacta, publicada el 5 de octubre de 2026, licencia MPL-2.0. El archivo de bloqueo cambió sólo para agregarla.
- **Local:**
  - primer caso de `theme-modes` aprobado contra el servidor de demostración (28,6 s), con 0 violaciones de contraste en ingreso, recuperación, privacidad y términos, en los dos modos;
  - tipos de las pruebas de navegador (`check:e2e`) sin errores;
  - 188 de 188 guardias de programas.
- **Descuido propio, sin consecuencias:** un `pkill -f "port 5179"` coincidió con su propio comando y lo cortó antes de hacer nada. Se repitió deteniendo el servidor por su número de proceso.

### Documentación de diseño

- **`DESIGN.md`:**
  - el frontmatter `colors` lleva los valores claros y `colors-dark` los oscuros, tomados de la paleta por programa;
  - las reglas «Dos modos», «Variable única» y «Equivalencias» reemplazan a «Tema único»;
  - textos de superficies, campos, elevación y «Do/Don't» actualizados.
- **`.impeccable/design.json`:** se regeneraron sus partes derivadas (40 colores con rampas desde los valores claros, las tres reglas, la huella `e3171acb…`) y la nota de la superficie de reserva online.
- **Documentos históricos:** `revision-ui-estructura.md` y `evidencia-etapa5-estructura.md` reciben una nota fechada que remite al estado actual; no se reescribieron.

### Candidata 1

- **Revisión:** `3e14f8a264a36409467c64bbf1d9f028748921a0`, armada sobre V11f con `build.sh`. Tiene 110 archivos (11 nuevos y 99 modificados, lista en `candidata-1-archivos-estado.txt`), con 3.562 líneas agregadas y 1.935 quitadas.
- **Excluidos a propósito:** `scripts/verify-production-auth-ux.mjs` y `supabase/templates/recovery.html`, que son de otro trabajo; además, capturas y archivos temporales.
- **`HEAD` e índice reales intactos.**
- **Rama** `verify/modo-claro-1` en el repositorio auxiliar.
- **CI:** cola `cola-ci.sh`; fase `a` (sólo `fast`) encolada a las 08:20 UTC.

## E5. Candidatas y CI

### Candidata 1: `fast` falló (corrida 41408482244, 07:46 a 07:49 UTC)

- **Falla:** `src/routes/booking-color-mode.test.ts`, 4 pruebas. La carga del diseño raíz ahora devuelve también `themePreference`, y la prueba exigía exactamente `{ bookingColorMode }`. Su simulación de cookies devolvía el mismo valor para cualquier nombre, por eso en un caso `themePreference` salió `dark`. Las otras 1.657 pruebas de servidor aprobaron.
- **Causa de fondo:** hueco propio de verificación. Se corrió la prueba de los ganchos del servidor pero no la de la carga modificada.
- **Hallazgo sobre CI:** la verificación rápida se detiene en la primera etapa que falla, así que las pruebas de cliente, las guardias y `svelte-check` no corrieron en esa corrida.
- **Corrección:**
  - la simulación distingue el nombre de cada cookie;
  - las afirmaciones esperan el campo nuevo;
  - 6 casos nuevos prueban que el modo de la web (`booking-color-mode`) y el de la app (`cita-theme`) son independientes, y que leer el modo de la app nunca escribe una cookie.
- **Para no repetir vueltas de CI**, antes de la candidata 2 se corrieron en local, de a una y con memoria limitada:
  - la suite completa de servidor: 211 archivos y 1.667 pruebas;
  - la de cliente: 35 archivos y 264 pruebas;
  - `svelte-check`: 0 errores y 0 advertencias;
  - las 188 guardias.

### Cambio agregado antes de la candidata 2

- **Reserva de Natalia sin la barra del navegador del modo de la app.** Antes del modo claro no había etiqueta `theme-color`. Su apariencia (`BookingAppearance.svelte`) quita esas etiquetas mientras está activa y las restituye al salir, como ya hacía con su atributo de modo. `booking-embed` exige que no haya ninguna en su página.

### Candidata 2

- **Revisión:** `e6b0b877eb3367a3b8ec9daedc407331c3f5e912`, sobre V11f, con 111 archivos (lista en `candidata-2-archivos-estado.txt`). Respecto de la candidata 1 cambian `booking-embed.spec.ts`, `BookingAppearance.svelte` y `booking-color-mode.test.ts`.
- **Rama:** `verify/modo-claro-2`. `HEAD` e índice reales intactos.
- **CI:** encadenado `fast` y, si aprueba, paquete más navegador completo (patrón `.`), en segundo plano. Registros: `cola-ci-a-modo-claro-2.log` y `cola-ci-b-modo-claro-2.log`.

## E6. Navegador de la candidata 2 y candidata 3 (08:13 a 13:50 UTC)

### Resultado de la candidata 2

- **Corridas:** `fast` 41409428455 aprobado; paquete 41409874791 aprobado; navegador completo 41410132980 con 3 fallas de 62 pruebas (59 aprobadas).
- **Evidencia:** reconstruida con `scripts/collect-verification-evidence.py` en `ci-41410132980/` (470 archivos). El informe de Playwright está en `runs/79155187-…/diagnostic-…/browser-diagnostic.json`.
- **Fallas:**
  1. `access-recovery-ui.spec.ts:36` esperaba el violeta fijo del tema único (`rgb(124, 58, 237)`). La página ahora es clara por defecto (`rgb(102, 51, 194)`). Era una prueba vieja.
  2. `login-register-ux.spec.ts:23` buscaba la clase `bg-[#7c3aed]`. También era una prueba vieja.
  3. `theme-modes`, recorrido de la app: 34 violaciones de contraste y 82 hallazgos de diseño.

### Diagnóstico del recorrido

- **Contraste (axe):**
  - **Semana de la agenda, los dos modos.** Los días sin turnos llevaban `opacity-70` sobre toda la tarjeta. «turnos» y «Sin turnos.» quedaban en 3,0 y 3,37:1 en oscuro, y en 3,26 y 2,95:1 en claro. En oscuro ya pasaba en V11f.
  - **Miga de pan de «Preguntas al paciente», oscuro: 4,28:1** (`#8b5cf6` sobre `#0b1626`). La regla CSS pintaba texto con `var(--accent)`, que es el violeta de íconos, foco y bordes.
  - **La misma confusión en tres textos que se ponen violetas al pasar el puntero** (Configuración, Reserva online y Webs conectadas): 4,01:1 en oscuro. axe no mide el puntero; los encontró la guardia nueva.
- **Diseño:**
  - **74 de los 82 eran falsos positivos.** Son controles nativos de 1 píxel a propósito: los `select` y las fechas detrás de los controles con estilo (`.ux-native-source`) y las entradas de archivo `.sr-only` que abre un botón. Las demás pruebas del proyecto ya los excluyen; el recorrido nuevo no lo hacía.
  - **Reales, y ya presentes en V11f:**
    - «Ver como paciente» se partía en dos renglones a 390 px: 4 rutas que llevan a la misma pantalla, en los dos modos;
    - un «·» quedaba colgado al final del renglón en el historial del profesional: 3 casos en cada modo.
- **Cobertura del criterio C4:**
  - varias rutas redirigen: `consultorio-publico` a Documentos; `comunicacion`, `whatsapp` y `mensajes` a Reserva online; `servicios`, `mis-preguntas`, `disponibilidad` y `profesionales` a Equipo;
  - faltaban rutas: lista de profesionales, pago en proceso, cuenta pendiente, turno reprogramado, confirmación de correo, enlace de recuperación, páginas de error, panel maestro con su almacenamiento y reserva embebida;
  - faltaban los estados que no son rutas: menús y diálogos.
- **Nodos indecisos:** 144 de las 160 pantallas tenían textos que axe no decidía, en su mayoría sobre los degradados suaves de tarjetas y cabeceras. No se contaban como aprobados, pero tampoco se medían.

### Correcciones (criterio del ajuste 12.1, punto 3, y ajuste 12.2)

| Caso | Cambio | Antes | Después |
|---|---|---|---|
| Semana de la agenda, día sin turnos | Sin `opacity-70`: fecha y número en `text-copy-muted`; «turnos» y «Sin turnos.» con sus colores de siempre | oscuro 3,0 y 3,37:1; claro 3,26 y 2,95:1 (axe) | oscuro 5,14 y 5,73:1; claro 6,21 y 5,26:1 (calculado sobre el fondo que midió axe) |
| Miga de pan de «Preguntas al paciente» | `var(--accent)` pasa a `var(--accent-text)` | oscuro 4,28:1 | oscuro 9,83:1; claro 8,63:1 |
| Texto violeta al pasar el puntero (3 reglas) | `var(--accent)` pasa a `var(--accent-text)` | oscuro 4,01:1 | oscuro 9,2:1; claro 9,33:1 |
| Cuenta chica del filtro activo del panel maestro | `--on-accent-muted` oscuro, de blanco al 72 % a blanco al 88 % | 3,70:1 | 4,77:1 (claro sin cambio: 5,55:1) |

- **Diseño, fuera del color** (regla `layoutIssues` del proyecto):
  - **«Ver como paciente»** (`BookingShareLink.svelte`): en celular, el campo ocupa el primer renglón y los dos botones comparten el siguiente mientras entran; si no entran, cada uno toma su renglón. Ninguna etiqueta se parte.
  - **Separadores del historial del profesional:** se unen a lo que sigue con un espacio que no corta (`· ` y `·&nbsp;`), como en el resto de la app.
  - **Ejemplo del campo de dirección** (Negocio): «Av. Santa Fe 1234, Piso 3, Consultorio B, CABA» no entraba a 390 px con el campo vacío. Pasa a ser «Av. Santa Fe 1234, CABA», y la indicación de piso y consultorio va al texto de ayuda («Incluí piso y consultorio si corresponde.»).

### Guardia y medición nuevas

- **`scripts/lib/theme-palette.test.mjs`:**
  - **pares nuevos:** `--option-text`, `--patient-muted` (sobre `--bg` y `--surface`), `--mini-warning-text`, `--mini-danger-text`, `--on-accent-muted`, `--warning-mark` y `--danger-mark-icon`;
  - **guardia nueva:** todo `color:` de CSS lee una variable probada como texto por esos pares, o una `--c-text-*`. Las reglas de Natalia leen su paleta congelada y quedan fuera;
  - **primero falló:** con los cuatro usos de `--accent`, y el par nuevo `--on-accent-muted` con 3,70:1;
  - **después aprobó:** 190 de 190 guardias, con dos pruebas nuevas.
- **`e2e/helpers/theme.ts`, medición del peor caso:** lo que axe deja sin decidir se mide contra cada combinación de paradas de los degradados de sus ancestros, con colores y opacidades compuestos hasta el documento.
  - El mínimo es 4,5:1, o 3:1 en texto grande.
  - El fondo de un `select` o de una entrada es su flecha o su calendario, no el fondo del texto.
  - Lo que no se puede medir, como un texto sobre una imagen, queda como indeciso, nunca aprobado.
  - Con `scope`, mide sólo un diálogo o un menú abierto, cuyo fondo tapa la página a propósito.
- **`e2e/theme-modes.spec.ts`:**
  - **prueba sintética nueva:** demuestra que la medición detecta un texto ilegible sobre un degradado y otro dentro de un contenedor tenue, que decide el `select` con flecha y que deja sin decidir sólo el texto sobre una imagen;
  - **controles medidos:** los mismos selectores que las demás pruebas, sin `.ux-native-source` ni `.sr-only`, y con `.ux-control-trigger`;
  - **rutas nuevas:** las que faltaban;
  - **estados nuevos:**
    - menú de cuenta, en computadora y celular;
    - menú de Configuración, en computadora;
    - asistente de turno nuevo;
    - alta rápida de paciente;
    - dirección vacía en Negocio, que exige un campo editable;
  - **panel maestro:** con el usuario maestro sintético de CI;
  - **nueva exigencia:** todo texto queda decidido, por axe o por el peor caso. La única excepción son los campos vacíos.

### Verificación local

Se usó un único servidor en modo demostración, con las mismas variables del programa oficial (`run-campaign-demo.mjs`) y el ingreso de demostración. Los programas son `recorrer.mjs` y `peor-caso.mjs`, en la carpeta temporal de la sesión.

- **Recorrido completo:**
  - 194 pantallas y estados: 45 rutas en los dos modos y a 390 y 1280 px, más los estados;
  - el modo correcto en todas;
  - 0 problemas de contraste y 0 de diseño;
  - 5.774 textos aprobados;
  - quedaron 8 indecisos, todos campos vacíos.
- **Ejemplo de dirección cortado:** apareció sólo acá, porque en CI el consultorio de prueba tiene dirección. Se corrigió, y el estado «dirección vacía» lo reproduce ahora en CI.
- **Peor caso,** medido antes de llevarlo al ayudante: 874 nodos, ninguno bajo el mínimo.
  - El más ajustado del oscuro da 4,58:1: texto terciario en la esquina violeta de una tarjeta dentro de otra.
  - El más ajustado del claro da 5,51:1.
- **`theme-modes`:** la prueba sintética y la de páginas públicas, con sus tres rutas nuevas, aprobaron en 33,6 s.
- **Suites, de a una:**
  - servidor 1.667 de 1.667;
  - cliente 264 de 264;
  - `svelte-check` sin errores ni advertencias en 1.443 archivos;
  - `check:e2e` sin errores;
  - 190 guardias.

  Salidas en `servidor-completo-local-2.txt`, `cliente-completo-local-2.txt`, `svelte-check-4.txt` y `check-e2e-4.txt`.
- **Límites del modo demostración:**
  - la agenda no permite crear turnos;
  - varias pantallas de configuración y del profesional dan 500, porque no hay base de datos;
  - todo eso lo cubre CI.

### Teclado del selector (criterio C3)

La prueba de CI opera el selector con clics. Para tener evidencia real del teclado sin cambiar la candidata en curso, se comprobó en Chromium contra el servidor de demostración, con el código de la candidata 3. Programa `teclado.mjs`; resultados y capturas en `.verification/modo-claro-20261102/teclado/`.

- **Resultado:** 14 de 14 comprobaciones aprobadas.
- **Computadora:**
  - el menú de la cuenta se abre con Enter;
  - Tab llega a «Oscuro», con foco visible (contorno de 2 px);
  - Enter lo aplica al instante, marca la opción y guarda la cookie;
  - Espacio sobre la opción elegida no cambia nada;
  - Tab pasa a «Automático», que con Enter sigue al dispositivo;
  - al recargar, se mantiene.
- **Celular:**
  - la hoja se abre con Enter;
  - Tab entra al grupo «Modo de color» en la opción elegida, con contorno de foco;
  - las flechas eligen «Oscuro» y después «Claro», y cada cambio se aplica al instante y se guarda;
  - al recargar, se mantiene.

### Descuidos propios, sin consecuencias

- **El traspaso decía 09:10 UTC,** cuando eran las 08:30. Se corrigió con la hora real (`date -u`).
- **`git diff` contra V11f mostró como borrados** archivos que existen. El índice del repositorio está en una revisión vieja que no se toca. La lista se recalculó comparando por huella cada archivo con el árbol de V11f.
- **Al detener el servidor de demostración por su comando,** el proceso de Vite quedó vivo y escuchando. Se identificó por su hora de inicio (era el de esta revisión, con el código actual) y se detuvo por su número de proceso.

### Candidata 3

- **Revisión:** `3003721df664c96211d6b4ce4b1c4be3ce0fee8e`, rama `verify/modo-claro-3`, 113 archivos: los 111 de la candidata 2, con su contenido nuevo, más las dos pruebas viejas. Lista en `candidata-3-archivos-estado.txt`.
  - Se comprobó por huella contra V11f. Lo demás que difiere es documentación o trabajo ajeno a la campaña (`verify-production-auth-ux.mjs`, `recovery.html` y `production-auth-ux.yml`), como en las candidatas anteriores.
  - `HEAD` (`80268e2`) e índice (`55cd8f79…`) intactos.
- **Datos personales:** el único correo en líneas cambiadas es el contacto de soporte que ya estaba en V11f.
- **CI:** `fast` 41456180177, despachado a las 13:48 UTC. Registros: `cola-ci-a-modo-claro-3.log` y, si aprueba, `cola-ci-b-modo-claro-3.log`.

### Capturas de producción antes de publicar (13:56 UTC)

Programa `capturas-produccion.mjs`, sólo con lecturas públicas. Resultados y capturas en `produccion/antes/`.

- **Qué se capturó:** con V11f en producción, la reserva de Natalia tal como la abre su web (`embed/v1/…`, enlace público de su sitio) en sus dos modos, y el ingreso de la app, a 390 y 1280 px.
- **Hallazgo:**
  - en V11f, el documento de su reserva era el de la app oscura: clase `dark`, esquema oscuro y fondo `#0b1626` detrás de su papel;
  - su papel cubre toda la ventana, así que ese fondo no se ve en las capturas;
  - el fondo sí aparece al estirar la página en el celular, y el esquema decide la barra de desplazamiento de la página;
  - con el claro predeterminado, ese lienzo pasaría a gris claro con esquema claro, aunque ella esté en oscuro.
- **Decisión** (ajuste 12.3 del plan): cuando su página se abre sola, el lienzo y el esquema del documento siguen el modo de ella, con el color de su papel. Dentro de un marco, el lienzo queda como el de la página que la contiene.

### Cambios preparados para la candidata 4

- **`BookingAppearance.svelte`:** marca `data-booking-canvas="natalia"` en el documento, sólo cuando su página se abre sola, y se quita al salir. Con esa marca, el lienzo y el esquema del documento siguen su modo.
  - La marca es propia porque `BookingFrameBridge` también da un modo al documento de cualquier reserva enmarcada. Sin ella, el papel de Natalia habría pintado la de otro consultorio.
- **`BookingAppearance.client.test.ts`:** un caso nuevo y dos afirmaciones más (estándar y enmarcada). Sin el cambio falló 1 de 5; con el cambio aprueban 5 de 5.
- **`booking-embed.spec.ts`:** en su página, con la cookie de la app en el modo contrario, exige el esquema y el lienzo de su modo (`rgb(243, 238, 229)` o `rgb(26, 22, 18)`), en el documento y en el cuerpo.
- **`theme-modes.spec.ts`:**
  - la prueba del selector se hace con teclado, como la verificación local (criterio C3);
  - en las pantallas con la apariencia de Natalia, el recorrido afirma su modo propio y no el de la app.
- **Local:**
  - `svelte-check` sin errores ni advertencias (`svelte-check-5.txt`);
  - cliente 265 de 265 (`cliente-completo-local-3.txt`);
  - guardias de color 19 de 19;
  - `check:e2e` sin errores.

## E7. Navegador de la candidata 3, candidatas 4 y 5 (14:06 a 14:20 UTC)

### Resultado de la candidata 3

- **Corridas:**
  - `fast` 41456180177 aprobado;
  - paquete 41456794263 aprobado;
  - navegador completo 41457112805 con 62 pruebas aprobadas y 2 fallas.
- **Evidencia:** `ci-41457112805/` (538 archivos, SHA-256 `1473bd34…`). Resumen con `extraer-recorrido.py` en `recorrido-resumen-41457112805.json`.
- **Recorrido completo, aprobado:**

  | Recorrido | Pantallas y estados | Textos aprobados | Medidos por peor caso | Contraste | Diseño | Sin decidir |
  |---|---|---|---|---|---|---|
  | Públicas | 28 | 1.860 | 72 | 0 | 0 | 8 campos vacíos |
  | App | 206 | 5.126 | 1.965 | 0 | 0 | 46 campos vacíos |
  | Panel maestro | 8 | 202 | 134 | 0 | 2 | 2 campos vacíos |

- **Falla 1:** `login-register-ux.spec.ts:48`. La clase vieja aparecía dos veces en ese archivo y la candidata 3 corrigió sólo la primera.
  - **Causa de fondo:** no se recorrió el archivo entero.
  - **Ahora:** se buscaron en todas las pruebas de navegador los colores y clases del tema único; quedaba sólo esa.
- **Falla 2:** en el panel maestro, a 390 px, el ejemplo «Buscar por consultorio o email…» quedaba cortado (259 px en 245) en los dos modos.
  - Es un defecto anterior, que apareció porque el recorrido ahora incluye el panel.
  - Pasa a «Consultorio o email…». El buscador tiene lupa y una etiqueta para lectores de pantalla.

### Candidata 4

- **Revisión:** `e7106d5e1b921c43667daa072cd632a3cc73d82f` (rama `verify/modo-claro-4`), 114 archivos.
- **Cambios respecto de la 3** (6 archivos):
  - el lienzo de Natalia (ajuste 12.3);
  - el selector por teclado en la prueba;
  - la afirmación del modo de Natalia en el recorrido;
  - la segunda afirmación de la prueba de ingreso;
  - el buscador del maestro.
- **CI:** `fast` 41459234761 aprobado; paquete 41459739316 aprobado; navegador 41460085937 en curso.

### Comparación de capturas con V11f (evidencia de la candidata 3)

Programa `comparar-capturas.py` contra la corrida 41368132842 de V11f. Resultados y capturas lado a lado en `comparacion-c3/`.

- **Reserva de Natalia, en sus dos modos y en cinco anchos** (`booking-embed`): diferencia media de 0 a 3,6 sobre 255 y los mismos colores dominantes. Es idéntica.
  - Las únicas diferencias mayores son de contenido: la hora del turno sintético y la tarjeta «Tu turno es pronto», que depende de la hora de la corrida.
- **Pantallas oscuras** (ficha del paciente en sus roles y anchos, equipo, agenda, asistente de equipo): diferencia media de 0,3 a 4,4, con casi los mismos colores dominantes.
- **Capturas con «light» en el nombre:** en V11f eran oscuras, porque la app era siempre oscura. Ahora son claras a propósito.
- **Hallazgo: las barras fijas.** A través de la barra superior se leía más el contenido de atrás.
  - La barra superior y la inferior del celular eran 95 % opacas en V11f y quedaron en 70 %, por la unificación con `[#13243d]/70` (ajuste 12.4).
  - Se compararon con V11f los 208 usos de fondos translúcidos y sólo esas dos capas cambiaban de forma visible. Detalle en el ajuste.
  - **Corrección:** variables propias `--c-bg-fill-0f1f36-95` y `--c-bg-fill-0b1d32-95`, exactas en oscuro y blanco al 95 % en claro. La prueba del selector exige los valores calculados en los dos modos.
  - **Local:** las cuatro combinaciones de modo y ancho dan el valor exacto con contenido desplazado por detrás (`barras/`).
- **Hallazgo anterior a la campaña, anotado como pendiente:** con el nombre del consultorio de demostración y seis secciones, la insignia «Permanente» del botón de cuenta queda cortada a 1280 px.
  - Fuera de los colores, las clases del diseño principal son idénticas a las de V11f, salvo los dos contenedores del selector. Por eso no lo causa esta campaña.
  - Queda en `pendientes-vigentes.md`.

### Candidata 5

- **Revisión:** `c21a19839c814a8a5f476cb522a13273a10f89c4` (rama `verify/modo-claro-5`), con la misma lista de 114 archivos.
- **Cambios respecto de la 4:** sólo la paleta, el diseño principal y la prueba de modos (3 archivos).
- **Local:**
  - guardias 190 de 190, corridas desde la raíz;
  - `svelte-check` sin errores ni advertencias (`svelte-check-7.txt`);
  - `check:e2e` sin errores.
- **Descuido propio, sin consecuencias:** una corrida de las guardias desde `apps/web` dio 17 fallas, porque leen las rutas desde la raíz. Desde la raíz aprueban todas.
- **CI:** encolada detrás del navegador de la candidata 4. Registros: `cola-ci-a-modo-claro-5.log` y `cola-ci-b-modo-claro-5.log`.

## E8. Candidata 5 y publicación de V12 (14:25 a 14:53 UTC)

### Candidata 4 en el navegador

- **Navegador completo 41460085937:** 64 de 64.
  - Incluye el selector por teclado, el lienzo de Natalia en sus dos modos y el panel maestro.
  - El recorrido quedó sin problemas de contraste ni de diseño.
- **Evidencia:** `ci-41460085937/`, SHA-256 `f657e642…`.

### Candidata 5, la publicada

- **Revisión:** `c21a19839c814a8a5f476cb522a13273a10f89c4`.
- **CI sobre la revisión exacta:**
  - `fast` 41460642336 aprobado;
  - paquete 41462444575 aprobado;
  - navegador completo sobre ese paquete 41462806211: 64 de 64 (evidencia `ci-41462806211/`, SHA-256 `b756531d…`).
- **Recorrido:**
  - públicas: 28 pantallas;
  - app: 206 pantallas y estados;
  - panel maestro: 8.

  En los tres, 0 problemas de contraste y 0 de diseño. Sin decidir quedaron sólo los campos vacíos.
- **Comparación con V11f** (`comparacion-c5/`): en la ficha oscura, la diferencia media bajó con las barras corregidas (de 0,1 a 3,4 sobre 255). Lado a lado, la barra superior se ve igual que en V11f.
- **Paquete bajado** a `release-candidate-v12/`: 229 archivos, con `version.json` en la revisión exacta.

### Publicación

- **Comando:** `NODE_OPTIONS=--max-old-space-size=192 node scripts/deploy-production-workers.mjs app .verification/modo-claro-20261102/release-candidate-v12/cloudflare-staging-c21a1983…`.
  - De 14:45:20 a 14:45:57 UTC.
  - El Worker `app` sirve la versión **`f18a80f2-fd65-4ffc-b92f-fc0101d4f85f`** (`despliegue-v12.log`).
- **`verify-production-release.mjs`:** aprobado a las 14:46:24 UTC (`verificacion-produccion-v12.log`).
  - 140 archivos del cliente idénticos al paquete;
  - política de contenido con el proyecto de producción;
  - HTTPS en los dos orígenes;
  - 0 de 74 relaciones expuestas sin sesión.
- **Revisión servida:** los dos `/_app/version.json` dicen `c21a19839c814a8a5f476cb522a13273a10f89c4`.
- **Primer pintado del servidor en producción** (`produccion-modo-servidor.txt`), en los dos orígenes:

  | Cookie | Resultado |
  |---|---|
  | ninguna, `light` o un valor inválido | `class=""`, con la barra `#f5f6f8` |
  | `dark` | `class="dark"`, con `#0b1626` |
  | `system` | `class="theme-system"`, con las dos etiquetas de barra según el dispositivo |

  No queda ningún marcador sin reemplazar.
- **Capturas de producción después de publicar** (`produccion/despues/`, comparadas con `produccion/antes/`):
  - **Reserva de Natalia, en sus dos modos y a 390 y 1280 px:** diferencia media de 0,0 a 0,1 sobre 255 y colores dominantes idénticos. Vale sin cookie de la app y con la app en oscuro o en claro.
    - Su lienzo y su esquema siguen el modo de ella, y no hay etiquetas de barra.
  - **Ingreso:** claro por defecto (`#f5f6f8`). Con la app en oscuro, se compara contra V11f:
    - diferencia de 2,8 a 3,7;
    - las únicas diferencias son correcciones aprobadas: borde de los campos a 3:1, textos de ejemplo y separador «o» legibles.
- **Puntero de la fuente:**
  - `certify-source-v12.mjs` (adaptado del de V10b) verificó que los 1.172 archivos de ejecución de la revisión coinciden con los locales, sobre un árbol de 1.233 archivos;
  - recibo en `ci-source-v12.json`;
  - `.verification/ci-source.json` apunta a V12;
  - el puntero anterior, que seguía en V10b porque el de V11f no se había movido, quedó en `ci-source-anterior-v10b.json`.
- **`HEAD` e índice reales:** intactos (`80268e2` y `55cd8f79…`).

### Visor clínico (criterio C8)

- **El archivo es idéntico al de V11f.** No lee variables del tema ni usa clases que cambien con el modo, y tiene su propio contorno de foco (cian).
- **No tiene controles nativos** ni zonas con desplazamiento propio que dependan del esquema del documento.
- **Sus clases de Tailwind** (`text-white`, `text-slate-300`, `text-slate-400` y `text-cyan-200/80`) existen en el CSS publicado.
- **En CI:** la prueba `clinical-files` lo abrió con la app en claro (sin cookie) y aprobó.
- **Límite:** en modo demostración el visor no se abre («La vista de imágenes no está disponible en el modo de demostración»), así que no hay captura local suya en claro (`visor/`).
- **PDF, Excel y archivos estáticos (script externo):** sin cambios respecto de V11f. Lo que cambió en la exportación es sólo su pantalla, con clases de color.

## Auditoría final contra los criterios del plan (sección 7)

| Criterio | Cumplido | Evidencia |
|---|---|---|
| C1. Claro predeterminado desde el servidor, aunque el navegador prefiera oscuro | Sí | Prueba 1 de `theme-modes` (sin cookie y con el dispositivo en oscuro) en 41462806211; `hooks.server.test.ts`; producción sin cookie: `class=""` |
| C2. `dark` desde el servidor; `system` sigue al dispositivo sin JavaScript y en vivo; valor inválido da claro; sin parpadeo | Sí | Prueba 1 (cinco combinaciones) y prueba 2 (automático en vivo); producción con las cuatro cookies en los dos orígenes |
| C3. Selector accesible en el menú de cuenta, en computadora y celular, con teclado; aplica al instante y persiste | Sí | Prueba 2 por teclado en CI (candidatas 4 y 5); 14 de 14 comprobaciones locales con capturas (`teclado/`); pruebas de componente del selector |
| C4. Toda ruta que el entorno de prueba abre, en claro y en oscuro, sin violaciones de contraste ni problemas de diseño, a 390 y 1280 px | Sí | Recorridos de 41462806211: 242 pantallas y estados (toda ruta con página, más menús, diálogos y campo vacío). 0 violaciones de axe y 0 del peor caso; 0 de `layoutIssues`; sin decidir sólo campos vacíos (ajuste 12.2) |
| C5. Cero colores fijos fuera de las variables y de las excepciones justificadas | Sí | `theme-colors.test.mjs`, con casos adversarios; 190 de 190 guardias |
| C6. El oscuro conserva cada color con ΔE2000 ≤ 2, salvo las excepciones aprobadas | Sí | Generador (`variables-v4/`), excepciones y correcciones listadas (12.1 y 12.2); capas flotantes con opacidad exacta (12.4); capturas de antes y después (`comparacion-c3/`, `comparacion-c5/` y producción) |
| C7. La reserva de Natalia se ve igual en sus dos modos, en computadora y en celular | Sí | CI: diferencia de 0 a 3,6 en cinco anchos, y lo distinto es sólo contenido. Producción: de 0,0 a 0,1 píxel a píxel, con la app en cualquier modo. Su lienzo sigue su modo (12.3) |
| C8. Visor clínico oscuro en los dos modos; PDF, Excel y script externo sin cambios | Sí | Archivos sin cambios respecto de V11f; el visor no depende del modo (E8); `clinical-files` aprobado con la app en claro |
| C9. Pares de la paleta con WCAG 2.2: AA en todo y AAA en el texto principal | Sí | `theme-palette.test.mjs` con los valores reales, más los pares nuevos y la guardia de texto (12.2) |
| C10. Pruebas de contrato actualizadas y pruebas nuevas de la preferencia | Sí | Las tres que afirmaban el tema único (las otras dos no lo hacían, E4), más `access-recovery-ui` y `login-register-ux`; pruebas nuevas de preferencia, selector, ganchos, carga raíz y apariencia de Natalia |
| C11. CI aprobado sobre la candidata exacta; `svelte-check` sin errores ni advertencias | Sí | 41460642336, 41462444575 y 41462806211 sobre `c21a1983…`; `svelte-check-7.txt` (0 y 0) |
| C12. Producción sirve la candidata, verificada en los dos orígenes, con revisión visual de claro y oscuro y vuelta atrás documentada | Sí | `verificacion-produccion-v12.log`, `version.json`, `produccion/` y `publicacion-y-reversion.md` |
| C13. Documentación coherente | Sí | `DESIGN.md` y `.impeccable/design.json` (E4); plan con 12.1 a 12.4; registro; traspaso; `publicacion-y-reversion.md`; `AGENTS.md`; README; índice de documentación; pendientes |

**Lo que queda fuera de la campaña:** la insignia cortada del botón de cuenta, que ya existía antes y está anotada en `pendientes-vigentes.md`.

## E9. Fondo general apenas más cálido: V12b (15:00 UTC en adelante)

**Pedido de Juan después de ver V12** (literal en el plan, 12.5): «el fondo gris general podria ser apenas mas calido o neutro».

### Medición y elección

- **El fondo de V12, `#f5f6f8`,** tiene tono 265° (azulado) y croma 0,0029 en OKLCH.
- **Alternativas medidas** (contraste del texto terciario sobre cada una):

  | Fondo | Tono | Croma | Texto terciario |
  |---|---|---|---|
  | `#f5f6f8` (V12) | 265° | 0,0029 | 4,99:1 |
  | `#f6f5f3` | 85° | 0,0029 | 4,95:1 |
  | `#f5f5f5` | — | 0 | 4,95:1 |
  | `#f7f6f3` | 91° | 0,0041 | 4,99:1 |

- **Comparación en la app,** con las variantes inyectadas como estilo sobre las mismas pantallas, sin tocar el repositorio (`fondos.mjs`):
  - el cálido `#f6f5f3` saca el tinte azulado y combina con los avisos color crema;
  - el neutro puro se ve más plano;
  - neutralizar además los grises internos casi no cambia nada;
  - llevarlos al tono cálido los vuelve beige (`#d8d4cc` en los bordes).

  Recortes a tamaño real en `fondo-calido/`.
- **Elegido:** `#f6f5f3`, la misma intensidad de tinte que antes pero cálida, y sólo para el fondo general.

### Cambio

- **`palette.js`:** `--bg` claro y `themeColor.light`, la barra del navegador, pasan a `#f6f5f3`.
- **Página de servicio no disponible** (`auth-unavailable.ts`): el mismo valor, con su prueba.
- **`theme-modes.spec.ts`:** el color de fondo esperado en claro es `rgb(246, 245, 243)`.
- **`DESIGN.md`:** el frontmatter y los dos textos que describían el fondo.
- **`.impeccable/design.json`:**
  - rampa del fondo recalculada con el método que reproduce exactamente la anterior;
  - huella de `DESIGN.md` y huellas de las 38 fuentes. Había 25 viejas desde las candidatas 3 a 5.

### Comprobaciones locales

- **Pruebas:**
  - guardias 190 de 190, entre ellas los pares de la paleta sobre el fondo nuevo y la igualdad de la barra con el fondo;
  - servicio no disponible, preferencia, ganchos y carga raíz: 46 de 46;
  - selector: 6 de 6;
  - `check:e2e` sin errores;
  - `svelte-check` sin errores ni advertencias (`svelte-check-8.txt`).
- **En el servidor de demostración:** el ingreso sin cookie pinta `rgb(246, 245, 243)` y la barra dice `#f6f5f3`. En oscuro no cambia nada.

### Candidata 6

- **Revisión:** `771fac5950c532b1123f11d4dde93eef9b42ceba` (rama `verify/modo-claro-6`), con la misma lista de 114 archivos.
- **Cambios respecto de V12:** sólo los 6 archivos descriptos, con 44 líneas cambiadas.
- **CI:** encolado con las dos fases (`cola-ci-a-modo-claro-6.log` y `cola-ci-b-modo-claro-6.log`).

### CI y publicación de V12b

- **CI sobre la revisión exacta `771fac59…`:**
  - `fast` 41469851263 aprobado;
  - paquete 41470383141 aprobado (229 archivos, bajado a `release-candidate-v12b/`);
  - navegador completo 41470743564: 64 de 64 (evidencia `ci-41470743564/`, SHA-256 `6792f9ab…`). El recorrido de 242 pantallas y estados quedó sin problemas de contraste ni de diseño; sin decidir, sólo campos vacíos.
- **Publicación:** de 15:33:19 a 15:33:50 UTC, versión **`277d332d-1794-4367-8ef0-567ced159f1b`** (`despliegue-v12b.log`).
- **`verify-production-release.mjs`:** aprobado a las 15:34:05 UTC, con 140 archivos idénticos y 0 de 74 relaciones expuestas (`verificacion-produccion-v12b.log`).
- **Los dos orígenes** sirven `771fac5950c532b1123f11d4dde93eef9b42ceba`.
- **Primer pintado del servidor** en los dos orígenes (`produccion-modo-servidor-v12b.txt`):
  - sin cookie o con un valor inválido: `class=""` y barra `#f6f5f3`;
  - con `dark`: `#0b1626`;
  - con `system`: las dos etiquetas.

  No queda ningún marcador sin reemplazar.
- **Capturas de producción contra V12** (`produccion/despues-v12b/` y `produccion/comparar/v12-v12b-*`):
  - la reserva de Natalia, idéntica en las 12 combinaciones de sus modos, la app y los dos anchos (diferencia de 0,0 a 0,1);
  - el ingreso en oscuro, idéntico;
  - el ingreso en claro: diferencia media de 0,9 a 1,0, sólo por el tinte del fondo (`rgb(246, 245, 243)`).
- **Puntero de la fuente:** `certify-source-v12b.mjs` verificó que los 1.172 archivos de ejecución coinciden con los locales. `.verification/ci-source.json` apunta a V12b y su recibo es `ci-source-v12b.json`.
- **`HEAD` e índice reales:** intactos.
- **Vuelta atrás:** a V12 (`f18a80f2-fd65-4ffc-b92f-fc0101d4f85f`) o a antes del modo claro (`986cf666-ae09-423b-ae05-1928007dccde`), sin pasos de datos.
