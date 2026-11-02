#!/usr/bin/env node
// Comprueba que nunca se pierda de vista qué historia y qué cambios están vigentes
// (docs/ESTADO-VIGENTE.md). Uso, desde la raíz: node scripts/check-repo-sync.mjs
// Sale con código 1 si:
// - la rama no es la registrada, o la copia local difiere de GitHub;
// - una rama local o de GitHub queda fuera de la historia sin estar declarada;
// - hay trabajo fuera de Git;
// - la revisión que sirve producción no es la registrada, o no está en la historia de la rama;
// - el código difiere de producción sin estar declarado en el registro.
// Sólo actualiza referencias remotas (git fetch); no modifica HEAD, el índice ni los archivos.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';

const env = { ...process.env, GIT_OPTIONAL_LOCKS: '0' };
const git = (...args) => execFileSync('git', args, { encoding: 'utf8', env, stdio: ['ignore', 'pipe', 'pipe'] }).trim();
const tryGit = (...args) => { try { return git(...args); } catch { return null; } };
const CODE = ['apps', 'packages', 'scripts', 'supabase', 'package.json', 'pnpm-lock.yaml', 'pnpm-workspace.yaml', '.dependency-cruiser.cjs', '.node-version', ':!apps/web/output'];
const problems = [];

const registro = fs.existsSync('docs/ESTADO-VIGENTE.md') ? fs.readFileSync('docs/ESTADO-VIGENTE.md', 'utf8') : '';
const block = (name) => ((registro.match(new RegExp('```' + name + '\\n([\\s\\S]*?)```')) ?? [])[1] ?? '').trim();
const estado = block('estado');
const dato = (key) => (estado.match(new RegExp(`^${key}:\\s*(\\S+)`, 'm')) ?? [])[1];
if (!estado) {
	console.error('REGISTRO: falta docs/ESTADO-VIGENTE.md o su bloque `estado`.');
	process.exit(1);
}

// 1. Rama registrada e igual a GitHub.
const branch = git('branch', '--show-current');
const expectedBranch = dato('rama_de_trabajo');
if (branch !== expectedBranch) problems.push(`RAMA: se trabaja en «${branch}» y el registro dice «${expectedBranch}».`);
if (tryGit('fetch', '--quiet', '--prune', 'origin') === null) problems.push('GITHUB: no se pudo leer el repositorio origin.');
const remote = tryGit('rev-parse', `origin/${expectedBranch}`);
const ahead = remote ? Number(git('rev-list', '--count', `${remote}..HEAD`)) : 0;
const behind = remote ? Number(git('rev-list', '--count', `HEAD..${remote}`)) : 0;
if (ahead && behind) problems.push(`DIVERGENCIA: ${ahead} commits sólo locales y ${behind} sólo en GitHub.`);
else if (ahead) problems.push(`SIN SUBIR: ${ahead} commits locales que GitHub no tiene.`);
else if (behind) problems.push(`ATRASADA: GitHub tiene ${behind} commits que la copia local no tiene.`);

// 2. Ninguna rama, local o de GitHub, fuera de la historia sin estar declarada.
const declaredBranches = block('ramas-fuera-de-main').split('\n').map((line) => line.trim()).filter(Boolean);
const branches = git('for-each-ref', '--format=%(refname)', 'refs/heads', 'refs/remotes/origin').split('\n').filter((ref) => ref && ref !== 'refs/remotes/origin/HEAD');
const outside = new Set();
for (const ref of branches)
	if (tryGit('merge-base', '--is-ancestor', ref, 'HEAD') === null) outside.add(ref.replace(/^refs\/(heads|remotes\/origin)\//, ''));
for (const name of outside) if (!declaredBranches.includes(name)) problems.push(`RAMA SIN DECLARAR: «${name}» no está en la historia de ${branch} ni en el registro.`);
for (const name of declaredBranches) if (!outside.has(name)) problems.push(`REGISTRO VIEJO: «${name}» figura fuera de ${branch}, pero ya está en su historia o no existe.`);

// 3. Nada fuera de Git.
const changes = git('status', '--porcelain').split('\n').filter(Boolean);
if (changes.length) {
	const untracked = changes.filter((line) => line.startsWith('??')).length;
	problems.push(`TRABAJO FUERA DE GIT: ${changes.length - untracked} archivos modificados y ${untracked} sin seguimiento (git status).`);
}

// 4. Producción: la revisión registrada es la servida y está en la historia.
const production = dato('produccion_revision');
if (!tryGit('cat-file', '-e', `${production}^{commit}`)) tryGit('fetch', '--quiet', dato('produccion_repositorio'), production);
if (!tryGit('cat-file', '-e', `${production}^{commit}`)) problems.push(`PRODUCCIÓN: la revisión ${production} no se pudo obtener.`);
else {
	if (tryGit('merge-base', '--is-ancestor', production, 'HEAD') === null)
		problems.push(`PRODUCCIÓN FUERA DE LA HISTORIA: ${production} no es antecesora de ${branch}.`);
	const actual = git('diff', '--name-status', production, 'HEAD', '--', ...CODE);
	const declared = block('codigo-distinto-de-produccion');
	if (actual !== declared)
		problems.push(`CÓDIGO NO DECLARADO: lo que difiere de producción no coincide con el registro.\n  real:\n${actual.replace(/^/gm, '    ')}\n  registrado:\n${declared.replace(/^/gm, '    ')}`);
}
try {
	const served = JSON.parse(execFileSync('curl', ['-s', '--max-time', '15', 'https://app.cita-suite.com.ar/_app/version.json'], { encoding: 'utf8' })).version;
	if (served !== production) problems.push(`PRODUCCIÓN: sirve ${served} y el registro dice ${production}.`);
} catch {
	problems.push('PRODUCCIÓN: no se pudo leer la revisión servida (https://app.cita-suite.com.ar/_app/version.json).');
}

console.log(`rama ${branch} en ${git('rev-parse', '--short', 'HEAD')} | GitHub ${remote?.slice(0, 7) ?? '?'} | producción ${production.slice(0, 7)} | cambios sin commitear ${changes.length}`);
if (!problems.length) {
	console.log('OK: la copia local, GitHub, producción y docs/ESTADO-VIGENTE.md coinciden.');
	process.exit(0);
}
for (const problem of problems) console.error(problem);
console.error('Resolver antes de seguir y dejar el estado en docs/ESTADO-VIGENTE.md.');
process.exit(1);
