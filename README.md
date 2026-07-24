# Pile Down

Prototype jouable réalisé avec Godot 4. **Pile Down** est un solitaire rapide
de mémoire : il faut compléter des piles descendantes avant la fin de chaque
compte à rebours.

## Règles

- Chaque pile commence à la valeur `S`.
- Une pile de valeur `s` accepte uniquement la carte `s - 1`.
- La carte posée est visible un court instant, puis sa valeur est masquée.
- Chaque nouvelle main contient au moins une carte jouable.
- Une mauvaise carte, une pile invalide ou un chronomètre arrivé à zéro coûte
  une erreur. Le round se termine après trois erreurs.
- Une pile qui atteint zéro est complétée. Le round est gagné quand toutes les
  piles ont disparu.
- Le compteur de rounds commence à `100`, puis descend après chaque victoire.
  La partie est terminée lorsqu'il atteint `0`.

Le meilleur score privilégie le plus petit nombre de rounds restants, puis le
temps le plus court en cas d'égalité. Le temps enregistré est celui du passage
au round atteint, pas celui de la défaite sur ce round. Le score est sauvegardé
dans `user://pile_down.cfg` et affiché sur l'écran d'accueil. Le timer de chaque
tour n'affiche que des secondes entières.

Après chaque victoire, la difficulté augmente aléatoirement : nouvelle pile
(55 %), main agrandie (20 %), valeur de départ augmentée (20 %) ou temps réduit
(5 %). Une option arrivée à sa limite est retirée du tirage.

## Lancer le prototype

1. Ouvrir ce dossier dans Godot 4.
2. Lancer le projet avec **F6/F5** (la scène principale est
   `resources/scenes/Game.tscn`).

En ligne de commande :

```sh
godot --path . --editor
```

ou directement :

```sh
godot --path .
```

## Commandes

1. Faire glisser une pièce depuis la main.
2. La déposer sur la pile qui attend cette valeur.
3. Mémoriser la nouvelle valeur avant que la carte ne se retourne.

La touche `Échap` revient à l'écran d'accueil depuis le jeu. Sur cet écran,
elle ferme l'application. La barre d'espace lance la partie depuis l'accueil
et relance une partie depuis l'écran de fin. La touche `M` coupe ou réactive
tous les sons. Pendant une partie, `T` affiche ou masque le temps total écoulé.

Les cartes et les piles restent des contrôles 2D et utilisent les sprites
pixel-art du dossier `resources/sprites/`. Toute pile survolée reçoit le même
halo et le même signal sonore pendant le glissement, sans révéler si le dépôt
sera valide. Un dépôt invalide consomme une erreur, puis retourne
brièvement la pile ciblée pour rappeler sa valeur actuelle. La carte revient
d'abord rapidement dans la même main, qui redevient immédiatement jouable
pendant la révélation de la pile. La position libérée par une carte jouée reste
réservée jusqu'à la disparition de la main : les
cartes restantes ne se recentrent donc pas. Dès qu'un dépôt est validé,
l'ancienne main descend hors de l'écran tandis que la suivante entre depuis la
droite. Ces animations se jouent en parallèle du rappel complet de la pile,
sans raccourcir celui-ci. La nouvelle main devient draggable dès qu'elle entre
dans l'écran, même si son animation continue. Des signatures sonores courtes
accompagnent aussi le lancement ou replay, l'annonce d'une règle spéciale, la
défaite et la victoire.

## Structure

```text
pile-down/
├── resources/
│   ├── fonts/
│   │   ├── PressStart2P-Regular.ttf
│   │   ├── Tiny5-Regular.ttf
│   │   └── VCR_OSD_MONO_1.001.ttf
│   ├── scenes/
│   │   ├── Game.tscn
│   │   ├── Card.tscn
│   │   └── Pile.tscn
│   ├── scripts/
│   │   ├── audio/
│   │   ├── core/
│   │   ├── gameplay/
│   │   ├── special_rules/
│   │   └── ui/
│   └── sprites/
│       ├── hand/
│       ├── tiles/
│       ├── background.png
│       ├── clock.png
│       └── round-background.png
├── project.godot
└── README.md
```

