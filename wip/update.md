# Pile Down - Implémentations post-jam

Implémenter les évolutions suivantes sans réécrire les systèmes existants.

Conserver notamment :

* `GameManager`
* `BonusManager`
* `SpecialRuleManager`
* `SpecialRuleRegistry`
* `BonusRegistry`
* `difficulty.gd`
* `debug.gd`
* la sauvegarde `user://pile_down.cfg`
* le compteur interne de progression croissant
* le compteur visuel normal descendant de 100 vers 0
* le mode `ENDLESS` existant

Les nouvelles fonctionnalités doivent s'intégrer à cette architecture et être configurables.

# 1. Progression de difficulté dirigée

Le tirage actuel des augmentations de statistiques est pondéré, mais il peut laisser trop longtemps le joueur avec une seule pile ou une seule carte en main.

Ajouter un système de pity dynamique.

## Principe

Chaque type d'augmentation possède un compteur indiquant depuis combien de tirages il n'a pas été sélectionné :

```gdscript
var difficulty_droughts := {
    &"pile": 0,
    &"hand": 0,
    &"start_value": 0,
    &"time": 0,
}
```

Lorsqu'une augmentation est éligible mais n'est pas obtenue, son poids augmente de `p %`.

Lorsqu'elle est sélectionnée, son compteur revient à zéro.

```gdscript
func get_directed_weight(
    base_weight: float,
    drought_count: int
) -> float:
    return base_weight * (
        1.0 + drought_count * Difficulty.STAT_PITY_RATE
    )
```

Ajouter dans `difficulty.gd` :

```gdscript
const STAT_PITY_RATE := 0.25
const MAX_STAT_DROUGHT := 5
const STARTER_STAT_MULTIPLIER := 2.0
```

`STAT_PITY_RATE = 0.25` signifie que le poids relatif augmente de 25 % de sa valeur de base à chaque échec.

## Sortie accélérée du début de partie

Tant que le joueur possède :

```gdscript
pile_count == 1
```

ou :

```gdscript
hand_size == 1
```

multiplier le poids de l'amélioration correspondante par `STARTER_STAT_MULTIPLIER`.

```gdscript
if pile_count == 1:
    pile_weight *= Difficulty.STARTER_STAT_MULTIPLIER

if hand_size == 1:
    hand_weight *= Difficulty.STARTER_STAT_MULTIPLIER
```

L'objectif est que le jeu atteigne rapidement au moins :

```text
2 piles
2 cartes en main
```

sans forcément garantir ces changements à des rounds fixes.

## Garantie après une trop longue absence

Lorsqu'une statistique atteint `MAX_STAT_DROUGHT`, elle devient prioritaire au prochain tirage où elle est éligible.

Si plusieurs statistiques atteignent la limite en même temps, effectuer un tirage pondéré uniquement entre elles.

Les statistiques déjà arrivées à leur limite maximale ne doivent :

* pas accumuler de drought ;
* pas participer au tirage ;
* pas provoquer de garantie impossible.

Un résultat `NO DIFFICULTY CHANGE` compte comme un échec pour toutes les augmentations encore éligibles.

## Sauvegarde et checkpoints

Les droughts font partie de l'état de progression.

Ils doivent être :

* réinitialisés lors d'une nouvelle partie classique ;
* copiés dans les snapshots de checkpoint ;
* restaurés au lancement d'une partie depuis un checkpoint ;
* simulés normalement lors d'un démarrage debug avancé.

# 2. Checkpoints de progression

Ajouter des checkpoints permanents permettant de recommencer à certains paliers.

## Configuration

Ajouter dans `difficulty.gd` :

```gdscript
const CHECKPOINT_INTERVAL := 10
const ENABLE_CHECKPOINTS := true
```

Le checkpoint `n` correspond au round interne :

```gdscript
checkpoint_round = n * CHECKPOINT_INTERVAL
```

Exemples :

```text
Checkpoint 1 : round 10
Checkpoint 2 : round 20
Checkpoint 3 : round 30
```

