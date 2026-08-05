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

Le preset `Android` produit un APK ARM64 en mode portrait. Le build par défaut
est signé avec une clé de debug locale générée dans `build/.android/` et peut
être installé directement sur un appareil :

```sh
./build/build_android.sh
```

L'APK versionné est écrit dans
`build/android/pile-down-android-<version>.apk`. L'export Android nécessite
OpenJDK 17 et un SDK Android configuré dans les paramètres d'éditeur Godot.
Le SDK doit notamment contenir Platform-Tools 35+, Build-Tools 35.0.1 et la
plateforme Android 35.
Le preset utilise les icônes Android dédiées de
`resources/sprites/android/` : une icône adaptative dont le motif reste dans
la zone sûre des masques de lanceur, ainsi qu'une silhouette monochrome pour
les icônes thématiques. Leur motif reprend directement les rendus pixel-art
des tuiles `3`, `2` et `1` du jeu, sans lissage.
Les exports Web, Linux et Windows utilisent la même pile de vraies tuiles via
`resources/sprites/branding/game-icon.png`, sur fond transparent et sans les couches
adaptatives propres à Android.

Pour produire un APK release, fournir la clé de signature hors du dépôt :

```sh
PILE_DOWN_ANDROID_EXPORT_MODE=release \
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/chemin/vers/pile-down.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=pile_down \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=mot_de_passe \
./build/build_android.sh
```

Pour produire les versions Web, Linux, Windows et Android en une seule
commande :

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

La touche `Échap` ou le petit bouton `ESC` en haut de l'écran revient à l'écran
d'accueil depuis le jeu. Le bouton fournit notamment ce contrôle aux écrans
tactiles. Sur l'écran d'accueil, `Échap` ferme l'application desktop et reste
sans effet dans la version Web. La
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
défaite et la victoire. Quand toutes les piles sont terminées, les cartes
restantes, jokers compris, sont défaussées vers le bas avant l'animation de
victoire.
La musique du menu joue en boucle sur l'accueil.
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
│       ├── android/
│       ├── backgrounds/
│       ├── branding/
│       ├── hand/
│       ├── tiles/
│       └── ui/
│           ├── buttons/
│           ├── icons/
│           │   └── arrows/
│           └── panels/
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

Les boutons `PLAY` et `REPLAY` utilisent
`resources/sprites/ui/buttons/button.png` à sa taille native 86×31. L'écran
final utilise `resources/sprites/ui/panels/pop-up.png` à sa taille native
256×192. Les tuiles utilisent leur format natif 34×37.

Le contour de progression de `resources/sprites/ui/icons/clock.png` est piloté
par un shader :
les pixels-clés du cercle sont remplis dans le sens horaire selon le temps
restant. Aucun arc vectoriel n'est dessiné par-dessus le pixel-art.

Les éléments visuels principaux sont positionnables directement dans
`resources/scenes/Game.tscn`. `TimerRing`, `RoundPanel`, `PilesBoard` et `HandTray`
peuvent être déplacés depuis l'éditeur 2D. La racine de cette scène est rangée
en branches repliables : `Artwork`, `Gameplay`, `Managers`,
`PresentationLayers` et `Screens`. Les trois vies sont des `TextureRect`
séparés sous `Gameplay/HandTray/MistakesDots` : le groupe ou chaque point
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

En mode debug, la touche `H` efface toute la progression globale : highscores,
Endless, checkpoints, découvertes, achievements présents ou ajoutés dans une
future version, et polices débloquées. Les volumes audio ne sont pas modifiés.

```gdscript
const ENABLED := false
const GOD_MODE := false
const START_AT_ROUND := 1
const LOCK_SPECIAL_RULES: Array[StringName] = []
```

Les annonces non interactives de progression, de checkpoint, de règle spéciale
et de combinaison peuvent être terminées immédiatement avec un clic, un toucher,
`Espace` ou `Entrée`. L'événement est consommé et ne déclenche jamais l'élément
de jeu situé dessous. Les écrans demandant un choix restent non skippables.

