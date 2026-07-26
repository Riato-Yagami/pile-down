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

Le menu d'accueil propose des curseurs séparés pour régler le volume de la
musique et celui des effets sonores. Ces préférences sont sauvegardées dans
`user://pile_down.cfg`.

Terminer une partie normale débloque définitivement le mode `ENDLESS`. Son
bouton apparaît alors dans le menu principal. Les rounds y sont comptés vers
le haut à partir de 1 et la partie continue jusqu'à la défaite. Ce mode possède
son propre high score, affiché à la place du score normal lorsque le bouton
`ENDLESS` est survolé ou sélectionné. Le déblocage et le score infini sont
sauvegardés dans `user://pile_down.cfg`.

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

## Build Web

Le preset `Web` produit une version release sans threads, compatible avec un
hébergement statique standard :

```sh
./build/build_web.sh
```

Les templates d'export doivent correspondre à la version de Godot utilisée.
S'ils manquent, les scripts téléchargent automatiquement les templates
officiels correspondants dans `build/.godot_data/`. Le premier téléchargement
est volumineux, mais l'archive est ensuite conservée dans
`build/.template_cache/`.
Le script lit `VERSION` (par exemple `v0.2`), produit le point d'entrée
`build/web/index.html`, puis crée automatiquement
`build/web/pile-down-web-<version>.zip`. Pour utiliser un
autre exécutable Godot :

```sh
PILE_DOWN_GODOT_BIN=/chemin/vers/godot ./build/build_web.sh
```

Le build Linux x86_64 et son archive versionnée sont produits dans
`build/linux/` avec :

```sh
./build/build_linux.sh
```

Le build Windows x86_64 produit `pile-down.exe` et une archive versionnée dans
`build/windows/` avec :

```sh
./build/build_windows.sh
```

Pour produire les versions Web, Linux et Windows en une seule commande :

```sh
./build/build_all.sh
```

La description HTML prête à intégrer à la page itch.io se trouve dans
`publishing/itch-description.html`, avec les images de publication. Les cinq
screenshots itch.io couvrent le menu, le plateau, une combinaison de règles,
la sélection d'un bonus et l'écran de fin. Ils peuvent être régénérés en
512 × 640, sans lissage, avec :

```sh
godot --display-driver x11 --rendering-driver opengl3 \
  --audio-driver Dummy --path . --resolution 512x640 \
  --script tests/capture_publishing_screenshots.gd
```

## Commandes

1. Faire glisser une pièce depuis la main.
2. La déposer sur la pile qui attend cette valeur.
3. Mémoriser la nouvelle valeur avant que la carte ne se retourne.

Sur mobile et dans la version Web, le glissement utilise directement les
événements tactiles sans les convertir en clics souris. Les cartes suivent le
pointeur avec le léger lissage visuel d'origine.
En plein écran, le jeu conserve son ratio vertical `256 × 320` et occupe la
plus grande surface possible. Les zones restantes sur les écrans plus larges
ou plus hauts utilisent la même couleur beige que le fond du jeu. La scène
`Main.tscn` fournit ce cadre adaptatif autour de la scène de jeu, directement
dans le canvas principal afin de conserver des coordonnées tactiles exactes.

La touche `Échap` revient à l'écran d'accueil depuis le jeu. Sur cet écran,
elle ferme l'application desktop et reste sans effet dans la version Web. La
barre d'espace lance la partie depuis l'accueil et relance une partie depuis
l'écran de fin. La touche `M` coupe ou réactive tous les sons. Pendant une
partie, `T` affiche ou masque le temps total écoulé.
Le titre du menu utilise le même effet ondulé que l'annonce `HIGHSCORE`. Le
temps du meilleur score reprend la police Tiny5 et la taille de l'écran de fin.

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
défaite et la victoire. La musique du menu joue en boucle sur l'accueil.
Lorsqu'une partie démarre, sa boucle en cours se termine avant que la musique
du jeu ne prenne le relais. Le jeu commence avec `section-1.wav`, puis passe à
la section numérotée suivante après chaque `TIER RELIEF`, à la fin du segment
musical de cinq secondes en cours. Si cette section n'existe pas, la section
courante continue en boucle.
L'apparition de chaque nouvelle main et le départ de son chronomètre sont
alignés sur la grille musicale. Ce comportement se configure dans
`resources/scripts/settings/settings.gd` : `SYNC_HANDS_TO_MUSIC` l'active ou le
désactive, et `HAND_BEAT_INTERVAL` vaut `1.0` pour un beat ou `0.5` pour un
demi-beat. `MUSIC_VOLUME_DB` règle le niveau de la musique et `SFX_VOLUME_DB`
le niveau global des effets sonores. `TILE_COLORS` contient les dix couleurs
utilisées par les cartes et les piles pour les valeurs de `0` à `9`. Un filtre
passe-bas, dont la fréquence est réglée par
`MUSIC_LOW_PASS_CUTOFF_HZ`, atténue la musique dans les menus et pendant les
annonces de règles spéciales. Il commence à se retirer dès la sortie de ces
écrans et s'ouvre progressivement pendant `MUSIC_LOW_PASS_RELEASE_SECONDS`.
Le lecteur musical utilise le mode de lecture `Stream` afin que ce filtre soit
également traité dans les exports Web ; les effets courts restent sur leur mode
de lecture à faible latence.
Les ticks du chronomètre sont discrets au début, puis accélèrent à partir des
deux dernières secondes : trois ticks entre `2` et `1`, puis six entre `1` et
`0`, avec une légère montée de volume et de hauteur. Pendant ces deux secondes,
l'horloge produit un flash rouge synchronisé avec chaque tick.

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
│   │   │   └── rules/
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
- `resources/scripts/special_rules/rules/` : implémentations et contrôleurs propres
  aux règles spéciales (lave, Sticky Fingers, lampe, mouvements et anneaux).
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

