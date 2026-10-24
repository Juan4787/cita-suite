import{readFileSync,writeFileSync,existsSync}from'node:fs';
import{createHash}from'node:crypto';
import{productionEnvironment,productionPsql}from'../scripts/lib/production-database.mjs';
import{deviceCleanupSql,deviceReportSql}from'../scripts/lib/device-push.mjs';
import{ownPhoneTab}from'./samsung-cdp-20261024.mjs';
const file='.verification/owned-provider-fixtures-cleanup-v2-20261024.json';
if(existsSync(file))throw Error('CLEANUP_RECEIPT_EXISTS_INSPECT_BEFORE_RETRY');
const measure=JSON.parse(readFileSync('.verification/capacity-two-final-state-20261024.json','utf8'));
if(measure.run!==40078561771||measure.status!=='completed')throw Error('CAPACITY_MEASUREMENT_NOT_FINISHED');
const deleted=JSON.parse(readFileSync('.verification/owned-calendar-google-ui-deletion-direct-search-20261024.json','utf8'));
if(deleted.remoteDeletionConfirmed!==true||deleted.googleUiReadConfirmed!==true)throw Error('CALENDAR_REMOTE_DELETION_NOT_PROVEN');
const push=JSON.parse(readFileSync('.verification/samsung-b5976b2b9428-final-durable-report-20261024.json','utf8'));
if(push.run!=='b5976b2b9428'||push.attempts.length!==3||push.attempts.some(x=>x.status!==201||!x.displayedAt||!x.receivedAt))throw Error('FINAL_DEVICE_PROOF_NOT_PRESERVED');
const{database}=productionEnvironment(process.cwd());const sql=s=>productionPsql(database,s,{application:'cita_suite_owned_provider_cleanup'}).trim();const j=s=>JSON.parse(sql('begin transaction read only;'+s+';commit;'));
const r={runId:'owned-provider-fixtures-cleanup-v2-20261024',at:new Date().toISOString(),scope:'Only two exact newly seeded provider fixtures and their fake owners. Calendar event already deleted through public action and independent Google UI. Preserve pre-existing Calendar IDs and any shared push device. Phone notification cleanup is operator action, not application deduplication evidence.',status:'preflight'};const save=()=>writeFileSync(file,JSON.stringify(r,null,2)+'\n',{mode:0o600});
const history=()=>j("select json_build_object('connections',(select count(*) from public.google_calendar_connections),'connectionIdentity',(select md5(coalesce(string_agg(id::text,',' order by id),'')) from public.google_calendar_connections),'events',(select count(*) from public.appointment_google_calendar_events),'eventIdentity',(select md5(coalesce(string_agg(appointment_id::text,',' order by appointment_id),'')) from public.appointment_google_calendar_events))");
r.historicalCalendarBefore=history();if(r.historicalCalendarBefore.connections!==1||r.historicalCalendarBefore.events!==1)throw Error('HISTORICAL_CALENDAR_SCOPE_CHANGED');
const own=j("select json_build_object('appointmentId',a.id,'ownDeviceCount',(select count(distinct device_id) from public.push_subscriptions s where s.business_id=b.id),'otherDeviceSubscriptions',(select count(*) from public.push_subscriptions s where s.business_id<>b.id and s.device_id in(select device_id from public.push_subscriptions own where own.business_id=b.id))) from public.appointments a join public.businesses b on b.id=a.business_id join public.patients p on p.id=a.patient_id and p.business_id=b.id join auth.users u on u.id=p.owner_id where b.slug='production-device-b5976b2b9428' and u.email=b.slug||'@example.test'");
if(!/^[0-9a-f-]{36}$/.test(own.appointmentId)||own.ownDeviceCount!==1)throw Error('OWN_PUSH_SCOPE_CHANGED');
save();let tab;
try{tab=await ownPhoneTab();r.phoneCleanup=await tab.evaluate(`(async()=>{const registration=await navigator.serviceWorker.getRegistration('/');if(!registration)return{ownShown:0,closed:0,unsubscribed:false,registrationPresent:false};const shown=await registration.getNotifications();const own=shown.filter(n=>(n.tag||'').startsWith('turno-'+${JSON.stringify(own.appointmentId)}+'-'));for(const n of own)n.close();let unsubscribed=false;if(${own.otherDeviceSubscriptions===0}){const subscription=await registration.pushManager.getSubscription();if(subscription)unsubscribed=await subscription.unsubscribe();}return{ownShown:own.length,closed:own.length,unsubscribed,registrationPresent:true,permission:Notification.permission}})()`);}
catch(e){r.phoneCleanup={confirmed:false,safeFailure:/^[A-Z_]+$/.test(e?.message??'')?e.message:'OWN_PHONE_CLEANUP_UNAVAILABLE'};}
finally{tab?.close();save();}
const targets=[['production-calendar-1a4b7003690d','cancelled'],['production-device-b5976b2b9428','confirmed']];r.targets=[];
for(const[slug,status]of targets){
 const guard=`do $$ declare v_b uuid;v_owner uuid;begin
 select b.id into strict v_b from public.businesses b where b.slug='${slug}' for update;
 select u.id into strict v_owner from auth.users u where u.email='${slug}@example.test' for update;
 if (select count(*) from public.patients where business_id=v_b)<>1
 or (select count(*) from public.patients where business_id=v_b and owner_id=v_owner)<>1
 or (select count(*) from public.appointments where business_id=v_b)<>1
 or (select count(*) from public.appointments where business_id=v_b and status='${status}')<>1
 or exists(select 1 from public.appointment_google_calendar_events where business_id=v_b)
 or exists(select 1 from public.clinical_entries where business_id=v_b)
 then raise exception 'OWN_FIXTURE_SCOPE_CHANGED';end if;end $$;`;
 r.status='cleaning-'+slug;r.currentTarget=slug;save();
 // The reused cleanup is already tested. The guard and deletion share its transaction and row locks.
 sql(deviceCleanupSql(slug).replace('begin;',()=> 'begin;\n'+guard));
 const report=j(deviceReportSql(slug.slice(-12),slug));
 const remaining=j(`select json_build_object('practices',(select count(*) from public.businesses where slug='${slug}'),'owners',(select count(*) from auth.users where email='${slug}@example.test'))`);
 if(report.appointmentStartsAt!==null||report.subscriptions.length||report.attempts.length||remaining.practices||remaining.owners)throw Error('OWN_FIXTURE_CLEANUP_INCOMPLETE');
 r.targets.push({slug,statusBefore:status,remaining,appointmentAbsent:true,subscriptions:0,deliveryAttempts:0});save();
}
r.historicalCalendarAfter=history();if(JSON.stringify(r.historicalCalendarAfter)!==JSON.stringify(r.historicalCalendarBefore))throw Error('HISTORICAL_CALENDAR_CHANGED');
r.status='backend-cleaned-historical-calendar-preserved';r.finishedAt=new Date().toISOString();r.currentTarget=null;save();console.log(JSON.stringify({status:r.status,targets:r.targets,historicalCalendarPreserved:true,phoneCleanup:r.phoneCleanup,receipt:file}));