Le nombre visuel descendant peut être affiché en complément, mais les données doivent utiliser le numéro interne croissant.

## Déblocage

Lorsqu'un joueur termine pour la première fois un round de checkpoint, afficher :

```text
CHECKPOINT 2
UNLOCKED
```

Le message doit être skippable.

Le checkpoint n'est débloqué qu'après la victoire du round correspondant.

## Snapshot de checkpoint

Au début de chaque round correspondant à un checkpoint, avant :

* la sélection des règles spéciales ;
* la génération de la main ;
* les modifications temporaires ;

capturer un snapshot de l'état permanent :

```gdscript
class_name CheckpointSnapshot
extends Resource

var checkpoint_id: int
var start_round: int

var pile_count: int
var hand_size: int
var start_value: int
var turn_time: float

var difficulty_droughts: Dictionary
var unlocked_endless: bool
```

Si le joueur termine le round, sauvegarder ce snapshot comme état officiel du checkpoint.

Ne pas remplacer automatiquement un snapshot déjà débloqué. Le checkpoint doit conserver l'état de la première partie qui l'a débloqué.

## Sauvegarde

Ajouter dans `user://pile_down.cfg` :

```text
checkpoints/unlocked
checkpoints/snapshots
checkpoints/highscores
checkpoints/no_mistake_highscores
```

Les snapshots doivent être sérialisés sous forme de dictionnaires simples.

# 3. Démarrer depuis un checkpoint

Ajouter dans le menu principal un choix entre :

```text
NEW RUN
CHECKPOINT
ENDLESS
```

Le bouton `CHECKPOINT` ouvre la liste des checkpoints débloqués.

Chaque entrée affiche :

```text
CHECKPOINT 2
ROUND 20
BEST: 37
```

Ne pas afficher les checkpoints encore verrouillés, ou les afficher avec `???` selon la direction visuelle retenue.

## Initialisation

Une partie checkpoint doit :

1. restaurer le snapshot ;
2. définir `run_mode = CHECKPOINT` ;
3. définir le round courant ;
4. restaurer les droughts ;
5. accorder les sélections de bonus qui auraient normalement déjà eu lieu ;
6. commencer le gameplay uniquement après ces sélections.

## Bonus de départ

Calculer le nombre de choix de bonus normalement obtenus avant le round de départ :

```gdscript
func get_checkpoint_bonus_choice_count(start_round: int) -> int:
    return int(
        floor(
            float(start_round - 1)
            / Difficulty.BONUS_INTERVAL
        )
    )
```

Exemple avec un bonus tous les 4 rounds :

```text
Départ round 10 : 2 choix
Départ round 20 : 4 choix
Départ round 30 : 7 choix
```

Pour chaque bonus dû :

* afficher l'écran normal de choix entre deux bonus ;
* laisser le joueur sélectionner un bonus ;
* appliquer les niveaux et doublons normalement ;
* enchaîner avec le choix suivant ;
* ne pas lancer de timer pendant cette séquence.

Les propositions peuvent être tirées à nouveau à chaque nouvelle partie checkpoint.

## Highscore checkpoint

Les parties checkpoint possèdent un highscore indépendant pour chaque checkpoint.

Enregistrer uniquement :

* le round le plus avancé ;
* éventuellement le nombre de rounds franchis depuis le checkpoint ;
* le meilleur résultat sans erreur.

Ne jamais utiliser le temps comme critère de classement en mode checkpoint.

Le temps total peut rester affiché pendant la partie, mais il ne doit être ni sauvegardé ni comparé.

Une partie checkpoint ne peut jamais modifier :

* le highscore classique ;
* le meilleur temps classique ;
* le highscore Endless.

# 4. Highscores sans erreur

Suivre une variable permanente pendant chaque run :

```gdscript
var run_mistake_count := 0
```

Elle augmente pour chaque vraie erreur, même si celle-ci est absorbée par :

* `SAFETY NET`
* une vie supplémentaire ;
* un bonus de survie.

