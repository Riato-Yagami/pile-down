# Pile Down

L’audit de performances et ses limites sont documentés dans
[`PERFORMANCE_AUDIT.md`](PERFORMANCE_AUDIT.md). Les benchmarks reproductibles
restent dans `tests/performance/` et utilisent des sauvegardes isolées :

```sh
python tests/performance/run_benchmarks.py --godot godot --matrix tests/performance/core-matrix.json --timeout 300
python tests/performance/run_benchmarks.py --godot godot --matrix tests/performance/display-matrix.json --timeout 150
```

Exécuter les matrices successivement, sans autre benchmark simultané. Elles
ouvrent des fenêtres de jeu et conservent métriques et logs dans
`tests/performance/results/`. Ne pas utiliser `--fixed-fps` pour ces mesures.

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

Chaque nouvelle run reçoit un seed 64 bits. Pour une run lancée depuis un seed
saisi, le menu Pause affiche sa forme partageable et permet de la copier. Le
seed d'une run aléatoire reste masqué pendant la partie et apparaît seulement
sur l'écran de victoire ou de défaite. La page `CHALLENGES` accepte aussi un
entier ou un texte dans
`PLAY A SEED`, dans une page séparée accessible avec l'icône `seeds.png` ; seuls
les challenges, bonus et règles spéciales déjà déverrouillés y sont proposés.
Chaque bonus sélectionné peut démarrer à un niveau déjà atteint dans la
progression, sans pouvoir dépasser le meilleur niveau enregistré. Bonus et
règles utilisent chacun un menu multi-sélection unique ; un seul niveau peut
être coché à la fois pour un même bonus. Les niveaux disponibles restent sur
la ligne du bonus et les entrées se répartissent en plusieurs colonnes lorsque
la largeur le permet. Pour une run lancée depuis
cette page, `REPLAY`, `RESTART` et le passage en Endless réutilisent le seed
saisi. Les runs aléatoires continuent de recevoir un nouveau seed lors d'un
replay ordinaire. Les records conservent le seed qui les a produits dans
`user://pile_down.cfg`.
L'affichage partageable utilise la scène commune
`resources/scenes/ui/SeedCopyDisplay.tscn` : l'icône Seeds remplace le libellé,
la valeur et l'icône Copy se surlignent ensemble, et un clic sur l'ensemble la
copie lorsque le presse-papier est disponible.
Au repos, le nombre de caractères du seed affichés est configurable sur
`SeedCopyDisplay` avec `collapsed_character_count` (cinq par défaut) ; le survol
ou le focus révèle sa valeur complète avec une courte animation et maintient
l'icône Copy juste à sa suite, sans modifier la valeur copiée.
La page Seeds permet également de présélectionner les bonus découverts et les
règles spéciales déjà battues. Ces choix utilisent les contrôles pixel-art
bleus, sont conservés par `REPLAY`/`RESTART` et ne permettent jamais de
contourner un verrou de progression ou une restriction de challenge.
La scène `ChallengeSelection.tscn` expose dans l'inspecteur `Show Editor
Preview`, `Editor Preview Page` et `Preview All Unlocked`. Ces propriétés
permettent de modifier directement les pages Challenges et Seeds dans
l'éditeur avec des données de démonstration, sans lire ni modifier la sauvegarde.

Les tirages de difficulté, mains, bonus, règles spéciales, mouvements et effets
cosmétiques utilisent des streams indépendants dérivés du seed de la run. Une
variation visuelle ne peut donc pas déplacer les prochains tirages de gameplay.
Tous les quatre rounds, une section sans véritable erreur depuis le précédent
choix affiche brièvement `FLAWLESS!` et propose trois bonus au lieu de deux ; le
joueur n'en choisit toujours qu'un. Une erreur absorbée par `SAFETY NET` casse
également cette série, contrairement aux retours de cartes non punitifs.

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

Pour mémoriser les chemins propres à un PC, copier
`build/export.local.sh.example` vers `build/export.local.sh` et y renseigner
Godot (`PILE_DOWN_GODOT_BIN`), le JDK (`JAVA_HOME`) et le SDK Android
(`ANDROID_HOME`). Tous les scripts de build chargent automatiquement ce fichier,
qui est ignoré par Git. Les valeurs déjà définies dans le terminal restent
prioritaires avec les affectations par défaut du modèle. Les variables
`PILE_DOWN_JAVA_HOME` et `PILE_DOWN_ANDROID_SDK` restent prioritaires pour Android.
Dans Git Bash, il suffit ensuite de lancer `bash build/scripts/build_android.sh`
ou le script de la plateforme souhaitée, sans refaire les commandes `export`.

Le preset `Web` produit une version release sans threads, compatible avec un
hébergement statique standard :

```sh
./build/scripts/build_web.sh
```

Les templates d'export doivent correspondre à la version de Godot utilisée.
S'ils manquent, les scripts téléchargent automatiquement les templates
officiels correspondants. Les caches sont regroupés dans `build/.cache/` :
`templates/` conserve l'archive téléchargée, `data/` les données Godot sous
Linux et `config/` la configuration locale. Sous Windows, Git Bash et Godot
natif utilisent `config/Godot/export_templates/` via un `APPDATA` local au
build. Le premier téléchargement est volumineux ; les builds suivants
réutilisent les templates sans réseau. Une archive déjà téléchargée peut
être fournie avec `PILE_DOWN_TEMPLATE_ARCHIVE=/chemin/vers/templates.tpz`.
Les scripts nécessitent Bash, Python 3 et `unzip`, ainsi que `curl` si les
templates doivent être téléchargés. Sous Windows, les lancer depuis Git Bash
et définir `PILE_DOWN_GODOT_BIN` avec le chemin du véritable exécutable Godot
(pas un raccourci ni un lanceur console dont l'exécutable associé manque).
`PILE_DOWN_PYTHON_BIN` permet de choisir Python (`python` sous Windows,
`python3` ailleurs). L'empaquetage conserve les droits d'exécution Linux,
y compris lorsque le ZIP est créé sous Windows.
Le script lit `VERSION` (par exemple `v0.2`), produit le point d'entrée
`build/platforms/web/index.html`, puis crée automatiquement
`build/platforms/web/pile-down-web-<version>.zip`. Pour utiliser un
autre exécutable Godot :

```sh
PILE_DOWN_GODOT_BIN=/chemin/vers/godot ./build/scripts/build_web.sh
```

Le build Linux x86_64 et son archive versionnée sont produits dans
`build/platforms/linux/` avec :

```sh
./build/scripts/build_linux.sh
```

Le build Windows x86_64 produit `pile-down.exe` et une archive versionnée dans
`build/platforms/windows/` avec :

```sh
./build/scripts/build_windows.sh
```

Le preset `Android` produit un APK ARM64 en mode portrait. Le build par défaut
utilise les templates APK standards, sans compilation Gradle. Le script transmet
les chemins validés du JDK et du SDK Android aux paramètres Godot du build,
puis vérifie que l'APK a bien été créé avant d'annoncer la réussite. Le build
est signé avec une clé de debug locale générée dans `build/.android/` et peut
être installé directement sur un appareil :

```sh
./build/scripts/build_android.sh
```

L'APK versionné est écrit dans
`build/platforms/android/pile-down-android-<version>.apk`. L'export Android nécessite
OpenJDK 17 et un SDK Android configuré dans les paramètres d'éditeur Godot.
Le SDK doit notamment contenir Platform-Tools 35+, Build-Tools 35.0.1 et la
plateforme Android 35.

Le script utilise `JAVA_HOME` pour le JDK et `ANDROID_HOME` (ou
`ANDROID_SDK_ROOT`) pour le SDK. `PILE_DOWN_JAVA_HOME` et
`PILE_DOWN_ANDROID_SDK` permettent de remplacer ces chemins. Sous Windows,
le SDK est recherch? par d?faut dans `%LOCALAPPDATA%/Android/Sdk` ; le JDK
17 ou plus r?cent doit ?tre install? et configur? explicitement (Java 8
et un simple JRE ne suffisent pas). Exemple Git Bash, en rempla?ant le
chemin du JDK par son emplacement r?el :

```bash
export JAVA_HOME="C:/chemin/vers/jdk-17"
export ANDROID_HOME="$LOCALAPPDATA/Android/Sdk"
bash build/scripts/build_android.sh
```

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
./build/scripts/build_android.sh
```

Pour produire un **Android App Bundle (`.aab`) release signé** pour Google Play,
utiliser le script dédié depuis Bash ou Git Bash :

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="C:/chemin/vers/upload.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="upload"
read -rsp "Mot de passe de la clé : " GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
echo
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
bash build/scripts/build_android_aab.sh
unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

