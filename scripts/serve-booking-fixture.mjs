import { createServer } from 'node:http';
import { spawnSync, spawn } from 'node:child_process';
import { createHmac } from 'node:crypto';
import { writeFileSync, openSync, rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../', import.meta.url)).replace(/\/$/, '');
const db = process.argv[2];
if (process.argv.length !== 3 || !/^cita-booking-test-[a-f0-9]{12}$/.test(db ?? ''))
    throw new Error('Supply only the disposable container printed by test-booking-foundation.mjs --keep. Remote databases are forbidden.');
const network = db + '-e2e-net';
const rest = db + '-rest';
const key = 'ab'.repeat(16), businessId = '90000000-0000-4000-8000-000000000001', serviceId = '90000000-0000-4000-8000-000000000002', professionalId = '90000000-0000-4000-8000-000000000003';
function docker(args, input) { const r = spawnSync('docker', args, { input, encoding: 'utf8' }); if (r.status !== 0)
    throw new Error(r.stderr); return r.stdout.trim(); }
const secret = 'cita-local-disposable-jwt-secret-with-more-than-32-characters';
function jwt(role, sub) { const head = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url'); const body = Buffer.from(JSON.stringify({ role, ...(sub ? {sub, email: sub === '90000000-0000-4000-8000-000000000004' ? 'e2e-owner@example.test' : 'e2e-doctor@example.test'} : {}), iss: 'supabase', iat: Math.floor(Date.now() / 1000), exp: Math.floor(Date.now() / 1000) + 7200 })).toString('base64url'); return head + '.' + body + '.' + createHmac('sha256', secret).update(head + '.' + body).digest('base64url'); }
let child, gateway, cleaned = false, verified = false;
function cleanup() { if (cleaned)
    return; cleaned = true; if (child)
    try {
        process.kill(-child.pid, 'SIGTERM');
    }
    catch { } if (gateway)
    gateway.close(); if (!verified)
    return; try {
    docker(['rm', '-f', rest]);
}
catch { } try {
    docker(['rm', '-f', '-v', db]);
}
catch { } for (const name of [network, db + '-net'])
    try {
        docker(['network', 'rm', name]);
    }
    catch { } rmSync('/tmp/cita-booking-runtime.json', { force: true }); }
process.on('SIGTERM', () => { cleanup(); process.exit(0); });
process.on('SIGINT', () => { cleanup(); process.exit(0); });
try {
    if (docker(['inspect', '--format', '{{index .Config.Labels "com.cita-suite.booking-fixture"}}', db]) !== 'true')
        throw new Error('The container was not created by the isolated fixture runner. Refusing to mutate it.');
    verified = true;
    docker(['image', 'inspect', 'public.ecr.aws/supabase/postgrest:v16.1']);
    // Local-only gateway publishes on loopback. PostgreSQL has no host ports.
    docker(['network', 'create', network]);
    docker(['network', 'connect', network, db]);
    docker(['run', '-d', '--name', rest, '--network', network, '--memory', '96m', '--cpus', '0.5', '-p', '127.0.0.1::3000', '-e', 'PGRST_DB_URI=postgres://supabase_admin:cita-disposable-test-only@' + db + ':5432/postgres', '-e', 'PGRST_DB_SCHEMAS=public,private', '-e', 'PGRST_DB_ANON_ROLE=anon', '-e', 'PGRST_JWT_SECRET=' + secret, '-e', 'PGRST_DB_POOL=2', '-e', 'PGRST_DB_MAX_ROWS=1000', 'public.ecr.aws/supabase/postgrest:v16.1']);
    const ports = JSON.parse(docker(['inspect', '--format', '{{json .NetworkSettings.Ports}}', rest]));
    const restOrigin = 'http://127.0.0.1:' + ports['3000/tcp'][0].HostPort;
    const appOrigin = 'http://127.0.0.1:5177';
    gateway = createServer(async (req, res) => {
        if (req.url === '/harness') {
            res.setHeader('Content-Type', 'text/html; charset=utf-8');
            res.end(`<!doctype html><html lang="es"><meta charset="utf-8"><title>Prueba aislada de integración</title><meta name="viewport" content="width=device-width,initial-scale=1"><body style="margin:24px;background:#f3eee5;font:18px sans-serif"><h1>Host de prueba</h1><button id="book">Reservar consulta</button><script src="${appOrigin}/booking/embed-v1.js"></script><script>window.completions=[];window.widget=CitaSuiteBooking.mount({integrationKey:'${key}',baseURL:'${appOrigin}',onComplete:function(){window.completions.push(Array.from(arguments))}});document.querySelector('#book').onclick=()=>widget.open();</script></body></html>`);
            return;
        }
        // Local Auth simulator only; it validates this fixture's signature and known identities.
        // This is not evidence of a real Supabase Auth session or deployment.
        if (req.url === '/auth/v1/user' && req.method === 'GET') {
            const token = String(req.headers.authorization ?? '').replace(/^Bearer /, '');
            const parts = token.split('.');
            const signature = createHmac('sha256', secret).update(parts.slice(0,2).join('.')).digest('base64url');
            try {
                const claims = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
                if (parts.length !== 3 || parts[2] !== signature || claims.role !== 'authenticated' || claims.exp <= Date.now()/1000 || !['90000000-0000-4000-8000-000000000004','90000000-0000-4000-8000-000000000007'].includes(claims.sub)) throw new Error();
                res.setHeader('Content-Type','application/json'); res.end(JSON.stringify({id: claims.sub, email: claims.email, aud: 'authenticated', role: 'authenticated', app_metadata: {}, user_metadata: {}, created_at: new Date().toISOString()}));
            } catch { res.statusCode=401; res.end('{}'); }
            return;
        }
        if (!req.url.startsWith('/rest/v1/')) {
            res.statusCode = 404;
            res.end();
            return;
        }
        try {
            const chunks = [];
            for await (const chunk of req)
                chunks.push(chunk);
            const headers = { ...req.headers };
            delete headers.host;
            delete headers['content-length'];
            const response = await fetch(restOrigin + req.url.slice('/rest/v1'.length), { method: req.method, headers, body: ['GET', 'HEAD'].includes(req.method) ? undefined : Buffer.concat(chunks) });
            res.statusCode = response.status;
            response.headers.forEach((value, name) => { if (!['content-encoding', 'content-length', 'transfer-encoding'].includes(name))
                res.setHeader(name, value); });
            res.end(Buffer.from(await response.arrayBuffer()));
        }
        catch {
            res.statusCode = 503;
            res.end('Local gateway unavailable');
        }
    });
    await new Promise(resolve => gateway.listen(0, '127.0.0.1', resolve));
    const apiOrigin = 'http://127.0.0.1:' + gateway.address().port;
    docker(['exec', '-i', db, 'psql', '-X', '-U', 'supabase_admin', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q'], `
 begin;
 insert into auth.users(id,email) values('90000000-0000-4000-8000-000000000004','e2e-owner@example.test'),('90000000-0000-4000-8000-000000000007','e2e-doctor@example.test');
 insert into public.businesses(id,name,slug,industry,timezone,min_booking_notice_minutes,max_booking_days_ahead,address) values('${businessId}','Consultorio de prueba','booking-e2e-isolated','other','America/Argentina/Buenos_Aires',60,30,'Dirección sintética 123');
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values('${businessId}','90000000-0000-4000-8000-000000000004','owner','active',now()),('${businessId}','90000000-0000-4000-8000-000000000007','professional','active',now());
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',paid_until=null,grace_until=null,restricted_until=null where business_id='${businessId}';
 insert into public.services(id,business_id,name,duration_minutes) values('${serviceId}','${businessId}','Consulta de prueba',30);
 insert into public.professionals(id,business_id,name) values('${professionalId}','${businessId}','Profesional de prueba');
 insert into public.professional_users(business_id,professional_id,user_id) values('${businessId}','${professionalId}','90000000-0000-4000-8000-000000000007');
 insert into public.professional_booking_forms(business_id,professional_id,fields) values('${businessId}','${professionalId}','[{"id":"age","label":"Edad","kind":"text","required":true,"maxLength":3,"patientField":"age"},{"id":"medication","label":"Medicación","kind":"textarea","required":false,"maxLength":1000,"patientField":"medication"},{"id":"insurance","label":"Obra social del perfil","kind":"text","required":true,"maxLength":120,"patientField":"insurance"}]');
 insert into public.professional_services(business_id,professional_id,service_id) values('${businessId}','${professionalId}','${serviceId}');
 insert into public.availability_rules(business_id,professional_id,weekday,start_time,end_time,slot_interval_minutes,break_minutes) select '${businessId}','${professionalId}',n,'09:00','17:00',30,10 from generate_series(0,6)n;
 insert into public.booking_integrations(business_id,public_key,name,is_active,is_default,theme,allowed_origins,allowed_service_ids,allowed_professional_ids,allowed_modalities,video_instructions,intake_schema) values('${businessId}','${key}','Host de prueba',true,true,'natalia',array['${apiOrigin}'],array['${serviceId}']::uuid[],array['${professionalId}']::uuid[],array['in_person','video'],'Instrucciones virtuales sintéticas: se coordina el acceso.','[{"id":"insurance","label":"Obra social y plan","kind":"text","required":true,"maxLength":120},{"id":"labs","label":"Estudios recientes","kind":"boolean","required":false}]');
 notify pgrst,'reload schema';
 commit;
 `);
    const anon = jwt('anon'), service = jwt('service_role');
    writeFileSync('/tmp/cita-booking-runtime.json', JSON.stringify({ appOrigin, apiOrigin, key, businessId, serviceId, professionalId, anon, service, ownerToken: jwt('authenticated', '90000000-0000-4000-8000-000000000004'), doctorToken: jwt('authenticated','90000000-0000-4000-8000-000000000007'), container: db }), { mode: 0o600 });
    child = spawn('pnpm', ['dev', '--host', '127.0.0.1', '--port', '5177', '--strictPort'], { cwd: root + '/apps/web', detached: true, stdio: ['ignore', openSync('/tmp/cita-booking-vite.log', 'w', 0o600), openSync('/tmp/cita-booking-vite-errors.log', 'w', 0o600)], env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=1024', ODONTO_SUPABASE_URL: apiOrigin, ODONTO_SUPABASE_ANON_KEY: anon, ODONTO_SUPABASE_SERVICE_ROLE_KEY: service, PUBLIC_ODONTO_SUPABASE_URL: apiOrigin, PUBLIC_ODONTO_SUPABASE_ANON_KEY: anon, PUBLIC_SITE_URL: appOrigin, BOOKING_INTEGRATIONS_ENABLED: 'true', BOOKING_CONTEXTS_AVAILABLE: 'true', BOOKING_INFORMATION_ENABLED: 'true', DEMO_MODE: 'false', GOOGLE_CALENDAR_MANAGED_ENABLED: 'false', MP_ACCESS_TOKEN: '', TURNSTILE_SECRET_KEY: '', PUBLIC_TURNSTILE_SITE_KEY: '', VAPID_PUBLIC_KEY: '', VAPID_PRIVATE_KEY: '', RATE_LIMIT_SALT: 'cita-disposable-local-only' } });
    for (let n = 0; n < 60; n++) {
        try {
            const response = await fetch(appOrigin + '/embed/v1/' + key);
            if (response.ok) {
                console.log('READY: local integration at ' + appOrigin + '; host ' + apiOrigin + '/harness');
                break;
            }
            if (n === 59)
                throw new Error('Application did not load: ' + response.status);
        }
        catch (error) {
            if (n === 59)
                throw error;
        }
        await new Promise(resolve => setTimeout(resolve, 500));
    }
    await new Promise(() => { });
}
catch (error) {
    console.error(error.message);
    cleanup();
    process.exitCode = 1;
}
