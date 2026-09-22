"""Diagnostic scenarios, isolated profiles; never touches the player's saves."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]


def run(godot, case, timeout):
    profile = (ROOT / '.godot' / 'audit-profiles' / uuid.uuid4().hex).resolve()
    assert profile.is_relative_to(ROOT / '.godot' / 'audit-profiles')
    profile.mkdir(parents=True)
    started = time.monotonic()
    env = dict(os.environ, APPDATA=str(profile), XDG_DATA_HOME=str(profile), XDG_CONFIG_HOME=str(profile))
    base_command = [godot, '--headless', '--path', str(ROOT), '--script', 'tests/audit/functional_probe.gd', '--']
    commands = [base_command + case.split(':')]
    if case == 'persistence':
        commands = [base_command + ['save', detail] for detail in ['persist_write', 'persist_read']]
    log = profile / 'output.log'
    with log.open('w', encoding='utf-8') as handle:
        for command in commands:
            process = subprocess.Popen(command, env=env, stdout=handle, stderr=subprocess.STDOUT)
            try:
                process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    output = log.read_text(encoding='utf-8', errors='replace')
    observations = [json.loads(line[6:]) for line in output.splitlines() if line.startswith('AUDIT ')]
    result = dict(case=case, seconds=round(time.monotonic()-started, 2), completed='AUDIT_DONE ' in output,
                  observations=observations, output=output, exit_code=process.returncode)
    shutil.rmtree(profile, ignore_errors=True)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--jobs', type=int, default=2)
    parser.add_argument('--timeout', type=int, default=120)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('cases', nargs='+')
    args = parser.parse_args()
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = [pool.submit(run, args.godot, case, args.timeout) for case in args.cases]
        for future in as_completed(futures):
            result = future.result()
            results.append(result)
            print(json.dumps({k: result[k] for k in ['case', 'seconds', 'completed']}), flush=True)
            for entry in result['observations']:
                if entry.get('matches') is False:
                    print(json.dumps(entry), flush=True)
            for line in result['output'].splitlines():
                if 'SCRIPT ERROR' in line: print(line, flush=True)
            args.report.write_text(json.dumps(results, indent=2), encoding='utf-8')


if __name__ == '__main__':
    main()
