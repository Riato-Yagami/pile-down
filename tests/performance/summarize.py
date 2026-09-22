"""Build compact evidence tables and a standalone figure from raw benchmark JSON."""
import csv
import json
from pathlib import Path
import statistics

HERE = Path(__file__).resolve().parent


def median(samples, key):
    values = [s[key] for s in samples if key in s]
    return statistics.median(values) if values else None


def main():
    results = [json.loads(p.read_text(encoding="utf-8")) | {"file": p.name}
               for p in sorted((HERE / "results").glob("*.json"))]
    rows = []
    runs = []
    for result in results:
        telemetry = result["process_samples"]
        cpu = [s for s in telemetry if "cpu_seconds" in s]
        cpu_percent = ((cpu[-1]["cpu_seconds"] - cpu[0]["cpu_seconds"]) /
                       (cpu[-1]["wall"] - cpu[0]["wall"]) * 100) if len(cpu) > 1 else None
        runs.append({"name": result["config"]["name"], "file": result["file"],
                     "seconds": result["elapsed"], "completed": result["completed"],
                     "cpu_percent_one_core": cpu_percent,
                     "peak_rss_mib": max((s.get("rss_bytes", 0) for s in telemetry), default=0) / 2**20,
                     "peak_private_mib": max((s.get("private_bytes", 0) for s in telemetry), default=0) / 2**20,
                     "failed_observations": [o for o in result["observations"] if o.get("matches") is False],
                     "script_errors": [e for e in result["errors"] if "SCRIPT ERROR" in e],
                     "errors": result["errors"], "metadata": result["metadata"]})
        for phase in result["phases"]:
            samples = phase["samples"]
            rows.append({"run": result["config"]["name"], "file": result["file"],
                         **{k: phase.get(k) for k in ["phase", "frames", "seconds", "fps", "fps_min_interval",
                                                      "mean_ms", "p95_ms", "p99_ms", "max_ms", "over_33ms"]},
                         "gpu_median_ms": median(samples, "render_gpu_ms"),
                         "render_cpu_median_ms": median(samples, "render_cpu_ms"),
                         "draw_calls_median": median(samples, "draw_calls"),
                         "static_end_mib": samples[-1]["static_bytes"] / 2**20,
                         "video_end_mib": samples[-1]["video_bytes"] / 2**20,
                         "texture_end_mib": samples[-1]["texture_bytes"] / 2**20,
                         **{k: samples[-1].get(k) for k in ["nodes", "objects", "resources", "orphans", "tweens", "background_layers"]}})
    with (HERE / "phases.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    (HERE / "summary.json").write_text(json.dumps({"runs": runs, "phases": rows}, indent=2), encoding="utf-8")
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5), constrained_layout=True)
    phases = ["menu", "start", "gameplay_idle", "round_played", "restart", "return_menu"]
    for name in ["states-A", "states-B", "states-C"]:
        selected = [next((r for r in rows if r["run"] == name and r["phase"] == phase), {}) for phase in phases]
        axes[0].plot(phases, [r.get("max_ms", 0) for r in selected], marker="o", label=name)
    axes[0].axhline(33.333, color="gray", linestyle="--", linewidth=1)
    axes[0].set(ylabel="Peak frame interval (ms)", title="State changes — 60 FPS cap")
    axes[0].tick_params(axis="x", rotation=30)
    axes[0].legend()
    stress = [r for r in rows if r["run"] == "stress" and r["phase"].startswith("restart_")]
    axes[1].plot(range(1, len(stress) + 1), [r["nodes"] for r in stress], marker=".", label="nodes")
    axes[1].set(xlabel="Restart cycle", ylabel="Nodes after cycle", title="Normal restart stress (absolute count)")
    axes[1].grid(alpha=0.2)
    fig.savefig(HERE / "performance-overview.svg")
    fig.savefig(HERE / "performance-overview.png", dpi=150)
    plt.close(fig)
    print(f"{len(results)} runs, {len(rows)} phases summarized")


if __name__ == "__main__":
    main()
