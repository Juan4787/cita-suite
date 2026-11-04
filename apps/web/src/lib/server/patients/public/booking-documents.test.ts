import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { RequestEvent } from '@sveltejs/kit';
const mocks = vi.hoisted(() => ({ rpc: vi.fn(), info: vi.fn(), signed: vi.fn(), limits: vi.fn() }));
vi.mock('./booking-information', () => ({ informationContext: async (event: RequestEvent) => ({ token: event.params.token,
 admin: { rpc: mocks.rpc, storage: { from: () => ({ info: mocks.info, createSignedUrl: mocks.signed }) } } }) }));
vi.mock('$lib/server/platform/rate-limits', async (original) => ({ ...await original<Record<string,unknown>>(), enforceRateLimits: mocks.limits }));
import { createPublicPatientDocumentUpload, createPublicPatientDocumentCompletion } from './booking-documents';
const token='a'.repeat(64), fileId='60000000-0000-4000-8000-000000000001', requestId='60000000-0000-4000-8000-000000000002';
const file={ id:fileId, status:'uploading', storage_bucket:'patient-clinical-files', storage_path:'own/file/original.png', mime_type:'image/png', bytes:32 };
const event=(body: unknown = {}) => ({ params:{token,fileId}, getClientAddress:()=> '127.0.0.1', fetch:vi.fn(),
 request:new Request('https://example.test/gestion/'+token+'/documentos',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(body)}) }) as unknown as RequestEvent;
beforeEach(()=>{
 vi.clearAllMocks();
 mocks.rpc.mockImplementation(async(name:string)=>({data:name==='get_public_patient_document_upload'?file:fileId,error:null}));
 mocks.info.mockResolvedValue({data:{size:32,contentType:'image/png'},error:null});
 mocks.signed.mockResolvedValue({data:{signedUrl:'https://storage.example.test/synthetic-signed-file'},error:null});
 const bytes=new Uint8Array(32);bytes.set([0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]);
 vi.stubGlobal('fetch',vi.fn().mockImplementation(async()=>new Response(bytes)));
});
afterEach(()=>vi.unstubAllGlobals());
describe('Patient document provider/SQL boundary',()=>{
 for(const legacy of [true,false]){
  it(`verifies actual image bytes before completing through the explicit ${legacy?'legacy':'capability'} channel`,async()=>{
   const response=await createPublicPatientDocumentCompletion(legacy)(event({p_legacy:!legacy,token:'b'.repeat(64)}));
   expect(response.status).toBe(200);
   expect(await response.json()).toEqual({ready:true,id:fileId});
   expect(mocks.rpc).toHaveBeenNthCalledWith(1,'get_public_patient_document_upload',{p_token:token,p_file_id:fileId,p_legacy:legacy});
   expect(globalThis.fetch).toHaveBeenCalledOnce();
   expect(mocks.rpc).toHaveBeenNthCalledWith(2,'complete_public_patient_document_upload',{p_token:token,p_file_id:fileId,p_legacy:legacy,p_bytes:32,p_mime:'image/png'});
  });
  it(`keeps the ${legacy?'legacy':'capability'} channel on upload start and ignores payload authority`,async()=>{
   mocks.rpc.mockResolvedValue({data:{...file,status:'ready'},error:null});
   const response=await createPublicPatientDocumentUpload(legacy)(event({requestId,filename:'own.png',mime:'image/png',bytes:32,sha256:'c'.repeat(64),note:'My image',p_legacy:!legacy,token:'b'.repeat(64)}));
   expect(response.status).toBe(200);
   expect(await response.json()).toEqual({id:fileId,already_complete:true});
   expect(mocks.rpc).toHaveBeenCalledWith('begin_public_patient_document_upload',expect.objectContaining({p_token:token,p_legacy:legacy,p_request_id:requestId}));
   expect(globalThis.fetch).not.toHaveBeenCalled();
  });
 }
 it('does not mark Ready when authority was revoked while the provider bytes were being checked',async()=>{
  mocks.rpc.mockImplementation(async(name:string)=>name==='complete_public_patient_document_upload'
   ?{data:null,error:new Error('BOOKING_INFORMATION_UNAVAILABLE')}:{data:file,error:null});
  const response=await createPublicPatientDocumentCompletion(false)(event());
  expect(globalThis.fetch).toHaveBeenCalledOnce();
  expect(response.status).toBe(404);
  const body=await response.json();expect(body.ready).toBeUndefined();expect(body.message).toContain('Contactá al consultorio');
  expect(JSON.stringify(body)).not.toContain('BOOKING_INFORMATION_UNAVAILABLE');
 });
 it('does not announce Ready for an empty completion response after valid provider verification',async()=>{
  mocks.rpc.mockImplementation(async(name:string)=>({data:name==='get_public_patient_document_upload'?file:null,error:null}));
  const response=await createPublicPatientDocumentCompletion(false)(event());
  expect(response.status).toBe(503);
  const body=await response.json();expect(body.ready).toBeUndefined();expect(body.message).toContain('Volvé a intentar confirmarlo');
 });
 it('does not call completion when provider content differs from the declared image',async()=>{
  vi.mocked(globalThis.fetch).mockResolvedValueOnce(new Response(new Uint8Array(32)));
  const response=await createPublicPatientDocumentCompletion(false)(event());
  expect(response.status).toBe(400);
  expect(mocks.rpc.mock.calls.map(([name])=>name)).toEqual(['get_public_patient_document_upload']);
 });
});