Le bouton illustré `ui/icons/stats.png`, placé en haut à droite du menu
principal, ouvre
les pages `HIGHSCORES`,
`ACHIEVEMENTS`, `BONUSES`, `SPECIAL RULES` et `FONTS`. Les entrées encore
inconnues restent masquées. La page des scores regroupe Classic, Endless et les
runs Checkpoint. Les polices débloquées peuvent être sélectionnées directement
depuis leur page ; chaque bouton conserve le nom de la police et une unique
rangée d'aperçu en bas utilise le vrai sprite coloré des tuiles à sa taille
native de 34×37 pixels. Les chiffres reprennent leur couleur de jeu et la ligne
peut défiler horizontalement. Elle affiche
les valeurs `1` à `N`, où `N` se règle avec `Font Preview Tile Count` dans
l'inspecteur de `ProgressionMenu`. Le choix actif reprend la
teinte bleue de la navigation. La liste `Tile Fonts > Available Fonts` du nœud
`Game` permet de choisir les polices proposées depuis l'inspecteur et la
propriété `Tile Font Size` de chaque entrée ajuste la taille des chiffres dans
le jeu et dans l'aperçu. La
police choisie s'applique uniquement aux valeurs des cartes et des piles, sans
modifier les textes de l'interface. Les cinq pages utilisent les
icônes sans panneau du dossier `resources/sprites/ui/icons/` (`stats.png`,
`trophies.png`, `bonuses.png`, `rules.png` et `fonts.png`) dans la
navigation. Tous les boutons fonctionnent à la souris, au clavier et au
tactile ; la touche `Escape` ou le bouton illustré `escape.png` ferme le menu.
Les pages Achievements, Bonuses, Special Rules et Fonts proposent un filtre
`BOTH`, `UNLOCKED` ou `LOCKED` ; la page Highscores n'affiche pas ce filtre.
La mise en page reste contenue dans la fenêtre logique minimale de 256×320 et
les listes longues défilent dans leur zone dédiée.
Les boutons illustrés utilisent tous `TextureHighlightButton.gd` et le shader
de surbrillance bleu commun au reste de l'interface.
La page `SPECIAL RULES` affiche une courte description fonctionnelle de chaque
règle découverte, distincte du texte d'ambiance utilisé pendant son annonce.
Les états débloqués et verrouillés des achievements, bonus et règles utilisent
les sprites `ui/check/checked.png` et `ui/check/unchecked.png` plutôt que des
marqueurs textuels.
`ProgressionMenu.tscn` fournit un aperçu directement dans l'éditeur. Les
propriétés `Editor Preview/Enabled` et `Editor Preview/Page` permettent
d'afficher chacune des cinq pages. La section `Entry Style` expose les polices
et tailles des titres et descriptions générés avec une actualisation immédiate.

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
    &"shaking_piles",
    &"wavy_baby",
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
const MERRY_GO_STACK_SPEED := 0.35
const MERRY_GO_STACK_SETUP_DURATION := 0.45
const MERRY_GO_STACK_MINIMUM_RADIUS := 58.0
const MERRY_GO_STACK_RADIUS_PADDING := 4.0
const SHAKING_PILES_AMPLITUDE_X := 4.0
const SHAKING_PILES_AMPLITUDE_Y := 4.0
const SHAKING_PILES_FREQUENCY_X := 1.8
const SHAKING_PILES_FREQUENCY_Y := 2.15
const SHAKING_PILES_PHASE_STEP_X := 1.73
const SHAKING_PILES_PHASE_STEP_Y := 2.31
const MOVING_PILES_SAFETY_SEARCH_ITERATIONS := 10
const MOVING_PILES_VISUAL_GAP := 2.0
const WAVY_BABY_AMPLITUDE := 12.0
const WAVY_BABY_SPEED := 1.6
const WAVY_BABY_PHASE := 0.0
const WAVY_BABY_HORIZONTAL_PHASE_SPACING := 0.06
const MIRROR_HORIZONTAL_WEIGHT := 75.0
const MIRROR_VERTICAL_WEIGHT := 20.0
const MIRROR_BOTH_AXES_WEIGHT := 5.0
```

`MERRY-GO-STACK` répartit régulièrement les piles sur une orbite autour de la
pile centrale. Son rayon respecte `MERRY_GO_STACK_MINIMUM_RADIUS` et grandit
automatiquement avec le nombre de piles pour conserver la distance minimale ;
`MERRY_GO_STACK_RADIUS_PADDING` ajoute une marge visuelle. Après leur entrée,
les piles rejoignent cette formation pendant
`MERRY_GO_STACK_SETUP_DURATION`, puis la rotation commence. `SHAKING PILES`
applique à chaque pile des phases horizontales et verticales différentes.
`WAVY BABY` utilise une phase commune décalée uniquement par la position
horizontale de chaque pile. Cela forme une vague globale continue qui traverse
le plateau de gauche à droite. Pour ces deux derniers mouvements, l'amplitude
est automatiquement réduite avant une
sortie du plateau ou un rapprochement inférieur à `MINIMUM_PILE_DISTANCE`.
Les amplitudes règlent la distance maximale sur chaque axe, les fréquences la
vitesse des oscillations et les `PHASE_STEP` le décalage entre deux piles.
`MOVING_PILES_SAFETY_SEARCH_ITERATIONS` contrôle la précision du calcul
continu de réduction de l'amplitude. Les positions de Wavy Baby restent
subpixel pendant le mouvement afin d'éviter des sauts d'un pixel entre deux
frames. `MOVING_PILES_VISUAL_GAP` conserve une petite séparation entre les
rectangles visibles, tandis que les limites sont celles de l'écran plutôt que
celles du conteneur logique du plateau.

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
statistique encore modifiable, choisie aléatoirement au premier palier,
deux statistiques distinctes au deuxième, puis trois et enfin quatre. Un
allègement retire une pile, une carte en main ou une valeur de départ, ou ajoute
une seconde au timer. Ce round de palier remplace entièrement l'augmentation de
difficulté habituelle : aucune statistique n'est d'abord augmentée. Chaque
valeur reste bornée par sa valeur initiale. Le démarrage debug à un round avancé
rejoue ces allègements dans leur ordre normal. Le premier relief correspond au
premier palier de règle spéciale, soit `FIRST_SPECIAL_RULE_ROUND` (`4` par
défaut), puis les suivants arrivent aux rounds 10, 18, 28 et 40.

Après la limite de cinq règles simultanées, les paliers théoriques continuent
de déclencher des `TIER RELIEF` selon la même formule, sans augmenter cette
limite. Avec la valeur par défaut `k = 4`, les reliefs supplémentaires arrivent aux rounds 54, 70 et
88. À partir du quatrième relief, les quatre statistiques sont allégées.

Les règles disponibles sont :

- `SHELL GAME` : échange animé de deux piles, puis de trois après le palier
  configurable ;
- `MERRY-GO-STACK` : orbite continue et régulière autour d'une pile centrale ;
- `SHAKING PILES` : oscillations locales désynchronisées autour des positions
  logiques des piles ;
- `WAVY BABY` : onde verticale continue dont la phase progresse horizontalement ;
- `FREE-RANGE CARDS` : entrée depuis le bord le plus proche de chaque position
  libre tirée aléatoirement, déplacement pseudo-aléatoire hors du plateau,
  puis sortie animée vers le bord le plus proche ;
- `PILE UP` : progression inversée de 0 vers S ;
- `LIGHTS OUT` : calque sombre avec lampe circulaire suivant le pointeur ou le
  doigt. Sur écran tactile, elle suit immédiatement la dernière position
  touchée sans revenir à une position de souris inactive. Le cercle lumineux
  se referme progressivement à l'activation et se rouvre à la fin du round.
  Son rayon en pixels se règle avec `LIGHTS_OUT_RADIUS` dans `difficulty.gd` ;
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
  chaque placement correct. Elle est incompatible avec `MERRY-GO-STACK`,
  `SHAKING PILES` et `WAVY BABY` ;
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

Tous les `BONUS_INTERVAL` rounds terminés (4 par défaut), le chrono s'arrête et
deux bonus persistants de catégories différentes sont proposés. Un doublon
améliore le bonus jusqu'au niveau III et un bonus au niveau maximal quitte le
pool. Les constantes de fréquence, de nombre de choix et de types actifs se
trouvent dans `resources/scripts/settings/difficulty.gd`.

Les bonus disponibles sont :

- mémoire : `OPEN BOOK`, `QUICK PEEK`, `LAST REMINDER`, `LESSON LEARNED`, `PILE MOVER` ;
- main : `WILD CARD`, `REDRAW`, `LUCKY HAND`, `BRING A FRIEND`, `DOUBLE DOWN`, `DEJA VU` ;
- temps : `TIME BANK`, `WARM-UP` ;
- survie : `SPARE LIFE`, `SAFETY NET`, `CLEAN SLATE` ;
- règles spéciales : `RULE BREAKER`, `ADAPTATION`.

`WILD CARD` remplace une carte de la main par un joker `J`, sans dépasser la
taille normale de la main. Lorsque la main contient au moins deux cartes, le
joker ne remplace pas la carte jouable garantie. Un joker non joué est conservé
à gauche et le remplissage suivant génère une carte de moins. Chaque nouveau
remplissage conserve néanmoins sa probabilité de générer un autre joker, tant
qu'une place reste disponible dans la main.
Le bouton de `REDRAW` utilise `redraw.png`, effectue une rotation complète lors
de son utilisation et affiche les relances restantes à partir du niveau II.
`LUCKY HAND` construit jusqu'à trois cartes utiles à partir des piles actives.
Le niveau I cible directement la pile la plus avancée. Le niveau II ajoute la
suite de cette pile avec `DOUBLE DOWN`, ou la prochaine valeur immédiatement
jouable. Le niveau III ajoute une seconde carte de chaîne lorsque le niveau de
`DOUBLE DOWN` le permet, sinon la valeur attendue par le plus de piles.
Avec `DEJA VU`, les copies sont limitées à son niveau et au nombre réel de
piles compatibles. Les jokers et la carte jouable garantie utilisent des
emplacements protégés et la taille normale de la main ne change jamais.
`LESSON LEARNED` possède trois niveaux et reprend les durées de flash de
`QUICK PEEK` se déclenche périodiquement : toutes les 4, 3 ou 2 mains selon
son niveau, pendant respectivement 0,10, 0,20 ou 0,25 seconde. Le timer est
suspendu pendant la révélation.

La progression des statistiques utilise un pity configurable
(`STAT_PITY_RATE`, `MAX_STAT_DROUGHT`, `STARTER_STAT_MULTIPLIER`). Les compteurs
sont plafonnés, restaurés avec les checkpoints et donnent la priorité à une
statistique éligible après une sécheresse maximale. Les checkpoints permanents
sont espacés par `CHECKPOINT_INTERVAL` et peuvent être
désactivés avec `ENABLE_CHECKPOINTS`.

Les mouvements continus sont séparés en trois règles : `MERRY-GO-STACK` utilise
des orbites prévisibles, `SHAKING PILES` conserve l'ancien mouvement local
irrégulier et `WAVY BABY` applique une onde verticale. Leurs amplitudes et
vitesses sont centralisées dans `difficulty.gd`.

Après la première victoire d'un round correspondant à `CHECKPOINT_INTERVAL`,
ou à l'un de ses multiples, son checkpoint est
conservé dans `user://pile_down.cfg` uniquement si aucune vie n'a été perdue
depuis le dernier checkpoint franchi (ou depuis le début de la run pour le
premier). Une erreur absorbée sans dégât ne bloque pas le déblocage. Le bouton
`FROM <round>`, placé à droite
de `PLAY`, lance le palier sélectionné. Les petites flèches, la molette ou les
touches haut/bas changent ce palier ; ses
statistiques permanentes sont restaurées et
les choix de bonus dus avant ce round sont proposés avant le lancement du
timer. Un départ inférieur ou égal à `TOTAL_ROUNDS` conserve le compteur visuel
descendant et un highscore partagé en rounds restants. Un checkpoint situé
au-delà de `TOTAL_ROUNDS` continue comme Endless et utilise un highscore partagé
en round atteint. Aucun classement checkpoint n'utilise le temps.

