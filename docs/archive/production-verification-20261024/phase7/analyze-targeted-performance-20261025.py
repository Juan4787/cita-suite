from pathlib import Path
import json, statistics, re, hashlib, datetime, subprocess

root = Path.cwd()
v = root / '.verification'
out = v / 'targeted-performance-analysis-20261025.json'
assert not out.exists()
def read(name):
    return json.loads((v / name).read_text())
def distribution(values):
    assert values and all(isinstance(x, (int, float)) and x >= 0 for x in values)
    return {'n': len(values), 'minimum': min(values), 'median': statistics.median(values), 'maximum': max(values)}
http = read('targeted-performance-http-baseline-20261025.json')
sql = read('targeted-performance-sql-baseline-v3-20261025.json')
cpu = read('targeted-performance-pure-cpu-20261025.json')
fixture = read('targeted-performance-fixture-20261025.json')
ci = read('targeted-performance-ci-20261025.json')
fast = read('targeted-performance-origin-fast-20261025.json')
assert ci['ok'] and fast['ok'] and ci['source'] == fast['source']
assert http['status'] == sql['status'] == 'complete'
assert len(http['requests']) == 22 and len(http['components']) == 24 and len(sql['plans']) == 43
assert all(r['status'] == 200 for r in http['requests'])
assert all(c['ownedReadback'] for c in http['created']) and len(http['created']) == 3
assert fixture['status'] == 'cleaned' and fixture['secretRemoved'] and not fixture['applicationCredentialsChanged']
for key in ['businesses', 'patients', 'appointments', 'storedObjects', 'storedObjectBytes', 'calendarEvents', 'calendarConnections']:
    assert fixture['before'][key] == fixture['afterCleanup'][key]
assert fixture['afterCleanup']['capacity'] == fixture['afterCleanup']['capacityOwners'] == 0
assert sql['pre']['appointments'] == sql['post']['appointments'] == 12003
assert sql['pre']['statementStatsReset'] and sql['pre']['statementStatsReset'] == sql['post']['statementStatsReset']
runtime = '0851de59ed7971debe2514e6d6851d142bbc5766'
differences = subprocess.check_output(['git', 'diff', '--name-only', runtime, ci['source'], '--',
    'apps', 'packages', 'supabase', '.node-version', 'package.json', 'pnpm-lock.yaml', 'pnpm-workspace.yaml'], text=True).splitlines()
assert len(differences) == 15 and all(x.startswith('apps/web/output/playwright/') and x.endswith('.png') for x in differences)
sqlgroups = {}
for plan in sql['plans']:
    sqlgroups.setdefault(re.sub(r'_r\d+$', '', plan['name']), []).append(plan['plan']['Execution Time'])
assert sorted(len(x) for x in sqlgroups.values()) == [3] + [5]*8
summary = json.loads((root / ci['summaryPath']).read_text())
diagnostic = summary['scenarios'][0]['targeted']
def httpgroups(records):
    result = {}
    for name in sorted({r['name'] for r in records}):
        rows = [r for r in records if r['name'] == name]
        result[name] = {'clientBodyMs': distribution([r['clientBodyMs'] for r in rows]),
            'serverWallMs': distribution([r['timing']['serverTotalMs'] for r in rows]),
            'authWallMs': distribution([r['timing']['auth'] for r in rows]),
            'longestHttpToHeadersMs': distribution([r['timing']['db_max'] for r in rows]),
            'httpTripsToAuthAndRest': sorted({r['timing']['db_http'] for r in rows})}
    return result
components = {}
for r in http['components']:
    components.setdefault(r['name'], []).append(r['clientBodyMs'])
sources = [
    'targeted-performance-protocol-20261025.json', 'targeted-performance-preflight-20261025.json',
    'targeted-performance-http-baseline-20261025.json', 'targeted-performance-sql-baseline-v3-20261025.json',
    'targeted-performance-pure-cpu-20261025.json', 'targeted-performance-integrity-20261025.json',
    'targeted-performance-fixture-20261025.json', 'targeted-performance-nested-boundary-20261025.json',
    'targeted-performance-origin-fast-20261025.json', 'targeted-performance-ci-20261025.json']
r = {'at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'runtime': runtime,
     'diagnosticSource': ci['source'], 'fastRun': fast['run'], 'diagnosticRun': ci['run'],
     'productionHttp': httpgroups(http['requests']),
     'productionComponentsMs': {k: distribution(x) for k,x in components.items()},
     'sqlExecutionMs': {k: distribution(x) for k,x in sqlgroups.items()},
     'rootPlanBufferObservations': {k: distribution([x['plan']['Plan'].get(k,0) for x in sql['plans']])
         for k in ['Shared Hit Blocks','Shared Read Blocks','Temp Read Blocks','Temp Written Blocks']},
     'workerdCiHttp': httpgroups(diagnostic['records']),
     'workerdSampledProfiles': diagnostic['profiles'],
     'localNodePureCalculator': {'first': cpu['measurements'][0],
         'warmCpuMs': distribution([r['cpuMs'] for r in cpu['measurements'][1:]]),
         'iterations': len(cpu['measurements']), 'scope': cpu['scope']},
     'preservation': {'fixtureCleaned': True, 'temporarySecretRemoved': True,
         'existingBusinessCalendarStorageCountsPreserved': True, 'applicationCredentialsChanged': False,
         'compiledSourcesUnchanged': True, 'onlyAppsDifferencesFromRuntime': differences},
     'limitations': [
         'One practice, one selected patient, few sequential requests; neither two-practice capacity nor worst-case patient history.',
         'Every measured root plan reported zero Shared Read Blocks and zero temporary blocks; these observations do not cover cold buffers or instance pressure.',
         'SQL and HTTP observations are separate; subtracting them does not yield a measured infrastructure delay or CPU.',
         'Server-Timing db sums overlapping fetch-to-header intervals including Auth; it is not SQL execution or critical-path time.',
         'EXPLAIN total times include nested RPC work; nested plans were unavailable without privileged settings, which were not changed.',
         'Only indices and loops actually exposed by the patient plans can be described; no inference about unseen nested plans.',
         'CI hot-path sampling is not hosted or billable CPU. Existing busyMs omits idle/program/GC; sample attribution is approximate.',
         'Short fast samples do not refute the two failed hosted loads or establish a unique provider bottleneck.',
         'Unchanged pg_stat_statements reset was observed for these probes; no global activity-counter delta is attributed exclusively to them.'
     ],
     'launchApproved': False, 'paidServiceActivated': False,
     'sourceHashes': {name: hashlib.sha256((v/name).read_bytes()).hexdigest() for name in sources}}
out.write_text(json.dumps(r, indent=2) + '\n')
print(json.dumps({'analysis': str(out.relative_to(root)), 'sql': r['sqlExecutionMs'],
                  'production': r['productionHttp'], 'ci': r['workerdCiHttp'],
                  'profiles': [{'name':p['name'],'requests':p['requests'],'sampledMs':p['sampledMs'],
                      'busyMs':p['busyMs'],'topSelf':p['self'][:15]} for p in diagnostic['profiles']]}))