Les retours sans erreur provoqués par :

* `HOT POTATOES`
* `THE FLOOR IS LAVA`
* un abandon de drag normal ;

ne comptent pas.

Si `run_mistake_count == 0`, la run est éligible au classement sans erreur.

Sauvegarder séparément :

```text
highscores/classic
highscores/classic_no_mistake
highscores/endless
highscores/endless_no_mistake
checkpoints/<id>/best
checkpoints/<id>/best_no_mistake
```

Pour le mode classique, le temps reste utilisé comme départage.

Pour le mode checkpoint, ne sauvegarder que la progression.

# 5. Animations skippables

Permettre de passer les séquences non interactives en cliquant, touchant l'écran ou appuyant sur `Space` ou `Enter`.

Sont concernées :

* augmentation de statistique ;
* annonce d'une règle spéciale ;
* annonce d'une combinaison ;
* annonce `TIER RELIEF` ;
* annonce de checkpoint ;
* notifications de déblocage.

Ne pas rendre skippables :

* les choix de bonus ;
* `RULE BREAKER` tant qu'une règle doit être choisie ;
* les écrans nécessitant une décision.

## Interface commune

Créer un composant ou une interface commune :

```gdscript
class_name SkippableSequence
extends Control

var can_skip := false
var is_skipping := false

func skip_to_end() -> void:
    pass
```

Lors d'un skip :

* terminer immédiatement les tweens ;
* placer les éléments dans leur état final ;
* appliquer les changements de gameplay ;
* consommer l'entrée ;
* empêcher ce même clic d'interagir avec le plateau ou le menu suivant.

Une seule pression doit terminer l'annonce et poursuivre la séquence.

Ne pas simplement accélérer les animations. Les terminer proprement avec `Tween.custom_step()` ou en appliquant directement l'état final.

# 6. Menu Progression

Ajouter un bouton :

```text
PROGRESSION
```

Il ouvre un nouvel écran contenant plusieurs onglets ou pages :

```text
HIGHSCORES
ACHIEVEMENTS
BONUSES
SPECIAL RULES
FONTS
```

Conserver la direction artistique pixel art actuelle.

## Highscores

Afficher au minimum :

### Classic

* meilleure progression ;
* meilleur temps correspondant ;
* meilleure progression sans erreur ;
* meilleur temps sans erreur.

### Endless

* meilleur round ;
* meilleur round sans erreur.

### Checkpoints

Pour chaque checkpoint débloqué :

* round de départ ;
* meilleur round atteint ;
* meilleur round atteint sans erreur.

Aucun temps pour les checkpoints.

## Bonus

Afficher tous les bonus du registre.

Un bonus déjà sélectionné dans au moins une partie est considéré comme découvert.

Carte découverte :

```text
WILD CARD
Jokers may appear.
MAX LEVEL III
```

Carte non découverte :

```text
???
Not discovered yet.
```

Sauvegarder :

```text
progression/discovered_bonuses
```

Un bonus est découvert lorsqu'il est sélectionné, pas simplement lorsqu'il est proposé.

## Special Rules

Afficher toutes les règles du registre.

Une règle est découverte dès qu'elle est activée dans une partie.

Sauvegarder :

```text
progression/encountered_special_rules
```

Une règle inconnue affiche :

```text
???
Survive more rounds to discover it.
```

Pour une règle découverte, afficher sa description courte utilisée dans la cheatsheet.

## Navigation

Le bouton `Escape` retourne au menu principal sans fermer l'application.

Les écrans doivent être utilisables :

* à la souris ;
* au clavier ;
* au tactile.

# 7. Achievements

Créer un système d'achievements piloté par des données.

```gdscript
class_name AchievementData
extends Resource

@export var id: StringName
@export var title: String
@export var description: String
@export var hidden := false
@export var reward_font: StringName
```

Créer :

```text
AchievementRegistry.gd
AchievementManager.gd
AchievementPopup.tscn
```

Les achievements sont sauvegardés définitivement.