Ce script utilise les mêmes variables JDK, SDK et Godot que l'export APK,
mais impose le mode release et le preset **Android AAB**. Les trois variables
de signature sont obligatoires ; aucune clé de debug n'est utilisée pour l'AAB.
Elles peuvent aussi être définies dans le fichier local `.env` à la racine,
chargé automatiquement par le script AAB.
Utiliser de préférence **OpenJDK 17** : le template Gradle actuel accepte les
JDK 17 à 23, mais échoue avec Java 25 fourni par certaines versions d'Android
Studio (`Unsupported class file major version 69`). Définir
`PILE_DOWN_JAVA_HOME` dans `build/export.local.sh` vers un JDK compatible.
Le fichier produit est `build/platforms/android/pile-down-android-<version>.aab`.
Le script installe le template `android_source.zip` correspondant à Godot, puis
le projet Gradle au premier export si `android/build/` n'existe pas. Un projet
Gradle déjà présent est conservé ; après un changement de version Godot, mettre
à jour son modèle via **Projet → Installer le modèle de compilation Android**.
Le premier build Gradle peut télécharger ses dépendances et nécessite un accès réseau.

Les presets **Android** et **Android AAB** utilisent le nom de package
`dev.juels.piledown`, attendu par la fiche Google Play. Renommer le fichier `.aab`
ne change pas cet identifiant intégré au bundle.
Avant la publication, configurer dans le preset **Android AAB** le numéro de version utilisateur (`version/name`)
et un `version/code` supérieur à celui déjà envoyé sur Google Play. Le fichier
`VERSION` contrôle le nom du fichier de sortie, pas ces métadonnées Android.
Le preset APK `Android` reste indépendant. Les clés et mots de passe doivent
rester hors du dépôt. Voir aussi la
[documentation d'export Android Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

Pour produire les versions Windows, Web, Linux, Android APK et Android AAB en une
seule commande (JDK, SDK Android et signature release requis comme ci-dessus) :

```sh
./build/scripts/build_all.sh
```

Le dossier `build/scripts/` regroupe les scripts et leurs outils communs.
Les exports sont rangés par plateforme dans `build/platforms/web/`, `linux/`,
`windows/` et `android/`. Les archives des différentes versions
cohabitent dans chaque dossier : par exemple `pile-down-windows-v2.0.zip` et
`pile-down-windows-v2.1.zip`. Le fichier `VERSION` détermine le nom de l'archive.
Une nouvelle version conserve les anciennes archives ; relancer la même version
remplace son archive. Les fichiers non versionnés (`index.html`, `pile-down.exe`,
etc.) correspondent au dernier export. Les presets de l'éditeur utilisent ces
mêmes dossiers par plateforme.
`renders/tiles/` contient les rendus utilisés par les outils de publication,
et `.android/` la clé de signature de debug. Les fichiers temporaires sont
regroupés dans `tmp/screenshots/`, `tmp/reports/`, `tmp/logs/` et `tmp/tools/` ;
les futurs profils de tests doivent aussi rester sous `tmp/`. Les caches et
`tmp/` sont ignorés par Git. Le contenu de `.cache/` est régénérable ; supprimer
les templates oblige toutefois à les télécharger de nouveau.

Les tests hors ligne des scripts vérifient les versions officielles, Mono et
prérelease, les chemins Windows, la réutilisation des templates, les erreurs
d'arguments ou d'archive, les droits d'exécution dans les ZIP et la conservation
de plusieurs versions dans le même dossier de plateforme :

```sh
python tests/test_build_scripts.py
```

Si Bash n'est pas dans le PATH, définir `PILE_DOWN_BASH` avec son chemin.
Ces tests utilisent des fixtures ; la validation des exports réels reste
`./build/scripts/build_all.sh`.

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

Les captures portrait de la v2.0 pour Google Play sont dans
[`publishing/screenshots/2.0/`](publishing/screenshots/2.0/README.md) : huit PNG
par série, sans chronomètre global ni transparence. `android/` utilise le mode
adaptatif en 1080 × 1920 ; `classic/` le mode classique en 1280 × 1600 (ratio 4:5).
Les séries `tablet-7/` et `tablet-10/` utilisent le mode adaptatif portrait en
1440 × 2560 et 1800 × 3200 respectivement.
L'ordre conseillé et les commandes de régénération accompagnent les images.

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

La touche `Échap` ou le petit bouton `ESC` en haut de l'écran ouvre une
confirmation de sortie pendant une partie. `RESTART` relance le même mode avec
ses valeurs initiales, `QUIT` revient à l'écran titre et `CONTINUE` referme la
popup sans modifier la partie. Cette confirmation ne
met en pause ni le compte à rebours du round ni le temps global de la run ; un
second appui sur `Échap` la ferme. Dans cette popup, `Entrée` quitte la run et
`R` la redémarre. Depuis les écrans de résultat, `ESC` revient à l'écran
d'accueil. Le bouton fournit notamment ce contrôle aux écrans
tactiles. Sur l'écran d'accueil, `Échap` ferme l'application desktop et reste
sans effet dans la version Web. La
barre d'espace lance la partie depuis l'accueil et relance le mode courant
(normal, endless, checkpoint ou challenge) depuis l'écran de fin. Lors d'un
restart ou replay, les valeurs initiales des piles restent visibles un peu plus
longtemps avant leur retournement. La durée lisible commence après la dernière
animation d'entrée et se règle avec `pile_value_hold_duration` dans
`GameManager`. La touche `M` coupe ou réactive tous les sons. Pendant une
partie, `T` affiche ou masque le temps total écoulé.
Le panneau de confirmation et ses trois boutons verticaux utilisent des marges
nine-slice : leurs coins pixel-art restent intacts lorsque le contenu est mis
en page. Les boutons s'élargissent sans réduire la police de 20 px, et le
panneau conserve une marge supplémentaire au-dessus et en dessous de la
colonne. Les cases d'acronymes des bonus emploient le même découpage pour
s'élargir selon leur texte sans déformer leurs bords.
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
défaite et la victoire. Lorsqu'une dernière erreur termine la partie, toutes
les piles encore visibles se retournent ensemble, restent découvertes un court
instant, puis la popup de game over apparaît. Quand toutes les piles sont terminées, les cartes
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

La répartition des responsabilités, les déplacements de ressources et les limites
de la validation de la refactorisation sont détaillés dans
[`REFACTORING.md`](REFACTORING.md).

```text
pile-down/
├── resources/
│   ├── data/                     # définitions et catalogues ordonnés activés
│   │   ├── achievements/
│   │   ├── bonuses/
│   │   ├── challenges/
│   │   ├── fonts/
│   │   ├── palettes/
│   │   └── special_rules/
│   ├── fonts/
│   │   ├── extra/
│   │   │   ├── PressStart2P/
│   │   │   └── autres polices et licences
│   │   ├── Tiny5-Regular.ttf
│   │   └── VCR_OSD_MONO_1.001.ttf
│   ├── scenes/
│   │   ├── Game.tscn
│   │   ├── Main.tscn
│   │   ├── bonuses/
│   │   ├── challenges/
│   │   ├── gameplay/             # Card, Pile
│   │   ├── progression/
│   │   └── special_rules/
│   ├── scripts/
│   │   ├── audio/
│   │   ├── bonuses/
│   │   ├── challenges/           # ui/ : construction et style de la page Seeds
│   │   ├── core/                 # debug/ et session/ : orchestration spécialisée
│   │   ├── data/                 # types Data et DataCatalog communs
│   │   ├── gameplay/             # card/, interaction/, round/
│   │   ├── progression/          # records et checkpoints/
│   │   ├── settings/             # SaveConfig et display/ScreenSizeOptions
│   │   ├── special_rules/
│   │   │   └── rules/
│   │   └── ui/                   # game/ et progression/ : présentation
│   ├── materials/                # backgrounds/ et textures/tiles/
│   ├── shaders/                  # backgrounds/ et ui/
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

Toutes les définitions persistantes héritent de `Data`, qui porte leur `id`
stable. Chaque fichier catalogue à la racine de `resources/data/` est un
`DataCatalog` : son tableau `enabled_data` active les définitions et fixe leur
ordre de présentation et d'utilisation. Les bonus et règles spéciales sont donc
éditables dans leurs propres `.tres`, au même titre que les achievements,
challenges, polices et palettes.

- `resources/scenes/Game.tscn` et `resources/scripts/core/GameManager.gd` : références
  de scène, état partagé et points d'entrée des signaux. Les contrôleurs spécialisés
  portent le déroulement des sessions/rounds, les interactions et la présentation.
- `resources/scripts/gameplay/PileLayoutManager.gd` : dispositions compactes et stables des piles.
- `resources/scripts/tools/export_unlockables.gd` : export Markdown des déblocables
  et achievements actifs, avec leurs conditions, valeurs par défaut et comptes.
- `resources/scripts/ui/DifficultyAnnouncement.gd` : apparition successive des hausses
  de difficulté, avec déplacement fluide de la première ligne et léger rebond
  de la seconde. Les deux restent lisibles ensemble ; l'annonce reste passable.
- `resources/scripts/gameplay/DifficultyProgression.gd` : état et calculs pondérés
  de la progression de difficulté, y compris les paliers de soulagement.
- `resources/scripts/settings/GameOptionsController.gd` : chargement et
  application des options audio, gameplay et graphiques, du fond, de la poussière
  et des dialogues de sauvegarde. `settings/display/ScreenSizeOptions.gd` porte
  la résolution et les sélecteurs d'affichage. Les
  méthodes homonymes de `GameManager` restent des façades pour les signaux des
  scènes et la compatibilité des tests.
- `resources/scripts/progression/ProgressionSnapshotBuilder.gd` : conversion de
  l'état de partie en données d'affichage pour les scores, succès, découvertes
  et cosmétiques, sans responsabilité d'animation.
- `resources/scripts/audio/SoftAudio.gd` : retours sonores doux générés sans ressource externe.
- `resources/scripts/ui/RoundDots.gd` : indicateurs minimalistes des erreurs restantes.
- `resources/scenes/gameplay/Card.tscn` et `resources/scripts/gameplay/Card.gd` : carte réutilisable, sélection et
  retournement, avec relief et inclinaison simulés.
- `resources/scripts/gameplay/card/` : composants visuels spécialisés des cartes ;
  `CardMotionController.gd` gère le mouvement par frame et
  `CardAppearance.gd` applique les textures, couleurs, polices et valeurs.
- `resources/scenes/gameplay/Pile.tscn` et `resources/scripts/gameplay/Pile.gd` : état d'une pile, valeur attendue et
  animations.
- `resources/scripts/gameplay/HandManager.gd` : génération des mains avec garantie d'une carte
  jouable.
- `resources/scripts/special_rules/rules/` : implémentations et contrôleurs propres
  aux règles spéciales (lave, Sticky Fingers, lampe, mouvements et anneaux).
- `resources/scripts/gameplay/TimerManager.gd` : compte à rebours indépendant.
- `resources/scripts/ui/progression/ProgressionPreviewBuilder.gd` : données de
  prévisualisation éditeur du menu de progression, séparées de son contrôle UI.

Les composants communiquent par signaux afin de rester faiblement couplés.
L'index des responsabilités et façades encore exposées par `GameManager` est
maintenu dans `docs/game-manager-function-index.md`.

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

## Exporter les déblocages actifs

Depuis la racine du projet :

```sh
godot --headless --path . --script resources/scripts/tools/export_unlockables.gd
```

Le script produit `DEBLOCAGES.md` avec uniquement les polices, palettes,
challenges et achievements présents dans les `enabled_data` de leurs catalogues.
Il indique les totaux par catégorie, le total des déblocables, les disponibilités
par défaut, la difficulté interne et les liens entre achievements et récompenses,
avec la logique de chaque association. Le tri suit la difficulté croissante dans
chaque catégorie ; les récompenses par défaut sont placées en premier.
Les cases et espaces de notes servent à préparer une nouvelle répartition ;
ils ne modifient pas les ressources du jeu automatiquement.

Pour conserver un document annoté, choisir un nouveau fichier de sortie :

```sh
godot --headless --path . --script resources/scripts/tools/export_unlockables.gd -- DEBLOCAGES_NOUVEAUX.md
```

Le script refuse d'écraser un fichier existant. Ajouter `--force` après `--`
pour le régénérer explicitement (cela remplace aussi les annotations).
Le dossier de destination doit déjà exister. Aucune sauvegarde joueur n'est lue
ou modifiée, et les options de déblocage du mode debug sont ignorées.

## Régler la difficulté

Tous les réglages sont centralisés dans `resources/scripts/settings/difficulty.gd` :

La montée en difficulté est plus rapide au début : après une hausse normale,
un second attribut peut augmenter avec une probabilité qui diminue à chaque
round. En contrepartie, la probabilité qu'un round n'ajoute aucune difficulté
augmente progressivement. Les chances initiales, leur variation par round et
le plafond des rounds sans hausse sont configurables avec les constantes
`EXTRA_DIFFICULTY_*` et `NO_DIFFICULTY_*`.

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
`DEBUG MODE` en rouge et la cheatsheet des raccourcis. La touche `U` active ou
désactive `UNLOCK EVERYTHING` et recharge la scène avec achievements, polices, palettes, bonus,
règles, checkpoints et Endless débloqués uniquement en mémoire. Le désactiver
recharge la progression réelle depuis la sauvegarde, qui n'est jamais modifiée
par ce toggle.

La touche `E` termine le round courant et peut être pressée rapidement pour
mettre plusieurs victoires en file. Pendant cette séquence accélérée, le timer
du tour est arrêté et ses expirations devenues obsolètes sont ignorées afin
qu'elles ne provoquent pas de dégât dans un round suivant.

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
depuis leur page ; chaque bouton conserve le nom de la police et l'aperçu en
bas utilise le vrai sprite coloré des tuiles à sa taille native de 34×37 pixels.
Les tuiles reviennent automatiquement à la ligne lorsqu'elles dépassent la
largeur disponible. L'aperçu est placé sous la navigation et le contenu pour
occuper toute la largeur intérieure de la fenêtre. Leur texte reprend le
centrage optique du jeu et affiche
d'abord le dos gris `?` utilisé en jeu, indépendamment de la palette, puis les
valeurs `0` jusqu'à la plus haute valeur de tuile déjà découverte. Cette valeur
est mémorisée dans `progression/max_discovered_tile_value`. L'aperçu réserve la
hauteur de ses lignes complètes et masque sa barre de défilement verticale afin
de ne jamais rogner le bas des tuiles. Dans l'éditeur uniquement,
`Editor Preview Tile Count` permet de simuler entre 1 et 10 tuiles numériques
pour vérifier les différents retours à la ligne ; cette valeur n'affecte pas la
progression en jeu. Les listes défilantes utilisent les sprites
`slide-bar/vertical/bar.png` et `selector.png`. La piste de 8 pixels est rendue
en nine-patch vertical avec des extrémités protégées sur 4 pixels. Le sélecteur
reste toujours à sa taille native de 6×14 pixels, centré dans la piste et
déplacé uniquement sur l'axe vertical ; le `VScrollBar` fonctionnel reste
invisible derrière ce visuel.
Le choix actif reprend la teinte bleue de la navigation. Chaque fichier de
`resources/data/fonts/` décrit une police proposée et expose la ressource,
`Tile Font Size`, `Tile Font Offset`, `Title Font Size`, `Title Font Offset` et
l'achievement requis pour la débloquer. La taille du titre peut ainsi différer
de celle des chiffres ; une valeur de `0` la synchronise avec `Tile Font Size`.
`Tile Font Size` n'impose aucune valeur minimale ou maximale et est appliqué tel
quel aux cartes, piles et previews.
Le premier offset ajuste la position des chiffres sans déplacer les tuiles ; le
second corrige indépendamment le titre rendu avec cette police dans la liste.
`Override Hidden Tile With Font` remplace le dos contenant un `?` pré-dessiné
par une tuile neutre et rend ce symbole avec la même police, taille et offset
que les chiffres, dans le jeu comme dans les previews. Cette option est activée
par défaut.
`FontRegistry` charge les entrées activées de `resources/data/fonts.tres` et les
trie par difficulté de l'achievement requis. La liste des achievements provient de
`resources/data/achievements.tres`. La taille choisie s'applique aux chiffres dans le jeu,
au titre de la police dans sa liste et immédiatement dans l'aperçu de l'éditeur
lorsqu'elle est modifiée. Dans le preview de l'éditeur uniquement, la police et
la palette sélectionnées apparaissent en tête de leurs listes ; leur ordre en jeu
reste celui de la difficulté de déblocage. Les réglages `Defaults` et `Editor Preview` sont
centralisés sur le nœud `FontCatalog` de `ProgressionMenu`. `Default Font` et
`Default Palette` déterminent les choix initiaux et de réinitialisation du jeu.
Le bouton `Reload Editor Preview` de ce même nœud permet de forcer le rendu. La
police choisie s'applique uniquement aux valeurs des cartes et des piles, sans
modifier les textes de l'interface. Les cinq pages utilisent les
icônes sans panneau du dossier `resources/sprites/ui/icons/` (`stats.png`,
`trophies.png`, `bonuses.png`, `rules.png` et `fonts.png`) dans la
navigation. Tous les boutons fonctionnent à la souris, au clavier et au
tactile ; la touche `Escape` ou le bouton illustré `escape.png` ferme le menu.
Sur toutes les pages sauf `HIGHSCORES`, le filtre de verrouillage est visible à
côté du titre. Chaque clic sur son unique cadenas parcourt `BOTH`, `LOCKED`,
puis `UNLOCKED` : `BOTH` montre le cadenas fermé normal, `LOCKED` l'assombrit
et enfonce son anse, et `UNLOCKED` retourne l'anse autour de son montant gauche.
Le cadenas conserve sa couleur claire dans les trois modes et son survol
l'éclaircit davantage, sans afficher de texte ou de tooltip. Le même filtre est
disponible dans la sélection des challenges.
Les deux menus instancient la scène partagée
`resources/scenes/ui/ProgressionLockFilter.tscn`. Son sélecteur
`Editor Preview Mode` prévisualise les trois états dans l'éditeur ; le nœud
`HandleFlipAnchor` définit visuellement le pivot du retournement de l'anse et
peut être déplacé pour ajuster l'ouverture aux deux instances simultanément.
Le nœud `HoverRegion` de cette scène définit la zone interactive commune aux
différentes poses du cadenas sans élargir son espace dans les conteneurs.
La propriété `Text Offset` du cadenas déplace tout le visuel et sa zone
interactive par rapport au titre voisin. La sélection des challenges garde un
spacer après le cadenas afin que le bouton retour reste aligné à droite.
Dans Progression, un emplacement de hauteur fixe reste réservé au cadenas sur
toutes les pages : le titre et le contenu ne bougent donc pas quand il est
absent. Son passage entre `HIGHSCORES` et les autres pages utilise un court
fondu avec réduction/agrandissement, sans modifier la taille du menu.
Les pastilles de ces boutons reprennent le même placement visuel que celle du
bouton de progression principal, après compensation du centrage de l'icône
23×25 dans les boutons 30×34 du panneau. L'aperçu éditeur simule uniquement
un nouvel achievement et n'affiche donc la pastille que sur `ACHIEVEMENTS`.

Le catalogue contient 28 polices, dont `PRESS START 2P`, `TINY5`, `VCR OSD
MONO`, `8-BIT ARCADE`, `EDIT UNDO DOT`, `PIXEL WESTERN`, `UPHEAVAL`, `VHS
GOTHIC`, `ALAGARD`, `ALKHEMIKAL`, `BETTER VCR`, `BIRCH LEAF`, `BOILED PASTA`,
`DICO`, les deux variantes `DIGITAL DISCO`, `DIGITALIX`, `EMPLOYEE OF THE
MONTH`, `GOTHIC PIXELS`, `GRAPE SODA`, `KIWI SODA`, `MONSTER FRIEND`, `MYSIMS
RACING`, `PIXELATED PUSAB`, `PIXELED` et `PIXELLARI`. Chaque police verrouillée
possède un achievement distinct. `PIXEL WESTERN` conserve sa taille native recommandée
de 8 px, `UPHEAVAL` sa taille de 14 pt et `EDIT UNDO DOT` est importée sans
anticrénelage conformément à sa documentation. Les fichiers de licence,
readme et attribution restent distribués avec les polices. `VHS GOTHIC` est
attribuée à Spottie Leonard et à la police source `CHARGEN '92` de
ParadigmTheGreat sous CC BY-SA 3.0.

Les polices sans licence locale mais indiquées « 100% free » sur leur page
DaFont sont intégrées selon cette autorisation. `8-bit pusab` et `Daydream DEMO`
ont été supprimées du dépôt car leurs licences jointes interdisaient l'usage
commercial. Les fichiers `.fon` restent hors du catalogue, car Godot ne les
prend pas en charge.

La palette `OR MASSIF` propose dix teintes bronze, dorées et champagne. Elle
se débloque avec `LA TOTALE`, obtenu en débloquant tous les autres achievements
actifs (sans se compter lui-même), y compris `PHOTO DE FAMILLE` et `CHACUN SON TOUR`.
Avec au moins quatre piles, `PHOTO DE FAMILLE` demande de les amener toutes à 1
avant d'en terminer une, dans un round descendant ; `CHACUN SON TOUR` demande
de terminer une pile avant de poser une carte sur une autre. Les erreurs sont
autorisées pour les deux, et les placements automatiques des bonus comptent.
Les conditions sont réinitialisées à chaque round. `LA TOTALE` est aussi vérifié
au chargement de la progression pour les sauvegardes déjà complètes.

Chaque fichier de `resources/data/palettes/` décrit une palette de dix couleurs
modifiables dans l'inspecteur. `ColorPaletteRegistry` charge les entrées
activées de `resources/data/palettes.tres`, triées par difficulté de déblocage. La page Fonts
présente les polices et les palettes comme les autres listes de progression,
dans deux rangées verticales possédant chacune son propre défilement. Elle
permet de sélectionner séparément la police et la palette ; la palette choisie
est sauvegardée dans `settings/selected_palette`, prévisualisée sur neuf tuiles
et appliquée aux cartes, aux piles et aux jokers.
La police et la palette actives restent cochées : pour les remplacer, il faut
choisir une autre entrée débloquée dans la même catégorie.
`ThemeManager` dérive aussi un thème global depuis la palette sélectionnée :
couleur de fond, teintes secondaires de shader, accent UI et échantillons de
boutons. La liste des palettes affiche donc les dix couleurs de tuiles ainsi
qu'une miniature du bouton et du fond associés. Les anciennes sauvegardes
restent compatibles : en l'absence de palette sélectionnée, la palette de base
déverrouillée est utilisée.
Le sélecteur `LOCKED / BOTH / UNLOCKED` filtre immédiatement la liste de la page
courante et revient sur `BOTH` à l'ouverture du menu.
Les changements de page des menus Progression et Options utilisent un court
glissement directionnel avec fondu ; les pages suivantes arrivent de la droite
et les pages précédentes de la gauche.
La mise en page reste contenue dans la fenêtre logique minimale de 256×320 et
les listes longues défilent dans leur zone dédiée.
Les boutons illustrés utilisent tous `TextureHighlightButton.gd` et le shader
de surbrillance bleu commun au reste de l'interface.
La page `SPECIAL RULES` affiche une courte description fonctionnelle de chaque
règle découverte, distincte du texte d'ambiance utilisé pendant son annonce.
Les champs encore inconnus des bonus et règles affichent `???`. Une entrée
rencontrée mais non obtenue ou non battue révèle son nom en semi-transparence,
affiche `???` à la place de sa description et n'affiche ni coche ni niveau.
Les titres associés aux pastilles utilisent `Entry Heading Text Offset`, réglé
par défaut à `(2, 2)`, afin de corriger leur centrage optique vers le bas et la
droite sans déplacer les icônes.
Les bonus obtenus sur plusieurs niveaux inscrivent leur meilleur niveau
dans le carré ; le carré devient doré au niveau maximal. Les états binaires
utilisent les sprites `ui/check/checked.png` et `ui/check/unchecked.png`.
Les achievements permanents sont décrits individuellement dans
`resources/data/achievements/`. `AchievementRegistry` charge les entrées
activées de `resources/data/achievements.tres`, regroupées par catégorie puis
triées par `difficulty` croissante. Ils sont évalués uniquement
sur les événements de jeu concernés et regroupés sous `STATS`, `ROUNDS`,
`CHECKPOINTS`, `ENDLESS`, `BONUSES & RULES`, `COMBOS`, `SPEEDRUN`, `CHALLENGES`
et `PROGRESSION`. La difficulté interne va de 1 (initiation) à 10 (collection
complète), sans être affichée au joueur. `ProgressionOrdering` applique aussi
ce classement aux polices, palettes et challenges d'après leur achievement
requis, avec les éléments disponibles par défaut en tête et l'ID pour départager
les égalités. Chaque catégorie garde son ordre de première apparition dans le
catalogue. Les 48 achievements actifs ont chacun une récompense distincte parmi
20 polices, 22 palettes et 6 challenges verrouillés ; la police et la palette
`CLASSIC` restent disponibles par défaut sans prérequis. `reward_rationale`
documente les associations dans l'export. Les acquis des anciennes sauvegardes
sont conservés, et les nouvelles associations sont appliquées au chargement.
`NO LOOKING BACK` et son achievement de complétion restent hors des catalogues
actifs ; ils ne bloquent donc plus `LA TOTALE`. Les
seuils modifiables sont stockés dans chaque ressource via `required_count` et,
pour les speedruns, `time_limit_seconds` exprimé en secondes. Les objectifs sont
strictement moins de **5 minutes pour 10 rounds**, **20 minutes pour 20 rounds**
et **45 minutes pour les 30 rounds** d'une partie normale commencée au début.
Le chrono compte le temps actif, animations de jeu comprises ; les transitions
entre rounds, les choix de bonus et les pauses en sont exclus. L'équilibrage
et les limites du joueur automatisé sont détaillés dans
[`tests/speedrun_balance.md`](tests/speedrun_balance.md).
Le succès
`FIRST STEP` se débloque après le premier round terminé. `BARE HANDS` exige
20 rounds d'une run normale sans bonus et `NO FRILLS` exige de terminer cette
run entière sans bonus.
Les achievements cumulatifs affichent leur complétion avec le sprite et le shader
des barres de volume. Leur détail numérique apparaît au survol de la barre,
tient sur plusieurs lignes si nécessaire et les embouts restent intacts grâce
à un découpage nine-patch horizontal de 2 pixels. Les barres de progression,
légèrement raccourcies à 80 pixels, et les barres de volume partagent ce même
découpage. Les succès cachés restent anonymes jusqu'à leur déblocage. Les règles simplement
rencontrées restent distinctes des règles battues, sauvegardées dans
`progression/beaten_special_rules`. `MAXIMUM BUILD` mémorise dans
`progression/bonuses_maxed_once` chaque bonus ayant atteint son niveau maximal
au moins une fois, puis exige tous les bonus actuellement activés. Les meilleurs
niveaux permanents sont affichés directement dans le carré pour les bonus
possédant plusieurs niveaux. La section `Bonus Level Style` de
`ProgressionMenu` expose séparément la police et la taille de ces numéros, y
compris dans les carrés dorés des niveaux maximaux. Leur texte est blanc et la
propriété `Bonus Level Text Offset` permet d'ajuster finement son centrage. Un
niveau sauvegardé à `0` est toujours traité comme non obtenu : carré bleu vide,
titre semi-transparent s'il a été vu et description remplacée par `???`.
Sur l'écran principal, l'icône `options.png`, placée à côté de l'icône des
statistiques, ouvre le menu `OPTIONS`. Les réglages `MUSIC` et `SOUND` y
reprennent les curseurs, le shader et la sauvegarde audio existants. Comme dans
le menu de progression, le titre reste en haut à gauche et le bouton illustré
Échap en haut à droite referme l'écran. L'icône classique `options.png`, puis
les icônes `sounds.png`, `graphics.png`, `saves.png` et `links.png` forment la
navigation verticale des catégories `GAMEPLAY`, `SOUND`, `GRAPHICS`,
`SAVE DATA` et `LINKS`, comme
dans le menu de progression. La section `SAVE DATA` permet d'exporter
la configuration complète en JSON, d'importer un export validé ou de supprimer
la sauvegarde après confirmation. Un import ou une suppression recharge la
scène afin de synchroniser immédiatement tout l'état en mémoire.

Les sous-menus Options, Progression, Challenges et Checkpoints entrent depuis
la droite par un swipe vers la gauche. Leur bouton retour ou la touche Échap
joue le mouvement inverse avant de rendre l'accueil interactif. La durée commune
est réglable avec `submenu_swipe_duration` sur `GameManager`.

Les boutons textuels illustrés héritent de
`resources/scenes/ui/RegionButton.tscn`. La section `Stretchable Texture` de sa
racine expose la texture, `Region Rect`, les quatre `Patch Margins` nine-slice
et les marges du contenu. Modifier ces valeurs dans la scène parente propage le
découpage aux boutons Play, Endless, Checkpoint, Replay, Quit et aux choix de
bonus ; une scène enfant peut toujours les surcharger dans son inspecteur.

La page `GAMEPLAY` permet de désactiver séparément les notifications
d'achievements et le chronomètre global de la partie. Cette option ne masque
jamais l'horloge ni la valeur du compte à rebours du round. Une notification
active s'affiche sans panneau de fond, avec l'icône achievement à gauche et le
nom obtenu à droite, accompagnée d'un court son ascendant ; plusieurs
achievements simultanés sont présentés successivement. Ces popups attendent la
fin des annonces de règles, checkpoints, changements de difficulté et choix de
bonus, ainsi que la vague de fin de round. Une popup dont l'animation a déjà
commencé n'est jamais masquée ou relancée : elle se termine normalement, tandis
que les suivantes restent en file. Leur position est recalculée sous les timers visibles avec une marge de
8 pixels, y compris lorsque la résolution adaptative modifie la zone logique.
Les choix sont appliqués
immédiatement et sauvegardés dans `gameplay/achievement_notifications` et
`gameplay/show_timer`. Le chronomètre global est masqué par défaut ; un choix
déjà sauvegardé reste prioritaire. Le compte à rebours de chaque tour reste affiché.

L'écran de fin de partie affiche les checkpoints débloqués, bonus découverts,
règles rencontrées et achievements obtenus pendant la partie sans titre
supplémentaire. Les checkpoints, bonus, règles et achievements sont précédés
de leurs icônes respectives (sauvegarde, bonus, règle et trophée) ;
plusieurs éléments d'une même catégorie sont séparés par `+`. Le récapitulatif
préfixe chaque ligne par `+`, sans libellé `NEW`. Il est placé sous la popup et
le titre `HIGHSCORE` au-dessus. La position du
panneau tient compte de la hauteur réelle de ces deux blocs pour centrer leur
ensemble, et sa hauteur minimale de 230 pixels laisse les marges nécessaires :
le titre et le récapitulatif restent attachés à la popup sans rejoindre les
bords supérieur et inférieur.
L'écran est défini par la scène partagée `resources/scenes/ui/EndScreen.tscn`.
Sa propriété `Layout > Result Gap` règle l'espace commun au-dessus et sous la
popup. À zéro, les trois éléments du même conteneur se touchent. Les options
`Editor Preview` permettent d'afficher ou masquer le highscore et les nouvelles
progressions directement dans l'éditeur.
La compensation des marges visuelles internes de la police et de la texture est
appliquée par la scène elle-même : aucune valeur négative n'est nécessaire et
la prévisualisation utilise exactement le même calcul que l'instance du jeu.
Les catégories sans nouveauté sont omises.
Quand tous les rounds d'un mode fini sont terminés, l'écran affiche `YOU WIN !`
pour les runs Classic, Checkpoint et Challenge non-Endless ; il n'affiche jamais
`0 ROUNDS LEFT` comme résultat d'une victoire. Les écrans de victoire et de mort
terminent immédiatement le gameplay : timers, convoyeur, mains en attente,
timeouts différés et victoires debug mises en file sont tous invalidés avant
l'affichage du résultat.

Ces nouveautés ajoutent `notification.png` au bouton Progression du menu
principal et à l'onglet concerné (`ACHIEVEMENTS`, `BONUSES` ou `SPECIAL RULES`).
Les highscores ne produisent jamais de notification. Cliquer sur l'icône d'un
onglet acquitte cette catégorie ; le
badge principal disparaît lorsque toutes les catégories ont été consultées.
Dans `resources/scenes/progression/ProgressionMenu.tscn`, `StatsNotification` est le modèle éditable du
placement. Le bouton d'inspecteur `Copy Notification Placement` recopie sa
position et sa taille sur les badges des autres onglets.

La page `LINKS` ouvre les profils externes dans le navigateur du système :
`ITCH.IO` mène à `https://juel-s.itch.io/` et `KO-FI` à
`https://ko-fi.com/juels`. Seules les adresses HTTPS codées dans le jeu sont
acceptées par le gestionnaire de liens.
Les sélecteurs d'import et d'export utilisent les dialogues natifs du système
pour ne pas dépasser la fenêtre logique du jeu ; la confirmation de suppression
utilise le sprite de popup et la police du jeu, avec les boutons `CANCEL` et
`DELETE`. `CANCEL` reçoit le focus à l'ouverture ; le texte se replie
automatiquement pour rester lisible.
Par défaut, le jeu démarre en HD (`TRUE PIXEL ART` désactivé) et en mode
`SEMI ADAPTIVE`. Les préférences graphiques déjà sauvegardées sont conservées.
La page `GRAPHICS` utilise une référence logique 256×320 afin que le zoom et
la taille des sprites ne changent pas. Le sélecteur de taille propose
`CLASSIC`, `SEMI ADAPTIVE` et `ADAPTIVE`. Le choix est sauvegardé dans
`graphics/screen_size_mode` et appliqué immédiatement ; les anciennes valeurs
`graphics/adaptive_resolution` restent prises en charge. `TRUE PIXEL ART`,
sauvegardé dans `graphics/true_pixel_art`, active le stretch viewport basse
résolution : tout le jeu est rendu à l'échelle des sprites et des polices avant
d'être agrandi. Lorsqu'il est désactivé, le jeu revient au mode canvas haute
résolution et les fonds ne sont plus pixellisés. Dans la sous-rubrique
`BACKGROUND`, `BACKGROUND DEFORMATION` active uniquement la déformation et
conserve les bandes lorsqu'elle est désactivée. Le choix reste sauvegardé dans
`graphics/dust_effects`. `SHOW BACKGROUND`, sauvegardé dans
`graphics/background_enabled`, est l'option parente et permet de masquer
entièrement le fond généré. Sa sous-option indentée `BACKGROUND DEFORMATION`
n'est affichée que lorsque le fond est actif.
Les fonds principaux sont des presets procéduraux pilotés par shader via
`BackgroundManager` et `BackgroundLayer`. La run démarre avec un fond choisi par
le stream cosmétique du seed, puis chaque annonce `TIER RELIEF` choisit un
nouveau preset en évitant fortement la répétition immédiate. La transition dure
`BG_TRANSITION_DURATION` et peut être skippée avec l'annonce ; le skip place le
nouveau fond dans son état final. La série de presets contient `stripes`,
`grid`, `dots`, `waves`, `diamonds`, `brick`, `checkered` et `circles`. Les
shaders reçoivent les couleurs de `BackgroundThemeCatalog`, donc changer les
données partagées du catalogue modifie aussi tous les fonds.
Les motifs sont calculés en pixels logiques du viewport avec une référence fixe
256×320 : le fond couvre toujours toute la fenêtre, mais une fenêtre plus large
ajoute du motif au lieu d'étirer ou d'incliner celui déjà visible. Le mode HD
conserve ainsi la même échelle de bandes, grilles, points et vagues que le mode
true pixel-art.
Chaque preset possède une entrée de catalogue et un material dans
`resources/materials/backgrounds/`. Les réglages communs (`viewport_size`,
`reference_size`, couleurs, intensité et pixellisation) viennent des données du
catalogue, tandis que les réglages de forme et la vitesse vectorielle restent
locaux au material concerné. Ces réglages communs sont envoyés aux shaders via
les Shader Globals `background_*`, déclarés dans `project.godot`, afin de ne pas
apparaître comme paramètres éditables sur chaque material. `diamonds` réutilise
le shader de grille avec une rotation différente, `brick` utilise le décalage
alterné des lignes, `checkered` expose une largeur, une longueur et une forme
de pavage (`Rectangle`, `Triangle` ou `Diamond`), et `circles` réutilise le
shader de points avec un rayon intérieur.
Le pool léger de poussière volatile est réparti dans tout le viewport. Les cartes la
repoussent localement à leur passage et les piles mobiles appliquent une
impulsion réduite. La souris produit elle aussi une impulsion discrète, bien
plus faible que celle d'une tile. Les complétions de piles propagent une onde
radiale dans la poussière. La quantité se règle désormais comme une densité
avec `Visual Effects > Dust Particles Per 10000 Pixels`, ce qui conserve la
même concentration sur les petits écrans et les viewports adaptatifs wide.
`Dust Viscosity` règle la force amortie qui ramène chaque particule vers sa
position d'origine après le passage d'une tile (2,2 par défaut). En résolution
adaptative, les ancres sont remises à l'échelle pour couvrir tout le viewport.
La simulation de poussière reste active pour fournir son champ d'impulsion,
mais ses particules ne sont actuellement pas dessinées.
Le fond utilise deux passes distinctes sans `CanvasGroup` imbriqués :
`StripeBackground.gdshader`, appliqué à `BackgroundArt`, génère les bandes ;
`BackgroundCopy` capture ce rendu avec un `BackBufferCopy`, puis
`DeformableBackground.gdshader`, appliqué au `DeformationOverlay`, échantillonne
la capture via `hint_screen_texture` et la déforme. L'échantillonnage emploie
les UV locaux du rectangle plein écran afin de rester aligné en mode adaptatif
et dans le viewport de jeu intégré à l'éditeur. `BackgroundArt` est un
`ColorRect` plein écran plutôt qu'une texture de taille
fixe. Sa couleur uniforme se règle avec `background_color` dans le matériau des
bandes. Dans `Game.tscn`, `Artwork` utilise aussi des ancres plein écran afin
que les bandes occupent immédiatement le cadre 256×320 dans l'aperçu 2D de
l'éditeur, sans attendre l'exécution du script. Le gameplay reste volontairement centré en 256×320 par `GameCenter`,
mais le contrôleur détache le rectangle `Artwork` de ce parent : il place son
origine globale en `(0, 0)` et lui attribue la taille réelle du viewport à
chaque redimensionnement. Le fond et le post-traitement couvrent ainsi tous les
ratios adaptatifs sans étirer la disposition du gameplay.
Les deux passes partagent un filtre de pixellisation en espace écran. Le réglage
`Pixel Filter > Background Pixel Size` du nœud `Artwork` fixe la taille commune
des blocs (2 pixels par défaut) pour les bandes et leur déformation. Cette
quantification dans les shaders évite un `SubViewport`, dont la texture aurait
compliqué l'alignement du back-buffer en résolution adaptative.
`Editor Preview > Editor Background Preview High Resolution` désactive cette
pixellisation sur les presets procéduraux pour inspecter le fond en haute
résolution dans l'éditeur. En jeu, `TRUE PIXEL ART` laisse cette pixellisation
active et force le rendu viewport low-res ; quand l'option est coupée, le
contrôleur garde le layout adaptatif mais rend le fond en haute résolution.
`PilesBoard` conserve de son côté une taille fixe de 164×163 et utilise des
ancres centrales. Les positions locales des piles ne sont jamais recalculées
pendant un round ; lors d'un redimensionnement, seul le plateau complet suit le
centre horizontal du viewport.
Le shader de bandes calcule son motif dans un espace pixel de référence 256×320,
à partir des uniforms `viewport_size` et `reference_size`. Un élargissement
horizontal ajoute donc des bandes de même largeur au lieu d'étirer le motif
existant ; les changements proportionnels conservent également le rendu.
Un tableau circulaire de huit impulsions transmet au GPU
les passages des cartes et de la souris ainsi que les ondes de complétion. Les
impulsions s'estompent progressivement sans reconstruire de géométrie côté CPU.
Une complétion se propage sous forme d'un anneau de déformation à largeur
constante. Son rayon maximal et sa durée sont calculés depuis la distance au coin
le plus éloigné du viewport ; l'anneau conserve son intensité jusqu'à ce que son
bord extérieur ait dépassé ce coin, puis fond pendant sa courte durée de queue.
`Background Deformation Speed` règle la vitesse globale de ces animations entre
0,1 et 2,0 (0,6 par défaut) sans modifier leur amplitude ; `1,0` correspond à
la vitesse d'origine. Ce réglage reste côté contrôleur, car il fait progresser
la durée de vie et le rayon des impulsions avant leur envoi au shader.
Les deux `ShaderMaterial` sont enregistrés dans `resources/materials/` et
assignés à `BackgroundArt` et `DeformationOverlay` dans `Game.tscn`. Les bandes sont donc
visibles dans l'aperçu 2D de l'éditeur et leurs uniforms restent accessibles en
ouvrant les matériaux depuis l'inspecteur. Le shader de bandes expose `stripe_color`,
`stripe_count`, `stripe_slope`, `stripe_core` et `stripe_softness`. Le shader de
déformation expose `wave_inner_width` et `wave_outer_width`.
Le script du nœud `Artwork` expose en plus dans l'inspecteur les groupes
`Deformation Timing` et `Deformation Shape`. `Stripe Scroll Speed` se règle
uniquement dans `StripeBackgroundMaterial.tres` : `0` arrête les bandes et une
valeur négative inverse leur direction. Le contrôleur ne remplace jamais cette
valeur au lancement, donc l'aperçu de l'éditeur et le jeu utilisent exactement
le même réglage. Les autres groupes règlent vitesse, durées, rayons et forces
qui alimentent les uniforms dynamiques.
Le rayon final d'une onde n'est pas configurable : il est calculé depuis son
origine jusqu'au coin le plus éloigné du viewport, marge du shader comprise.
Les impulsions de mouvement ne peuvent pas évincer une onde encore active.
Chaque carte et pile visible transmet son centre, sa taille et ses coins arrondis
au shader du fond. La zone sous la tuile reste stable et les bandes se courbent
autour de son contour comme une toile tendue sous une pierre, sans ombre ni
assombrissement ; le poids apparent augmente pendant un drag. Les réglages `Tile Weight Radius`,
`Tile Weight Strength`, `Pile Weight Multiplier`, `Card Weight Multiplier` et
`Dragged Weight Multiplier` sont exposés sur `Artwork` dans l'inspecteur. Les
piles pèsent davantage que les cartes de la main ; leur poids apparaît pendant
l'entrée et retombe progressivement à zéro pendant la dissolution de fin.
Dans l'éditeur, `Editor Preview > Show Pile Weight Preview` sur `Artwork`
affiche une pile de démonstration au centre du fond. Elle réagit immédiatement
aux réglages de masse de ce nœud. Son nœud et ses uniforms sont supprimés au
démarrage du jeu. Chaque carte ajoutée à une pile émet aussi une petite onde
qui disparaît rapidement ; sa durée, sa vitesse et sa force se règlent dans
`Tile Impact Wave` sur `Artwork`.
Lorsqu'une pile atteint zéro, son matériau échantillonne le fond déjà rendu :
la tuile se contracte, courbe les bandes dans sa silhouette puis se dissout
dans celles-ci. L'onde émise au même centre prolonge ensuite la transition dans
le reste du viewport.
Toutes les textures raster utilisées par le rendu du jeu (tuiles, main, vies,
boutons, cases, icônes, notifications et panneaux) sont exposées comme des
`CanvasTexture` dans `resources/materials/`. Leurs normal maps correspondantes,
aux mêmes dimensions que les sprites diffus, sont regroupées sous
`resources/normals/`. Les maps dérivées encodent les pentes X/Y d'un champ de
hauteur construit depuis la transparence et la luminance du pixel art, avec un
canal Z reconstruit ; elles ne sont donc pas de simples aplats. Une lumière
directionnelle uniforme accentue leur relief
sans éclaircir localement le fond, tandis qu'une lumière locale très légère suit
la souris sur les tuiles et icônes principales. En mode debug, `V` renforce ou
rétablit temporairement ces deux lumières pour inspecter clairement le relief.
La page `GRAPHICS` regroupe `BACKGROUND DEFORMATION` et `SHOW BACKGROUND` dans
la même sous-rubrique `BACKGROUND`. Quand la déformation est inactive, les
bandes restent visibles et l'onde `RoundWave` du gameplay remplace l'onde du
shader. Les piles terminées reprennent alors leur ancienne animation de montée
et disparition ; la dissolution dans les bandes est réservée au fond déformé.
Le relief lumineux et son option `3D LIGHTING` sont
temporairement désactivés ; les nœuds, normal maps et matériaux sont conservés
pour une réactivation ultérieure. L'ancien champ de sauvegarde
`graphics/lighting_effects` est ignoré.
`Dust Particle Color`, `Dust Mouse Influence`, `Dust Dragged Tile Influence`,
`Dust Automatic Tile Influence` et `Dust Completion Wave Influence` permettent
d'ajuster séparément la couleur et chaque interaction depuis l'inspecteur.
`SHOW_DUST_DEBUG` dans `debug.gd` affiche son repère de
diagnostic. `FORCE_BACKGROUND_ID`, `FORCE_THEME_PALETTE`,
`DISABLE_SHADER_BACKGROUNDS` et `DISABLE_BG_MORPH_TRANSITION` permettent de
tester rapidement les fonds, les thèmes et leurs fallbacks. Comme les choix de
police et de palette, les options à
sélection unique affichent le carré `selected` pour la valeur active et le
carré `unchecked` pour les autres valeurs. Leur couleur reste inchangée ; seule
la surbrillance commune aux boutons apparaît au survol. Ces choix sont affichés
comme une liste de progression alignée en haut de page, sans panneau ni
encadrement persistant autour de la valeur active.
Les pages `SOUND` et `SAVE DATA` utilisent la même présentation en liste : les
volumes occupent deux lignes sous le titre `VOLUME`, tandis qu'export, import et
suppression forment trois actions verticales plates avec highlight au survol.
Les libellés `MUSIC` et `SOUNDS` partagent une colonne fixe de 72 pixels afin
que leurs deux barres commencent au même emplacement et gardent la même largeur.
Les libellés des choix et des actions restent sombres au repos, puis prennent
le bleu actif au survol, à la pression ou lorsqu'ils reçoivent le focus clavier.
Ce comportement s'applique notamment aux actions `SAVE DATA` et `LINKS`.
En affichage adaptatif, le fond de la main utilise un découpage nine-patch qui
préserve ses extrémités sur 18 pixels pendant que seul son centre s'étire. Le
bouton Échap du gameplay est ancré au bord supérieur droit et suit donc la
largeur réelle du viewport étendu.
La propriété `Editor Display > Start Adaptive In Editor` du nœud `Game` force
le mode adaptatif dès un lancement depuis l'éditeur. Elle est activée dans la
scène principale et n'affecte ni les builds exportés ni la préférence graphique
sauvegardée du joueur.
Dans le menu de progression, la navigation de catégories occupe une colonne
compacte de 30 pixels près du bord gauche. Les listes réservent une marge de
10 pixels devant leur barre de défilement afin que textes et indicateurs de
progression ne passent jamais sous celle-ci.
Chaque choix de police affiche son nom avec la police correspondante. Le titre
de chaque palette débloquée alterne ses caractères entre toutes les couleurs de
la palette afin de la reconnaître directement dans la liste. Une palette
verrouillée conserve le titre `???`, dont les trois caractères utilisent ses
trois premières couleurs sans révéler son nom. Les noms de
polices et de palettes reviennent automatiquement à la ligne et agrandissent
leur entrée lorsqu'ils dépassent la largeur disponible.
Le catalogue actif contient uniquement les ressources de `enabled_data` dans
`palettes.tres`, sans doublon. `CLASSIC` est disponible par défaut ; les 22 autres
palettes correspondent chacune à un achievement distinct. `DEBLOCAGES.md`
répertorie les associations actuelles. Chaque palette contient dix teintes distinctes
indexées de `0` à `9`. Les palettes verrouillées sont accordées par leurs
achievements associés et enregistrées dans `progression/unlocked_palettes`.
La règle `COLORBLIND` ne modifie jamais la palette sélectionnée : elle remplace
seulement son rendu par les teintes grises pendant le round concerné, puis la
palette choisie réapparaît automatiquement au round suivant.

`resources/scenes/progression/ProgressionMenu.tscn` reste masqué par défaut dans l'éditeur. Pour afficher son
aperçu ponctuellement, activer `Menu Editor Preview/Show Editor Preview` sur sa
racine, puis `Editor Preview/Enabled` sur `FontCatalog`. `Editor Preview/Page`
permet d'afficher chacune des cinq pages. `Editor Preview Font` et
`Editor Preview Palette` permettent de choisir indépendamment la police et la
palette appliquées aux tuiles de démonstration, sans modifier la sauvegarde ni
la sélection du joueur. La section `Entry Style` expose les polices
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
- `P` affiche ou masque en direct les probabilités de difficulté du round ;
- `R` réinitialise immédiatement la partie avec les valeurs de départ ;
- `H` efface le high score sauvegardé.

Dans `resources/scripts/settings/debug.gd`, `UNLOCK_ENDLESS_MODE` permet d'afficher
le mode infini sans avoir préalablement terminé le jeu lorsque le debug est
activé.

## Challenge Runs

L'icône Challenges placée à gauche des boutons Options et Progression ouvre les
ressources `.tres` du dossier `resources/data/challenges/`, activées et ordonnées
par `resources/data/challenges.tres`. Chaque carte indique son
achievement de déblocage, ses rounds `start_round` et `target_round`, son
meilleur round et, après réussite, son accès Endless. Les résultats sont
sauvegardés séparément dans la section `challenges` de `pile_down.cfg` et ne
modifient aucun highscore Classic, Checkpoint ou Endless classique.

Chaque ressource `ChallengeData` est modifiable dans l'inspecteur. Elle expose
le titre, la description, l'achievement requis, les rounds de départ et cible,
l'accès Endless, ainsi que les modificateurs suivants : garantie d'une main
jouable, vie unique, désactivation des bonus de vie, physique Pool Party et
masquage des valeurs. Les listes de bonus et règles forcés ou désactivés sont
également stockées dans la ressource. `forced_bonuses` associe chaque identifiant
de bonus à son niveau initial (par exemple `{&"redraw": 2}`), tandis que
`forced_rules` contient les identifiants des règles actives dès le départ.
`disabled_bonuses` et `disabled_rules` les bannissent de toute la partie.
`disable_special_rules_on_first_round`, activé par défaut, neutralise toutes
les règles spéciales pendant le premier round du challenge, y compris les
règles forcées. Le désactiver permet aux règles de s'appliquer immédiatement.

La catégorie `Starting Difficulty` permet aussi de fixer directement
`starting_pile_count`, `starting_hand_size`, `starting_card_value` et
`starting_turn_time`. La valeur `-1` conserve pour la statistique concernée la
difficulté simulée depuis `start_round`; toute autre valeur la surcharge après
cette simulation. Ajouter un challenge consiste à créer un
nouveau `.tres` dans `resources/data/challenges/`, puis à l'ajouter à
`resources/data/challenges.tres` à la position voulue.

Les challenges réutilisent la simulation de difficulté des checkpoints sans
accorder les bonus des rounds précédents. `RELOAD REQUIRED` retire la garantie
de main jouable et fournit un reload illimité. Le chrono est suspendu pendant
le remplacement de la main et conserve son temps restant. S'il reste moins
d'une seconde, le reload lui ajoute `reload_low_time_bonus` secondes (2 par
défaut), puis le chrono reprend sans être réinitialisé. Sa toute
première main est toujours injouable afin de présenter cette mécanique ; les
mains suivantes retrouvent immédiatement le tirage habituel. `ONE SHOT`
impose une vie et exclut les protections ; `POOL PARTY` active son contexte de
physique et ses exclusions ; `TRUE COLORS` masque les valeurs tout en conservant
les couleurs et le symbole des jokers.

