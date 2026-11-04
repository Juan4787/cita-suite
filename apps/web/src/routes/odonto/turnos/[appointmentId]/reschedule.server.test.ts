import { beforeEach, describe, expect, it, vi } from 'vitest';
const mocks = vi.hoisted(() => ({ submit: vi.fn(),context: vi.fn(),admin: vi.fn(),push: vi.fn(),calendar: vi.fn() }));
vi.mock('$env/dynamic/private',()=>({ env: {} }));
vi.mock('$lib/server/access/public/business',()=>({ demoBusinessContext: vi.fn() }));
vi.mock('$lib/server/access/public/odonto-context',()=>({ getOdontoContext: mocks.context }));
vi.mock('$lib/server/platform/supabase',()=>({ createSupabaseAdminClient: mocks.admin }));
vi.mock('$lib/server/scheduling/public/staff-management-flow',()=>({ submitStaffManagementAction: mocks.submit }));
vi.mock('$lib/server/integrations/public/google-calendar',()=>({ processAppointmentGoogleCalendarSync: mocks.calendar }));
vi.mock('$lib/server/integrations/public/push',()=>({ sendReschedulePushNotice: mocks.push }));
vi.mock('$lib/server/scheduling/public/reminders',()=>({ buildAppointmentActivationDelivery: vi.fn(),buildArgentineWaMeUrl: vi.fn(),buildRescheduleWhatsAppMessage: vi.fn() }));
vi.mock('$lib/server/integrations/public/messaging',()=>({ publicRescheduleUrl: vi.fn() }));
const { actions } = await import('./+page.server');
const change = { changed: true,idempotentReplay: false,startsAt: '2026-12-02T15:00:00Z',status: 'reserved' };
const observed = { operation_id: 'original-operation',expected_revision: 'original-revision',slot_starts_at: change.startsAt,
 reprogram_date: '2026-12-02',ignore_break: 'false',availability_revision: '9' };
const read = {}, write = {};
const business = { canOperate: true,business: { id: 'business',timezone: 'America/Argentina/Buenos_Aires' } };
const call = (kind: 'reschedule'|'update_status' = 'reschedule') => actions[kind]({
 request: new Request(`https://app.test/odonto/turnos/appointment?/${kind}`,{ method: 'POST',body: new URLSearchParams(observed) }),
 params: { appointmentId: 'appointment' },locals: { auth: { access_token: 'token' } },fetch: vi.fn(),cookies: {} } as never);
beforeEach(()=>{
 vi.clearAllMocks();mocks.context.mockResolvedValue({ supabase: read,business,userId: 'verified-actor' });
 mocks.admin.mockResolvedValue(write);mocks.submit.mockResolvedValue({ success: true,result: change });
 mocks.push.mockResolvedValue(undefined);mocks.calendar.mockResolvedValue(undefined);
});
describe('staff detail route after atomic command',()=>{
 it('passes the original form and verified actor to the command, then attempts external effects',async()=>{
  await expect(call()).rejects.toMatchObject({ status:303,location:'/odonto/turnos/appointment?from_date=2026-12-02&reprogram_date=2026-12-02&rescheduled=1' });
  const args=mocks.submit.mock.calls[0];expect(args.slice(0,3)).toEqual([read,{ writer:write,business:business.business,userId:'verified-actor',appointmentId:'appointment' },'reschedule']);
  expect(Object.fromEntries(args[3])).toEqual(observed);
  expect(mocks.push).toHaveBeenCalledOnce();expect(mocks.calendar).toHaveBeenCalledOnce();
 });
 it('external failures do not turn a committed change into a rejected action',async()=>{
  mocks.push.mockRejectedValueOnce(new Error('provider down'));mocks.calendar.mockRejectedValueOnce(new Error('provider down'));
  await expect(call()).rejects.toMatchObject({ status:303 });expect(mocks.submit).toHaveBeenCalledOnce();
 });
 it.each([{ changed:false,idempotentReplay:false },{ changed:true,idempotentReplay:true }])('does not repeat immediate effects for %o',async flags=>{
  mocks.submit.mockResolvedValueOnce({ success:true,result:{ ...change,...flags } });
  expect(await call()).toMatchObject({ success:true });expect(mocks.push).not.toHaveBeenCalled();expect(mocks.calendar).not.toHaveBeenCalled();
 });
 it('preserves an uncertain operation for the rendered retry instead of redirecting to a fresh form',async()=>{
  const retry={ action:'reschedule',fields:observed };mocks.submit.mockResolvedValueOnce({ success:false,message:'Comprobar',retry });
  expect(await call()).toMatchObject({ status:503,data:{ success:false,retry } });
  expect(mocks.push).not.toHaveBeenCalled();expect(mocks.calendar).not.toHaveBeenCalled();
 });
 it('rejects a known conflict without external effects',async()=>{
  mocks.submit.mockResolvedValueOnce({ success:false,message:'Revisá el turno' });
  expect(await call()).toMatchObject({ status:409 });expect(mocks.push).not.toHaveBeenCalled();expect(mocks.calendar).not.toHaveBeenCalled();
 });
 it('does not dispatch when the verified context cannot operate',async()=>{
  mocks.context.mockResolvedValueOnce({ supabase:read,business:{ ...business,canOperate:false },userId:'actor' });
  expect(await call()).toMatchObject({ status:403 });expect(mocks.submit).not.toHaveBeenCalled();expect(mocks.admin).not.toHaveBeenCalled();
 });
 it('attempts calendar cancellation only for a newly committed cancellation',async()=>{
  mocks.submit.mockResolvedValueOnce({ success:true,result:{ ...change,status:'cancelled' } });
  expect(await call('update_status')).toMatchObject({ success:true });expect(mocks.calendar).toHaveBeenCalledOnce();expect(mocks.push).not.toHaveBeenCalled();
 });
});
