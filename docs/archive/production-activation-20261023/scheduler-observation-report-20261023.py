"""Read-only evidence classifier. Routine success is distinct from launch acceptance."""
import json,math,sys
from datetime import datetime,timezone
from pathlib import Path
PERIODS={'push':5,'calendar':5,'reviews':10,'uploads':15}
KINDS=set(PERIODS)|{'commercial','storage'}
def dt(value):return datetime.fromisoformat(value.replace('Z','+00:00'))
def finite(value):return type(value) in (int,float) and math.isfinite(value)
def analyze(rows,metadata):
 findings=[];groups={kind:[] for kind in KINDS};cpu_excess=[];cpu_missing=[]
 for i,row in enumerate(rows):
  kind=row.get('path','').removeprefix('/internal/jobs/');job=row.get('job') or {};codes=[]
  if kind not in KINDS:codes.append('unknown-route')
  else:groups[kind].append(row)
  if row.get('status')!=200 or row.get('outcome')!='ok' or job.get('ok') is not True:codes.append('failed-request-or-receipt')
  if job.get('kind')!=kind:codes.append('receipt-route-mismatch')
  if job.get('profile')!='free' or job.get('maxCalls')!=40:codes.append('wrong-budget-profile')
  used,db,provider=(job.get(k) for k in ('usedCalls','databaseRequests','providerRequests'))
  if not all(finite(v) and v>=0 for v in (used,db,provider)) or used>40 or used!=1+db+provider:codes.append('invalid-chain-counts')
  elapsed=job.get('elapsedMs')
  if not finite(elapsed) or not 0<=elapsed<=20000:codes.append('invalid-job-duration')
  try:
   scheduled=dt(job.get('scheduledFor',''));at=row.get('at');minute=scheduled.minute
   valid_minute={'push':minute%5==0,'calendar':minute%5==1,'reviews':minute%10==2,'uploads':minute%15==3,'commercial':minute==17 and scheduled.hour%6==0,'storage':minute==17 and scheduled.hour%6==3}.get(kind,False)
   if not finite(at) or not 0<=at/1000-scheduled.timestamp()<=600 or not valid_minute:codes.append('invalid-schedule-or-delay')
  except (AttributeError,ValueError,TypeError):codes.append('missing-schedule')
  cpu=row.get('cpuTimeMs')
  if not finite(cpu) or cpu<0:cpu_missing.append(i)
  elif cpu>10:cpu_excess.append({'index':i,'kind':kind,'cpuTimeMs':cpu})
  if codes:findings.append({'index':i,'kind':kind if kind in KINDS else 'unknown','codes':codes})
 try:observed=(dt(metadata['reportedAt'])-dt(metadata['tailReadyAt'])).total_seconds()
 except (KeyError,TypeError,ValueError,AttributeError):observed=0
 missing=[];cadence=[]
 for kind,period in PERIODS.items():
  if len(groups[kind])<1200//(period*60):missing.append(kind)
  times=sorted(r['at']/1000 for r in groups[kind] if finite(r.get('at')))
  if any(b-a>period*60+120 for a,b in zip(times,times[1:])):cadence.append(kind)
 observation_healthy=observed>=1200 and metadata.get('parseFailures')==0
 routine_ok=observation_healthy and not findings and not missing and not cadence
 provider_flags={kind:sorted({(r.get('job') or {}).get('configured') for r in group if type((r.get('job') or {}).get('configured')) is bool}) for kind,group in groups.items() if group}
 provider_ready=all(provider_flags.get(kind)==[True] for kind in ('push','calendar','reviews'))
 maintenance=all(groups[kind] for kind in ('commercial','storage'))
 return {'reportedAt':metadata.get('reportedAt'),'readyAt':metadata.get('tailReadyAt'),'observedSeconds':observed,'events':len(rows),'counts':{k:len(v) for k,v in groups.items()},'observationHealthy20Minutes':observation_healthy,'missingRoutineCounts':missing,'cadenceGaps':cadence,'failures':findings,'routinesOperationalPassed':routine_ok,'cpuExcess':cpu_excess,'cpuMissing':cpu_missing,'freeCpuPassed':bool(rows) and not cpu_excess and not cpu_missing,'configuredFlags':provider_flags,'allThreeProvidersConfigured':provider_ready,'bothMaintenanceCategoriesObserved':bool(maintenance),'launchSchedulerAccepted':bool(routine_ok and provider_ready and maintenance and not cpu_excess and not cpu_missing),'scope':'Sanitized app events plus code/provider schedule evidence; empty queues do not prove delivery, backlog fairness or device receipt. Routine checks do not certify CPU or external providers.'}
if __name__=='__main__':
 if len(sys.argv)!=4:raise SystemExit('Use JOBS_JSONL LIVE_OR_FINAL_METADATA NEW_OUTPUT')
 source,meta,out=map(Path,sys.argv[1:]);result=analyze([json.loads(x) for x in source.read_text().splitlines() if x],json.loads(meta.read_text()))
 with out.open('x') as f:f.write(json.dumps(result,indent=2)+'\n')
 print(json.dumps(result))
 if not result['routinesOperationalPassed']:raise SystemExit(1)