Tous les réglages sont centralisés dans `resources/scripts/settings/difficulty.gd` :

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

Les options de développement sont centralisées dans `resources/scripts/settings/debug.gd`.
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
  avant leurs paliers normaux et même si elles sont normalement incompatibles.
  Les contraintes de règles requises sont également ignorées afin de permettre
  le test de n’importe quelle combinaison. Par exemple, utiliser
  `[&"peek_a_card", &"lights_out"]`. Une liste vide restaure la sélection
  normale. Les doublons et identifiants inconnus sont ignorés avec un
  avertissement.

Lorsque `ENABLED` vaut `true`, un aide-mémoire des raccourcis est affiché en
jeu :

- `S` prépare la section musicale suivante, jouée à la fin du segment de cinq
  secondes en cours ;
- `G` active ou désactive le god mode pendant l'exécution ;
- `R` réinitialise immédiatement la partie avec les valeurs de départ ;
- `H` efface le high score sauvegardé.

Dans `resources/scripts/settings/debug.gd`, `UNLOCK_ENDLESS_MODE` permet d'afficher
le mode infini sans avoir préalablement terminé le jeu lorsque le debug est
activé.

## Special Rules

Un modificateur temporaire peut être sélectionné au début de chaque round de
progression. Les réglages se trouvent également dans `resources/scripts/settings/difficulty.gd` :

```gdscript
const ENABLED_SPECIAL_RULES: Array[StringName] = [
    &"shell_game",
    &"merry_go_stack",
    &"free_range_cards",
    &"pile_up",
    &"lights_out",
    &"peek_a_card",
    &"stack_attack",
    &"roman_holiday",
    &"musical_stacks",
    &"sticky_fingers",
    &"hot_potatoes",
    &"blind_delivery",
    &"mirror_match",
    &"sudden_death",
    &"grace_period",
    &"colorblind",
    &"floor_is_lava",
]

const FIRST_SPECIAL_RULE_ROUND := 4
const EXTRA_SPECIAL_RULE_CHANCE := 0.75
const MAX_COMBINED_RULES := 5
const LIGHTS_OUT_RADIUS := 60.0
const HOT_POTATO_DURATION := 1.0
const STICKY_HOT_POTATO_DURATION := 2.0
const GRACE_PERIOD_REVEAL_TIME := 1.25
const MIRROR_HORIZONTAL_WEIGHT := 75.0
const MIRROR_VERTICAL_WEIGHT := 20.0
const MIRROR_BOTH_AXES_WEIGHT := 5.0
```

Pour désactiver une règle dans les tirages automatiques, il suffit de commenter
sa ligne dans `ENABLED_SPECIAL_RULES`. Les verrouillages explicites de
`debug.gd` continuent de contourner ce filtre afin de permettre les tests.

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
  rester dans les tuiles ;
- `MUSICAL STACKS` : rotation cyclique et animée des piles encore actives après
  chaque placement correct ;
- `STICKY FINGERS` : une carte relâchée dans le vide reste attachée au pointeur
  jusqu'à son dépôt ou un retour forcé ;
- `HOT POTATOES` : un timer de drag de 1,5 seconde force le retour de la carte
  sans consommer d'erreur ni redémarrer le timer du tour ;
- `BLIND DELIVERY` : une carte visible se retourne dès son survol ou son
  premier contact tactile et reste cachée pendant le drag ;
