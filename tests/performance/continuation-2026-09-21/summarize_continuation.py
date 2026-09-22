"""Summarize this audit pass without replacing the historical baseline."""
import hashlib
import json
from pathlib import Path
import statistics

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def summarize():
    runs = []
    for folder in ("resize", "resize-trace", "start"):
        for path in sorted((HERE / folder).glob("*.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            errors = [line for line in data["errors"]
                      if line != "ERROR: Failed to read the root certificate store."]
            observations_ok = all(entry.get("matches", True) for entry in data["observations"])
            row = {"file": str(path.relative_to(HERE)), "config": data["config"],
                   "passed": data["completed"] and data["exit_code"] == 0
                   and not data["timed_out"] and not errors and observations_ok,
                   "errors": errors, "elapsed_seconds": data["elapsed"], "phases": {}}
            for phase in data["phases"]:
                if phase["phase"] == "boot":
                    continue
                metrics = {key: phase.get(key) for key in
                           ("frames", "fps", "mean_ms", "p95_ms", "max_ms", "over_33ms")}
                for metric in ("render_gpu_ms", "nodes", "draw_calls"):
                    values = [s[metric] for s in phase["samples"] if metric in s]
                    metrics[metric + "_median"] = statistics.median(values) if values else None
                row["phases"][phase["phase"]] = metrics
            for diag in data["diagnostics"]:
                if diag["label"] == "resize_set_size":
                    timings = sorted(diag["total_ms"])
                    row["setter_ms"] = dict(median=statistics.median(timings),
                                            p95=timings[int((len(timings)-1)*0.95)], max=max(timings))
                    expected = [f"({512 + i % 60 * 16}, {640 + i % 40 * 8})" for i in range(180)]
                    row["sizes_match"] = diag["actual_sizes"] == expected
                    row["passed"] &= row["sizes_match"] and len(timings) == 180
                elif diag["label"] == "resize_handler_calls":
                    calls = diag["calls"]
                    times = [c["ms"] for c in calls]
                    row["handler"] = {
                        "count": len(calls), "viewport": sum(c["source"] == "viewport" for c in calls),
                        "item_rect": sum(c["source"] == "item_rect" for c in calls),
                        "outermost_total_ms": sum(c["ms"] for c in calls if c["depth"] == 0),
                        "median_ms": statistics.median(times), "max_ms": max(times)}
                elif diag["label"] == "synchronous_start_game":
                    row["synchronous_start_ms"] = diag["ms"]
            runs.append(row)
    files = ["tests/performance/performance_probe.gd", "tests/performance/run_benchmarks.py",
             "resources/scripts/settings/debug.gd", "resources/scripts/core/GameManager.gd",
             "resources/scripts/core/session/GameSessionController.gd",
             "resources/scripts/settings/display/ScreenSizeOptions.gd",
             "resources/scripts/settings/GameOptionsController.gd",
             "resources/scripts/ui/CustomCursor.gd", "project.godot"]
    output = {"runs": runs, "source_sha256": {
        name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in files}}
    (HERE / "summary.json").write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(f"{sum(r['passed'] for r in runs)}/{len(runs)} valid runs")
    for row in runs:
        phase = row["phases"].get("resize_continuous", row["phases"].get("start", {}))
        print(row["file"], {k: round(v, 3) for k, v in phase.items() if isinstance(v, (int, float))},
              row.get("handler", {}), row.get("synchronous_start_ms", ""))
    return all(row["passed"] for row in runs) and bool(runs)


if __name__ == "__main__":
    raise SystemExit(0 if summarize() else 1)
