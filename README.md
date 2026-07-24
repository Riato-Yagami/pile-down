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

Le score final est le temps total, en secondes entières, nécessaire pour aller
du round `100` au round `0`. Le meilleur temps est sauvegardé dans
`user://pile_down.cfg`. Le timer de chaque tour n'affiche lui aussi que des
secondes entières.

Après chaque victoire, la difficulté augmente aléatoirement : nouvelle pile
(55 %), main agrandie (20 %), valeur de départ augmentée (20 %) ou temps réduit
(5 %). Une option arrivée à sa limite est retirée du tirage.

## Lancer le prototype

1. Ouvrir ce dossier dans Godot 4.
2. Lancer le projet avec **F6/F5** (la scène principale est
   `scenes/Game.tscn`).

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

Les cartes et les piles restent des contrôles 2D et utilisent les sprites
pixel-art du dossier `sprites/`. Une cible compatible reçoit un halo discret
pendant le glissement. Un dépôt invalide consomme une erreur sans révéler la
valeur attendue. La position libérée par une carte jouée reste réservée jusqu'à
la disparition de la main : les cartes restantes ne se recentrent donc pas.
Elles sont ensuite défaussées avec une sortie échelonnée, puis la nouvelle main
est piochée avec une animation d'arrivée.

## Structure

```text
pile-down/
├── scenes/
│   ├── Game3D.tscn
│   ├── Piece3D.tscn
│   ├── Pile3D.tscn
│   ├── Game.tscn
│   ├── Card.tscn
│   └── Pile.tscn
├── scripts/
│   ├── Game3DManager.gd
│   ├── Piece3D.gd
│   ├── Pile3D.gd
│   ├── GameManager.gd
│   ├── HandManager.gd
│   ├── TimerManager.gd
│   ├── Card.gd
│   └── Pile.gd
├── sprites/
│   ├── hand/
│   ├── tiles/
│   ├── background.png
│   ├── clock.png
│   └── round-background.png
├── font/
│   └── VCR_OSD_MONO_1.001.ttf
├── project.godot
└── README.md
```

- `scenes/Game.tscn` et `scripts/GameManager.gd` : version principale en 2D,
  interface minimaliste, rounds, erreurs, drag-and-drop et progression.
- `scenes/Game3D.tscn` et `scripts/Game3DManager.gd` : prototype 3D conservé
  comme variante expérimentale.
- `scenes/Piece3D.tscn` et `scripts/Piece3D.gd` : tuile volumique, collision,
  sélection, déplacement et retournement.
- `scenes/Pile3D.tscn` et `scripts/Pile3D.gd` : emplacement fixe et empilement
  spatial des tuiles.
- `scripts/PileLayoutManager.gd` : dispositions compactes et stables des piles.
- `scripts/SoftAudio.gd` : retours sonores doux générés sans ressource externe.
- `scripts/RoundedTileMesh.gd` : maillages arrondis générés pour les pièces et
  le plateau de la main.
- `scripts/RoundDots.gd` : indicateurs minimalistes des erreurs restantes.
- `scenes/Card.tscn` et `scripts/Card.gd` : carte réutilisable, sélection et
  retournement, avec relief et inclinaison simulés.
- `scenes/Pile.tscn` et `scripts/Pile.gd` : état d'une pile, valeur attendue et
  animations.
- `scripts/HandManager.gd` : génération des mains avec garantie d'une carte
  jouable.
- `scripts/TimerManager.gd` : compte à rebours indépendant.

Les composants communiquent par signaux afin de rester faiblement couplés.

## Direction artistique

La version principale est rendue dans un viewport pixel-art de 256×320,
identique à la taille du fond, puis affichée en 512×640 avec un agrandissement
entier ×2 sans filtrage. Les textes, shaders et effets sont donc rasterisés à
la résolution native avant l'agrandissement. Le HUD n'affiche pendant la partie
que le temps entier, le nombre de rounds restants et les trois erreurs
disponibles. Une erreur de dépôt ou l'expiration du timer produit un signal
sonore descendant. Le fond, les cartouches du HUD, les vies et les faces des
pièces proviennent tous de `sprites/`. Un shader remplace le vert du sprite de face par la couleur
associée à la valeur de chaque carte. Les textes utilisent la police
`VCR_OSD_MONO_1.001.ttf` du dossier `font/`. Sa grille native est 12×14 :
tous les textes utilisent donc une hauteur de 14 px ou un multiple entier
(28, 42, 84 ou 98 px selon le contexte), sans transformation non uniforme des
caractères. Les sprites
restent à leur taille native hors animations. L'antialiasing, le positionnement
subpixel et le fallback système sont désactivés pour la police. Son raster
utilise un oversampling fixe de 1 et un hinting entier afin d'aligner les
contours des glyphes sur la grille avant l'agrandissement global.

Les boutons `PLAY` et `REPLAY` utilisent `sprites/button.png` à sa taille
native 86×31. L'écran final utilise `sprites/pop-up.png` à sa taille native
256×192. Les tuiles utilisent leur format natif 34×37.

Le contour de progression de `sprites/clock.png` est piloté par un shader :
les pixels-clés du cercle sont remplis dans le sens horaire selon le temps
restant. Aucun arc vectoriel n'est dessiné par-dessus le pixel-art.

Les éléments visuels principaux sont positionnables directement dans
`scenes/Game.tscn`. `TimerRing`, `RoundPanel`, `PilesBoard` et `HandTray`
peuvent être déplacés depuis l'éditeur 2D. Les trois vies sont des
`TextureRect` séparés sous `HandTray/MistakesDots` : le groupe ou chaque point
peut donc être replacé visuellement sans modifier de script.

Au lancement, un splash screen affiche `PILE DOWN` et attend une pression sur
`PLAY`. Tous les textes du jeu sont en anglais. En cas de défaite, l'écran de
score affiche le nombre de rounds restants et le temps écoulé ; une victoire
affiche `YOU WON` et la durée totale. Le format omet les heures ou les minutes
tant qu'elles ne sont pas nécessaires.

## Régler la difficulté

Tous les réglages sont centralisés dans `scripts/difficulty.gd` :

- valeurs initiales de piles, cartes, valeur de départ et timer ;
- limites maximales, ainsi que le temps minimal ;
- nombre total de rounds ;
- poids de probabilité de chaque malus ;
- poids séparés du premier malus.

Les poids sont relatifs et n'ont pas besoin de totaliser 100. Une valeur de
`0` désactive l'option correspondante. Après le premier round, le malus est
obligatoirement soit une nouvelle pile, soit une nouvelle carte en main. Les
malus de valeur et de temps ne deviennent disponibles qu'ensuite.