Les checkpoints sont séquentiels : le checkpoint `N` exige que `N - 1` soit
déjà débloqué. Plusieurs checkpoints peuvent néanmoins être obtenus pendant
une même run si chaque section qui les sépare est terminée sans perdre de vie.
Tant que `SAFETY NET` est disponible, tous les points de vie utilisent un
shader métallique argenté. Sa consommation joue une rupture visuelle et un
son métallique propres avant de restaurer les couleurs normales.

`BRING A FRIEND` emporte une voisine au niveau I (celle de droite en priorité),
les deux voisines au niveau II, puis toute la main au niveau III. Au dépôt, la
carte principale suit les règles normales tandis que chaque accompagnatrice
cherche automatiquement une pile compatible dans le voisinage immédiat de la
pile visée. Le rayon couvre les voisines au nord, au sud, à l'est et à l'ouest
du placement standard, mais pas les diagonales plus éloignées. Une
accompagnatrice qui ne trouve rien revient sans provoquer d'erreur ; chaque
pile ne peut en recevoir qu'une par dépôt. Si le placement principal est
incorrect, l'erreur annule immédiatement tout le groupe et aucune
accompagnatrice n'est jouée. Le timer de `HOT POTATOES` et la lave ne
surveillent que la carte principale et renvoient tout le groupe.

