from pathlib import Path
import subprocess, json, hashlib, datetime, re

root = Path.cwd()
repo = 'Juan4787/cita-suite'
run = 40161186500
sha = '5930f73ab868ff9956408f04d0c1f102c1044a38'
out = root / '.verification/targeted-performance-ci-20261025.json'
assert not out.exists()
state = json.loads(subprocess.check_output([
    'gh', 'run', 'view', str(run), '--repo', repo,
    '--json', 'status,conclusion,headSha,createdAt,updatedAt,url'
], text=True))
assert state['status'] == 'completed' and state['headSha'] == sha
log = root / f'.verification/targeted-logs-{run}.zip'
dest = root / f'.verification/targeted-remote-{run}'
assert not log.exists() and not dest.exists()
result = subprocess.run(['gh', 'api', f'repos/{repo}/actions/runs/{run}/logs'],
                        capture_output=True, timeout=65)
assert result.returncode == 0 and len(result.stdout) < 24 * 1024**2
log.write_bytes(result.stdout)
log.chmod(0o600)
result = subprocess.run(['python3', 'scripts/collect-verification-evidence.py',
                         str(log), str(dest)], capture_output=True, text=True, timeout=60)
assert result.returncode == 0, 'EVIDENCE_RECOVERY_FAILED_INSPECT'
match = re.fullmatch(r'Recovered (\d+) evidence files; SHA-256 ([a-f0-9]{64})\n', result.stdout)
assert match
found = list(dest.glob('.verification/runs/*/capacity/summary.json'))
assert len(found) == 1, 'TARGETED_SUMMARY_MISSING_INSPECT_FAILURE_LOG'
summary = json.loads(found[0].read_text())
assert summary['mode'] == '--targeted' and len(summary['scenarios']) == 1
s = summary['scenarios'][0]
assert s['practices'] == 1 and s['seed']['patients'] == 6000 and s['seed']['appointments'] == 12000
d = s['targeted']
assert len(d['records']) == 22 and d['ownedCreationsPersisted'] == 3
counts = {name: sum(r['name'] == name for r in d['records'])
          for name in ['availability', 'patient_detail', 'creation_prepare', 'create_appointment']}
assert counts == {'availability': 8, 'patient_detail': 8, 'creation_prepare': 3, 'create_appointment': 3}
assert len(d['profiles']) == 3 and [p['name'] for p in d['profiles']] == [
    'availability', 'patient_detail', 'create_appointment']
assert [p['requests'] for p in d['profiles']] == [8, 8, 6]
assert all(p['sampledMs'] > 0 and p['self'] and p['total'] for p in d['profiles'])
assert s['integrity']['crossPractice'] == 0 and s['integrity']['overlaps'] == 0
c = s['cleanup']
assert c['passed'] and c['guards']['foreignMember'] and c['guards']['unknownPractice']
assert c['remaining'] == {'practices': 0, 'owners': 0}
assert c['practices'] == 1 and c['patients'] == 6000 and c['appointments'] == 12003 and c['ownersRemoved'] == 1
platforms = list(found[0].parent.glob('platform-state-1.json'))
assert len(platforms) == 1
p = json.loads(platforms[0].read_text())
assert len(p['containers']) == 4 and all(x.get('running') and not x.get('oomKilled') and not x.get('unavailable') for x in p['containers'])
assert p['connections']['deadlocks'] == 0 and p['authErrors'] == []
assert state['conclusion'] == 'success' and s['passed']
r = {'at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
     'repository': repo, 'run': run, 'source': sha, 'ci': state,
     'applicationSourceUnchanged': '0851de59ed7971debe2514e6d6851d142bbc5766',
     'runId': found[0].parent.parent.name,
     'evidenceFiles': int(match[1]), 'packageSha256': match[2],
     'privateWorkflowLogSha256': hashlib.sha256(log.read_bytes()).hexdigest(),
     'summaryPath': str(found[0].relative_to(root)), 'counts': counts,
     'ownedCreationsPersisted': 3, 'cleanup': c,
     'platformChecked': {'containers': 4, 'oomKilled': False, 'deadlocks': 0, 'authErrors': 0},
     'ok': True,
     'scope': 'Isolated one-practice workerd hot-path diagnostic, not hosted capacity or billable CPU certification. No production deployment or credentials.'}
out.write_text(json.dumps(r, indent=2) + '\n')
print(json.dumps(r))