Le highscore standard de chaque challenge fonctionne comme celui du mode
Classic : il compare d'abord le nombre de rounds restant avant `target_round`,
puis le temps lorsque deux runs atteignent la même progression. La popup et le
menu affichent ces deux valeurs. Les versions Endless conservent leur highscore
en round atteint.

Quatre variantes supplémentaires sont chargées par le même registre :

- `SHARED CLOCK` remplace les timers de main par un budget commun au round,
  affiché en secondes seules. Le nombre exact de tuiles à poser est
  `pile_count * start_value`; le nombre de mains estimé est son quotient par la
  taille de main, arrondi au supérieur. `shared_clock_seconds_per_hand` règle
  dans chaque `ChallengeData` le temps accordé par main estimée ; `-1` utilise
  le timer normal courant.
  Son expiration termine immédiatement la run, quelles que soient les vies ou
  protections restantes. Les bonus `TIME BANK` et `WARM-UP` alimentent
  directement ce budget. Une erreur suspend le décompte jusqu'à la fin de son
  animation complète, mais la main est déverrouillée pendant le feedback afin
  de permettre immédiatement un nouveau drag. Utiliser `REDRAW` ajoute
  `SHARED_CLOCK_RELOAD_TIME_BONUS` (3 secondes par défaut) au timer global.
