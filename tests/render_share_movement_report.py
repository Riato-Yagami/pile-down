"""Build a standalone visual report from test_share_movement_audit.gd snapshots."""

import argparse
import html
import json
from pathlib import Path


def diagram(points):
    if not points:
        return ""
    left = min(p["x"] for p in points) - 20
    top = min(p["y"] for p in points) - 22
    width = max(p["x"] for p in points) - left + 20
    height = max(p["y"] for p in points) - top + 22
    shapes = []
    for point in points:
        x, y = point["x"], point["y"]
        opacity = "0.2" if point["completed"] else "1"
        shapes.append(f'<g opacity="{opacity}"><rect x="{x-16}" y="{y-18}" width="32" height="36" rx="4" fill="white" stroke="#4d82c2" stroke-width="1.5"/>'
                      f'<text x="{x}" y="{y+6}" text-anchor="middle" font-size="18" fill="#344253">{point["value"]}</text></g>')
    return f'<svg viewBox="{left} {top} {width} {height}" role="img" aria-label="Positions des piles">' + "".join(shapes) + "</svg>"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshots", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    samples = json.loads(args.snapshots.read_text())
    cards = []
    for sample in samples:
        label = f'{sample["case"]} · {sample["count"]} piles · {sample["phase"]}'
        cards.append(f'<article data-case="{sample["case"]}" data-count="{sample["count"]}"><h2>{html.escape(label)}</h2><div class="pair"><figure>{diagram(sample["points"])}<figcaption>Positions du jeu (piles terminées estompées)</figcaption></figure><figure><pre>{html.escape(sample["grid"])}</pre><figcaption>Texte exact copié</figcaption></figure></div></article>')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text('''<!doctype html><html lang="fr"><meta charset="utf-8"><title>Audit des grilles de partage</title>
<style>body{font:16px system-ui;background:#f7f6f2;color:#343b43;margin:24px}h1{font-size:24px}h2{font-size:16px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(480px,1fr));gap:16px}article{background:white;padding:18px;border:1px solid #dbe1e7;border-radius:12px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}svg{width:100%;height:250px}pre{font:20px/1.4 monospace;white-space:pre;min-height:240px;margin:0;display:flex;align-items:center}figcaption{font-size:12px;color:#637082}select{font:inherit;margin:0 18px 20px 4px}</style>
<h1>Audit des grilles de partage</h1><p>Comparaison des positions réelles et du texte copié. Les espaces sont insécables ; leur largeur finale dépend de la police utilisée par le réseau social.</p>
<label>Règle <select id="rule"><option value="">Toutes</option>''' + "".join(f'<option>{html.escape(case)}</option>' for case in sorted({s['case'] for s in samples})) + '''</select></label><label>Piles <select id="count"><option value="">Toutes</option><option>3</option><option>13</option><option>25</option></select></label><main>''' + "".join(cards) + '''</main><script>const rule=document.getElementById('rule'),count=document.getElementById('count');for(const select of document.querySelectorAll('select'))select.onchange=()=>{for(const card of document.querySelectorAll('article'))card.hidden=!!((rule.value&&card.dataset.case!==rule.value)||(count.value&&card.dataset.count!==count.value))}</script></html>''')
    print(f"{len(samples)} visual comparisons: {args.output}")


if __name__ == "__main__":
    main()
