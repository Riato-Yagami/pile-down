# Refactorisation du projet

Cette passe conserve les points d'entrée des scènes, les signaux, les propriétés
exportées, les valeurs de configuration et les séquences de tirages aléatoires.
Les modifications présentes avant cette intervention servent de référence.

## Répartition des responsabilités

| Script principal | Avant | Après | Responsabilités extraites |
| --- | ---: | ---: | --- |
| `GameManager.gd` | 6 091 lignes | 2 801 lignes | Sessions, rounds, checkpoints, records, debug, interactions, menus, HUD et transitions |
| `ChallengeSelection.gd` | 1 197 | 699 | Construction de Seeds et style des contrôles/popups |
| `ProgressionMenu.gd` | 1 022 | 629 | Choix cosmétiques, aperçu et construction des entrées |
| `Card.gd` | 856 | 601 | Animations d'entrée/sortie, poses et retournements |
| `GameOptionsController.gd` | 842 | 570 | Résolution, canvas et sélecteur de taille d'écran |

Les nouveaux contrôleurs restent des fonctions spécialisées appelées par les
nœuds existants. Ils ne possèdent pas de référence persistante à leur hôte et ne
recherchent pas de gestionnaire global. Les méthodes de façade sont conservées
pour les connexions de signaux, les appels différés et les tests existants.
Les attentes de coroutines restent aux mêmes endroits dans les traitements.

- `scripts/core/session/` : début, reprise, abandon et fin de partie.
- `scripts/core/debug/` : raccourcis et présentation du debug.
- `scripts/gameplay/round/` : préparation des rounds, mains et progression de fin de round.
- `scripts/gameplay/interaction/` : placement des cartes, erreurs, déplacements de piles,
  contrôles tactiles, cartes compagnes et emplacements stables de la main.
- `scripts/gameplay/card/CardAnimations.gd` : animations des cartes.
- `scripts/gameplay/ConveyorController.gd` : tirage et déplacement des cartes du convoyeur.
- `scripts/progression/RunRecordStore.gd` : records, découvertes et migration de sauvegarde.
- `scripts/progression/checkpoints/` : stockage, restauration et interface des checkpoints.
- `scripts/ui/game/` : disposition, transitions, menus et HUD.
- `scripts/ui/progression/` : entrées, cosmétiques et aperçu de progression.
- `scripts/challenges/ui/` : contrôles et sélection de Seeds.
- `scripts/settings/display/` : configuration de l'affichage.

Tous ces chemins sont relatifs à `resources/`.

## Mutualisations et ressources

- `RunRNG.shuffle()` remplace les trois implémentations identiques de Fisher–Yates.
  L'ordre des itérations et le nombre d'appels au stream fourni sont conservés.
- `SaveConfig` centralise le chemin de sauvegarde et les lectures sans traitement
  particulier d'erreur. Les lectures qui contrôlent les erreurs, les clés, le
  schéma et l'ordre des écritures sont conservés.
- `PixelUi.button_style()` construit le style partagé des sélecteurs d'options
  et de Seeds avec les mêmes textures et marges.
- Les shaders de progression, d'icônes dorées et de Safety Net résident dans
  `resources/shaders/ui/`. Le shader doré est commun aux vies et aux icônes.
  Les shaders sont préchargés ; les matériaux restent distincts pour conserver
  les paramètres indépendants de chaque élément.
- Les deux matériaux de fond sont déplacés dans `resources/materials/backgrounds/`.
  Les deux CanvasTexture de cartes sont dans `resources/materials/textures/tiles/`.
  Les shaders StripeBackground et DeformableBackground rejoignent `shaders/backgrounds/`.
  Les UID existants et leurs fichiers associés sont conservés ; les références
  dans les scènes, scripts et tests sont mises à jour.
- La référence du bus audio dans `project.godot` utilise le chemin explicite du
  même fichier pour ne pas dépendre du cache des UID au premier import.
- Le nœud `RoundWave` est résolu une fois au chargement de la scène.

L'ancienne méthode de placement 3D `PileLayoutManager.positions_for()`, ses deux
constantes et le calcul inutilisé `_low_resolution_scale()` ont été retirés après
vérification de leurs références. Aucun asset graphique, audio ou catalogue de
gameplay n'a été supprimé : une absence de référence littérale seule ne suffit
pas à exclure un chargement dynamique ou une utilisation dans l'éditeur.

## Validation

Commandes de validation :

```sh
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 240
python tests/run_godot_tests.py --godot godot --jobs 2 --report .godot/test-report.json
```

Le lanceur Python utilise des profils de sauvegarde isolés dans `.godot/`, détecte
les erreurs de script même si Godot renvoie un code de sortie nul et interrompt
un test bloqué. Pour diagnostiquer un test sensible au temps réel, utiliser
`--jobs 1`. Un motif de fichier peut être fourni en dernier argument.

La référence avant refactorisation comporte **38 tests réussis sur 52**. Les
14 autres présentent déjà une assertion, une erreur d'exécution ou un blocage :
`active_bonus_grid`, `bonus_system`, `challenges`, `debug_shortcuts`, `high_score`,
`new_challenge_modes`, `new_special_rules`, `progression_game_integration`,
`progression_menu`, `screen_size_options`, `selectable_data_catalog`,
`sticky_hand_lock`, `touch_drag`, `victory_display` (préfixe `test_`, suffixe `.gd`).
Le dernier appelle notamment une méthode déjà absente avant cette intervention.
Ces tests ne sont pas assouplis pour masquer les échecs.

Après refactorisation, la suite complète retrouve **les mêmes 38 réussites et les
mêmes 14 échecs**, aux mêmes lignes des tests. Aucun nouvel échec n'est observé.
L'import éditeur et le démarrage pendant 240 frames ne produisent aucune erreur
de parsing, de script ou de ressource manquante. Tous les nouveaux scripts
disposent d'un fichier `.uid`. Les 11 tests Python des scripts de build sont
ignorés par leur propre condition d'environnement sous Windows.

Les tests ciblés couvrent notamment seeds/replay, checkpoints, démarrage,
déplacements, cartes compagnes, choix cosmétiques, sauvegardes, shaders et retour
au menu semi-adaptatif. Les chemins littéraux `res://` ont été contrôlés.
L'environnement Windows isolé signale également l'impossibilité de lire le
magasin de certificats système ; ce message est distingué des erreurs du projet.

## Limites conservées volontairement

`GameManager` garde les références de scène, l'état partagé et les façades. Les
contrôleurs dépendent donc encore de son interface typée. Remplacer cet état par
des objets de contexte plus étroits demanderait une deuxième migration des
connexions, des callbacks et des mécanismes d'annulation asynchrones.

Les fonctions de résolution des erreurs, les combinaisons bonus/règles et les
migrations de sauvegarde sont déplacées sans réécriture de leurs branches.
Les probabilités, timings et données des catalogues restent inchangés. Une
validation entièrement verte exige de traiter séparément les échecs de référence
et les tests sensibles au temps réel ; cette passe ne prétend pas établir une
absence absolue de régression visuelle ou fonctionnelle.
