import { randomBytes } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { productionEnvironment, productionPsql } from './lib/production-database.mjs';

// Real email check on production: one synthetic practice whose only patient address is the agreed
// test mailbox, with the sender already verified in Zoho. Each command makes one real change through
// the writers the app uses; the scheduled email run then sends what corresponds, so reception proves
// the whole chain. The recipient is fixed here on purpose: no argument can address anyone else.
// Reports carry states and counts, never links or message bodies. Nothing here touches another practice.
const TEST_MAILBOX = 'citasuite@gmail.com';
const SENDER_DOMAIN = 'prueba-correo.cita-suite.com.ar';

const root = fileURLToPath(new URL('../', import.meta.url));
const [operation, runArgument, value] = process.argv.slice(2);
const OPERATIONS = ['seed', 'book', 'book-deposit', 'move', 'cancel', 'email', 'report', 'cleanup'];
if (!OPERATIONS.includes(operation) || process.argv.length > 5)
	throw new Error('Usage: production-email-practice.mjs seed | book|book-deposit <run> <hours ahead> | move|cancel|report|cleanup <run> | email <run> on|off');
const run = operation === 'seed' ? randomBytes(6).toString('hex') : runArgument;
if (!/^[a-f0-9]{12}$/.test(run ?? '')) throw new Error('A run is 12 hexadecimal characters.');
const slug = `production-email-${run}`;
const { database } = productionEnvironment(root);
const execute = (sql, args = ['-q']) => productionPsql(database, sql, { application: 'cita_suite_production_email_practice', args }).trim();
const hours = () => {
	if (!/^\d{1,4}(\.\d{1,3})?$/.test(value ?? '') || Number(value) <= 0) throw new Error('Hours ahead must be a positive number.');
	return value;
};
const business = `(select id from public.businesses where slug='${slug}')`;
const latest = `(select a.id from public.appointments a where a.business_id=${business} and a.status in ('reserved','confirmed') order by a.created_at desc limit 1)`;
// The real staff writer, as the operator's synthetic owner of this practice.
const staff = (action, starts) => `begin;
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select public.apply_staff_appointment_management(${business},(select id from auth.users where email='${slug}@example.test'),${latest},gen_random_uuid(),
 private.appointment_semantic_revision(${business},${latest}),'${action}',${starts},false,
 ${action === 'reschedule' ? `(select booking_availability_revision from public.businesses where slug='${slug}')` : 'null'}) is not null;
commit;`;
const book = (deposit) => `begin;
do $$
declare v_business uuid:=${business}; v_starts timestamptz:=date_trunc('minute',now())+make_interval(secs=>${Number(hours()) * 3600});
 v_service uuid; v_professional uuid; v_patient uuid; v_appointment uuid;
begin
 select id into v_service from public.services where business_id=v_business limit 1;
 select id into v_professional from public.professionals where business_id=v_business limit 1;
 select id into v_patient from public.patients where business_id=v_business limit 1;
 insert into public.appointments(business_id,patient_id,service_id,professional_id,starts_at,ends_at,blocking_starts_at,blocking_ends_at,
  status,source,service_name_snapshot,professional_name_snapshot,duration_minutes_snapshot)
 values(v_business,v_patient,v_service,v_professional,v_starts,v_starts+interval '30 minutes',v_starts,v_starts+interval '30 minutes',
  'reserved','manual','Consulta','Profesional sintético',30) returning id into v_appointment;
 -- The obligation is written on this synthetic appointment: the global deposit switch stays as it is.
 ${deposit ? `insert into public.appointment_deposits(business_id,appointment_id,status,amount,request_days,deadline_hours,min_payment_hours,policy_revision,request_from,due_at,auto_cancel)
 values(v_business,v_appointment,'pending',40000,7,48,24,1,now(),v_starts-interval '48 hours',false);` : ''}
end $$;
commit;`;
const report = () => JSON.parse(execute(`select json_build_object('practice','${slug}','at',now(),
 'runtime',(select json_build_object('producer',email_producer_enabled,'pausedUntil',email_paused_until,'pauseReason',email_pause_reason) from private.appointment_management_runtime where singleton),
 'sender',(select json_build_object('domain',sending_domain,'state',domain_state,'ready',private.email_sender_ready(business_id)) from private.business_email_senders where business_id=${business}),
 'appointments',coalesce((select json_agg(json_build_object('startsAt',a.starts_at,'status',a.status,'deposit',d.status) order by a.created_at)
  from public.appointments a left join public.appointment_deposits d on (d.business_id,d.appointment_id)=(a.business_id,a.id) where a.business_id=${business}),'[]'::json),
 'deliveries',coalesce((select json_agg(json_build_object('purpose',x.purpose,'revision',x.schedule_revision,'state',x.state,'attempts',x.attempts,'startedAt',x.started_at,
   'acceptedAt',x.accepted_at,'deliveredAt',x.delivered_at,'bouncedAt',x.bounced_at,'failure',x.failure_code,'discard',x.discard_reason,'reference',x.id) order by x.created_at)
  from private.appointment_email_deliveries x where x.business_id=${business}),'[]'::json)
)`, ['-Atq']));