- `resources/scenes/Game.tscn` et `resources/scripts/core/GameManager.gd` : version principale en 2D,
  interface minimaliste, rounds, erreurs, drag-and-drop et progression.
- `resources/scripts/gameplay/PileLayoutManager.gd` : dispositions compactes et stables des piles.
- `resources/scripts/audio/SoftAudio.gd` : retours sonores doux générés sans ressource externe.
- `resources/scripts/ui/RoundDots.gd` : indicateurs minimalistes des erreurs restantes.
- `resources/scenes/Card.tscn` et `resources/scripts/gameplay/Card.gd` : carte réutilisable, sélection et
  retournement, avec relief et inclinaison simulés.
- `resources/scenes/Pile.tscn` et `resources/scripts/gameplay/Pile.gd` : état d'une pile, valeur attendue et
  animations.
- `resources/scripts/gameplay/HandManager.gd` : génération des mains avec garantie d'une carte
  jouable.
- `resources/scripts/gameplay/TimerManager.gd` : compte à rebours indépendant.

Les composants communiquent par signaux afin de rester faiblement couplés.

## Direction artistique

La version principale est rendue dans un viewport pixel-art de 256×320,
identique à la taille du fond, puis affichée en 512×640 avec un agrandissement
entier ×2 sans filtrage. Les textes, shaders et effets sont donc rasterisés à
la résolution native avant l'agrandissement. Le HUD n'affiche pendant la partie
que le temps entier, le nombre de rounds restants et les trois erreurs
disponibles. Une erreur de dépôt ou l'expiration du timer produit un signal
sonore descendant. Le fond, les cartouches du HUD, les vies et les faces des
pièces proviennent tous de `resources/sprites/`. Un shader remplace le vert du sprite de face par la couleur
associée à la valeur de chaque carte. Les textes utilisent la police
`VCR_OSD_MONO_1.001.ttf` du dossier `resources/fonts/`. Les tailles sont normalisées sur
des multiples de 20 px (20, 40, 80 ou 100 px selon le contexte), sans
transformation non uniforme des caractères. Les sprites
restent à leur taille native hors animations. L'antialiasing, le positionnement
subpixel et le fallback système sont désactivés pour la police. Son raster
utilise un oversampling fixe de 1 et un hinting entier afin d'aligner les
contours des glyphes sur la grille avant l'agrandissement global.

Les boutons `PLAY` et `REPLAY` utilisent `resources/sprites/button.png` à sa taille
native 86×31. L'écran final utilise `resources/sprites/pop-up.png` à sa taille native
256×192. Les tuiles utilisent leur format natif 34×37.

Le contour de progression de `resources/sprites/clock.png` est piloté par un shader :
les pixels-clés du cercle sont remplis dans le sens horaire selon le temps
restant. Aucun arc vectoriel n'est dessiné par-dessus le pixel-art.

Les éléments visuels principaux sont positionnables directement dans
`resources/scenes/Game.tscn`. `TimerRing`, `RoundPanel`, `PilesBoard` et `HandTray`
peuvent être déplacés depuis l'éditeur 2D. Les trois vies sont des
`TextureRect` séparés sous `HandTray/MistakesDots` : le groupe ou chaque point
peut donc être replacé visuellement sans modifier de script.

Au lancement, un splash screen affiche `PILE DOWN` et attend une pression sur
`PLAY`. Il indique aussi le meilleur nombre de rounds restants et le temps
nécessaire pour l'atteindre. Tous les textes du jeu sont en anglais. En cas de
défaite, l'écran de score affiche le nombre de rounds restants et le temps
de passage correspondant. Lors d'un nouveau record, le titre `HIGHSCORE`
apparaît avec une vague animée au-dessus du popup afin de ne pas déséquilibrer
son contenu. La valeur battue est colorée en bleu : le round pour une meilleure
progression, ou le temps lorsque le même round est atteint plus vite. Une
victoire sans nouveau record affiche `YOU WON` et la durée totale. Le format
du score utilise des unités lisibles, par exemple `1 min 12 s 323 ms`, et omet
les heures ou les minutes lorsqu'elles valent zéro. Il est présenté sous la
forme `in 1 min 12 s 323 ms`.

