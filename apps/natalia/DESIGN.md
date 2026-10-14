---
name: "Web Natalia"
description: "Migración y extensión del sistema visual incumbente de WEB NATALIA."
colors:
  accent: "#A94B22"
  accent-hover: "#8E3D1A"
  accent-text: "#8E3D1A"
  on-accent: "#FFF8F0"
  accent-soft: "rgba(169, 75, 34, 0.09)"
  paper: "#F3EEE5"
  paper-2: "#EAE2D4"
  paper-3: "#DED2BF"
  card: "#FBF8F2"
  night: "#241E18"
  ink: "#1E1A16"
  ink-2: "#463E36"
  ink-3: "#6B6155"
  line: "rgba(30, 26, 22, 0.13)"
  line-strong: "rgba(30, 26, 22, 0.26)"
  dark-accent: "#E07A4F"
  dark-accent-hover: "#EC9068"
  dark-accent-text: "#EC9068"
  dark-on-accent: "#1A1612"
  dark-accent-soft: "rgba(224, 122, 79, 0.13)"
  dark-paper: "#1A1612"
  dark-paper-2: "#211C17"
  dark-paper-3: "#2B241D"
  dark-card: "#241E19"
  dark-night: "#120F0C"
  dark-ink: "#EFE8DC"
  dark-ink-2: "#CFC5B6"
  dark-ink-3: "#A39888"
  dark-line: "rgba(239, 232, 220, 0.12)"
  dark-line-strong: "rgba(239, 232, 220, 0.24)"
  booking-surface: "#fffaf2"
  booking-dark-surface: "#211c17"
  booking-dark-on-accent: "#1e1a16"
  booking-border-strong: "rgba(30,26,22,.2)"
  booking-dark-border: "rgba(241,234,223,.14)"
typography:
  display:
    fontFamily: "'Newsreader', 'Iowan Old Style', Georgia, serif"
    fontSize: "clamp(2.9rem, 1.6rem + 5.2vw, 6rem)"
    fontWeight: 350
    lineHeight: 0.98
    letterSpacing: "-0.028em"
  headline:
    fontFamily: "'Newsreader', 'Iowan Old Style', Georgia, serif"
    fontSize: "clamp(2.1rem, 1.4rem + 2.8vw, 3.6rem)"
    fontWeight: 400
    lineHeight: 1.08
    letterSpacing: "-0.015em"
  title:
    fontFamily: "'Newsreader', 'Iowan Old Style', Georgia, serif"
    fontSize: "1.35rem"
    fontWeight: 400
    lineHeight: 1.22
    letterSpacing: "-0.015em"
  body:
    fontFamily: "'Hanken Grotesk', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.65
    fontFeature: "\"ss01\", \"kern\""
  lead:
    fontFamily: "'Hanken Grotesk', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "clamp(1.08rem, 1rem + 0.35vw, 1.25rem)"
    lineHeight: 1.6
  label:
    fontFamily: "'Hanken Grotesk', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "0.98rem"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "0.005em"
  navigation:
    fontFamily: "'Hanken Grotesk', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "0.94rem"
    fontWeight: 500
  small:
    fontFamily: "'Hanken Grotesk', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "0.9rem"
  caption:
    fontFamily: "'Hanken Grotesk', system-ui, -apple-system, 'Segoe UI', sans-serif"
    fontSize: "0.8rem"
  booking-title:
    fontFamily: "'Newsreader', Georgia, serif"
    fontSize: "clamp(1.7rem, 2.4vw, 2.5rem)"
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: "-0.01em"
rounded:
  r-s: "6px"
  r-m: "12px"
  r-l: "20px"
  r-pill: "999px"
  arch: "999px 999px 0 0"
  booking-control: "1rem"
  booking-container: "14px"