```text
progression/unlocked_achievements
```

## Première liste

Implémenter au minimum :

```text
FIRST STEPS
Complete your first round.

PERFECT ROUND
Complete a round without a mistake.

TEN DOWN
Reach round 10.

CHECKED IN
Unlock your first checkpoint.

RULE OF THREE
Survive a round with three special rules.

FULL HOUSE
Reach the maximum hand size.

CLEAN RUN
Reach round 20 without a mistake.

COUNTED DOWN
Complete the normal mode.

FOREVER COUNTING
Reach round 25 in Endless Mode.
```

Les valeurs doivent rester configurables.

Les popups d'achievement :

* apparaissent sans interrompre la partie ;
* restent brièvement en haut de l'écran ;
* peuvent attendre la fin d'une annonce importante ;
* ne doivent pas cacher le timer.

# 8. Déblocage de polices

Ajouter un registre de polices sélectionnables.

```gdscript
class_name FontData
extends Resource

@export var id: StringName
@export var display_name: String
@export var font: Font
@export var default_unlocked := false
@export var required_achievement: StringName
```

Créer :

```text
FontRegistry.gd
FontManager.gd
```

Le joueur choisit sa police depuis :

```text
PROGRESSION > FONTS
```

Sauvegarder :

```text
progression/unlocked_fonts
settings/selected_font
```

Le changement doit s'appliquer aux textes de gameplay et de menu sans modifier :

* les dimensions des tuiles ;
* les zones interactives ;
* les positions du HUD.

Si une police ne tient pas correctement dans certaines tuiles, utiliser les réglages spécifiques déjà employés pour les chiffres romains.

Les nouvelles polices sont principalement débloquées via les achievements.

Ne pas partager, télécharger ou ajouter automatiquement de nouvelles polices. Utiliser uniquement les ressources déjà présentes dans le projet ou ajoutées manuellement au dossier `resources/fonts/`.

# 9. Ecran de fin retravaillé

A la mort ou à la victoire, collecter les découvertes effectuées pendant la run :

```gdscript
var newly_discovered_bonuses: Array[StringName]
var newly_encountered_rules: Array[StringName]
var newly_unlocked_achievements: Array[StringName]
var newly_unlocked_fonts: Array[StringName]
var newly_unlocked_checkpoints: Array[int]
```

Après le score, afficher uniquement les catégories non vides.

Exemple :

```text
NEW BONUS
DOUBLE DOWN

NEW SPECIAL RULE
WAVY BABY

NEW FONT
TINY5

CHECKPOINT 2
UNLOCKED
```

Ne pas afficher une longue liste simultanément.

Présenter les éléments successivement ou dans une liste compacte pouvant être passée par clic.

Lorsque rien n'a été débloqué, conserver l'écran de fin actuel.

# 10. Peek-a-Card sur mobile

Revoir uniquement le comportement tactile de `PEEK-A-CARD`.

Le fonctionnement souris reste inchangé.

## Problème

Sur mobile, l'absence de hover laisse trop peu de temps pour lire une carte avant le drag.

## Nouveau comportement tactile

Au premier contact :

1. révéler immédiatement la carte ;
2. ne pas démarrer le drag instantanément ;
3. attendre un court délai ou un déplacement suffisant ;
4. commencer ensuite le drag sans exiger de relâcher le doigt.

Ajouter dans `difficulty.gd` :

```gdscript
const TOUCH_PEEK_DRAG_DELAY := 0.12
const TOUCH_PEEK_VISIBLE_GRACE := 0.18
const TOUCH_DRAG_DISTANCE := 5.0
```

Etat conseillé :

```gdscript
enum TouchCardState {
    IDLE,
    REVEALED,
    DRAGGING,
}
```

## Déroulement

* `touch_pressed` révèle la carte ;
* si le doigt reste presque immobile, la carte reste visible ;
* si le doigt dépasse `TOUCH_DRAG_DISTANCE`, démarrer le drag ;
* lors du début du drag, conserver la face visible pendant `TOUCH_PEEK_VISIBLE_GRACE` ;
* retourner ensuite la carte sans interrompre le drag ;
* si le doigt est relâché sans drag, conserver la révélation environ 0,4 seconde avant de la masquer.

