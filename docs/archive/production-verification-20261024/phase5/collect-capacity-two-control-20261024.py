import subprocess,json,pathlib,hashlib,zipfile,io,datetime
R=pathlib.Path.cwd();RUN=40099997857;SHA='0851de59ed7971debe2514e6d6851d142bbc5766';REPO='Juan4787/cita-suite-verificacion';out=R/'.verification/capacity-two-control-completion-20261024.json';assert not out.exists(),'CONTROL_ALREADY_COLLECTED_INSPECT_FIRST'
def gh(args):
 p=subprocess.run(['gh',*args],capture_output=True,timeout=65);assert p.returncode==0,'SUPPORTED_GITHUB_READ_FAILED';return p.stdout
state=json.loads(gh(['run','view',str(RUN),'--repo',REPO,'--json','status,conclusion,headSha,createdAt,updatedAt']));assert state['status']=='completed'and state['headSha']==SHA,'CONTROL_NOT_COMPLETE_OR_WRONG_SOURCE'
arts=json.loads(gh(['api',f'repos/{REPO}/actions/runs/{RUN}/artifacts']))['artifacts'];arts=[x for x in arts if x['name']==f'production-measure-{RUN}'];assert len(arts)==1 and not arts[0]['expired'],'EXACT_ARTIFACT_UNAVAILABLE';a=arts[0];raw=gh(['api',f'repos/{REPO}/actions/artifacts/{a["id"]}/zip']);digest=hashlib.sha256(raw).hexdigest();assert a['digest']=='sha256:'+digest,'ARTIFACT_DIGEST_DIFFERS';assert len(raw)<5*1024**2
archive=R/f'.verification/production-measure-{RUN}.zip';assert not archive.exists();archive.write_bytes(raw);archive.chmod(0o600)
with zipfile.ZipFile(io.BytesIO(raw))as z:
 files=[x for x in z.infolist()if not x.is_dir()];assert len(files)==1 and files[0].filename=='production-capacity-measure.json' and files[0].file_size<2*1024**2;data=z.read(files[0]);measure=json.loads(data)
assert measure['origin']=='https://app.cita-suite.workers.dev'and measure['practices']==2 and [x['repetition']for x in measure['repetitions']]==[1,2,3] and isinstance(measure['passedHttp'],bool)
for x in [*(r['summary']for r in measure['repetitions']),measure['publicBooking']['summary']]:
 for k in ['read','write']:assert x[k]['count']>0 and all(isinstance(x[k][p],(float,int))and x[k][p]>=0 for p in ['p50','p95','p99','max'])
dest=R/f'.verification/production-measure-{RUN}';assert not dest.exists();dest.mkdir(mode=0o700);f=dest/'production-capacity-measure.json';f.write_bytes(data);f.chmod(0o600)
# Only after the external generator has completed are PostgreSQL reports allowed.
for mode in ['integrity','report']:
 q=subprocess.run(['node','--max-old-space-size=128','scripts/production-capacity.mjs',mode],capture_output=True,text=True,timeout=180);log=R/f'.verification/capacity-two-control-after-{mode}-20261024.log';assert not log.exists();log.write_text((q.stdout or'')+(q.stderr or''));log.chmod(0o600);assert q.returncode==0,'POSTCONTROL_READ_FAILED_INSPECT_LOG'
r={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'run':RUN,'source':SHA,'ci':state,'artifactId':a['id'],'artifactSha256':digest,'jsonSha256':hashlib.sha256(data).hexdigest(),'artifactBytes':len(raw),'jsonBytes':len(data),'githubDigestMatched':True,'externalGeneratorCompletedBeforeDatabaseReports':True,'samplerAbsentByProtocol':True,'passedHttpAsReported':measure['passedHttp'],'scope':'Exact result of the single prespecified comparison. Preserve previous failed run40078561771; recompute all thresholds separately before interpretation. Integrity/report performed only after completion.'};out.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
