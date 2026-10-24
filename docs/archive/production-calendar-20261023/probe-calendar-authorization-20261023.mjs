import {productionEnvironment,productionPsql} from '../scripts/lib/production-database.mjs';
import {writeFileSync} from 'node:fs';
const {database}=productionEnvironment(process.cwd());
const value=productionPsql(database,`begin transaction read only;
select a.confirmation_token from public.appointments a join public.businesses b on b.id=a.business_id
where b.slug='capacity-01' and a.starts_at>now()+interval '1 day' and a.status in ('reserved','confirmed','reschedule_requested') order by a.starts_at,a.id limit 1;
commit;`,{application:'cita_suite_calendar_owned_authorization_probe'}).trim();
if(!/^[a-f0-9]{64}$/.test(value))throw new Error('Owned synthetic active appointment not found');
const startedAt=new Date().toISOString();
const r=await fetch(`https://app.cita-suite.workers.dev/turno/${value}/google-calendar/connect`,{redirect:'manual',signal:AbortSignal.timeout(20000)});
let redirect;try{redirect=new URL(r.headers.get('location'))}catch{}
const receipt={startedAt,finishedAt:new Date().toISOString(),scope:'Initiate real managed OAuth on an owned capacity-01 synthetic future appointment; normal app creates a ten-minute encrypted attempt and may clean expired attempts. No Google account login/consent or event mutation. Management URL/state/code_verifier and response body discarded.',status:r.status,googleAuthorizationEndpoint:redirect?.origin==='https://accounts.google.com'&&redirect?.pathname==='/o/oauth2/v2/auth',redirectUri:redirect?.searchParams.get('redirect_uri')??null,clientId:redirect?.searchParams.get('client_id')??null,pkceMethod:redirect?.searchParams.get('code_challenge_method')??null,scope:redirect?.searchParams.get('scope')??null,hasOpaqueState:Boolean(redirect?.searchParams.get('state')),statePersistedOrPrinted:false,callbackCompleted:false,googleConsentCompleted:false};
receipt.runtimeConfigured=receipt.status===303&&receipt.googleAuthorizationEndpoint&&receipt.pkceMethod==='S256'&&receipt.hasOpaqueState;
receipt.canonicalCallback=receipt.redirectUri==='https://app.cita-suite.workers.dev/oauth/google-calendar/callback';
writeFileSync('.verification/production-calendar-authorization-probe-20261023.json',JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify(receipt));
if(!receipt.runtimeConfigured||!receipt.canonicalCallback)process.exitCode=1;