- `MIRROR MATCH` : toute l'image du jeu est retournée horizontalement,
  verticalement ou sur les deux axes. Les probabilités relatives des trois
  variantes se règlent avec `MIRROR_HORIZONTAL_WEIGHT`,
  `MIRROR_VERTICAL_WEIGHT` et `MIRROR_BOTH_AXES_WEIGHT` ;
- `SUDDEN DEATH` : le round ne possède qu'un seul indicateur d'erreur ;
- `GRACE PERIOD` : le timer réel continue de tourner, mais son affichage est
  masqué entre les mains et apparaît seulement
  `GRACE_PERIOD_REVEAL_TIME` secondes avant la fin, avec une transition animée ;
- `COLORBLIND` : les couleurs permanentes des cartes et piles sont remplacées
  par une palette grise, sans supprimer les feedbacks temporaires ;
- `THE FLOOR IS LAVA` : une grande masse corail part des bords de l'écran et
  entoure une baie centrale sûre ouverte vers la main, comme une île de jeu.
  Son contour repose sur quelques points d'ancrage reliés par des courbes de
  Bézier légèrement déformées. Deux versions fixes existent : le contour du
  mockup de référence avec sa langue de lave à droite, et son miroir exact avec
  la langue à gauche. La baie est ajustée depuis l'emplacement réel des piles et
  des cartes de la main. Sa collision conserve les creux concaves et son contact
  force le retour d'une carte sans consommer d'erreur.

`SpecialRuleRegistry.gd` déclare toutes les règles, leurs poids, leurs rounds
minimums et leurs incompatibilités. `SpecialRuleManager.gd` effectue ensuite
la sélection pondérée sans doublon. Ensemble, `BLIND DELIVERY` et
`PEEK-A-CARD` gardent les cartes cachées sauf pendant leur survol dans la
main ; elles sont de nouveau masquées pendant le drag. Avant le round 25,
`SUDDEN DEATH` n'est pas combiné avec
`LIGHTS OUT`, `STICKY FINGERS` ou `THE FLOOR IS LAVA`.

`SpecialRule.gd` fournit la classe de base commune et `SpecialRuleData` en
hérite. `RoundModifiers.gd` reste l'unique état consulté par le gameplay et
chaque règle agit par `activate()` et `deactivate()` sur un `RoundContext`.
Le nettoyage central de fin de round annule les drags et timers de carte,
restaure les faces et couleurs, arrête les piles, supprime la lave et réaffiche
le timer.

Certaines paires reçoivent un titre spécial dans l'annonce, y compris
lorsqu'elles font partie d'une combinaison plus grande :

- `LIGHTS OUT + PEEK-A-CARD` : `BLIND DATE` ;
- `PILE UP + STACK ATTACK` : `ONE STEP FORWARD...` ;
- `ROMAN HOLIDAY + PILE UP` : `THE EMPIRE RISES` ;
- `SHELL GAME + ROMAN HOLIDAY` : `ET TU, STACK?` ;
- `FREE-RANGE CARDS + PEEK-A-CARD` : `CARDIO TRAINING` ;
- `LIGHTS OUT + STACK ATTACK` : `FEAR OF THE STACK`.
- `MUSICAL STACKS + MIRROR MATCH` : `DANCE LIKE NOBODY'S WATCHING` ;
- `STICKY FINGERS + HOT POTATOES` : `HANDS FULL` ;
- `BLIND DELIVERY + PEEK-A-CARD` : `LOOK, DON'T CARRY` ;
- `BLIND DELIVERY + MIRROR MATCH` : `WRONG ADDRESS` ;
- `SUDDEN DEATH + GRACE PERIOD` : `SURPRISE EXAM` ;
- `COLORBLIND + MIRROR MATCH` : `GREY MATTER` ;
- `THE FLOOR IS LAVA + HOT POTATOES` : `TOO HOT TO HANDLE` ;
- `THE FLOOR IS LAVA + STICKY FINGERS` : `COMMITMENT ISSUES` ;
- `MUSICAL STACKS + THE FLOOR IS LAVA` : `DANCE FLOOR`.

Les scènes spécialisées sont :

- `SpecialRuleAnnouncement.tscn` pour l'annonce en anglais ;
- `FlashlightOverlay.tscn` pour `LIGHTS OUT` ;
- `RegenerationRing.tscn` pour les timers de `STACK ATTACK`.
- `LavaZone.tscn` pour les zones réutilisables de `THE FLOOR IS LAVA`.

Les contrôles automatisés peuvent être lancés avec :

