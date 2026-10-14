import '@testing-library/jest-dom/vitest';
import { afterEach, expect, it, vi } from 'vitest';
import { cleanup, render, screen } from '@testing-library/svelte';
const requestId = '10000000-0000-4000-8000-000000000001';
vi.mock('$app/forms', () => ({ enhance: () => ({ destroy() {} }) }));
vi.mock('$app/navigation', () => ({ afterNavigate() {} }));
vi.mock('$app/state', () => ({ page: { url: new URL('https://booking.example.test/embed/v1/' + 'a'.repeat(32) + '?service_id=service&professional_id=professional&date=2026-11-02&slot=2026-11-02T09%3A00%3A00.000Z') }, navigating: { to: null } }));
import { navigating } from '$app/state';
import PublicBookingFlow from './PublicBookingFlow.svelte';
afterEach(cleanup);

it('renders a server-reported unknown result as recovery-required, preserving the attempt and frame context', () => {
  render(PublicBookingFlow, { data: {
    state: { business: { name: 'Consultorio sintético', timezone: 'UTC' }, services: [{ id: 'service', name: 'Consulta', description: null, duration_minutes: 30, price_label: null }], professionals: [{ id: 'professional', name: 'Profesional sintético', specialty: null }], days: [{ date: '2026-11-02', label: 'Lunes', count: 1 }], slots: [{ date: '2026-11-02', time: '09:00', starts_at: '2026-11-02T09:00:00.000Z', ends_at: '2026-11-02T09:30:00.000Z', professional_id: 'professional', professional_name: 'Profesional sintético' }], issue: null },
    selected: { serviceId: 'service', professionalId: 'professional', professionalIds: [], bookingMode: 'individual', date: '2026-11-02' }, mapsLink: null, turnstileSiteKey: null, bookingRequestId: requestId, integration: { publicKey: 'a'.repeat(32), revision: 1 }, presentation: { theme: 'cita-suite', modalities: ['in_person'], intakeFields: [], videoInstructions: null }, embed: { parentOrigin: 'https://natalia.example.test', instanceId: 'b'.repeat(32) }, demo: false
  }, form: { uncertain: true, message: 'No pudimos comprobar el resultado.', values: { idempotency_key: requestId } } });
  expect(screen.getByRole('button', { name: 'Confirmar reserva' })).toBeDisabled();
  const recovery = new URL(screen.getByRole('link', { name: 'Revisar resultado de la reserva' }).getAttribute('href')!, 'https://booking.example.test');
  expect(recovery.searchParams.get('request_id')).toBe(requestId);
  expect(recovery.searchParams.get('recover')).toBe('1');
  expect(recovery.searchParams.get('parent_origin')).toBe('https://natalia.example.test');
  const restart = new URL(screen.getByRole('link', { name: 'Empezar de nuevo' }).getAttribute('href')!, 'https://booking.example.test');
  expect(restart.searchParams.get('request_id')).toBe(requestId);
  expect(restart.searchParams.has('service_id')).toBe(false);
  const action = new URL(screen.getByRole('button', { name: 'Confirmar reserva' }).closest('form')!.getAttribute('action')!, 'https://booking.example.test');
  expect(action.searchParams.has('/create_booking')).toBe(true);
  expect(action.searchParams.get('instance_id')).toBe('b'.repeat(32));
});

it('keeps the pending virtual selection in the form and onward links', () => {
  const pending = new URL('https://booking.example.test/embed/v1/'+'a'.repeat(32)+'?service_id=service&professional_id=professional&date=2026-11-02&slot=2026-11-02T09%3A00%3A00.000Z&modality=video');
  Object.assign(navigating, {to:{url:pending}});
  try {
    render(PublicBookingFlow, {data: bookingFixture(['in_person','video'])});
    expect(document.querySelector<HTMLInputElement>('[name="modality"]')?.value).toBe('video');
    const restart = new URL(screen.getByRole('link',{name:'Empezar de nuevo'}).getAttribute('href')!,pending);
    expect(restart.searchParams.get('modality')).toBe('video');
  } finally { Object.assign(navigating,{to:null}); }
});
it('renders the professional required profile data in the shared native flow', () => {
  const data = bookingFixture(['in_person']);
  Object.assign(data,{patientFields:{hash:'c'.repeat(64),fields:[{id:'profile_insurance',label:'Cobertura exigida',kind:'text',required:true,maxLength:120,patientField:'insurance'}]}});
  render(PublicBookingFlow,{data});
  expect(screen.getByLabelText('Cobertura exigida')).toBeRequired();
  expect(document.querySelector<HTMLInputElement>('[name="patient_schema_hash"]')?.value).toBe('c'.repeat(64));
});
function bookingFixture(modalities: Array<'in_person'|'video'>) {
 return {state:{business:{name:'Consultorio sintético',timezone:'UTC'},services:[{id:'service',name:'Consulta',description:null,duration_minutes:30,price_label:null}],professionals:[{id:'professional',name:'Profesional sintético',specialty:null}],days:[{date:'2026-11-02',label:'Lunes',count:1}],slots:[{date:'2026-11-02',time:'09:00',starts_at:'2026-11-02T09:00:00.000Z',ends_at:'2026-11-02T09:30:00.000Z',professional_id:'professional',professional_name:'Profesional sintético'}],issue:null},selected:{serviceId:'service',professionalId:'professional',professionalIds:[],bookingMode:'individual' as const,date:'2026-11-02'},mapsLink:null,turnstileSiteKey:null,bookingRequestId:requestId,integration:{publicKey:'a'.repeat(32),revision:1},presentation:{theme:'cita-suite' as const,modalities,intakeFields:[],videoInstructions:null},demo:false};
}