if (operation === 'seed') {
	execute(`begin;
do $$
declare v_owner uuid:=gen_random_uuid(); v_business uuid; v_service uuid; v_professional uuid;
begin
 insert into auth.users(id,email) values(v_owner,'${slug}@example.test');
 insert into public.businesses(name,slug,industry,timezone,address,public_booking_enabled,max_booking_days_ahead)
 values('Consultorio de prueba de correo','${slug}','other','America/Argentina/Buenos_Aires','Calle Sintética 123',true,30) returning id into v_business;
 update public.business_subscriptions set commercial_access_enabled=true,is_permanent=true,subscription_status='active',
  paid_until=null,grace_until=null,restricted_until=null,archived_at=null where business_id=v_business;
 insert into public.business_users(business_id,user_id,role,status,accepted_at) values(v_business,v_owner,'owner','active',now());
 insert into public.services(business_id,name,duration_minutes,is_public) values(v_business,'Consulta',30,true) returning id into v_service;
 insert into public.professionals(business_id,name,is_public) values(v_business,'Profesional sintético',true) returning id into v_professional;
 insert into public.professional_services(business_id,professional_id,service_id) values(v_business,v_professional,v_service);
 -- Every day from 7 to 21, so the patient's own reschedule always has a time to offer.
 insert into public.availability_rules(business_id,professional_id,weekday,start_time,end_time,slot_interval_minutes,break_minutes)
 select v_business,v_professional,weekday,'07:00','21:00',30,0 from generate_series(0,6) weekday;
 insert into public.patients(owner_id,business_id,full_name,email) values(v_owner,v_business,'Paciente sintético de correo','${TEST_MAILBOX}');
 perform public.operator_set_business_email_sender(v_business,'${SENDER_DOMAIN}','verified',null,'${TEST_MAILBOX}');
end $$;
commit;`);
	console.log(JSON.stringify({ run, practice: slug, recipient: TEST_MAILBOX }));
} else if (operation === 'book' || operation === 'book-deposit') {
	execute(book(operation === 'book-deposit'));
	console.log(JSON.stringify(report().appointments.at(-1)));
} else if (operation === 'move') {
	execute(staff('reschedule', `(select starts_at+interval '1 day' from public.appointments where id=${latest})`));
	console.log(JSON.stringify(report().appointments.at(-1)));
} else if (operation === 'cancel') {
	execute(staff('cancel', 'null'));
	console.log(JSON.stringify(report().appointments.at(-1)));
} else if (operation === 'email') {
	if (!['on', 'off'].includes(value)) throw new Error('email takes on or off.');
	execute(`update public.appointment_email_policies set email_enabled=${value === 'on'} where business_id=${business};`);
	console.log(JSON.stringify({ emailEnabled: value === 'on' }));
} else if (operation === 'report') {
	console.log(JSON.stringify(report(), null, 1));
} else {
	execute(`begin;
delete from private.email_suppressions where business_id=${business};
delete from public.businesses where slug='${slug}';
delete from auth.users where email='${slug}@example.test';
commit;`);
	console.log(JSON.stringify({ run, remaining: Number(execute(`select count(*) from public.businesses where slug='${slug}';`, ['-Atq'])) }));
}