- `BOSS RUSH` demande des règles à chaque round. Leur nombre suit
  `BOSS_RUSH_RULE_PROGRESSION`, puis reste à `MAX_COMBINED_RULES` en Endless,
  sans contourner les incompatibilités ni `RULE BREAKER`.
- `NO LOOKING BACK` masque une carte dès son drag et conserve son engagement
  après un relâchement dans le vide. Un retour forcé Hot Potatoes ou Lava annule
  cet engagement. `BLIND DELIVERY` et `STICKY FINGERS` y sont exclus.
- `CONVEYOR BELT` remplace la main par un flux horizontal dont la direction est
  fixée de droite à gauche : les cartes entrent directement dans le tray depuis
  une position entièrement hors écran à droite, puis tournent avant les vies
  au niveau de la branche gauche du tapis et sortent par le bas. Le point de
  virage et son aperçu sont configurables sur le nœud `HandTray` dans l'éditeur.
  Les slots conservent un petit espace de quatre pixels. Lorsqu'une carte est
  prise, une nouvelle tuile reprend immédiatement sa position afin qu'aucun
  slot vide ne traverse le tapis. La vitesse de descente reste identique afin
  de conserver la même cadence dans la branche. Chaque tirage non garanti possède aussi
  `CONVEYOR_HIGH_TILE_CHANCE` de produire une valeur supérieure à la valeur de
  départ, sans dépasser `MAX_CARD_VALUE`. Le tray utilise
  `resources/sprites/hand/conveyer.png`, étiré en NinePatch jusqu'au bord droit.
  Leur trajectoire verticale suit le
  centre de sa surface visible via `CONVEYOR_CARD_VERTICAL_OFFSET`. Les spawns
  conservent leur reliquat de distance et ne sont pas limités par un plafond de
  cartes visibles, afin que le flux reste continu sans pause.
  Les cartes sorties disparaissent sans erreur. Tant qu'aucune solution n'est
  visible, le prochain spawn est obligatoirement jouable. La limite de tirages
  morts reste réglée par `CONVEYOR_MAX_UNPLAYABLE_SPAWNS`. La vitesse plafonne à
  `CONVEYOR_MAX_SPEED` et sa base est configurable par `conveyor_speed` dans le
  challenge. Un dépôt incorrect applique l'erreur normale, puis éjecte la carte
  avec une animation au lieu de la réinsérer. `REDRAW` et `FREE-RANGE CARDS`
  sont exclus.

