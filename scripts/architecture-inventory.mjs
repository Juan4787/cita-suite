import { readdirSync, readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

export const repositoryRoot = fileURLToPath(new URL('../', import.meta.url)).replace(/\/$/, '');
const areas = ['apps/web/src', 'apps/natalia/src', 'packages/shared/src', 'supabase/migrations', 'supabase/tests', 'scripts'];
const extensions = /\.(?:ts|svelte|js|mjs|sql|astro|css|sh)$/;
const configurations = ['package.json', 'pnpm-lock.yaml', 'pnpm-workspace.yaml', 'tsconfig.base.json', 'apps/web/package.json', 'apps/web/vite.config.ts', 'apps/web/vitest.client.config.ts', 'apps/web/playwright.config.ts', 'apps/web/svelte.config.js', 'apps/web/wrangler.jsonc', 'apps/natalia/package.json', 'apps/natalia/astro.config.mjs', 'supabase/config.toml'];

function walk(folder) {
  return readdirSync(resolve(repositoryRoot, folder), { withFileTypes: true }).flatMap(entry => {
    const path = `${folder}/${entry.name}`;
    if (entry.isSymbolicLink()) return [];
    if (entry.isDirectory()) return walk(path);
    return extensions.test(path) ? [path] : [];
  });
}

function routeDomain(route) {
  if (route.startsWith('/administrativo')) return 'legacy-administration';
  if (/^\/(?:api\/whatsapp|odonto\/(?:mensajes|configuracion\/whatsapp))/.test(route)) return 'legacy-messaging';
  if (/^\/(?:internal\/jobs|turno\/.*\/(?:push|calendario|ir)|api\/google|oauth\/google-calendar|r\/|odonto\/(?:recordatorios|configuracion\/(?:resena-google|comunicacion)))/.test(route)) return 'integrations-and-jobs';
  if (/^\/(?:api\/mercadopago|odonto\/configuracion\/(?:suscripcion|usuarios|ayuda)|odonto\/(?:maestro|pendiente|pago)|login|register|auth|logout|reset)/.test(route)) return 'access-and-subscriptions';
  if (route.includes('/pacientes') || route.includes('/exportaciones') || route.includes('/exportar-datos')) return 'patients-and-clinical';
  if (/^\/odonto\/(?:profesionales|servicios)/.test(route)) return 'team-and-services';
  if (route.includes('/reserva-online') || route.includes('/api/public/contacto')) return 'public-configuration';
  if (route.includes('/mis-preguntas')) return 'questionnaires';
  if (/^\/(?:reservar|embed|turno|confirmar|cancelar|reprogramar|api\/public\/reservas|odonto\/(?:agenda|turnos|mis-turnos|seguimientos|disponibilidad))/.test(route)) return 'booking-and-agenda';
  if (route.startsWith('/odonto/configuracion')) return 'practice-settings';
  if (['/', '/odonto', '/privacidad', '/terminos'].includes(route)) return 'shell-and-legal';
  return 'needs-review';
}

export function collectArchitectureInventory() {
  const paths = [...new Set([...areas.flatMap(walk), ...configurations])].sort();
  const digest = createHash('sha256');
  const files = paths.map(path => {
    const bytes = readFileSync(resolve(repositoryRoot, path));
    const source = bytes.toString('utf8');
    const sha256 = createHash('sha256').update(bytes).digest('hex');
    digest.update(`${path}\0${sha256}\n`);
    return { path, sha256, lines: source.split(/\r?\n/).length - Number(source.endsWith('\n')), bytes: bytes.length,
      test: /(?:\.test\.|\.spec\.|\/tests\/|\/(?:test-|qa-))/.test(path),
      generated: path.endsWith('/database.types.ts'),
      anySites: (source.match(/\bas\s+any\b|:\s*any\b/g) ?? []).length };
  });
  const routes = files.filter(file => /apps\/web\/src\/routes\/.*\+(?:page|layout|server)(?:\.server)?\.(?:ts|svelte)$/.test(file.path)).map(file => {
    const route = file.path.replace('apps/web/src/routes', '').replace(/\/\+[^/]+$/, '') || '/';
    const source = readFileSync(resolve(repositoryRoot, file.path), 'utf8');
    return { route, file: file.path, domain: routeDomain(route),
      kind: file.path.split('/').pop(),
      explicitContextReferences: [...new Set(source.match(/\b(?:getOdontoContext|resolveActiveBusiness|assertInternalJobRequest|assertClinicalFile\w+|resolveBookingIntegrationRequest)\b/g) ?? [])] };
  });
  const tests = files.filter(file => file.test).map(file => file.path);
  const e2e = readdirSync(resolve(repositoryRoot, 'apps/web/e2e')).filter(file => file.endsWith('.spec.ts')).map(file => `apps/web/e2e/${file}`);
  return {
    schemaVersion: 1,
    gitRevision: execFileSync('git', ['rev-parse', 'HEAD'], { cwd: repositoryRoot, encoding: 'utf8' }).trim(),
    sourceFingerprint: digest.digest('hex'),
    method: 'Source/configuration snapshot, including new phase-one scripts. Counts are not runtime queries, coverage or proof of capacity. Route domains and explicit context references are navigation aids, not authorization audits.',
    areas: areas.map(area => { const rows = files.filter(file => file.path.startsWith(area + '/')); return { path: area, files: rows.length, lines: rows.reduce((n, file) => n + file.lines, 0), testFiles: rows.filter(file => file.test).length }; }),
    routes, e2e, tests, files
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  if (process.argv.length !== 2) throw new Error('This read-only inventory accepts no arguments. Redirect stdout to save the JSON.');
  console.log(JSON.stringify(collectArchitectureInventory(), null, 2));
}
