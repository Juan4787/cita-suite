import { beforeEach, describe, expect, it, vi } from 'vitest';
const mocks=vi.hoisted(()=>({management:vi.fn(),stable:vi.fn(),integration:vi.fn()}));
vi.mock('$env/dynamic/private',()=>({env:{}}));
vi.mock('$lib/server/platform/supabase',()=>({createSupabaseAdminClient:vi.fn(async()=>({admin:true}))}));
vi.mock('./patient-management',()=>({loadPatientManagementView:mocks.management}));
vi.mock('./public-appointments',()=>({loadPublicAppointmentByToken:mocks.stable,demoPublicAppointment:vi.fn()}));
vi.mock('$lib/server/sites/public/booking-integration-request',()=>({resolveBookingIntegrationRequest:mocks.integration}));
import { load as notice } from '../../../../routes/turno/[token]/reprogramado/+page.server';
import { load as managedNotice } from '../../../../routes/gestion/[token]/reprogramado/+page.server';
import { load as embedded } from '../../../../routes/embed/v1/[integrationKey]/turno/[token]/+page.server';

const token='a'.repeat(64);
const appointment={id:'appointment',token,status:'reserved',is_past:false,business:{id:'business'},booking_context:{theme:'cita-suite'}};
const event=()=>({params:{token,integrationKey:'integration-key'},fetch:vi.fn(),setHeaders:vi.fn(),
 url:new URL('https://app.test/embed/v1/integration-key/turno/'+token)} as never);
beforeEach(()=>{
 vi.clearAllMocks();mocks.stable.mockResolvedValue(appointment);
 mocks.management.mockResolvedValue({appointment,integration:{id:'integration'},newBookingAllowed:true});
 mocks.integration.mockResolvedValue({integration:{id:'integration',businessId:'business',publicKey:'integration-key',theme:'cita-suite'},embed:{}});
});
describe('expanded public readers cannot borrow Calendar-only authority',()=>{
 it('withholds the reschedule detail after management revocation',async()=>{
  mocks.management.mockResolvedValueOnce(null);
  const result=await notice(event());
  expect(result).toMatchObject({appointment:null,active:false});
  expect(mocks.stable).not.toHaveBeenCalled();
 });
 it('withholds the framed receipt after management revocation',async()=>{
  mocks.management.mockResolvedValueOnce(null);
  await expect(embedded(event())).rejects.toMatchObject({status:404});
  expect(mocks.stable).not.toHaveBeenCalled();
 });
 it('preserves an authorized current reschedule detail',async()=>{
  await expect(notice(event())).resolves.toMatchObject({appointment,active:true,demo:false});
 });
 it('preserves an authorized framed receipt within its actual integration',async()=>{
  await expect(embedded(event())).resolves.toMatchObject({appointment,publicKey:'integration-key'});
 });
});


it('keeps a managed notice on its original capability channel',async()=>{
 await expect(managedNotice(event())).resolves.toMatchObject({appointment,active:true});
 expect(mocks.management).toHaveBeenCalledExactlyOnceWith({admin:true},{token,legacy:false});
 expect(mocks.stable).not.toHaveBeenCalled();
});
it('does not display the framed receipt through an unrelated integration',async()=>{
 mocks.management.mockResolvedValueOnce({appointment,integration:{id:'other-integration'},newBookingAllowed:true});
 await expect(embedded(event())).rejects.toMatchObject({status:404});
});
