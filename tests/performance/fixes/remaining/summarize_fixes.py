"""Compare valid trials, retaining failed experiments outside the comparison."""
import hashlib
import json
from pathlib import Path
import statistics

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def read_runs(folders):
    valid, rejected = [], []
    for folder in folders:
        for path in sorted((HERE / folder).glob("*.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            errors = [e for e in data["errors"]
                      if e != "ERROR: Failed to read the root certificate store."]
            passed = (data["completed"] and data["exit_code"] == 0 and not data["timed_out"]
                      and not errors and all(o.get("matches", True) for o in data["observations"]))
            row = {"file": path.relative_to(HERE).as_posix(), "config": data["config"],
                   "errors": errors, "phases": {}}
            for phase in data["phases"]:
                row["phases"][phase["phase"]] = {
                    k: phase.get(k) for k in ("fps", "p95_ms", "max_ms", "over_33ms", "seconds")}
            (valid if passed else rejected).append(row)
    return valid, rejected


def summarize():
    before, rejected = read_runs(["before", "before-retry"])
    after, failures = read_runs(["after-coalesced"])
    rejected.extend(failures)
    output = {"before": before, "after": after, "excluded": rejected, "comparison": {}}
    states, state_failures = read_runs(["validated-states"])
    output["validated_states"] = states
    output["excluded"].extend(state_failures)
    for scenario, phase in [("baseline", "start"), ("resize", "resize_continuous")]:
        result = {}
        for label, runs in [("before", before), ("after", after)]:
            selected = [r for r in runs if r["config"]["scenario"] == scenario]
            metrics = {}
            for key in ("fps", "p95_ms", "max_ms", "over_33ms"):
                values = [r["phases"][phase][key] for r in selected]
                if values:
                    metrics[key] = dict(min=min(values), median=statistics.median(values), max=max(values))
            boot = [r["phases"]["boot"]["seconds"] for r in selected]
            metrics["boot_seconds"] = dict(min=min(boot), median=statistics.median(boot), max=max(boot))
            result[label] = metrics
        output["comparison"][phase] = result
    files = ["resources/scripts/core/GameManager.gd", "resources/scripts/settings/GameOptionsController.gd",
             "resources/scripts/effects/DustPool.gd", "resources/scripts/effects/RenderWarmup.gd",
             "tests/performance/performance_probe.gd"]
    output["source_sha256"] = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in files}
    (HERE / "summary.json").write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(json.dumps(output["comparison"], indent=2))
    print(f"Valid trials: {len(before)} before / {len(after)} after; {len(rejected)} excluded")


if __name__ == "__main__":
    summarize()
