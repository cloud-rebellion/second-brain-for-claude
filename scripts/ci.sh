#!/usr/bin/env bash
# Syntax and template validation; never installs hooks, tools or scheduled jobs.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PYCI'
import ast, json, pathlib, plistlib, subprocess
root = pathlib.Path.cwd()
paths = [pathlib.Path(x) for x in subprocess.check_output(['git','ls-files','-z']).decode().split('\0') if x]
counts = dict(shell=0, python=0, json=0, plist=0)
for name in ('README.md','SETUP.md','LICENSE'):
    assert pathlib.Path(name).is_file(), 'Missing repository entry point: '+name
for p in paths:
    if str(p).endswith(('.sh','.sh.template')):
        subprocess.run(['bash','-n',str(p)],check=True);counts['shell']+=1
    elif p.suffix=='.py':
        ast.parse(p.read_text(),filename=str(p));counts['python']+=1
    elif str(p).endswith(('.json','.json.template')):
        json.loads(p.read_text());counts['json']+=1
    elif str(p).endswith(('.plist','.plist.template')):
        value=plistlib.loads(p.read_bytes())
        assert isinstance(value,dict) and value.get('Label') and value.get('ProgramArguments'), 'Invalid launchd template: '+str(p)
        counts['plist']+=1
assert all(counts.values()), 'Validation coverage unexpectedly empty: '+str(counts)
print('Validated syntax/templates:',json.dumps(counts,sort_keys=True))
print('Installer, hooks and scheduled jobs were not executed.')
PYCI