Le joueur doit pouvoir :

* lire la carte ;
* maintenir ;
* glisser ;

avec un seul geste.

Ne pas demander un double tap obligatoire.

## Compatibilités

Avec `BLIND DELIVERY + PEEK-A-CARD` :

* la carte est visible pendant la phase de consultation tactile ;
* elle se retourne dès le début effectif du drag ;
* ne pas appliquer `TOUCH_PEEK_VISIBLE_GRACE`.

# 11. Rework de Lucky Hand

`LUCKY HAND` ne doit plus pouvoir produire de carte morte.

Chaque carte ajoutée par le bonus doit être :

* jouable immédiatement ;
* ou garantie utilisable par une chaîne automatique de `DOUBLE DOWN` ;
* ou garantie utilisable par `DEJA VU`.

## Niveau I

Garantir une carte pour la pile la plus basse.

En mode Pile Down, la pile la plus basse est la pile active ayant la valeur actuelle la plus proche de zéro.

En mode Pile Up, prendre la pile la plus proche de `S`.

```gdscript
func get_most_advanced_pile() -> Pile:
    pass
```

Générer sa prochaine valeur attendue.

## Niveau II

Ajouter dans cet ordre :

1. une carte pour la pile la plus avancée ;
2. si possible, une carte permettant de continuer immédiatement sur cette même pile ;
3. sinon, une carte pour la pile suivante la plus avancée.

Exemple Pile Down :

```text
Pile ciblée : 5
Lucky Hand : 4, 3
```

Le `3` est réservé à la chaîne de `DOUBLE DOWN` si ce bonus est actif.

Sans `DOUBLE DOWN`, le `3` doit être remplacé par une carte immédiatement jouable.

## Niveau III

Ajouter ensuite une carte dont la valeur correspond au plus grand nombre de piles actives.

```gdscript
func get_most_shared_expected_value() -> int:
    pass
```

En cas d'égalité :

1. privilégier la valeur de la pile la plus avancée ;
2. puis choisir aléatoirement.

## Synergie Deja Vu

Si `DEJA VU` est possédé :

* privilégier plusieurs copies d'une valeur attendue par plusieurs piles ;
* ne pas créer plus de copies que le nombre de piles compatibles ;
* respecter le niveau de `DEJA VU`.

Exemple :

```text
Piles attendent : 4, 4, 7
Lucky Hand : 4, 4
```

## Synergie Double Down

Si `DOUBLE DOWN` est possédé :

* réserver les emplacements disponibles pour une suite descendante ou montante ;
* ne pas dépasser le niveau de `DOUBLE DOWN` ;
* arrêter la suite lorsqu'une valeur est hors limites.

Exemple Pile Down :

```text
Pile : 6
Lucky Hand III : 5, 4, 3
```

## Contraintes

* conserver la taille normale de la main ;
* remplacer des cartes aléatoires, ne pas ajouter d'emplacements ;
* ne pas remplacer le joker conservé ;
* ne pas créer de doublon inutile ;
* ne jamais retirer l'unique carte jouable garantie par le générateur avant d'avoir placé les cartes Lucky Hand ;
* si une synergie est impossible, utiliser une carte immédiatement jouable comme fallback.

Ajouter des tests vérifiant que chaque main produite par Lucky Hand contient uniquement des cartes exploitables selon l'état courant et les bonus possédés.

# 12. Rework de Quick Peek

Remplacer les durées actuelles par un déclenchement périodique.

## Niveaux

```text
Niveau I
Toutes les 4 mains
Révélation pendant 0,10 seconde

Niveau II
Toutes les 3 mains
Révélation pendant 0,20 seconde

Niveau III
Toutes les 2 mains
Révélation pendant 0,25 seconde
```

Ajouter dans `difficulty.gd` :