Les réglages de ces modes sont centralisés dans
`resources/scripts/settings/difficulty.gd`. Leurs achievements de déblocage et
de completion sont des ressources ordinaires de `resources/data/achievements/`.
Chaque challenge actif possède un achievement obtenu en terminant son parcours
normal : `LOCK AND RELOAD` (Reload Required), `ONE AND DONE` (One Shot),
`COLOR ME VICTORIOUS` (True Colors), `AGAINST THE CLOCK` (Shared Clock),
`EXPRESS DELIVERY` (Conveyor Belt) et `BOSS SLAYER` (Boss Rush).
Une défaite ou une run Endless ne valide pas ces achievements de complétion.
`CHALLENGE ACCEPTED` parcourt dynamiquement toutes les définitions chargées par
`ChallengeRegistry`.

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
    &"pixelated",
    &"floor_is_lava",
]

const FIRST_SPECIAL_RULE_ROUND := 4
const EXTRA_SPECIAL_RULE_CHANCE := 0.75
const MAX_COMBINED_RULES := 5
const LIGHTS_OUT_RADIUS := 60.0
const PIXELATION_PIXEL_SIZE := 4.0
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
- `PEEK-A-CARD` : cartes cachées révélées au survol ou au premier toucher. Sur
  écran tactile, un premier contact passe la carte de `IDLE` à `REVEALED`. Le
  même doigt peut ensuite déclencher `DRAGGING`, sans second tap, après 0,12 s
  et 8 pixels de déplacement. Un simple tap garde la face visible 0,35 s avant
  de la masquer. Avec `BLIND DELIVERY`, la face reste encore visible 0,18 s au
  début du drag, puis se retourne pendant le transport ;
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
- `PIXELATED` : toute la zone de jeu est regroupée en blocs dont la taille se
  règle avec `PIXELATION_PIXEL_SIZE`. Les blocs grandissent progressivement à
  l'activation puis retrouvent doucement leur taille normale en fin de round.
  La fenêtre de sortie reste rendue au-dessus du filtre et demeure nette ;
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
pool. Le bouton `SKIP`, en bas à droite, permet de refuser le choix sans obtenir
de bonus ; pour une réserve Checkpoint, ce refus consomme bien un choix dû. Les
constantes de fréquence, de nombre de choix et de types actifs se
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
les choix de bonus dus avant ce round alimentent la réserve distribuée aux fins
de rounds suivantes. Un départ inférieur ou égal à `TOTAL_ROUNDS` conserve le compteur visuel
descendant et un highscore partagé en rounds restants. Un checkpoint situé
au-delà de `TOTAL_ROUNDS` continue comme Endless et utilise un highscore partagé
en round atteint. Aucun classement checkpoint n'utilise le temps.