```sh
godot --headless --path . --script res://tests/test_special_rules.gd
godot --headless --path . --script res://tests/test_special_rule_effects.gd
godot --headless --path . --script res://tests/test_new_special_rules.gd
godot --headless --path . --script res://tests/test_game_start.gd
```

## Bonus de partie

Tous les `BONUS_INTERVAL` rounds terminés (5 par défaut), le chrono s'arrête et
deux bonus persistants de catégories différentes sont proposés. Un doublon
améliore le bonus jusqu'au niveau III et un bonus au niveau maximal quitte le
pool. Les constantes de fréquence, de nombre de choix et de types actifs se
trouvent dans `resources/scripts/settings/difficulty.gd`.

Les bonus disponibles sont :

- mémoire : `OPEN BOOK`, `QUICK PEEK`, `LAST REMINDER`, `LESSON LEARNED` ;
- main : `WILD CARD`, `REDRAW`, `LUCKY HAND` ;
- temps : `TIME BANK`, `WARM-UP` ;
- survie : `SPARE LIFE`, `SAFETY NET`, `CLEAN SLATE` ;
- règles spéciales : `RULE BREAKER`, `ADAPTATION`.

`WILD CARD` remplace une carte de la main par un joker `J`, sans dépasser la
taille normale de la main. Lorsque la main contient au moins deux cartes, le
joker ne remplace pas la carte jouable garantie. Un joker non joué est conservé
à gauche et le remplissage suivant génère une carte de moins.
Le bouton de `REDRAW` utilise `redraw.png`, effectue une rotation complète lors
de son utilisation et affiche les relances restantes à partir du niveau II.
`LESSON LEARNED` possède trois niveaux et reprend les durées de flash de
`QUICK PEEK` : 0,25, 0,4 puis 0,6 seconde.
Tant que `SAFETY NET` est disponible, tous les points de vie utilisent un
shader métallique argenté. Sa consommation joue une rupture visuelle et un
son métallique propres avant de restaurer les couleurs normales.

Au lancement d'une partie, le menu glisse vers le bas tandis que le timer, le
round, le plateau puis la main apparaissent successivement derrière lui. Les
durées, le décalage entre éléments et l'échelle initiale sont exposés dans la
section `Start Transition` de `GameManager` dans l'Inspector.

En mode debug, `F1` masque ou réaffiche la cheatsheet des raccourcis.
`RULE BREAKER` affiche toutes les règles d'une combinaison et permet d'en
retirer une avant son activation. Il réutilise l'écran d'annonce spécial,
affiche `DELETE N`, barre la règle survolée puis attend le clic avant de la
faire disparaître. Après la dernière suppression, une courte pause précède le
round. Au niveau I, il supprime une règle uniquement lorsqu'il en reste au
moins une autre. Au niveau II, il supprime toujours une seule règle mais peut
retirer l'unique règle du round. Au niveau III, il permet deux suppressions et
peut également vider complètement le round. `ADAPTATION` réduit leur intensité
de 20, 30 ou 40 %. Elle élargit la lumière de `LIGHTS OUT`, allonge le délai de
`HOT POTATOES` et la régénération de `STACK ATTACK`, fait réapparaître plus tôt
le timer de `GRACE PERIOD`, puis ralentit les déplacements de
`MUSICAL STACKS`, `SHELL GAME`, `MERRY-GO-STACK` et `FREE-RANGE CARDS`.

Les données statiques sont dans `resources/scripts/bonuses/BonusRegistry.gd`.
Tous les réglages d'équilibrage des bonus sont regroupés à la fin de
`resources/scripts/settings/difficulty.gd`, notamment les probabilités du
joker et de `LUCKY HAND`, les durées de révélation et les valeurs de chaque
niveau. La barre récapitulative des bonus possédés est réservée au mode debug ;
les bonus restent actifs lorsqu'elle est masquée.
`BonusManager.gd` conserve l'état de la partie et pilote
`BonusSelection.tscn`. Les propositions, le titre, le fond, les colonnes et les
valeurs d'animation sont éditables dans cette scène, également ouverte comme
instance éditable dans `Game.tscn`. `BonusChoiceCard.tscn` contient le sprite
et le shader des boutons, tandis que `ActiveBonusBadge.tscn` définit les
indicateurs de la barre. Une nouvelle partie réinitialise toujours les bonus.
Pour les tests, `LOCK_BONUSES` dans `resources/scripts/settings/debug.gd`
accepte des entrées `bonus_id: niveau`. Ces bonus sont accordés au lancement
et retirés du tirage afin de conserver exactement le niveau demandé.
Le test autonome se lance avec :

```sh
godot --headless --path . --script res://tests/test_bonus_system.gd
```
