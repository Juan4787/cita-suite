import { spawn, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { randomUUID } from 'node:crypto';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, existsSync, openSync, closeSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { collectArchitectureInventory, repositoryRoot as root } from './architecture-inventory.mjs';

if (process.argv.includes('--help')) {
  console.log('pnpm verify:baseline\nSequential local verification: inventory, all type checks, server/component tests, builds, Natalia browser contracts, all SQL contracts and real local native booking. Requires cached Docker fixture images and installed Chromium. No deployment, remote database or paid external API is used. Evidence goes to a private temporary directory.');
  process.exit(0);
}
if (process.argv.length !== 2) throw new Error('No filtering or remote targets are accepted by the full baseline.');
const lock = join(tmpdir(), 'cita-baseline.lock');
try { mkdirSync(lock, { mode: 0o700 }); } catch { throw new Error(`Another baseline owns ${lock}. Do not run verification concurrently.`); }
const output = mkdtempSync(join(tmpdir(), 'cita-baseline-'));
writeFileSync(join(lock, 'owner.json'), JSON.stringify({ pid: process.pid, output }), { mode: 0o600 });
const receipt = { schemaVersion: 1, startedAt: new Date().toISOString(), scope: 'Local fixtures only; full baseline is not a production/load/physical-device certification.', browser: 'No host-managed browser capability exposed; installed Playwright/Chromium used.', stages: [], passed: false };
let active, supervisor, database, signal, baseline, resourcesMayExist = false;
const env = { ...process.env, CITA_BASELINE_RUN_ID: randomUUID(), NODE_OPTIONS: '--max-old-space-size=768', DEMO_MODE: 'false',
  ODONTO_SUPABASE_URL: '', ODONTO_SUPABASE_ANON_KEY: '', ODONTO_SUPABASE_SERVICE_ROLE_KEY: '',
  ADMIN_SUPABASE_URL: '', ADMIN_SUPABASE_ANON_KEY: '', ADMIN_SUPABASE_SERVICE_ROLE_KEY: '',
  MP_ACCESS_TOKEN: '', MP_WEBHOOK_SECRET: '', GOOGLE_CLIENT_ID: '', GOOGLE_CLIENT_SECRET: '',
  GOOGLE_CALENDAR_CLIENT_ID: '', GOOGLE_CALENDAR_CLIENT_SECRET: '',
  WHATSAPP_ACCESS_TOKEN: '', WHATSAPP_APP_SECRET: '', VAPID_PUBLIC_KEY: '', VAPID_PRIVATE_KEY: '',
  PUBLIC_CITA_BASE_URL: 'https://app.cita-suite.workers.dev', PUBLIC_NATALIA_INTEGRATION_KEY: 'a'.repeat(32)
};
const require = createRequire(resolve(root, 'apps/web/package.json'));
function docker(args, options = {}) {
  const result = spawnSync('docker', args, { encoding: 'utf8', timeout: 30_000, maxBuffer: 16 * 1024 * 1024, ...options });
  if (result.error || result.status !== 0) throw new Error(`Local Docker command failed: ${args[0]}`);
  return result.stdout.trim();
}
function capture(name, data) { writeFileSync(join(output, name), JSON.stringify(data, null, 2) + '\n', { mode: 0o600 }); }
async function run(name, command, args) {
  if (signal) throw new Error(`Interrupted by ${signal}`);
  const log = join(output, `${String(receipt.stages.length + 1).padStart(2, '0')}-${name}.log`);
  const stage = { name, command: [command, ...args], log, startedAt: new Date().toISOString(), passed: false };
  receipt.stages.push(stage); capture('result.json', receipt);
  console.log(`START ${name}`);
  const fd = openSync(log, 'w', 0o600);
  const started = performance.now();
  try {
    active = spawn('prlimit', ['--core=0', '--', command, ...args], {
      cwd: root, env: { ...env, ...(name === 'types' ? { NODE_OPTIONS: '--max-old-space-size=1024' } : {}) },
      detached: true, stdio: ['ignore', fd, fd]
    });
    const code = await new Promise((resolveExit, reject) => { active.once('error', reject); active.once('exit', resolveExit); });
    stage.exitCode = code; stage.durationMs = Math.round(performance.now() - started);
    if (code !== 0 || signal) throw new Error(`${name} failed; inspect ${log}`);
    stage.passed = true;
    console.log(`PASS ${name} (${Math.round(stage.durationMs / 1000)}s)`);
    return readFileSync(log, 'utf8');
  } finally { active = undefined; closeSync(fd); capture('result.json', receipt); }
}
function inspectTests(file, stage) {
  const result = JSON.parse(readFileSync(file, 'utf8'));
  receipt.stages.at(-1).tests = { files: result.testResults.length, passed: result.numPassedTests, failed: result.numFailedTests, pending: result.numPendingTests };
  if (!result.success || result.numPassedTests < 1 || result.numFailedTests || result.numPendingTests) {
    receipt.stages.at(-1).passed = false;
    throw new Error(`${stage} did not execute a complete passing suite; inspect ${file}`);
  }
}
async function stopSupervisor() {
  if (!supervisor || supervisor.exitCode !== null) return;
  const exited = new Promise(resolveExit => supervisor.once('exit', resolveExit));
  supervisor.kill('SIGTERM');
  await Promise.race([exited, delay(15_000, undefined, { ref: false })]);
  if (supervisor.exitCode === null) { supervisor.kill('SIGKILL'); await exited; }
}
async function cleanup() {
  try {
    await stopSupervisor();
    if (resourcesMayExist) {
      const owned = docker(['ps', '-a', '--filter', 'label=com.cita-suite.baseline-run=' + env.CITA_BASELINE_RUN_ID, '--format', '{{.Names}}']).split('\n').filter(Boolean);
      // Recover this run's database name even if SQL verification was interrupted.
      database ??= owned.find(name => /^cita-booking-test-[a-f0-9]{12}$/.test(name));
      if (database) {
        for (const name of [database + '-rest', database + '-storage', database]) {
          const check = spawnSync('docker', ['inspect', '--format', '{{index .Config.Labels "com.cita-suite.booking-fixture"}}', name], { encoding: 'utf8', timeout: 10_000 });
          if (check.status === 0 && check.stdout.trim() === 'true') docker(['rm', '-f', '-v', name]);
        }
        for (const name of [database + '-e2e-net', database + '-net']) spawnSync('docker', ['network', 'rm', name], { stdio: 'ignore', timeout: 10_000 });
      }
    }
  } finally { rmSync(lock, { recursive: true, force: true }); }
}
for (const event of ['SIGTERM', 'SIGINT']) process.on(event, () => {
  signal = event;
  if (active?.pid) try { process.kill(-active.pid, 'SIGTERM'); } catch {}
  supervisor?.kill('SIGTERM');
});

try {
  if (existsSync('/tmp/cita-booking-runtime.json') || existsSync('/tmp/cita-booking-storage.json')) throw new Error('A fixture runtime already exists. Stop its owner before running this baseline.');
  if (spawnSync('prlimit', ['--core=0', '--', 'node', '--version'], { stdio: 'ignore' }).status !== 0) throw new Error('Linux prlimit (util-linux) is required to disable memory core dumps in test subprocesses.');
  for (const image of ['public.ecr.aws/supabase/postgres:17.6.1.166', 'public.ecr.aws/supabase/postgrest:v16.1']) docker(['image', 'inspect', image]);
  if (!existsSync(require('@playwright/test').chromium.executablePath())) throw new Error('Installed Chromium is required; no browser or Docker image is downloaded automatically.');
  baseline = collectArchitectureInventory(); capture('source-inventory.json', baseline);
  receipt.gitRevision = baseline.gitRevision; receipt.sourceFingerprint = baseline.sourceFingerprint;
  await run('types', 'pnpm', ['check']);
  const serverReport = join(output, 'server-tests.json'), clientReport = join(output, 'component-tests.json');
  await run('server-tests', 'pnpm', ['--filter', 'web', 'test', '--reporter=json', '--outputFile=' + serverReport]);
  inspectTests(serverReport, 'server-tests');
  await run('component-tests', 'pnpm', ['--filter', 'web', 'test:client', '--reporter=json', '--outputFile=' + clientReport]);
  inspectTests(clientReport, 'component-tests');
  await run('cloudflare-build', 'pnpm', ['--filter', 'web', 'build:cloudflare']);
  await run('natalia-build', 'pnpm', ['--filter', 'natalia', 'exec', 'astro', 'build']);
  await run('natalia-public-contract', 'pnpm', ['--filter', 'natalia', 'check:assets']);
  await run('natalia-fidelity', 'pnpm', ['--filter', 'natalia', 'check:public']);
  const nataliaLog = await run('natalia-browser', 'pnpm', ['--filter', 'natalia', 'test:browser']);
  const browserResult = JSON.parse(nataliaLog.trim().split('\n').at(-1));
  if (!browserResult.results?.length || browserResult.results.some(test => !test.passed)) throw new Error('Natalia browser contract is incomplete.');
  receipt.stages.at(-1).scenarios = browserResult.results.length;
  resourcesMayExist = true;
  const sqlLog = await run('sql-contracts', 'node', ['scripts/test-booking-foundation.mjs', '--all-contracts', '--keep']);
  database = sqlLog.match(/Disposable database retained for local development only: (cita-booking-test-[a-f0-9]{12})/)?.[1];
  if (!database) throw new Error('Disposable SQL fixture was not retained.');
  const sqlResult = sqlLog.split('\n').filter(line => line.startsWith('{')).map(line => JSON.parse(line)).find(value => value.allContracts === true);
  if (!sqlResult || sqlResult.assertions < 1) throw new Error('SQL assertions were not executed.');
  receipt.stages.at(-1).contracts = sqlResult;
  const effective = docker(['exec', '-i', database, 'psql', '-X', '-U', 'supabase_admin', '-d', 'postgres', '-qAt', '-v', 'ON_ERROR_STOP=1'], { input: "select jsonb_build_object('source','isolated migration reconstruction','functions',coalesce((select jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,'arguments',pg_get_function_identity_arguments(p.oid),'returns',pg_get_function_result(p.oid),'security_definer',p.prosecdef) order by n.nspname,p.proname,p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','private')),'[]'::jsonb),'tables',coalesce((select jsonb_agg(jsonb_build_object('schema',schemaname,'name',tablename,'rls',rowsecurity) order by schemaname,tablename) from pg_tables where schemaname in ('public','private')),'[]'::jsonb));" });
  capture('effective-database-contract.json', JSON.parse(effective));
  receipt.fixtureStartup = { startedAt: new Date().toISOString(), passed: false };
  console.log('START local-fixture (waiting for real SSR/database readiness)');
  const fd = openSync(join(output, 'fixture-supervisor.log'), 'w', 0o600);
  supervisor = spawn('prlimit', ['--core=0', '--', 'node', 'scripts/serve-booking-fixture.mjs', database], { cwd: root, env, stdio: ['ignore', fd, fd] });
  closeSync(fd);
  let ready = false;
  for (let attempt = 0; attempt < 240 && !ready; attempt++) {
    if (signal || supervisor.exitCode !== null) throw new Error('Local fixture supervisor stopped before readiness.');
    if (existsSync('/tmp/cita-booking-runtime.json')) {
      const runtime = JSON.parse(readFileSync('/tmp/cita-booking-runtime.json', 'utf8'));
      if (runtime.container !== database || new URL(runtime.appOrigin).hostname !== '127.0.0.1') throw new Error('Unexpected fixture runtime.');
      // A static SDK response does not prove the SSR route has compiled or reached
      // its database. The supervisor emits READY only after that real page is OK.
      ready = readFileSync(join(output, 'fixture-supervisor.log'), 'utf8').includes('READY: local integration at ' + runtime.appOrigin);
    }
    if (!ready) await delay(500);
  }
  if (!ready) throw new Error('Local fixture did not become ready.');
  receipt.fixtureStartup.passed = true;
  receipt.fixtureStartup.finishedAt = new Date().toISOString();
  console.log('PASS local-fixture');
  const nativeLog = await run('native-booking-browser', 'node', ['scripts/qa-natalia-direct-booking.mjs']);
  const nativeResult = JSON.parse(nativeLog);
  if (!nativeResult.passed || nativeResult.checks?.length !== 2) throw new Error('Native booking desktop/mobile verification incomplete.');
  capture('native-booking.json', nativeResult);
  receipt.stages.at(-1).scenarios = nativeResult.checks.length;
  const serverDiagnostics = readFileSync('/tmp/cita-booking-vite-errors.log', 'utf8');
  writeFileSync(join(output, 'fixture-server-diagnostics.log'), serverDiagnostics, { mode: 0o600 });
  const lifetimeWarnings = (serverDiagnostics.match(/Calling `event\.fetch\(\.\.\.\)` in a promise handler after `load\(\.\.\.\)` has returned/g) ?? []).length;
  receipt.observations = lifetimeWarnings ? [{ code: 'loader-fetch-lifetime', occurrences: lifetimeWarnings, owner: 'Phase 4: request/loader boundaries', scope: 'SvelteKit development warning; invalidation behavior requires a targeted regression. Not suppressed or counted as a production incident.' }] : [];
  await stopSupervisor();
  if (collectArchitectureInventory().sourceFingerprint !== baseline.sourceFingerprint) throw new Error('Source changed during verification; rerun the baseline.');
  receipt.passed = true;
} catch (error) {
  receipt.error = error instanceof Error ? error.message : 'Verification failed';
  console.error(receipt.error);
  process.exitCode = 1;
} finally {
  try { await cleanup(); receipt.cleanupCompleted = true; } catch { receipt.cleanupCompleted = false; receipt.passed = false; process.exitCode = 1; }
  receipt.finishedAt = new Date().toISOString(); capture('result.json', receipt);
  console.log(`Evidence: ${output}/result.json`);
  console.log(receipt.passed ? 'PASS complete local baseline' : 'FAIL baseline; no deployment performed');
}