Une run Checkpoint commence avec une sélection de bonus vierge et sans empiler
au lancement tous les choix dus aux rounds sautés. Ces choix forment une réserve
et un seul choix supplémentaire est proposé après chaque round gagné jusqu'à
épuisement de la réserve. Les choix gagnés normalement tous les
`BONUS_INTERVAL` rounds restent indépendants. Le replay réinitialise également
cette réserve, rétablit la main standard et applique les règles du round sans
rejouer leur annonce.

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
debug peuvent toujours contourner cette liste. Les bonus possédés sont affichés
en permanence dans des cases d'acronymes au-dessus de la main.
Le premier badge apparaît au-dessus du bord droit de la main et les suivants
remplissent la ligne vers la gauche. Le niveau est omis au niveau I puis ajouté,
après une espace, en chiffres romains à partir du niveau II. L'acronyme conserve
l'initiale de chaque mot, sans limite de longueur (`BRING A FRIEND` devient
`BAF`), tandis qu'un titre en un seul mot garde ses deux premières lettres. Six
En cas de doublon, les mots concernés sont allongés progressivement avec des
lettres minuscules (`OB` peut ainsi devenir `OpB` ou `OlB`) jusqu'à rendre
chaque acronyme unique. Six cases tiennent sur une ligne ;
la grille ajoute ensuite les lignes suivantes au-dessus de la main. Un badge
`EditorBonusBadgePreview` reste visible dans `Game.tscn` pour régler directement
son texte, sa police et son échelle depuis l'aperçu 2D. Le survol éclaircit le
badge et affiche uniquement la description dans `ActiveBonusDescription`, une
boîte repliable limitée à la moitié de la largeur de l'écran. La boîte se centre
sur le badge survolé tant qu'elle tient dans l'écran, puis se cale contre le bord
le plus proche. Son label reste visible dans l'éditeur afin d'y régler
directement sa police.
`BonusManager.gd` conserve l'état de la partie et pilote
`BonusSelection.tscn`. Les propositions, le titre, le fond, les colonnes et les
valeurs d'animation sont éditables dans cette scène, également ouverte comme
instance éditable dans `Game.tscn`. `BonusChoiceCard.tscn` contient le sprite
et le shader des boutons, tandis que `resources/scenes/bonuses/ActiveBonusBadge.tscn` définit les
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
