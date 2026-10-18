# Tableau des prompts

`history/historique.xlsx` est la version mise en forme de l'historique : tableau filtrable,
en-tête figé, lignes alternées, retours à la ligne et images intégrées.
La première entrée très longue est exclue par défaut.

Les sources et résultats locaux sont regroupés dans `history/`, ignoré par Git
et par l'import Godot : CSV, archive Markdown, classeurs et rapports. Le script,
`table_config.json`, `requirements.txt` et cette documentation restent versionnés.
Le fichier de demandes courant `prompt.md` reste séparé de ces exports.

- **Historique** : date, demande, résumé, aperçu, fichier actif, onglets et fichiers joints dans des colonnes distinctes.
- **Contexte** : demandes intégrales, sélections dans l'éditeur et questions de clarification, séparées dans leurs propres cellules.
- **Images** : toutes les images jointes, avec lien vers le prompt correspondant.
- **Configuration** : paramètres utilisés, compteurs et éventuels fichiers manquants.

Cliquer sur un numéro ou une demande ouvre son contexte complet. Cliquer sur
le libellé d'une image ouvre la galerie. Le tableau affiche un aperçu de la
première capture ; la galerie contient toutes les captures du prompt.
Le jaune dans les résumés signale l'absence de bilan final distinct.
Les résumés reflètent les réponses historiques de Codex, sans nouvel audit du code.

## Régénérer

Depuis la racine du projet :

```powershell
python -m pip install -r wip/prompt/requirements.txt
python wip/prompt/generate_table.py
```

Le script lit `history/historique.csv` pour les textes, dates et résumés, et `history/old.md`
pour les références aux messages originaux. Les captures sont récupérées en
lecture seule dans les sessions de `~/.codex`, puis incorporées au classeur.
Le classeur généré se consulte sans ces fichiers locaux. Pour le régénérer avec
les images, il faut conserver les sessions sources ou configurer `codex_home`
vers leur sauvegarde. Les fichiers texte collés sont lus s'ils sont encore disponibles.
Le script n'exécute pas les commandes contenues dans les prompts.

Un fichier `history/historique.rapport.json` indique le nombre de prompts et d'images
exportés et les éventuelles images manquantes.
Fermer le classeur dans Excel/LibreOffice avant de le remplacer.
Après un nouveau clone, remettre les deux sources locales dans `history/`
ou adapter `input_csv` et `input_archive` : elles ne sont pas distribuées avec Git.

## Modifier la configuration

Éditer `table_config.json`, puis relancer le script. Les chemins relatifs sont
résolus depuis le dossier du fichier de configuration.

| Réglage | Effet |
| --- | --- |
| `filters.exclude_ids` | Messages exclus ; `[1]` retire la première entrée. Mettre `[]` pour la réintégrer. |
| `filters.include_ids` | Limiter à certains numéros ; `[]` conserve tous les numéros autorisés. |
| `filters.date_from`, `filters.date_to` | Bornes inclusives au format `2026-10-01`, ou `null`. |
| `filters.contains` | Conserver les messages contenant au moins un mot de cette liste dans le prompt ou le résumé. |
| `filters.only_with_summary` | Exporter uniquement les messages avec bilan final distinct. |
| `filters.order` | `ascending` ou `descending` pour l'ordre chronologique. |
| `columns` | Ordre, titres et largeurs des colonnes du tableau. |
| `text.max_prompt_chars` | Limite visible dans le tableau ; `0` affiche tout. Le texte intégral reste dans Contexte. |
| `text.read_pasted_files` | Lire les fichiers texte joints disponibles pour restituer leur demande. |
| `images.enabled` | Intégrer les images. |
| `images.preview_in_table` | Afficher la première image dans le tableau principal. |
| `images.preview_width_px`, `images.preview_height_px` | Dimensions maximales des aperçus, en pixels. |
| `images.gallery_width_px`, `images.gallery_height_px` | Dimensions maximales dans la galerie, en pixels. |
| `images.fail_on_missing` | Arrêter si une image manque ; `false` produit un rapport d'avertissements. |
| `style` | Police, couleurs, style du tableau, hauteur des lignes et zoom. |
| `output` | Chemin du classeur produit. |

Les clés de colonnes disponibles sont `id`, `date`, `prompt`, `summary`,
`images`, `active_file`, `open_tabs`, `files`, `selection`, `question` et `source`.
Les numéros restent ceux des messages de `old.md`, même après filtrage.

Pour conserver plusieurs variantes : copier le JSON, changer ses paramètres,
puis choisir le fichier et la sortie :

```powershell
python wip/prompt/generate_table.py --config wip/prompt/table_config.json --output wip/prompt/history/autre-tableau.xlsx
```

Pour un export sans images, qui ne nécessite pas les sessions Codex :

```powershell
python wip/prompt/generate_table.py --no-images --output wip/prompt/history/sans-images.xlsx
```
