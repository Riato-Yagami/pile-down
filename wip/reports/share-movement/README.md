# Audit visuel du partage — déplacements des piles

28 scénarios et 198 instantanés vérifiés avec les contrôleurs du jeu, sur des
plateaux de 3, 13 et 25 piles. Chaque capture contrôle le nombre de tuiles,
l’absence de coches/carrés, la hauteur maximale et l’indépendance du rendu par
rapport au retournement visuel d’une pile.

- [Rapport filtrable : positions du jeu et texte exact](index.html)
- [Aperçu après ajustements](after.png)
- [Aperçu avant ajustements](before.png)
- [Rapport avant ajustements](before.html)
- [Résultats des tests principaux](tests.json)
- [Résultats Adaptation III](adaptation-tests.json)
- [Résultats Bonneteau + Merry-Go-Stack](shell-orbit-tests.json)

Les schémas représentent les coordonnées réelles capturées, pas des screenshots.
Les aperçus PNG remplacent les chiffres emoji par des tuiles numérotées pour
comparer la géométrie sans dépendre de la police emoji locale. Le HTML affiche
également le texte exact, avec ses espaces insécables.

| Règle / bonus | Scénarios vérifiés | Résultat |
| --- | --- | --- |
| Disposition initiale | 3, 13, 25 piles | Triangle centré, rangées et centrage conservés. |
| Shell Game / Bonneteau | 13 piles, pendant et après les échanges | Toutes les valeurs sont conservées ; l’approximation suit les croisements. |
| Shell Game + Merry-Go-Stack | 13 piles, échanges sur les trajectoires orbitales | Capture pendant et après les permutations. |
| Musical Stacks | 13 piles, trois rotations | Ordre spatial conservé après permutation. |
| Merry-Go-Stack | 3, 13, 25 piles, trois phases | Cercles réguliers à 13 piles ; 11 lignes pour 24 piles autour du centre. |
| Shaking Piles | 13 piles | Les oscillations de faible amplitude ne déforment pas les rangées. |
| Wavy Baby | 3, 13, 25 piles, trois phases | Rangées mieux conservées après correction de l’estimation verticale. |
| Snake | 3, 13, 25 piles, glissement et fin de glissement | Coudes, trous et corps conservés. |
| Snake + Shell Game | 13 piles | Échanges et nouvelle position des segments suivis. |
| Pile Mover | 3, 13, 25 piles | Positions réellement acceptées par le déplacement manuel. |
| Pile Mover + orbit / shake / wave | 13 piles | Capture au lâcher puis après poursuite du mouvement. |
| Mirror Match + orbit | 13 piles | Valeurs ordonnées selon la réflexion visible. |
| Adaptation III + orbit / shake / wave / Snake | 13 piles | Espacement valide avec l’intensité modifiée. |

Tous les scénarios comprennent une capture réfléchie et une capture avec des
piles terminées. Les emplacements de ces dernières restent blancs. Seul Pile
Mover déplace directement les piles parmi les bonus ; Adaptation est couvert
car il change la vitesse et l’intensité des règles de mouvement.

## Ajustements retenus

L’espacement vertical était parfois mesuré entre deux piles en diagonale.
Wavy Baby pouvait ainsi produire cinq lignes pour quatre rangées, et Pile Mover
ajouter une ligne blanche. Il est désormais estimé entre voisins approximativement
alignés : les quatre rangées restent sur quatre lignes dans les cas mesurés.

Les anneaux utilisent une orientation symétrique favorisant les paires de piles
plutôt que des lignes vides intercalées. Pour l’anneau de 24 piles et sa pile
centrale, la limite verticale est passée de 10 à 12 lignes : son rendu utilise
11 lignes et évite la projection générale asymétrique.

Le rendu conserve le texte demandé : `.Pile Down.`, piles, score et temps, liens
bruts ; aucun libellé de plateau, main, carré ou coche n’est ajouté.

## Validation et limites

Les quatre tests principaux, le test Adaptation et le test Bonneteau + orbite passent, ainsi que l’import
éditeur Godot et le démarrage headless de 240 frames. Les collisions d’arrondi
ne suppriment aucune pile, y compris pendant un échange.

Les espaces et les emoji peuvent avoir des largeurs différentes selon la police
du réseau social. Les placements intermédiaires réellement superposés restent
une approximation : la grille textuelle ne peut pas reproduire une superposition.

## Reproduire les contrôles

```sh
python3 tests/run_godot_tests.py --jobs 2 --timeout 260 \
  test_share_movement_audit.gd test_share_movement_adaptation.gd \
  test_share_movement_shell_orbit.gd test_result_share_layout.gd \
  test_result_share.gd test_result_share_hand.gd
```

Pour exporter les coordonnées d’une suite, définir `PILE_DOWN_SHARE_AUDIT_OUTPUT`
vers un fichier distinct avant son lancement. `snapshots.json` rassemble les
captures des trois audits de mouvement ; le renderer Python du dossier `tests/`
produit le rapport HTML sans dépendance externe.
