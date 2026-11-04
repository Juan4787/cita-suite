import { beforeEach, describe, expect, it, vi } from 'vitest';
const mocks = vi.hoisted(() => ({ admin: vi.fn(), management: vi.fn() }));
vi.mock('$env/dynamic/private', () => ({ env: {} }));
vi.mock('$env/dynamic/public', () => ({ env: {} }));
vi.mock('$lib/server/platform/supabase', () => ({ createSupabaseAdminClient: mocks.admin }));
vi.mock('./patient-management', () => ({ loadPatientManagementView: mocks.management }));
import { loadPublicBookingPage } from './public-booking-page';

const id='11111111-1111-4111-8111-111111111111';
const token='a'.repeat(64);
const integration={ id:'22222222-2222-4222-8222-222222222222',businessId:'33333333-3333-4333-8333-333333333333',publicKey:'key',isActive:true };
const requestId='44444444-4444-4444-8444-444444444444';
const event=()=>({params:{},fetch:vi.fn(),url:new URL(`https://app.test/embed/v1/key?recover=1&request_id=${requestId}`),setHeaders:vi.fn()} as never);
let client: any;
beforeEach(()=>{
 vi.clearAllMocks();
 const chain: any={select:()=>chain,eq:()=>chain,maybeSingle:async()=>({data:{id,confirmation_token:token},error:null})};
 client={from:vi.fn(()=>chain)};
 mocks.admin.mockResolvedValue(client);
 mocks.management.mockResolvedValue({appointment:{id,business:{id:integration.businessId}}});
});
describe('creation recovery preserves current patient authority',()=>{
 it('does not expose the token of an already reassigned or revoked booking just because its original request key is known',async()=>{
  mocks.management.mockResolvedValueOnce(null);
  await expect(loadPublicBookingPage(event(),integration as never)).rejects.toMatchObject({status:404});
  expect(mocks.management).toHaveBeenCalledWith(client,{token,legacy:true});
 });
 it('does not redirect to a different appointment returned by a contradictory authority result',async()=>{
  mocks.management.mockResolvedValueOnce({appointment:{id:'different-appointment',business:{id:integration.businessId}}});
  await expect(loadPublicBookingPage(event(),integration as never)).rejects.toMatchObject({status:404});
 });
 it('recovers an unchanged initial booking without minting another capability or losing the committed result',async()=>{
  await expect(loadPublicBookingPage(event(),integration as never)).rejects.toMatchObject({status:303,location:`/turno/${token}?recuperado=1`});
  expect(mocks.management).toHaveBeenCalledExactlyOnceWith(client,{token,legacy:true});
 });
});
