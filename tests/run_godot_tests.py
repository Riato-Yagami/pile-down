"""Run Godot tests with isolated saves and detect assertions even on exit code 0."""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
from pathlib import Path
import subprocess
import shutil
import time
import uuid


ROOT = Path(__file__).resolve().parents[1]


def run_test(godot, script, timeout):
    profile_root = (ROOT / ".godot" / "test-profiles").resolve()
    if not profile_root.is_relative_to(ROOT):
        raise ValueError("Test profiles must stay inside the project")
    profile_root.mkdir(parents=True, exist_ok=True)
    profile = profile_root / uuid.uuid4().hex
    profile.mkdir()
    try:
        env = os.environ.copy()
        env.update(APPDATA=str(profile), XDG_DATA_HOME=str(profile), XDG_CONFIG_HOME=str(profile))
        command = [godot, "--headless", "--path", str(ROOT), "--script", str(script)]
        log = profile / "test-output.log"
        with log.open("w", encoding="utf-8") as output_file:
            process = subprocess.Popen(command, env=env, stdout=output_file, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + timeout
            timed_out = False
            while process.poll() is None:
                output = log.read_text(encoding="utf-8", errors="replace")
                timed_out = time.monotonic() >= deadline
                if timed_out or "SCRIPT ERROR:" in output:
                    process.kill()
                    break
                time.sleep(0.1)
            process.wait()
            output = log.read_text(encoding="utf-8", errors="replace")
            # Windows sandbox certificate access is unrelated to script validation.
            errors = [line for line in output.splitlines()
                      if ("ERROR:" in line or "Assertion failed" in line)
                      and "Failed to read the root certificate store" not in line]
            if timed_out:
                errors.append(f"Timeout after {timeout}s")
            passed = process.returncode == 0 and not errors
        return {"test": script.name, "passed": passed, "errors": errors, "output": output}
    finally:
        # The resolved profile root was checked above; only this run's directory is removed.
        shutil.rmtree(profile, ignore_errors=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--jobs", type=int, default=2)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--report", type=Path)
    parser.add_argument("patterns", nargs="*", default=["test_*.gd"])
    args = parser.parse_args()
    scripts = sorted({path for pattern in args.patterns for path in (ROOT / "tests").glob(pattern)})
    if not scripts:
        parser.error("No matching tests")
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = [pool.submit(run_test, args.godot, script, args.timeout) for script in scripts]
        results = []
        for future in as_completed(futures):
            result = future.result()
            results.append(result)
            print(f"{'PASS' if result['passed'] else 'FAIL'} {result['test']}", flush=True)
            for error in result["errors"]:
                print(f"  {error}", flush=True)
    results.sort(key=lambda result: result["test"])
    if args.report:
        args.report.write_text(json.dumps(results, indent=2), encoding="utf-8")
    passed = sum(result["passed"] for result in results)
    print(f"{passed}/{len(results)} passed")
    return int(passed != len(results))


if __name__ == "__main__":
    raise SystemExit(main())
