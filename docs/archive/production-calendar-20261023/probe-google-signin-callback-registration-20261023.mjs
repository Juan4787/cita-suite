import {createHash,randomBytes} from 'node:crypto';import {readFileSync,writeFileSync} from 'node:fs';
const source={clientId:'372761266416-6pt6cuh73a5s4uttv31co0jc43ifrmtc.apps.googleusercontent.com',redirectUri:'https://yjzferwuzbtgpmdnzlcb.supabase.co/auth/v1/callback'};
const client=source.clientId;
const probe=async(redirectUri)=>{
 const challenge=createHash('sha256').update(randomBytes(48)).digest('base64url');
 const url=new URL('https://accounts.google.com/o/oauth2/v2/auth');
 url.search=new URLSearchParams({client_id:client,redirect_uri:redirectUri,response_type:'code',scope:'openid email profile',access_type:'offline',state:randomBytes(32).toString('base64url'),code_challenge:challenge,code_challenge_method:'S256',prompt:'select_account'}).toString();
 const result={redirectUri,hops:[],redirectMismatch:false,providerErrorPage:false,loginPageReached:false,errorCodes:[]};let next=url;
 for(let i=0;i<4;i++){
  if(next.origin!=='https://accounts.google.com')break;
  const r=await fetch(next,{redirect:'manual',signal:AbortSignal.timeout(20000)}),body=await r.text();
  const error=next.searchParams.get('authError');let decoded='';try{if(error)decoded=Buffer.from(error,'base64url').toString('utf8')}catch{}
  result.hops.push({status:r.status,path:next.pathname});
  const codes=['redirect_uri_mismatch','invalid_request','invalid_client','deleted_client','access_denied'].filter(code=>decoded.includes(code)); result.errorCodes=[...new Set([...result.errorCodes,...codes])];
  result.redirectMismatch||=codes.includes('redirect_uri_mismatch');
  result.providerErrorPage||=next.pathname.includes('/oauth/error');
  result.loginPageReached||=r.status===200&&/\/signin\/(identifier|accountchooser)/.test(next.pathname)&&!result.providerErrorPage;
  if(r.status<300||r.status>=400)break;
  try{next=new URL(r.headers.get('location'),next)}catch{break}
 }
 return result;
};
const negative=await probe('https://yjzferwuzbtgpmdnzlcb.supabase.co/auth/v1/callback-verification-negative');
const actual=await probe(source.redirectUri);
const receipt={at:new Date().toISOString(),scope:'Two unauthenticated Google authorization requests; negative callback control first. No account selected, no consent, no callback code, no private URL/state/response body persisted. Google sign-in callback registration preflight only; Supabase app redirect allowlist and complete login remain unproven.',clientId:client,negative,actual,negativeControlDetected:negative.redirectMismatch,canonicalCallbackAcceptedBeforeLogin:negative.redirectMismatch&&!actual.redirectMismatch&&!actual.providerErrorPage&&actual.loginPageReached,completeGoogleAuthorizationVerified:false};
writeFileSync('.verification/production-google-signin-callback-registration-20261023.json',JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify(receipt));
if(!receipt.negativeControlDetected||!receipt.canonicalCallbackAcceptedBeforeLogin)process.exitCode=1;
