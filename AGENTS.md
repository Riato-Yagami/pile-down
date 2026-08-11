# AGENTS.md

Ce fichier décrit les conventions à suivre pour toute intervention automatisée
ou manuelle dans le dépôt **Pile Down**.

## Objectif du projet

Pile Down est un prototype Godot 4 de solitaire rapide basé sur la mémoire. Le
joueur sélectionne une carte, puis une pile qui attend exactement la valeur
précédente moins un. Les valeurs posées sont ensuite masquées.

Conserver en priorité une boucle de jeu courte, lisible et immédiatement
jouable. La scène principale utilise des contrôles 2D avec des effets de relief
simulés, sans dépendance externe.

## Organisation

- `resources/scenes/` contient uniquement les scènes Godot réutilisables et la scène
  principale.
- `resources/scripts/` contient tous les scripts GDScript.
- `resources/fonts/` regroupe les polices et leurs licences.
- `resources/sprites/` regroupe les textures utilisées par le jeu.
- `resources/normals/` regroupe les normal maps utilisées pour le relief 2D.
- `project.godot` et la documentation restent à la racine.
- Les nouvelles ressources vont dans le sous-dossier approprié de `resources/`.
- Les tests automatisés éventuels vont dans `tests/`.

Lors d'un déplacement, mettre à jour toutes les références `res://`, le chemin
de la scène principale dans `project.godot` et les exemples du `README.md`.
Conserver les fichiers `.uid` associés aux scripts.

## Architecture

- `GameManager.gd` orchestre la version principale en 2D.
- `PileLayoutManager.gd` calcule les dispositions compactes et stables.
- `SoftAudio.gd` génère les retours sonores courts sans ressource externe.
- `RoundDots.gd` dessine les indicateurs d'erreur du HUD minimaliste.
- `HandManager.gd` est seul responsable de la génération et de l'affichage de
  la main.
- `TimerManager.gd` expose le temps restant par signaux.
- `Card.gd` et `Pile.gd` encapsulent leur état, leur pseudo-volume 2D, le
  drag-and-drop et leurs animations.
- Les composants communiquent par signaux. Éviter d'ajouter des recherches de
  nœuds globales ou des dépendances circulaires.

## Invariants de gameplay

Toute modification doit préserver ces règles :

- une pile de valeur `s` accepte uniquement `s - 1` ;
- chaque nouvelle main contient au moins une carte jouable ;
- les valeurs sont comprises entre `0` et `S - 1` ;
- une carte validée est révélée brièvement, puis masquée ;
- un dépôt invalide ne révèle jamais la valeur attendue ;
- les piles restantes ne changent jamais de position pendant un round ;
- le joueur dispose de trois erreurs par round ;
- `M <= 4`, `S <= 9` et `T >= 2` ;
- un round se termine uniquement lorsque toutes les piles ont atteint zéro ;
- le bouton de transition vers le round suivant conserve score et difficulté ;
- le bouton de game over démarre une nouvelle partie avec les valeurs initiales.

## Style GDScript

- Cibler Godot 4 et utiliser le typage statique lorsque le type est clair.
- Employer `snake_case` pour fonctions et variables, `PascalCase` pour les
  classes et `UPPER_SNAKE_CASE` pour les constantes.
- Préférer les petits gestionnaires spécialisés aux nouvelles responsabilités
  ajoutées à `GameManager.gd`.
- Commenter les décisions de gameplay ou d'architecture, pas les opérations
  évidentes.
- Ne pas introduire de plugin ou de ressource externe sans demande explicite.

## Validation

Après toute modification de scène, de script ou de chemin, lancer au minimum :

```sh
godot --headless --path . --editor --quit
```

Pour vérifier aussi le démarrage de la boucle de jeu :

```sh
godot --headless --path . --quit-after 240
```

Dans un environnement isolé qui interdit l'écriture dans le profil utilisateur,
rediriger les dossiers XDG vers `/tmp` :

```sh
XDG_DATA_HOME=/tmp/pile-down-data \
XDG_CONFIG_HOME=/tmp/pile-down-config \
godot --headless --path . --quit-after 240
```

Une validation réussie ne doit produire aucune erreur de parsing, aucun chemin
de ressource manquant et aucune erreur d'exécution.

## Documentation

Mettre à jour `README.md` dès qu'une règle, une commande de lancement, une
valeur de configuration ou l'organisation du dépôt change.
