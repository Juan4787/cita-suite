import { beforeEach, describe, expect, it, vi } from 'vitest';
const mocks=vi.hoisted(()=>({ raw:vi.fn(), management:vi.fn(), create:vi.fn(), env:{} as Record<string,string> }));
vi.mock('$env/dynamic/private',()=>({env:mocks.env}));
vi.mock('$lib/server/platform/supabase',()=>({createSupabaseAdminClient:mocks.create}));
vi.mock('./patient-management',()=>({loadPatientManagementView:mocks.management}));
vi.mock('./public-appointments',()=>({loadPublicAppointmentByToken:mocks.raw,demoPublicAppointment:(token:string)=>({token})}));
import { loadAppointmentForManagementAccess, loadAppointmentForToken } from './appointment-token';
const client={owned:true};const token='a'.repeat(64);
beforeEach(()=>{vi.clearAllMocks();delete mocks.env.DEMO_MODE;mocks.create.mockResolvedValue(client);mocks.raw.mockResolvedValue({token:'stable-calendar'});});
describe('Calendar identity and management authority stay separate',()=>{
 for(const legacy of [true,false]) it(`loads only the explicit ${legacy?'legacy':'capability'} management projection`,async()=>{
  mocks.management.mockResolvedValue({appointment:{token:'stable-calendar'}});
  const result=await loadAppointmentForManagementAccess(fetch,{token,legacy});
  expect(mocks.management).toHaveBeenCalledWith(client,{token,legacy});expect(mocks.raw).not.toHaveBeenCalled();
  expect(result.appointment).toEqual({token:'stable-calendar'});
 });
 it('does not fall back to a readable stable calendar identity when management was revoked',async()=>{
  mocks.management.mockResolvedValue(null);
  expect(await loadAppointmentForManagementAccess(fetch,{token,legacy:true})).toMatchObject({appointment:null});
  expect(mocks.raw).not.toHaveBeenCalled();
  expect((await loadAppointmentForToken(fetch,token)).appointment).toEqual({token:'stable-calendar'});
 });
 it('does not query private data for an invalid URL token',async()=>{
  expect(await loadAppointmentForManagementAccess(fetch,{token:'invalid',legacy:false})).toMatchObject({appointment:null,supabase:null});
  expect(mocks.create).not.toHaveBeenCalled();
 });
 it('preserves provider/contract errors instead of turning them into a raw-token fallback',async()=>{
  mocks.management.mockRejectedValue(new Error('private contract failure'));
  await expect(loadAppointmentForManagementAccess(fetch,{token,legacy:false})).rejects.toThrow('private contract failure');
  expect(mocks.raw).not.toHaveBeenCalled();
 });
});