spacing:
  gutter: "clamp(20px, 5vw, 56px)"
  section-y: "clamp(88px, 11vw, 156px)"
  card-gap: "20px"
  method-gap: "24px"
  button-inline: "24px"
  booking-field: "0.75rem 1rem"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.on-accent}"
    typography: "{typography.label}"
    rounded: "{rounded.r-pill}"
    padding: "0 24px"
    height: "48px"
  button-primary-hover:
    backgroundColor: "{colors.accent-hover}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.r-pill}"
    padding: "0 24px"
    height: "48px"
  button-secondary-hover:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
  signal-card:
    backgroundColor: "{colors.card}"
    textColor: "{colors.ink}"
    rounded: "{rounded.r-m}"
    padding: "24px 28px"
  method-card:
    backgroundColor: "{colors.card}"
    textColor: "{colors.ink}"
    rounded: "{rounded.r-l}"
    padding: "32px 28px"
  navigation:
    textColor: "{colors.ink-2}"
    typography: "{typography.navigation}"
    padding: "8px 12px"
  faq:
    textColor: "{colors.ink}"
    rounded: "{rounded.r-s}"
    padding: "24px 16px"
  booking-input:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.booking-control}"
    padding: "{spacing.booking-field}"
  booking-primary:
    backgroundColor: "{colors.accent-text}"
    textColor: "{colors.on-accent}"
    rounded: "{rounded.booking-control}"
    padding: "0.7rem 1.25rem"
  booking-badge:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.accent-text}"
    rounded: "{rounded.r-pill}"
    padding: "0.4rem 0.8rem"
---

# Design System: Web Natalia

## Overview

**Creative North Star: "Papel, tinta y terracota de WEB NATALIA"**

Este sistema documenta la migración y extensión del mundo incumbente de WEB NATALIA. Conserva sus papeles cálidos, tinta, terracota, pareja Newsreader/Hanken Grotesk, fotografías suministradas y retratos en arco. El nombre de esta guía describe esos materiales ya aprobados; no propone una identidad nueva ni un concepto generado.

La composición combina títulos editoriales, texto legible y aire entre bloques. La superficie pública se entrega con Astro, TypeScript y Tailwind en un artefacto estático. La reserva y la información posterior continúan en el motor de Cita Suite mediante un adaptador visual Natalia; el panel de gestión conserva su propio sistema.

Los valores de esta guía son una extracción del código terminado. La autoridad de ejecución sigue siendo src/styles/public.css y, para los formularios públicos, apps/web/src/lib/booking/BookingAppearance.svelte junto con apps/web/src/app.css. No convierten la maqueta ni las fixtures locales en horarios, prestaciones, precios o datos de contacto confirmados.

**Key Characteristics:**

- Papel y tinta cálidos con variantes claras y oscuras ya implementadas.
- Titulares Newsreader, lectura y controles Hanken Grotesk.
- Fotografía existente, recorte en arco y superficies de baja profundidad.
- Continuidad visual de Natalia en los formularios públicos y separación del panel Cita Suite.

## Colors

La paleta conserva los materiales de WEB NATALIA: papel cálido, tinta legible y terracota. Los valores claros figuran con el nombre del rol; la variante oscura lleva el prefijo `dark-`. Son variantes del mismo sistema, no una segunda identidad. Las referencias de componentes del frontmatter describen la variante clara; en ejecución los mismos custom properties cambian bajo `html.dark`.

### Primary

- **Terracota:** `accent` para acciones; `accent-hover` para interacción y `accent-text` para la cursiva editorial. `on-accent` mantiene la lectura sobre acciones y `accent-soft` el tinte sutil.

### Neutral

- **Papeles cálidos:** `paper`, `paper-2` y `paper-3` estructuran el fondo, bloques alternados y base fotográfica; `card` separa tarjetas. `night` sostiene el cierre oscuro.
- **Tintas:** `ink`, `ink-2` e `ink-3` distinguen títulos, cuerpo y texto auxiliar; `line` y `line-strong` separan sin bordes pesados.
- **Superficies de reserva:** `booking-surface` y `booking-dark-surface` registran el adaptador, cuyo panel no usa exactamente el color `card` de Astro. `booking-dark-on-accent`, `booking-border-strong` y `booking-dark-border` conservan otras diferencias reales del adaptador; no se igualaron por documentación.

**The Continuidad Rule.** Heredar el mundo de WEB NATALIA y aplicar sus variantes por rol; una extensión local no autoriza una identidad nueva.

## Typography

**Display Font:** Newsreader, con Iowan Old Style y Georgia como alternativas en la web pública.

**Body Font:** Hanken Grotesk, con system-ui, -apple-system y Segoe UI como alternativas en la web pública.

**Character:** Newsreader aporta la voz editorial y la cursiva de énfasis; Hanken mantiene la lectura y los controles claros. No se introduce una tercera familia.

### Hierarchy