## Régler la difficulté

Tous les réglages sont centralisés dans `resources/scripts/core/difficulty.gd` :

- valeurs initiales de piles, cartes, valeur de départ et timer ;
- limites maximales, ainsi que le temps minimal ;
- nombre total de rounds ;
- poids de probabilité de chaque malus ;
- poids de probabilité de n'appliquer aucun changement ;
- poids séparés du premier malus.

Les poids sont relatifs et n'ont pas besoin de totaliser 100. Une valeur de
`0` désactive l'option correspondante. `NO_DIFFICULTY_CHANGE_WEIGHT` ajoute une
issue silencieuse qui laisse toutes les statistiques intactes et lance
directement le round suivant. Au premier round, les seuls autres résultats sont
une nouvelle pile ou une nouvelle carte en main. Les malus de valeur et de
temps ne deviennent disponibles qu'ensuite. Les rounds `TIER RELIEF` ne
participent pas à ce tirage.

## Debug

Les options de développement sont centralisées dans `resources/scripts/core/debug.gd`.
`ENABLED` est l'interrupteur global : lorsqu'il vaut `false`, toutes les autres
options sont ignorées. Lorsqu'il vaut `true`, le menu principal affiche
`DEBUG MODE` en rouge.

```gdscript
const ENABLED := false
const GOD_MODE := false
const START_AT_ROUND := 1
const LOCK_SPECIAL_RULES: Array[StringName] = []
```

- `GOD_MODE` conserve les trois vies après une erreur ;
- `START_AT_ROUND` choisit le round de progression initial entre 1 et 100 ;
  les améliorations des rounds précédents sont alors tirées et appliquées
  comme pendant une partie normale, y compris les allègements de palier ;
- `LOCK_SPECIAL_RULES` force une ou plusieurs règles à chaque round, y compris
  avant leurs paliers normaux. Par exemple, utiliser
  `[&"peek_a_card", &"lights_out"]`. Une liste vide restaure la sélection
  normale. Les doublons et identifiants inconnus sont ignorés avec un
  avertissement.

Lorsque `ENABLED` vaut `true`, deux raccourcis clavier sont disponibles :

- `S` termine le round courant et passe au suivant ;
- `R` réinitialise immédiatement la partie avec les valeurs de départ ;
- `H` efface le high score sauvegardé.

## Special Rules

Un modificateur temporaire peut être sélectionné au début de chaque round de
progression. Les réglages se trouvent également dans `resources/scripts/core/difficulty.gd` :

```gdscript
const FIRST_SPECIAL_RULE_ROUND := 4
const EXTRA_SPECIAL_RULE_CHANCE := 0.75
const MAX_COMBINED_RULES := 5
const LIGHTS_OUT_RADIUS := 54.0
```

Le numéro utilisé pour ces paliers commence à 1 et augmente, même si le HUD
affiche le nombre de rounds restants de 100 vers 0. Aucune règle spéciale
n'apparaît avant `FIRST_SPECIAL_RULE_ROUND` (`k`). Ce premier round spécial
garantit exactement une règle. Sur les rounds éligibles suivants, la première
règle a une probabilité `EXTRA_SPECIAL_RULE_CHANCE` (`c`) d'apparaître. Chaque
règle supplémentaire est tirée avec la même probabilité, et les tirages
s'arrêtent au premier échec. Deux rounds avec règles spéciales ne peuvent
jamais se suivre.

La capacité passe à `n` règles au round `(k + n - 1) × n`, jusqu'à
`MAX_COMBINED_RULES`. Avec la valeur par défaut `k = 4`, les paliers sont donc 2 règles au round 10,
3 au round 18, 4 au round 28 et 5 au round 40. La combinaison complète est
garantie précisément sur chacun de ces rounds ; le round précédent reste sans
règle afin de préserver l'alternance.

À chaque palier théorique de règles combinables, un `TIER RELIEF` allège une
statistique choisie aléatoirement au premier palier,
deux statistiques distinctes au deuxième, puis trois et enfin quatre. Un
allègement retire une pile, une carte en main ou une valeur de départ, ou ajoute
une seconde au timer. Ce round de palier remplace entièrement l'augmentation de
difficulté habituelle : aucune statistique n'est d'abord augmentée. Chaque
valeur reste bornée par sa valeur initiale. Le démarrage debug à un round avancé
rejoue ces allègements dans leur ordre normal.

