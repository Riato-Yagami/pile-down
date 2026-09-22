"""Serial, isolated Godot benchmarks. No fixed timestep, no parallel GPU runs."""
import argparse
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]


class Counters(ctypes.Structure):
    _fields_ = [("cb", wintypes.DWORD), ("PageFaultCount", wintypes.DWORD)] + [
        (name, ctypes.c_size_t) for name in ["PeakWorkingSetSize", "WorkingSetSize",
        "QuotaPeakPagedPoolUsage", "QuotaPagedPoolUsage", "QuotaPeakNonPagedPoolUsage",
        "QuotaNonPagedPoolUsage", "PagefileUsage", "PeakPagefileUsage", "PrivateUsage"]]


def process_sample(process):
    if os.name != "nt":
        return {}
    handle = wintypes.HANDLE(int(process._handle))
    memory = Counters()
    memory.cb = ctypes.sizeof(memory)
    ok = ctypes.windll.psapi.GetProcessMemoryInfo(handle, ctypes.byref(memory), memory.cb)
    times = [wintypes.FILETIME() for _ in range(4)]
    cpu_ok = ctypes.windll.kernel32.GetProcessTimes(handle, *(ctypes.byref(t) for t in times))
    result = {"wall": time.monotonic()}
    if ok:
        result.update(rss_bytes=memory.WorkingSetSize, private_bytes=memory.PrivateUsage)
    if cpu_ok:
        result["cpu_seconds"] = sum((t.dwHighDateTime << 32) + t.dwLowDateTime for t in times[2:]) / 1e7
    return result


def run(godot, config, outdir, timeout):
    identity = config.get("name", config["scenario"]) + "-" + uuid.uuid4().hex[:8]
    profile = ROOT / ".godot" / "audit-profiles" / identity
    profile.mkdir(parents=True)
    env = dict(os.environ, APPDATA=str(profile), XDG_DATA_HOME=str(profile), XDG_CONFIG_HOME=str(profile))
    command = [godot, "--path", str(ROOT), "--rendering-method", config.get("renderer", "gl_compatibility")]
    if config.get("headless"):
        command.append("--headless")
    command += ["--script", "tests/performance/performance_probe.gd", "--", json.dumps(config)]
    log = outdir / (identity + ".log")
    start = time.monotonic()
    telemetry = []
    with log.open("w", encoding="utf-8") as stream:
        process = subprocess.Popen(command, env=env, stdout=stream, stderr=subprocess.STDOUT)
        timed_out = False
        while process.poll() is None:
            telemetry.append(process_sample(process))
            if time.monotonic() - start > timeout:
                timed_out = True
                process.kill()
                break
            time.sleep(0.25)
        process.wait()
    output = log.read_text(encoding="utf-8", errors="replace")
    phases = [json.loads(line[5:]) for line in output.splitlines() if line.startswith("PERF ")]
    metadata = [json.loads(line[10:]) for line in output.splitlines() if line.startswith("PERF_META ")]
    observations = [json.loads(line[6:]) for line in output.splitlines() if line.startswith("AUDIT ")]
    diagnostics = [json.loads(line[10:]) for line in output.splitlines() if line.startswith("PERF_DIAG ")]
    result = dict(config=config, command=command, elapsed=time.monotonic()-start,
                  exit_code=process.returncode, timed_out=timed_out, completed="PERF_DONE" in output,
                  metadata=metadata, phases=phases, process_samples=telemetry, observations=observations, diagnostics=diagnostics,
                  errors=[line for line in output.splitlines() if "ERROR:" in line], log=log.name)
    (outdir / (identity + ".json")).write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(dict(name=identity, completed=result["completed"], seconds=round(result["elapsed"], 1), errors=result["errors"])), flush=True)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--matrix", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=ROOT / "tests/performance/results")
    parser.add_argument("--timeout", type=float, default=240)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for config in json.loads(args.matrix.read_text(encoding="utf-8")):
        run(args.godot, config, args.output, args.timeout)


if __name__ == "__main__":
    main()