- **Display:** `display` para el titular principal, con escala fluida y líneas compactas. El titular usa peso (350) y su énfasis cursivo (300), cubiertos por el intervalo variable (300–600) que declaran las fuentes locales; conservan los pesos solicitados por el CSS incumbente.
- **Headline:** `headline` en los títulos de sección; `title` describe los títulos de las tarjetas de enfoque que sí están implementados. El token CSS heredado `fs-h3` no se incorpora: no tiene consumo en esta superficie.
- **Body / Lead:** `body` para la lectura corriente; `lead` para introducciones de mayor escala. Los párrafos principales llegan hasta (36em), el hero hasta (34em) y la introducción de consultas hasta (52ch).
- **Label / Navigation:** `label` corresponde a los botones públicos y `navigation` a enlaces del encabezado. `small` y `caption` recogen lectura auxiliar. No se canoniza el estilo de los eyebrows heredados.
- **Booking title:** `booking-title` conserva la escala del motor compartido con Newsreader y peso (500), sin importar la escala del hero al formulario.

Las fuentes de Astro se sirven localmente en WOFF2, con `font-display: swap` y dos precargas. El adaptador de reserva sigue cargando estas mismas familias desde Google Fonts; la ausencia de solicitudes externas de fuentes sólo describe el artefacto Astro.

**The Pareja Tipográfica Rule.** Usar Newsreader en títulos editoriales y Hanken Grotesk en lectura y controles, conservando las familias y alternativas declaradas.

## Layout

Contenedor centrado con ancho máximo (1240px), margen lateral fluido y separación de secciones definidos por `gutter` y `section-y`. El hero usa columnas proporcionales (6.8fr / 5.2fr); los encabezados de sección (7fr / 5fr). Las tarjetas de señales parten de dos columnas; los momentos del enfoque, de tres. El retrato acompaña el texto, sin convertir las nuevas opciones de agenda en una composición distinta.

La cascada vigente reduce hero, encabezados y bloque sobre la profesional a una columna a (1024px), a pesar de la regla anterior del hero a (900px). La navegación principal pasa a menú en ese mismo límite. A (760px) la cabecera baja de (76px) a (66px) y las acciones principales ocupan el ancho disponible; a (680px) desaparece la reserva pequeña de cabecera y los datos del hero forman una columna. Las señales cambian a una columna a (768px); enfoque y servicios a (900px); el bloque de contraste a (960px); sus columnas a (600px). El contacto tiene su propia regla final a (700px). El menú móvil conserva un inicio fijo de (76px) en el CSS vigente; no se deduce un ajuste que el código no implementa.

La página de enlace alternativo `/turnos` tiene una columna, ancho máximo (760px) y separación vertical (30px). Muestra el estado pendiente cuando no hay integración configurada. Las superficies de reserva conservan la densidad y las unidades rem del motor compartido, cuya raíz tipográfica es (17px).

## Elevation & Depth

La web mezcla separación tonal, líneas suaves y sombras difusas cálidas. Las tarjetas de señales y de enfoque usan `shadow-1`; los retratos usan `shadow-2`. El adaptador reserva aplana sus contenedores, con radio propio, y conserva una sombra terracota para la acción principal. Las sombras oscuras de Astro usan negro, no una nueva familia de color.

### Shadow Vocabulary

Los valores exactos, extraídos del código, viven en `extensions.shadows` del sidecar:

- **shadow-1 / dark-shadow-1:** profundidad baja en tarjetas y etiqueta del retrato.
- **shadow-2 / dark-shadow-2:** profundidad del retrato y hover de tarjeta de señales.
- **header / dark-header:** sombra fija del encabezado.
- **booking-accent / booking-dark-accent:** sombra cálida de la acción principal del adaptador Natalia.

No se incorpora `shadow-3`: la superficie documentada no lo consume.

**The Ámbito de Reserva Rule.** La sombra cálida del botón de reserva se aplica sólo dentro del adaptador Natalia; no reemplaza los tokens del panel Cita Suite.

## Shapes

Controles públicos en píldora (`r-pill`), iconos circulares y tarjetas con curvas suaves (`r-m` / `r-l`). El radio pequeño (`r-s`) se observa en los desplegables. El arco (`arch`) conserva el recorte superior redondo y la base recta de las fotografías; no se sustituye por una forma nueva.

Los campos y botones de reserva conservan `booking-control` del motor compartido; los contenedores del adaptador usan `booking-container`. No se fuerza el radio de la web editorial sobre el formulario operativo. Las fotografías del hero y sobre la profesional mantienen proporciones de recorte (4 / 5.2) y (4 / 5).

## Components

### Buttons