```gdscript
const QUICK_PEEK_HAND_INTERVALS := [4, 3, 2]
const QUICK_PEEK_DURATIONS := [0.10, 0.20, 0.25]
```

## Compteur

Maintenir un compteur par round :

```gdscript
var hands_since_quick_peek := 0
```

Il revient à zéro :

* au début de chaque round ;
* après chaque activation de Quick Peek.

La première main compte comme une main normale.

Au déclenchement :

1. terminer l'entrée de la nouvelle main ;
2. révéler toutes les piles ;
3. conserver leur valeur pendant la durée du niveau ;
4. les retourner ;
5. démarrer ou reprendre le timer.

Le timer ne doit pas consommer le temps de révélation.

`QUICK PEEK` doit temporairement passer au-dessus des effets de masquage sans désactiver leurs règles.

# 13. Rework de Merry-Go-Stack

Remplacer les anciens motifs génériques par un vrai système d'orbites circulaires continues.

## Nouveau principe

Une ou plusieurs piles servent de centre fixe.

Les autres piles tournent continuellement autour de ce centre.

Chaque pile mobile suit sa propre position sur l'orbite :

```gdscript
position = orbit_center + Vector2(
    cos(angle),
    sin(angle)
) * orbit_radius
```

## Distribution

Pour un petit nombre de piles :

```text
1 pile centrale
1 ou plusieurs piles en orbite
```

Lorsque le cercle est assez grand pour contenir davantage de piles :

* répartir plusieurs piles régulièrement sur la même orbite ;
* utiliser un angle de départ différent pour chacune ;
* conserver une distance minimale entre elles.

Si toutes les piles ne tiennent pas :

* créer une seconde orbite ;
* ou utiliser plusieurs piles centrales regroupées ;
* ne jamais réduire la distance au point de faire chevaucher les zones de dépôt.

Calculer la capacité approximative d'une orbite avec :

```gdscript
capacity = floor(
    TAU * orbit_radius
    / minimum_pile_spacing
)
```

## Mouvement

Le mouvement doit être :

* continu ;
* lent ;
* prévisible ;
* identique pendant tout le round ;
* sans téléportation ;
* sans changement brusque de sens.

L'orbite peut être horaire ou antihoraire, choisie au début du round.

Les `DropArea`, timers de régénération, halos et effets doivent suivre les piles.

## Incompatibilités

Déclarer le nouveau `MERRY-GO-STACK` incompatible avec :

* `WAVY BABY`
* `PILE MOVER`
* les autres règles de mouvement continu utilisant directement la position des piles.

Il peut rester compatible avec `MUSICAL STACKS` uniquement si Musical Stacks permute les identités ou les phases orbitales sans interrompre l'orbite. Sinon, les déclarer incompatibles pour la première version.

# 14. Transformer l'ancien Merry-Go-Stack

Conserver l'ancien effet de mouvement irrégulier sous une nouvelle règle.

```text
SHAKING PILES
Please remain unstable.
```

Identifiant :

```gdscript
&"shaking_piles"
```

## Effet

Chaque pile reste proche de sa position logique, mais suit un léger mouvement local :

```gdscript
offset = Vector2(
    sin(time * speed_x + phase_x),
    cos(time * speed_y + phase_y)
) * amplitude
```

Les mouvements doivent rester assez faibles pour que :

* les piles ne se chevauchent pas ;
* les zones de dépôt restent lisibles ;
* le drag reste agréable.

Les piles ne doivent pas toutes trembler en synchronisation.

Ajouter cette règle au registre avec :

* son poids ;
* son round minimum ;
* ses incompatibilités ;
* sa description de progression.

# 15. Nouvelle règle Wavy Baby

Ajouter :

```text
WAVY BABY
Go with the flow.
```

Identifiant :

```gdscript
&"wavy_baby"
```

## Effet

Les piles suivent une ondulation verticale.

Chaque pile conserve une position de base et reçoit un offset sinusoïdal :

