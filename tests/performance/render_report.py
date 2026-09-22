"""Refresh measured tables in the audit; qualitative findings are edited separately."""
import json
from pathlib import Path
import re
import statistics

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def number(value):
    return "n/d" if value is None else f"{value:.2f}"


def span(values):
    values = [v for v in values if v is not None]
    if not values:
        return "n/d"
    return number(min(values)) if max(values) == min(values) else f"{min(values):.2f}–{max(values):.2f}"


def table(headers, rows):
    return "\n".join(["| " + " | ".join(headers) + " |", "|" + "---|" * len(headers)] +
                     ["| " + " | ".join(map(str, row)) + " |" for row in rows]) + "\n"


def main():
    summary = json.loads((HERE / "summary.json").read_text())
    rows, runs = summary["phases"], summary["runs"]
    excluded = {r["file"] for r in runs if r.get("script_errors")}
    rows = [r for r in rows if r["file"] not in excluded]
    raw = [json.loads((HERE / "results" / r["file"]).read_text()) for r in runs]
    measured = []
    baseline = [r for r in rows if r["run"].startswith("states-")]
    measured.append("### États du jeu, trois seeds, limite 60 FPS\n\nPlages entre trois essais ; pic = pire intervalle, GPU = plage des médianes échantillonnées.\n")
    phases = [r["phase"] for r in baseline if r["run"] == "states-A"]
    measured.append(table(["Phase", "FPS moyens", "FPS min intervalle", "Moyenne ms", "P95 ms", "Pic ms", "GPU ms", "Draw calls"], [
        [phase, span([r["fps"] for r in baseline if r["phase"] == phase]),
         span([r["fps_min_interval"] for r in baseline if r["phase"] == phase]),
         span([r["mean_ms"] for r in baseline if r["phase"] == phase]),
         span([r["p95_ms"] for r in baseline if r["phase"] == phase]),
         number(max(r["max_ms"] for r in baseline if r["phase"] == phase)),
         "n/d (initialisation)" if phase == "boot" else span([r["gpu_median_ms"] for r in baseline if r["phase"] == phase]),
         span([r["draw_calls_median"] for r in baseline if r["phase"] == phase])] for phase in phases]))
    measured.append("Les FPS minimum par intervalle, P99 et comptes de frames >33,333 ms sont dans [phases.csv](tests/performance/phases.csv). `boot` ne comprend pas le préchargement du script. Les valeurs GPU ne localisent pas individuellement les pics.\n")
    measured.append("### Chargement initial\n\nHorloge moteur au début/à la fin de `boot`, en secondes : la première colonne de temps inclut déjà le moteur et les préchargements. La durée de la sonde inclut instanciation, `_ready` et cinq frames. Ce ne sont pas des temps d’export Release ni des lectures disque à cache froid.\n")
    loads = []
    for run in raw:
        if run["config"]["name"].startswith("states-"):
            boot = next(p for p in run["phases"] if p["phase"] == "boot")
            loads.append([run["config"]["name"], number(boot["samples"][0]["time_ms"] / 1000), number(boot["seconds"]), number(boot["samples"][-1]["time_ms"] / 1000)])
    measured.append(table(["Essai", "Avant instanciation s", "Durée boot s", "Menu disponible, horloge moteur s"], loads))
    measured.append("### Renderers, fenêtre 512×640, sans limite ni VSync\n\nUn essai par renderer : comparaison exploratoire, pas un classement reproductible de moteurs. Même seed PERF-A.\n")
    measured.append(table(["Renderer", "FPS menu", "FPS gameplay", "P95 gameplay ms", "Pic gameplay ms", "GPU gameplay ms"], [
        [run["metadata"][0]["renderer"], number(next(r["fps"] for r in rows if r["run"] == run["name"] and r["phase"] == "menu")),
         *[number(next(r[k] for r in rows if r["run"] == run["name"] and r["phase"] == "gameplay_idle")) for k in ["fps", "p95_ms", "max_ms", "gpu_median_ms"]]]
        for run in runs if run["name"].startswith("renderer-")]))
    measured.append("### Affichage et résolution\n\nGameplay au repos, y compris éventuelle fin d’entrée des cartes. Fenêtre = taille retournée par le moteur ; espace logique ≠ nombre de pixels du rendu final. Un essai par configuration sauf les deux passages HD indiqués.\n")
    display_runs = [r for r in runs if r["name"].startswith(("display-", "hd-baseline", "4k-hd", "pixel-baseline", "pixel-4k")) or r["name"] in ["vsync", "fullscreen"]]
    measured.append(table(["Essai", "Fenêtre", "Espace logique", "True Pixel", "FPS", "P95 ms", "Pic ms", "GPU ms"], [
        [r["name"], r["metadata"][0]["window"], r["metadata"][0]["viewport"], "oui" if r["metadata"][0].get("true_pixel_art", False) else "non",
         *[number(next(p[k] for p in rows if p["run"] == r["name"] and p["phase"] == "gameplay_idle")) for k in ["fps", "p95_ms", "max_ms", "gpu_median_ms"]]] for r in display_runs]))
    measured.append("Par défaut, `display-*` utilise le mode semi_adaptive avec True Pixel Art **désactivé** (`GameOptionsController`, profil vierge). `hd-baseline-*` et `4k-hd` passent en adaptive, toujours sans True Pixel Art. `pixel-*` active explicitement True Pixel Art en semi_adaptive. Un espace logique de 568×320 ne signifie donc pas à lui seul un rendu à cette résolution : le mode CANVAS_ITEMS et le mode VIEWPORT diffèrent. `vsync` et `fullscreen` demandent VSync active ; aucun taux de rafraîchissement écran n’est déduit du seul mode VSync.\n")
    measured.append("### Huit backgrounds\n\nDeux passages par taille en semi_adaptive, True Pixel Art désactivé, avec l’UI de gameplay masquée mais les effets et le reste de la scène présents. Le passage « seul » libère Main et dessine seulement un BackgroundLayer ; les ressources préchargées restent référencées par le script. Deux passages complémentaires comparent adaptive sans True Pixel Art et semi_adaptive avec True Pixel Art, à 1920×1080.\n")
    names = ["stripes", "grid", "dots", "waves", "diamonds", "brick", "checkered", "circles"]
    bgrows = []
    for name in names:
        variants = [[r for r in rows if r["run"].startswith(prefix) and r["phase"] == "background_" + name] for prefix in ["bg-512-", "bg-1920-", "hd-bg"]]
        isolated = [r for r in rows if r["run"] == "isolated-bg" and r["phase"] == "isolated_background_" + name]
        pixel = [r for r in rows if r["run"] == "pixel-bg" and r["phase"] == "background_" + name]
        bgrows.append([name, span([r["fps"] for r in variants[0]]), span([r["gpu_median_ms"] for r in variants[0]]),
                       span([r["fps"] for r in variants[1]]), span([r["gpu_median_ms"] for r in variants[1]]),
                       span([r["gpu_median_ms"] for r in isolated]), span([r["gpu_median_ms"] for r in variants[2]]), span([r["gpu_median_ms"] for r in pixel])])
    measured.append(table(["Fond", "FPS 512", "GPU 512 ms", "FPS 1080p", "GPU 1080p ms", "GPU seul ms", "GPU adaptive ms", "GPU True Pixel ms"], bgrows))
    transitions = [r for r in rows if r["run"].startswith("bg-") and r["phase"].startswith("transition_")]
    if transitions:
        measured.append(f"Transitions séquentielles : {len(transitions)} phases, pics de {span([r['max_ms'] for r in transitions])} ms. La première cible peut être identique au fond tiré au démarrage. Les huit morphs ne couvrent pas toutes les paires possibles. Les traces donnent aussi les essais `background_disabled`, `empty_renderer`, les changements de palette et les draw calls.\n")
    measured.append("### UI, redimensionnement et challenges\n")
    selected = [r for r in rows if ((r["run"] == "ui" or r["run"].startswith("resize")) and r["phase"] not in ["boot", "start", "menu"]) or (r["run"].startswith("challenge-") and r["phase"].startswith("challenge_"))]
    measured.append(table(["Phase", "Durée s", "FPS", "P95 ms", "Pic ms", "GPU ms", "Nodes fin"], [[r["phase"] + (" / " + r["run"] if r["run"].startswith("resize") else ""), *[number(r[k]) for k in ["seconds", "fps", "p95_ms", "max_ms", "gpu_median_ms", "nodes"]]] for r in selected]))
    measured.append("Chaque challenge est mesuré au repos puis sur un round réellement résolu, sans répéter toutes les combinaisons de règles. Boss Rush n’active pas forcément ses règles les plus lourdes dès le round initial. No Looking Back et Pool Party sont hors catalogue actif et chargés directement. Le popup de pause ne suspend pas le jeu par conception ; les mesures d’état arrêtent explicitement le timer.\n")
    measured.append("### CPU, RAM et stress\n\nRSS/octets privés = maximum échantillonné sur le processus entier. CPU = moyenne sur le processus entier en % d’un cœur, lancement compris.\n")
    memruns = [r for r in runs if r["name"].startswith(("states-", "renderer-")) or r["name"] in ["stress", "endless"]]
    measured.append(table(["Essai", "Durée s", "CPU % 1 cœur", "RSS pic Mio", "Privé pic Mio"], [[r["name"], *[number(r[k]) for k in ["seconds", "cpu_percent_one_core", "peak_rss_mib", "peak_private_mib"]]] for r in memruns]))
    stress_rows = [r for r in rows if r["run"] == "stress" and r["phase"] in ["stress_baseline", "restart_000", "restart_010", "restart_020", "restart_029", "stress_settled"]]
    measured.append(table(["État", "Nodes", "Objets", "Ressources", "Statique Mio", "Vidéo Mio", "Tweens"], [[r["phase"], *[number(r[k]) for k in ["nodes", "objects", "resources", "static_end_mib", "video_end_mib", "tweens"]]] for r in stress_rows]))
    measured.append("Le léger accroissement initial se stabilise dans les cycles normaux. Les 12 rounds endless ont une difficulté croissante : comparer directement leur nombre de nodes ne permet pas de conclure à une fuite. Ce test n’est pas une endurance de plusieurs heures. Les couches résiduelles de MEM-001 sont, elles, comparées à état équivalent.\n")
    measured.append("### Microbenchmarks CPU\n\nTrois lots par opération, timings synchrones totaux en ms ; le coût GPU ultérieur n’est pas inclus. Ces lots artificiels ne sont pas des frames normales du jeu.\n")
    diags = [d for run in raw if run["config"]["name"] == "micro" for d in run.get("diagnostics", []) if "total_ms" in d]
    measured.append(table(["Lot", "Essai 1 ms", "Essai 2 ms", "Essai 3 ms"], [[d["label"], *map(number, d["total_ms"])] for d in diags]))
    measured.append("`tile_weights_500` = 500 actualisations ; `sfx_20` = 20 sons générés ; `save_30` = 30 sauvegardes sur profil isolé ; `music_load` = un chargement de section audio par lot, sans purge de cache.\n\n![Pics et stabilité des nodes](tests/performance/performance-overview.svg)\n")
    complete = sum(r["completed"] for r in runs)
    failures = sum(len(r["failed_observations"]) for r in runs)
    coverage = f"""- **{complete}/{len(runs)} processus instrumentés terminés**, {len(summary['phases'])} phases enregistrées ; {failures} observation(s) attendue(s) non conforme(s). {len(excluded)} premiers essais de challenge ont émis une erreur de script pendant la destruction forcée de Main par la sonde ; ils sont conservés dans les traces mais exclus des tableaux. Shared Clock, Conveyor Belt et Boss Rush ont été rejoués après suppression de cette destruction artificielle. Le smoke test est également identifiable séparément et n’est pas utilisé dans les comparaisons.
- Plateforme : Windows, rendu réel sur RTX 2070 SUPER. Compatibility/OpenGL, Mobile/D3D12 et Forward+/D3D12 effectivement exécutés.
- Affichage : fenêtré 256×320, 512×640, 1280×720, 1920×1080, 2560×1440, 1024×768 (4:3), 1280×800 (16:10), 2560×1080 (ultrawide), 300×1000 (étroit), et 3840×2160. Les dimensions réelles sont dans le tableau. Plein écran et VSync testés ; modes semi_adaptive/adaptive, True Pixel Art activé explicitement et désactivé.
- Redimensionnement : 180 demandes consécutives, une par frame, trois essais. FPS plafonnés à 60 ou non plafonnés selon les configurations. VSync demandée active et inactive.
- Fonds : huit variantes, deux passages à 512×640 et deux à 1920×1080 ; passage avec fond seul et passage HD ; transitions séquentielles, changements de palette, fond désactivé et transitions interrompues.
- Seeds fixes : PERF-A, PERF-B et PERF-C pour les états ; PERF-A pour les autres scénarios. Les paramètres complets et le renderer effectivement choisi sont conservés par processus.
- Gameplay : menu, départ, premier round joué, bonus, Flawless, dommage, reload, tier et fin injectés, popup/reprise, restart, retour menu, progression/options, huit challenges et endless.
- Stress normal : **30 restarts, 150 appels d’ouverture/fermeture du popup, 30 demandes de transition de fond et 6 retours menu/nouvelles parties**. Stress de transitions interrompues : **30 interruptions × 3 essais**. Endless : **12 rounds réellement joués**, sans prise de bonus ; durées ci-dessus.
- Aucun export Debug/Release : runtime de développement uniquement. Les scénarios sont des mesures ciblées et ne certifient pas les cas non testés ci-dessous.
"""
    path = ROOT / "PERFORMANCE_AUDIT.md"
    content = path.read_text(encoding="utf-8")
    for tag, replacement in [("MEASUREMENTS", "\n".join(measured)), ("COVERAGE", coverage)]:
        block = f"<!-- BEGIN {tag} -->\n{replacement}\n<!-- END {tag} -->"
        if f"<!-- {tag} -->" in content:
            content = content.replace(f"<!-- {tag} -->", block)
        else:
            content = re.sub(f"<!-- BEGIN {tag} -->.*?<!-- END {tag} -->", lambda _: block, content, flags=re.S)
    path.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    main()
