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
tous les sons.

Les cartes et les piles restent des contrôles 2D et utilisent les sprites
pixel-art du dossier `resources/sprites/`. Toute pile survolée reçoit le même
halo et le même signal sonore pendant le glissement, sans révéler si le dépôt
sera valide. Un dépôt invalide consomme une erreur, puis retourne
brièvement la pile ciblée pour rappeler sa valeur actuelle. La carte revient
d'abord rapidement dans la même main, qui redevient immédiatement jouable
pendant la révélation de la pile. La position libérée par une carte jouée reste
réservée jusqu'à la disparition de la main : les
cartes restantes ne se recentrent donc pas. Elles sont ensuite défaussées avec
une sortie échelonnée, puis la nouvelle main est piochée avec une animation
d'arrivée.

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
de passage correspondant. Il annonce `ROUND RECORD` lorsqu'une meilleure
progression est atteinte et `TIME RECORD` lorsque le même round est atteint
plus vite. Une victoire affiche `YOU WON` et la durée totale. Le format omet
les heures ou les minutes tant qu'elles ne sont pas nécessaires.

## Régler la difficulté

Tous les réglages sont centralisés dans `resources/scripts/core/difficulty.gd` :

- valeurs initiales de piles, cartes, valeur de départ et timer ;
- limites maximales, ainsi que le temps minimal ;
- nombre total de rounds ;
- poids de probabilité de chaque malus ;
- poids séparés du premier malus.

Les poids sont relatifs et n'ont pas besoin de totaliser 100. Une valeur de
`0` désactive l'option correspondante. Après le premier round, le malus est
obligatoirement soit une nouvelle pile, soit une nouvelle carte en main. Les
malus de valeur et de temps ne deviennent disponibles qu'ensuite.

## Debug

Les options de développement sont centralisées dans `resources/scripts/core/debug.gd`.
`ENABLED` est l'interrupteur global : lorsqu'il vaut `false`, toutes les autres
options sont ignorées.

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
  normale. Les doublons, identifiants inconnus et combinaisons structurellement
  incompatibles sont ignorés avec un avertissement.

Lorsque `ENABLED` vaut `true`, deux raccourcis clavier sont disponibles :

- `S` termine le round courant et passe au suivant ;
- `R` réinitialise immédiatement la partie avec les valeurs de départ ;
- `H` efface le high score sauvegardé.

## Special Rules

Un modificateur temporaire peut être sélectionné au début de chaque round de
progression. Les réglages se trouvent également dans `resources/scripts/core/difficulty.gd` :

```gdscript
const SPECIAL_RULE_FREQUENCY := 5
const SPECIAL_RULE_START_ROUND := 4
const EXTRA_SPECIAL_RULE_CHANCE := 0.75
const MAX_COMBINED_RULES := 5
```

Le numéro utilisé pour ces paliers commence à 1 et augmente, même si le HUD
affiche le nombre de rounds restants de 100 vers 0. Aucune règle spéciale
n'apparaît avant `SPECIAL_RULE_START_ROUND`. La capacité est calculée avec
`floor(round / SPECIAL_RULE_START_ROUND)` et plafonnée par
`MAX_COMBINED_RULES`. Avec un palier de 4, elle vaut donc une règle au round 4,
deux au round 8, trois au round 12, quatre au round 16 et cinq au round 20.

Après le palier de départ, les multiples de `SPECIAL_RULE_FREQUENCY`
garantissent la première règle. Chaque emplacement disponible supplémentaire,
ainsi que le premier emplacement des autres rounds, est rempli avec une
probabilité de `EXTRA_SPECIAL_RULE_CHANCE`. Les tirages sont successifs et
s'arrêtent au premier échec : atteindre la capacité maximale n'est donc jamais
automatique.

Lorsqu'un round augmente la capacité maximale de règles combinables, un
`TIER RELIEF` réduit de 1 le nombre de piles, la taille de main et la valeur de
départ, puis ajoute 1 seconde au timer. Chaque valeur reste bornée par sa valeur
initiale : cet allègement ne rend jamais le jeu plus facile que le premier
round. Le démarrage debug à un round avancé rejoue ces allègements dans leur
ordre normal.

Les règles disponibles sont :

- `SHELL GAME` : échange animé de deux piles, puis de trois après le palier
  configurable ;
- `MERRY-GO-STACK` : mouvement continu, lent et déterministe des piles parmi
  six motifs : ellipse, pendule horizontal, figure en huit, orbites
  concentriques, vague verticale et circuit par points fixes ;
- `FREE-RANGE CARDS` : apparition directe à des positions libres de l'écran,
  puis déplacement pseudo-aléatoire hors du plateau ;
- `PILE UP` : progression inversée de 0 vers S ;
- `LIGHTS OUT` : calque sombre avec lampe circulaire suivant le pointeur ;
- `PEEK-A-CARD` : cartes cachées révélées au survol ou au premier toucher ;
- `STACK ATTACK` : régénération temporisée d'une sélection de piles, affichée
  avec le masque pixel-art `resources/sprites/tiles/tile-regen.png`. Une pile se retourne
  brièvement pour révéler sa nouvelle valeur après chaque régénération. Le
  cercle reprend les couleurs du timer global et reste masqué lorsque la pile
  ne peut pas se régénérer davantage ;
- `ROMAN HOLIDAY` : valeurs de cartes et de piles en chiffres romains.

`SpecialRuleManager.gd` sélectionne les règles pondérées sans doublon et
rejette les combinaisons incompatibles. `RoundModifiers.gd` constitue l'unique
état consulté par le gameplay. Chaque `SpecialRuleData` expose `activate()` et
`deactivate()` sur un `RoundContext`. La fin du round restaure les positions,
arrête les timers, masque la lampe et réinitialise tous les modificateurs.

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