```gdscript
var phase := base_position.x * phase_spacing

var offset_y := sin(
    elapsed_time * wave_speed + phase
) * wave_amplitude

pile.position = base_position + Vector2(0.0, offset_y)
```

Le déphasage entre les piles doit donner l'impression qu'une onde traverse le plateau de bas en haut ou d'un côté à l'autre.

Pour plusieurs rangées :

* utiliser la position verticale pour décaler le moment où l'onde atteint chaque rangée ;
* ne pas déplacer toutes les rangées exactement ensemble.

## Configuration

Ajouter dans `difficulty.gd` :

```gdscript
const WAVY_BABY_AMPLITUDE := 12.0
const WAVY_BABY_SPEED := 1.6
const WAVY_BABY_PHASE_SPACING := 0.06
```

Ces valeurs doivent être adaptées à la résolution native `256 x 320`.

L'amplitude réelle doit être réduite automatiquement si elle risque de provoquer :

* un chevauchement ;
* une sortie de la zone jouable ;
* un contact permanent avec la lave.

## Incompatibilités

Déclarer incompatible avec :

* `MERRY-GO-STACK`
* `PILE MOVER`
* toute autre règle contrôlant continuellement la position absolue des piles.

# 16. Effet lumineux pendant le drag

Ajouter un léger halo autour des cartes déplacées.

L'effet doit respecter le pixel art natif.

Ne pas utiliser de flou haute résolution.

Créer un sprite ou shader pixelisé :

```text
Card
└── DragGlow
```

Comportement :

* masqué au repos ;
* apparaît progressivement au début du drag ;
* suit la couleur de la carte ;
* faible opacité ;
* pulsation très légère ;
* disparaît lors du dépôt ou du retour.

Pour `COLORBLIND`, utiliser un halo blanc ou gris neutre.

Pour `BRING A FRIEND` :

* la carte principale possède le halo complet ;
* les accompagnatrices utilisent une opacité réduite.

Eviter les halos trop grands qui révéleraient une carte cachée ou gêneraient la lecture des piles.

# 17. Poussière déplacée par les cartes

Ajouter une couche de particules de poussière très discrète sur le plateau.

L'effet doit donner l'impression que les cartes déplacent une poussière stagnante.

## Implémentation recommandée

Utiliser un pool léger de particules 2D, plutôt qu'un grand système GPU.

```text
DustManager
├── DustParticle
├── DustParticle
└── ...
```

Chaque particule :

* mesure 1 à 2 pixels natifs ;
* dérive très lentement ;
* reste peu visible au repos ;
* reçoit une impulsion lorsqu'une carte passe à proximité ;
* ralentit progressivement après l'impulsion.

```gdscript
func push_dust(
    card_position: Vector2,
    card_velocity: Vector2
) -> void:
    for dust in nearby_dust:
        var distance := dust.position.distance_to(card_position)

        if distance > push_radius:
            continue

        var strength := 1.0 - distance / push_radius
        dust.velocity += card_velocity.normalized() \
            * strength \
            * push_force
```

Limiter le nombre de particules, par exemple :

```gdscript
const DUST_PARTICLE_COUNT := 48
```

Ne pas placer de poussière :

* sur le HUD ;
* dans la main ;
* au-dessus des textes ;
* dans les menus.

La poussière doit être affectée par :

* les cartes draggées ;
* les groupes `BRING A FRIEND` ;
* les piles mobiles, avec une force plus faible.

Prévoir une option permettant de désactiver cet effet pour les appareils peu puissants.

# 18. Sauvegarde et migration

Ajouter une version de schéma :

```text
save/schema_version
```

Lors du chargement d'une ancienne sauvegarde :

* conserver le highscore existant ;
* conserver Endless débloqué ;
* initialiser les checkpoints comme verrouillés ;
* initialiser les collections de découvertes ;
* initialiser les achievements ;
* déverrouiller la police actuellement utilisée ;
* ne jamais effacer silencieusement une ancienne valeur.

Toutes les nouvelles clés doivent avoir une valeur par défaut sûre.

