# Traspaso de la campaña de modo claro

> **Nota del 2 de noviembre de 2026:** las instrucciones de este documento de preservar el `HEAD` `80268e2` y el índice `55cd8f79…` quedaron superadas. Esa regla dejó divergir la copia local de GitHub y de producción. Ahora la rama de trabajo es `main`, que contiene la historia completa. El estado vigente está en [el registro único](../ESTADO-VIGENTE.md) y se comprueba con `node scripts/check-repo-sync.mjs`.

**Fuente de verdad:** [plan aprobado](modo-claro-20261102.md). Registro: [registro-modo-claro-20261102.md](registro-modo-claro-20261102.md). Evidencia: `.verification/modo-claro-20261102/`.

## Punto exacto (2 de noviembre, 15:40 UTC): V12b publicada y comprobada; no queda trabajo en curso

- **Producción sirve V12b** `771fac5950c532b1123f11d4dde93eef9b42ceba`, Worker `app`, versión `277d332d-1794-4367-8ef0-567ced159f1b`.
  - Es el modo claro de V12 con el fondo general apenas más cálido (`#f6f5f3`), a pedido de Juan (plan, 12.5).
  - Verificación completa en el registro, E9: CI 64 de 64, producción verificada, y Natalia y el oscuro idénticos.
- **Auditoría C1 a C13** (registro, E8): sigue valiendo. V12b cambia sólo el valor claro de `--bg`, verificado por las guardias, por el recorrido completo y en producción.
- **Puntero de la fuente** en V12b.
- **Vuelta atrás:**
  - a V12: `wrangler rollback f18a80f2-fd65-4ffc-b92f-fc0101d4f85f`;
  - a antes del modo claro: `986cf666-ae09-423b-ae05-1928007dccde`;
  - nunca `59f81e89…`.
- **Pendiente anotado** (anterior a la campaña): la insignia cortada del botón de cuenta (`pendientes-vigentes.md`, sección 4).

## Si hay que retomar algo

- **Cambiar colores:** sólo en `apps/web/src/lib/theme/palette.js`, con las guardias `scripts/lib/theme-colors.test.mjs` y `theme-palette.test.mjs` (desde la raíz del repositorio) y el recorrido `e2e/theme-modes.spec.ts` en CI.
- **Resumir un navegador de CI:** `python3 -I .verification/modo-claro-20261102/extraer-recorrido.py <evidencia reconstruida>`.

## Cómo retomar (comandos exactos)

- **Base de las candidatas:** V11f `72d59ab00db67a8502ca560c762c61e6cfac1923`.
- **Armar una candidata** desde la raíz del repositorio:
  - `c=$(bash .verification/senas-avisos-20261029/build.sh 72d59ab00db67a8502ca560c762c61e6cfac1923 "<mensaje>" <archivos...>)`;
  - después comprobar `[[ "$c" =~ ^[0-9a-f]{40}$ ]]`, porque una subida con origen vacío borra la rama remota.
- **Subir:** `git push github-secundaria:Juan4787/cita-suite-verificacion.git "$c:refs/heads/verify/modo-claro-<n>"`.
- **Encolar CI:** copiar `.verification/ayuda-duraciones-20261101/cola-ci.sh` a la carpeta de esta campaña, ajustando su variable `D`. La fase `a` corre tipos, SQL y `fast`; la fase `b`, el paquete y el navegador.
- **Pruebas locales, una por vez, desde `apps/web`:**
  - servidor: `NODE_OPTIONS=--max-old-space-size=640 pnpm exec vitest run <archivo>`;
  - componentes: `NODE_OPTIONS=--max-old-space-size=768 pnpm exec vitest run --config vitest.client.config.ts <archivo>`.
- **Guardias de programas,** desde la raíz: `node --test scripts/lib/<archivo>.test.mjs`.

## Reglas vigentes de esta campaña

- No tocar el `HEAD` (`80268e2`) ni el índice (`55cd8f79…`). Toda lectura de git usa `GIT_OPTIONAL_LOCKS=0`.
- Nada de datos personales en candidatas: el repositorio auxiliar es público.
- La cuenta, el consultorio y la configuración de Natalia no se tocan. Su reserva debe verse igual.
- Publicar en producción está autorizado (plan, sección 3). Se mantienen CI sobre la candidata exacta, la comprobación del destino y la vuelta atrás a `986cf666…`.
