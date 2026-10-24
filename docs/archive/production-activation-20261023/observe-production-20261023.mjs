import {spawn} from 'node:child_process';
import {appendFileSync,readFileSync,writeFileSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {assertLightVerificationResources} from '../scripts/lib/verification-resources.mjs';
import {jobMeasurement,requestMeasurement,routeCatalogSha256,splitJsonObjects,summarizeJobMeasurements,summarizeRequestMeasurements} from '../scripts/lib/worker-tail.mjs';
assertLightVerificationResources();
const [run,minutesText]=process.argv.slice(2),minutes=Number(minutesText);
if(process.argv.length!==4||!/^[a-f0-9]{12}$/.test(run??'')||!Number.isInteger(minutes)||minutes<1||minutes>90)throw new Error('Use a new12hex run and duration1–90min');
const prefix=`.verification/production-observer-${run}`,paths={jobs:prefix+'-jobs.jsonl',requests:prefix+'-requests.jsonl',live:prefix+'-live.json',final:prefix+'-final.json'};
for(const path of Object.values(paths))if(existsSync(path))throw new Error('Observer evidence exists; no overwrite');
for(const path of [paths.jobs,paths.requests])writeFileSync(path,'',{flag:'wx'});
const sha=b=>createHash('sha256').update(b).digest('hex');
const metadata={run,minutes,startedAt:new Date().toISOString(),scope:'One read-only Wrangler tail; sanitized job and request metrics, no raw events or credentials persisted',observerSha256:sha(readFileSync(fileURLToPath(import.meta.url))),filterSha256:sha(readFileSync('scripts/lib/worker-tail.mjs')),routeCatalogSha256,paths};
const jobs=[],requests=[];let parseFailures=0,tailReadyAt=null;
const split=splitJsonObjects(text=>{
 let event;try{event=JSON.parse(text)}catch{parseFailures++;return}
 tailReadyAt??=new Date().toISOString();
 const job=jobMeasurement(event),request=requestMeasurement(event);
 if(job){jobs.push(job);appendFileSync(paths.jobs,JSON.stringify(job)+'\n')}
 if(request){requests.push(request);appendFileSync(paths.requests,JSON.stringify(request)+'\n')}
});
const child=spawn('node',['--max-old-space-size=192','apps/web/node_modules/wrangler/bin/wrangler.js','tail','app','--format','json','--config','apps/web/wrangler.jsonc'],{stdio:['ignore','pipe','pipe']});
child.stdout.setEncoding('utf8').on('data',split);child.stderr.on('data',()=>{});
const report=()=>({...metadata,reportedAt:new Date().toISOString(),tailReadyAt,parseFailures,jobs:summarizeJobMeasurements(jobs),requests:summarizeRequestMeasurements(requests)});
const heartbeat=setInterval(()=>{writeFileSync(paths.live,JSON.stringify(report(),null,2)+'\n');console.log(JSON.stringify({run,at:new Date().toISOString(),jobs:jobs.length,requests:requests.length,parseFailures}))},60000);
let stoppedByDuration=false;
const timeout=setTimeout(()=>{stoppedByDuration=true;child.kill('SIGINT')},minutes*60000);
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>child.kill('SIGINT'));
const end=await new Promise(resolve=>{child.once('error',()=>resolve({code:null,spawnError:true}));child.once('close',(code,signal)=>resolve({code,signal}))});
clearInterval(heartbeat);clearTimeout(timeout);
const final={...report(),finishedAt:new Date().toISOString(),...end,stoppedByDuration};writeFileSync(paths.final,JSON.stringify(final,null,2)+'\n',{flag:'wx'});writeFileSync(paths.live,JSON.stringify(final,null,2)+'\n');
console.log(JSON.stringify({run,finished:true,jobs:jobs.length,requests:requests.length,code:end.code,stoppedByDuration,parseFailures}));if(end.spawnError||(!stoppedByDuration&&end.code!==0&&end.signal!=='SIGINT'))process.exitCode=1;