# 19. Debug

Ajouter dans `debug.gd` :

```gdscript
const UNLOCK_ALL_CHECKPOINTS := false
const START_FROM_CHECKPOINT := 0
const UNLOCK_ALL_ACHIEVEMENTS := false
const UNLOCK_ALL_FONTS := false
const DISCOVER_ALL_BONUSES := false
const DISCOVER_ALL_SPECIAL_RULES := false
const FORCE_WAVY_BABY := false
const FORCE_SHAKING_PILES := false
const SHOW_DUST_DEBUG := false
```

`START_FROM_CHECKPOINT = 0` désactive le démarrage forcé.

Le debug doit pouvoir tester les checkpoints sans modifier définitivement la sauvegarde, sauf action explicite.

# 20. Tests automatisés

Ajouter ou étendre les tests suivants.

## Difficulté dirigée

* les poids augmentent après chaque échec ;
* le compteur sélectionné revient à zéro ;
* une statistique à sa limite ne participe plus ;
* une pile ou main à 1 reçoit bien le multiplicateur ;
* la garantie se déclenche après `MAX_STAT_DROUGHT`.

## Checkpoints

* le checkpoint se débloque uniquement après victoire ;
* le snapshot correspond au début du round ;
* le nombre de bonus de départ est correct ;
* les bonus sont sélectionnés avant le gameplay ;
* le highscore checkpoint n'écrase pas le highscore classique ;
* aucun temps checkpoint n'est sauvegardé.

## Animations skippables

* un clic termine l'annonce ;
* les effets de la règle sont tout de même activés ;
* le clic ne traverse pas vers le plateau ;
* les choix interactifs ne sont pas skippés.

## Progression

* les bonus sélectionnés sont découverts ;
* les règles activées sont rencontrées ;
* les achievements se débloquent une seule fois ;
* les polices restent débloquées ;
* la police choisie est restaurée au lancement.

## Peek-a-Card mobile

* le premier contact révèle la carte ;
* un maintien permet de la lire ;
* le drag démarre sans second tap ;
* la carte se masque au bon moment ;
* la combinaison avec Blind Delivery reste cohérente.

## Lucky Hand

* aucune carte générée n'est morte ;
* le niveau I cible la pile la plus avancée ;
* le niveau II crée une suite uniquement avec Double Down ;
* le niveau III choisit une valeur partagée ;
* Deja Vu génère le bon nombre de copies ;
* les jokers et emplacements réservés sont respectés.

## Quick Peek

* les intervalles 4, 3 et 2 sont respectés ;
* les durées sont correctes ;
* le compteur se réinitialise au début du round ;
* le timer ne diminue pas pendant la révélation.

## Mouvements

* Merry-Go-Stack conserve les distances minimales ;
* les DropArea suivent les orbites ;
* Wavy Baby ne fait pas sortir les piles de l'écran ;
* Shaking Piles conserve chaque pile près de sa position logique ;
* les incompatibilités du registre sont respectées.

# 21. Ordre d'implémentation

Procéder dans cet ordre :

1. sauvegarde versionnée et structures de données ;
2. progression dirigée des statistiques ;
3. checkpoints et snapshots ;
4. highscores séparés ;
5. sélections de bonus au lancement checkpoint ;
6. animations skippables ;
7. menu Progression ;
8. découvertes et écran de fin ;
9. achievements ;
10. sélection et déblocage des polices ;
11. rework tactile de Peek-a-Card ;
12. rework de Lucky Hand ;
13. rework de Quick Peek ;
14. nouveau Merry-Go-Stack ;
15. Shaking Piles ;
16. Wavy Baby ;
17. halo de drag ;
18. poussière ;
19. tests automatisés ;
20. vérification Web, desktop et tactile.

A chaque étape :

* lancer les tests existants ;
* éviter les régressions sur les règles et bonus déjà implantés ;
* conserver la compatibilité Web sans threads ;
* conserver la résolution pixel art native ;
* documenter les nouvelles constantes dans le README.