`PILE MOVER` permet de glisser une pile lorsque aucune carte n'est sélectionnée.
La zone autorisée couvre presque toute la fenêtre, y compris les marges autour
du plateau compact. Seuls les chevauchements avec la main, une autre pile ou la
lave sont interdits. Le timer, le compteur de round, l'aide debug et la barre
de bonus debug sont purement informatifs et ne bloquent pas les piles. Si une
pile est relâchée dans une zone interdite ou hors écran, elle est replacée à la
position autorisée la plus proche du dépôt. Sa dernière position valide ne
sert de repli que si aucune place n'est disponible. Les positions validées
deviennent les slots de la rotation suivante de `MUSICAL STACKS`.

Après un placement manuel, `DEJA VU` distribue jusqu'à une, deux ou trois copies
de la même valeur sur autant de piles compatibles distinctes. `DOUBLE DOWN`
enchaîne ensuite jusqu'à une, deux ou trois valeurs attendues sur la pile
initiale. Les deux bonus utilisent la même animation volontairement plus lente
pour laisser le temps de lire l'évolution du plateau. Ces placements
automatiques ne coûtent ni temps ni erreur et une seule nouvelle main est
générée à la fin de l'action complète.

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
niveau. La liste `ENABLED_BONUSES` permet de retirer un bonus de toutes les
sélections automatiques en commentant simplement son identifiant, comme
`ENABLED_SPECIAL_RULES` pour les règles. Les bonus verrouillés par le mode
debug peuvent toujours contourner cette liste. La barre récapitulative des
bonus possédés est réservée au mode debug ;
les bonus restent actifs lorsqu'elle est masquée.
`BonusManager.gd` conserve l'état de la partie et pilote
`BonusSelection.tscn`. Les propositions, le titre, le fond, les colonnes et les
valeurs d'animation sont éditables dans cette scène, également ouverte comme
instance éditable dans `Game.tscn`. `BonusChoiceCard.tscn` contient le sprite
et le shader des boutons, tandis que `ActiveBonusBadge.tscn` définit les
indicateurs de la barre. Une nouvelle partie réinitialise toujours les bonus.
Pour les tests, `LOCK_BONUSES` dans `resources/scripts/settings/debug.gd`
accepte des entrées `bonus_id: niveau`. Ces bonus sont accordés au lancement
et retirés du tirage afin de conserver exactement le niveau demandé. Un niveau
négatif force en plus les activations probabilistes à 100 %, tout en utilisant
les statistiques du niveau correspondant : `-1` conserve le niveau I, `-2` le
niveau II, etc. La valeur absolue est bornée au niveau maximal du bonus.
Le test autonome se lance avec :

```sh
godot --headless --path . --script res://tests/test_bonus_system.gd
```