Acciones legibles y de borde continuo. La variante principal pública usa terracota y tinta de contraste; la secundaria parte de fondo transparente y se invierte al hover. Altura mínima normal (48px); pequeñas (38px), grandes (56px). Los paddings laterales son (24px), (16px) y (30px), respectivamente. El estado activo baja (1px), el deshabilitado reduce opacidad (0.45). El foco público final tiene contorno terracota (3px) separado (5px).

El botón de reserva operativa conserva tamaño y padding del motor compartido, invierte el orden principal/hover de terracota respecto de Astro y usa la sombra cálida del adaptador. Su foco tiene contorno (2px) y separación (3px). Es una variante operativa existente, no un reemplazo del botón editorial.

### Cards / Containers

Las señales combinan numeración editorial, fondo de tarjeta, borde suave, `r-m` y padding (24px 28px). Su hover eleva (2px) y pasa a sombra media. Los momentos del enfoque usan `r-l`, padding (32px 28px) y hover de (3px) sin cambiar sombra. Los contenedores de reserva tienen fondo propio, borde contextual y ninguna sombra de tarjeta.

### Inputs / Fields

La web estática no tiene formulario de datos del paciente. Los campos pertenecen al motor compartido: fondo papel, texto contextual, border adaptado, radio `booking-control`, padding `booking-field` y altura mínima (2.75rem). El foco cambia al acento y añade anillo (3px) con `accent-soft`; los campos deshabilitados conservan opacidad (0.55). Etiquetas, obligatoriedad y mensajes describen los campos realmente configurados; ninguna carga de archivos forma parte de esta superficie.

### Chips

El badge operativo de reserva tiene fondo terracota suave, texto de acento y contorno en píldora. Es informativo; no se documenta como un control seleccionable.

### Navigation

Encabezado fijo, marca editorial, enlaces pequeños y subrayado de acento al hover. La regla CSS contempla `aria-current`, pero el script público no calcula automáticamente la sección activa. El menú móvil conserva enlaces y reserva, permite cerrar con Escape y devuelve foco al botón de apertura. El enlace para saltar al contenido aparece al recibir foco. La preferencia de tema se guarda con `nf_theme`; sin preferencia guardada, Astro toma el tema del sistema al inicio.

### Questions

Los desplegables son `details` / `summary` nativos, con divisores finos, título editorial y control circular hecho con CSS. El hover y el estado abierto cambian color y fondo; el padding permanece estable. La transición del summary está limitada a color y fondo, conforme a la corrección F2; las transiciones genéricas heredadas de otros elementos no se promueven a regla del sistema.

### Photography and Motion

Los retratos y la imagen del consultorio proceden de los assets suministrados. Astro usa WebP con tamaños responsivos, dimensiones explícitas y carga diferida bajo el primer bloque. El contenido queda visible por defecto. El titular entra una vez (650ms), desde opacidad (0.7) y desplazamiento (8px); los hovers fotográficos usan transformaciones discretas. La regla final de movimiento reducido desactiva animación, transiciones y scroll suave.

### Booking Continuity

El SDK se carga después de pulsar una reserva configurada y recibe el tema vigente; el `href` sigue disponible sin JavaScript, para apertura alternativa y ante fallo de carga. No hay iframe ni SDK previo a esa intención. El catálogo puede cargarse cerca de su entrada en viewport cuando existe integración; esta petición de datos no debe describirse como carga del SDK.

El comprobante usa el tema guardado con la reserva y el formulario público de información recibe ese tema histórico. En acceso directo, el adaptador Natalia sigue la preferencia del sistema; embebido, recibe claro/oscuro mediante el puente del SDK. Esto distingue identidad guardada (`natalia` / `cita-suite`) de modo claro/oscuro. La identidad histórica no significa que se conserve una elección clara/oscura del navegador de origen.

## Do's and Don'ts

### Do:

- Do conservar la pareja tipográfica, la paleta por roles, el arco y las fotografías existentes.
- Do distinguir la web estática del adaptador de reservas y verificar ambos temas cuando se cambie un componente público.
- Do mantener el contenido visible, el foco reconocible y la reducción de movimiento implementada.
- Do conservar el enlace de reserva alternativo y el estado pendiente mientras falte configuración operativa.

### Don't:

- Don't extender el tema Natalia al panel autenticado de Cita Suite.
- Don't presentar datos de la maqueta o de fixtures como prestaciones, horarios, aranceles o contactos reales.
- Don't incorporar WhatsApp ni superficies de carga de estudios, PDFs o imágenes en esta entrega.
