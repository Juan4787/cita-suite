import copy,importlib.util,unittest
from datetime import datetime,timezone
from pathlib import Path
p=Path(__file__).with_name('scheduler-observation-report-20261023.py');spec=importlib.util.spec_from_file_location('scheduler_report',p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
meta={'tailReadyAt':'2026-10-23T14:40:00Z','reportedAt':'2026-10-23T15:01:30Z','parseFailures':0}
def row(kind,hour,minute):
 time=datetime(2026,10,23,hour,minute,tzinfo=timezone.utc)
 return {'path':'/internal/jobs/'+kind,'status':200,'outcome':'ok','at':int(time.timestamp()*1000)+500,'cpuTimeMs':4,'job':{'kind':kind,'ok':True,'profile':'free','maxCalls':40,'usedCalls':3,'databaseRequests':2,'providerRequests':0,'elapsedMs':200,'scheduledFor':time.isoformat(),'configured':True}}
rows=[row(k,h,minute) for k,times in {'push':[(14,45),(14,50),(14,55),(15,0)],'calendar':[(14,46),(14,51),(14,56),(15,1)],'reviews':[(14,42),(14,52)],'uploads':[(14,48)]}.items() for h,minute in times]
class Cases(unittest.TestCase):
 def test_positive_routines_still_do_not_certify_unobserved_maintenance(self):
  r=m.analyze(rows,meta);self.assertTrue(r['routinesOperationalPassed']);self.assertFalse(r['launchSchedulerAccepted'])
 def test_platform_ok_does_not_hide_real401(self):
  x=copy.deepcopy(rows);x[0]['status']=401;x[0]['job']=None;self.assertFalse(m.analyze(x,meta)['routinesOperationalPassed'])
 def test_cpu_excess_keeps_routine_and_free_results_separate(self):
  x=copy.deepcopy(rows);x[0]['cpuTimeMs']=42;r=m.analyze(x,meta);self.assertTrue(r['routinesOperationalPassed']);self.assertFalse(r['freeCpuPassed']);self.assertFalse(r['launchSchedulerAccepted'])
 def test_wrong_category_calls_time_schedule_are_each_rejected(self):
  for key,value in [('kind','calendar'),('usedCalls',41),('databaseRequests',1),('elapsedMs',20001),('scheduledFor','2026-10-23T14:44:00Z')]:
   x=copy.deepcopy(rows);x[0]['job'][key]=value;self.assertFalse(m.analyze(x,meta)['routinesOperationalPassed'],key)
 def test_alive_but_empty_or_short_or_parse_failure_cannot_pass(self):
  self.assertFalse(m.analyze([],meta)['routinesOperationalPassed'])
  for changed in [{'reportedAt':'2026-10-23T14:41:00Z'},{'parseFailures':1},{'tailReadyAt':None}]:self.assertFalse(m.analyze(rows,{**meta,**changed})['routinesOperationalPassed'])
 def test_no_cpu_or_disabled_provider_cannot_certify_launch(self):
  for change in ['cpu','calendar']:
   x=copy.deepcopy(rows)
   if change=='cpu':x[0]['cpuTimeMs']=None
   else:
    for r in x:
     if r['job']['kind']=='calendar':r['job']['configured']=False
   r=m.analyze(x,meta);self.assertTrue(r['routinesOperationalPassed']);self.assertFalse(r['launchSchedulerAccepted'])
unittest.main()