Après la limite de cinq règles simultanées, les paliers théoriques continuent
de déclencher des `TIER RELIEF` selon la même formule, sans augmenter cette
limite. Avec la valeur par défaut `k = 4`, les reliefs supplémentaires arrivent aux rounds 54, 70 et
88. À partir du quatrième relief, les quatre statistiques sont allégées.

Les règles disponibles sont :

- `SHELL GAME` : échange animé de deux piles, puis de trois après le palier
  configurable ;
- `MERRY-GO-STACK` : mouvement continu, lent et déterministe des piles parmi
  six motifs : ellipse, pendule horizontal, figure en huit, orbites
  concentriques, vague verticale et circuit par points fixes ;
- `FREE-RANGE CARDS` : entrée depuis le bord le plus proche de chaque position
  libre tirée aléatoirement, déplacement pseudo-aléatoire hors du plateau,
  puis sortie animée vers le bord le plus proche ;
- `PILE UP` : progression inversée de 0 vers S ;
- `LIGHTS OUT` : calque sombre avec lampe circulaire suivant le pointeur ; le
  cercle lumineux se referme progressivement à l'activation et se rouvre à la
  fin du round. Son rayon en pixels se règle avec `LIGHTS_OUT_RADIUS` dans
  `difficulty.gd` ;
- `PEEK-A-CARD` : cartes cachées révélées au survol ou au premier toucher ;
- `STACK ATTACK` : régénération temporisée d'une sélection de piles, affichée
  avec le masque pixel-art `resources/sprites/tiles/tile-regen.png`. Une main
  devenue entièrement injouable après une régénération est immédiatement
  retirée et repiochée avec une carte garantie jouable. Une pile se retourne
  brièvement pour révéler sa nouvelle valeur après chaque régénération. Le
  cercle reprend les couleurs du timer global et reste masqué lorsque la pile
  ne peut pas se régénérer davantage ;
- `ROMAN HOLIDAY` : valeurs de cartes et de piles en chiffres romains ; `VII`
  et `VIII` utilisent la police `Tiny5 Regular` avec une taille réduite afin de
  rester dans les tuiles.

`SpecialRuleManager.gd` sélectionne les règles pondérées sans doublon. Les
combinaisons difficiles restent autorisées ; seule `LIGHTS OUT` est
incompatible avec les règles déplaçant les piles (`SHELL GAME` et
`MERRY-GO-STACK`). `RoundModifiers.gd` constitue l'unique état consulté par le
gameplay. Chaque `SpecialRuleData` expose `activate()` et `deactivate()` sur un
`RoundContext`. La fin du round restaure les positions, arrête les timers,
masque la lampe et réinitialise tous les modificateurs.

Certaines paires reçoivent un titre spécial dans l'annonce, y compris
lorsqu'elles font partie d'une combinaison plus grande :

- `LIGHTS OUT + PEEK-A-CARD` : `BLIND DATE` ;
- `PILE UP + STACK ATTACK` : `ONE STEP FORWARD...` ;
- `ROMAN HOLIDAY + PILE UP` : `THE EMPIRE RISES` ;
- `SHELL GAME + ROMAN HOLIDAY` : `ET TU, STACK?` ;
- `FREE-RANGE CARDS + PEEK-A-CARD` : `CARDIO TRAINING` ;
- `LIGHTS OUT + STACK ATTACK` : `FEAR OF THE STACK`.

Les scènes spécialisées sont :

- `SpecialRuleAnnouncement.tscn` pour l'annonce en anglais ;
- `FlashlightOverlay.tscn` pour `LIGHTS OUT` ;
- `RegenerationRing.tscn` pour les timers de `STACK ATTACK`.

Les contrôles automatisés peuvent être lancés avec :

```sh
godot --headless --path . --script res://tests/test_special_rules.gd
godot --headless --path . --script res://tests/test_special_rule_effects.gd
godot --headless --path . --script res://tests/test_game_start.gd
```
