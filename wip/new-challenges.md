# Nouveaux Challenge Runs

Ajouter quatre nouveaux challenges :

```text
SHARED CLOCK
CONVEYOR BELT
BOSS RUSH
NO LOOKING BACK
```

Ils doivent utiliser le système `ChallengeRegistry`, `ChallengeManager` et `ChallengeModifiers` déjà prévu.

Règles communes :

* `start_round = 5` par défaut ;
* `target_round = 20` par défaut ;
* valeurs configurables individuellement ;
* battre `target_round` termine le challenge ;
* terminer le challenge débloque sa version Endless ;
* highscore indépendant pour chaque challenge ;
* pas de checkpoints pendant un challenge ;
* aucun challenge ne modifie les highscores Classic, Checkpoint ou Endless classique.

Les challenges doivent modifier le gameplay existant via des flags/modificateurs, pas dupliquer `GameManager`.

---

# 1. Shared Clock

```text
SHARED CLOCK
Every second counts.
```

Identifiant :

```gdscript
&"shared_clock"
```

## Déblocage

Débloqué via un achievement de speedrun.

Par défaut :

```gdscript
unlock_achievement = &"speedrun_10_rounds"
```

Garder cette valeur configurable dans `ChallengeData`.

## Concept

Supprimer le timer individuel de chaque main.

A la place, chaque round possède un seul timer global.

Exemple :

```text
ROUND TIME

00:38.6
```

Toutes les mains du round consomment ce même temps.

Le timer :

* démarre au début réel du gameplay ;
* continue lorsqu'une nouvelle main est générée ;
* continue pendant un drag ;
* continue pendant les animations de placement normales ;
* s'arrête pendant les écrans qui arrêtent déjà le gameplay ;
* atteint `0` -> perte d'une vie.

## Calcul du temps initial

Ne pas utiliser une durée arbitraire.

Calculer un temps de round à partir de la difficulté actuelle.

Ajouter dans `difficulty.gd` :

```gdscript
const SHARED_CLOCK_BASE_MULTIPLIER := 1.0
const SHARED_CLOCK_MIN_TIME := 8.0
const SHARED_CLOCK_LIFE_PENALTY := 0.0
```

Créer une estimation du nombre de mains nécessaires pour terminer le round.

La formule peut utiliser :

* nombre de piles ;
* valeur de départ ;
* taille de main ;
* timer normal actuel.

Exemple de base :

```gdscript
func estimate_round_actions() -> int:
    return pile_count * start_value
```

Puis estimer le nombre de mains :

```gdscript
estimated_hands = ceil(
    float(estimated_actions)
    / max(1, hand_size)
)
```

Temps :

```gdscript
shared_round_time = max(
    Difficulty.SHARED_CLOCK_MIN_TIME,
    estimated_hands
        * turn_time
        * Difficulty.SHARED_CLOCK_BASE_MULTIPLIER
)
```

La formule exacte peut être ajustée après test, mais doit rester centralisée dans `difficulty.gd`.

## Erreur

Si le timer arrive à zéro :

1. retirer une vie selon les règles normales ;
2. si le joueur est encore vivant, ne pas recommencer le round ;
3. ajouter une petite quantité de temps et continuer.

Ajouter :

```gdscript
const SHARED_CLOCK_TIME_AFTER_TIMEOUT := 5.0
```

Cela évite qu'une expiration du timer rende automatiquement impossible tout le round.

Si `SUDDEN DEATH` est actif, l'expiration peut bien sûr terminer immédiatement la run.

## Bonus temporels

Adapter les bonus de temps au Shared Clock.

### TIME BANK

Il doit ajouter directement du temps au timer global.

Exemple :

```gdscript
shared_clock += bonus_seconds
```

### WARM-UP

Il peut augmenter le temps initial du round.

Ne pas maintenir une mécanique basée sur un timer de main invisible.

## Grace Period

`GRACE PERIOD` reste compatible.

Elle masque le timer global.

Lorsque le temps restant atteint son seuil de révélation, afficher le Shared Clock.

## Hot Potatoes

`HOT POTATOES` conserve son propre timer de drag.

Il est indépendant du Shared Clock.

Les deux timers continuent simultanément.

## UI

Remplacer visuellement le timer habituel par un timer plus important :

```text
ROUND
00:38
```

Le changement doit rester cohérent avec le HUD existant.

Dans les dernières secondes :

* légère pulsation ;
* feedback audio actuel du timer ;
* ne pas rendre l'interface agressivement clignotante.

## Endless

Dans :

```text
SHARED CLOCK - ENDLESS
```

le calcul est réévalué à chaque round selon la difficulté courante.

---

# 2. Conveyor Belt

```text
CONVEYOR BELT
Keep it moving.
```

Identifiant :

```gdscript
&"conveyor_belt"
```

## Déblocage

Débloqué après avoir battu un round combinant :

```text
FREE-RANGE CARDS
+
HOT POTATOES
```

Créer si nécessaire l'achievement :

```text
FAST FOOD
Beat a round with Free-Range Cards and Hot Potatoes.
```

Identifiant :

```gdscript
&"free_range_hot_potatoes"
```

## Concept

La main classique disparaît.

Les cartes entrent progressivement sur un tapis roulant horizontal situé dans la zone habituelle de la main.

Exemple :

```text
     PLAY AREA


→ [4]   [7]   [2]   [5] →
──────────────────────────
       CONVEYOR
```

Les cartes :

* apparaissent depuis un côté de l'écran ;
* se déplacent continuellement ;
* peuvent être attrapées pendant leur déplacement ;
* continuent vers la sortie si elles ne sont pas utilisées ;
* disparaissent lorsqu'elles quittent le tapis.

## Direction

Par défaut :

```gdscript
left_to_right = true
```

Autoriser le challenge à choisir aléatoirement au début d'un round :

```text
LEFT -> RIGHT
RIGHT -> LEFT
```

Ne pas changer de direction pendant un round.

Ajouter :

```gdscript
const CONVEYOR_RANDOM_DIRECTION := true
```

## Vitesse

Ajouter :

```gdscript
const CONVEYOR_BASE_SPEED := 22.0
const CONVEYOR_MIN_CARD_SPACING := 38.0
const CONVEYOR_MAX_VISIBLE_CARDS := 5
```

Adapter ces valeurs à la résolution native du jeu.

La vitesse peut augmenter légèrement avec la progression, mais doit rester suffisamment lente pour permettre de lire les cartes.

Créer :

```gdscript
func get_conveyor_speed(round: int) -> float:
    pass
```

avec une limite maximale configurable.

## Génération

Le tapis ne doit pas permettre un softlock.

Contrairement au challenge `RELOAD REQUIRED`, garantir qu'une carte jouable apparaîtra régulièrement.

Ne pas nécessairement garantir que chaque carte est jouable.

Ajouter :

```gdscript
const CONVEYOR_MAX_UNPLAYABLE_SPAWNS := 3
```

Après au maximum `CONVEYOR_MAX_UNPLAYABLE_SPAWNS` cartes non jouables consécutives, forcer la prochaine carte à être jouable.

Cela permet :

```text
junk
junk
junk
solution
```

sans donner constamment la solution.

## Sortie d'une carte

Une carte qui quitte l'écran :

* disparaît ;
* ne coûte pas de vie ;
* ne compte pas comme erreur ;
* permet immédiatement au générateur de préparer une future carte.

Le joueur n'est pas obligé d'utiliser toutes les cartes.

## Drag

Lorsqu'une carte est attrapée :

* elle quitte temporairement le tapis ;
* le tapis continue de fonctionner ;
* les autres cartes continuent à avancer.

Si le joueur relâche la carte sans placement valide :

* comportement d'erreur normal si elle est posée incorrectement sur une pile ;
* retour sur le tapis si elle est simplement relâchée dans le vide et qu'une position libre existe ;
* sinon réinsérer la carte au début du tapis.

Ne pas permettre à la carte retournée d'écraser une autre carte.

## Quick Peek

`QUICK PEEK` reste applicable aux piles.

Il ne doit pas arrêter le tapis, sauf si le système actuel suspend déjà complètement le gameplay pendant ce reveal.

## Lucky Hand

Adapter Lucky Hand.

Au lieu de modifier une main entière, Lucky Hand influence les prochains spawns.

Par exemple :

```gdscript
var lucky_conveyor_queue: Array[int]
```

Les cartes garanties par Lucky Hand sont injectées progressivement dans les prochains spawns.

Respecter toujours les nouvelles règles de Lucky Hand :

* pile la plus avancée ;
* synergie Double Down ;
* synergie Deja Vu ;
* aucune carte morte générée par Lucky Hand.

## Redraw

`REDRAW` est désactivé dans ce challenge.

## Free-Range Cards

Désactiver :

```text
FREE-RANGE CARDS
```

car le tapis remplit déjà cette fonction.

## Hot Potatoes

`HOT POTATOES` peut rester actif.

Le timer Hot Potatoes ne commence qu'après que la carte a quitté le tapis et est réellement draggée.

## Peek-a-Card

Compatible.

Sur desktop :

* la carte du tapis se révèle au hover.

Sur tactile :

* utiliser le comportement tactile amélioré déjà prévu ;
* ne pas rendre impossible l'attrapage d'une carte mobile.

Réduire si nécessaire la vitesse du tapis pendant le court état tactile `REVEALED`.

## Endless

La vitesse augmente progressivement jusqu'à un maximum configurable.

Ne jamais augmenter la vitesse sans limite.

---

# 3. Boss Rush

```text
BOSS RUSH
No easy rounds.
```

Identifiant :

```gdscript
&"boss_rush"
```

## Déblocage

Débloqué par :

```text
TOTAL CHAOS
Beat a round with the maximum number of Special Rules.
```

Identifiant existant :

```gdscript
&"beat_max_special_rules"
```

## Concept

Chaque round du challenge contient des Special Rules.

Aucun round normal.

Le nombre de règles augmente rapidement jusqu'au maximum.

Exemple par défaut pour `start_round = 5` et `target_round = 20` :

```text
Challenge round 5-8
2 Special Rules

9-12
3 Special Rules

13-16
4 Special Rules

17-20
MAX Special Rules
```

Ne pas coder ces seuils directement.

Ajouter dans `difficulty.gd` :

```gdscript
const BOSS_RUSH_RULE_PROGRESSION := [
    {
        "progress": 0.00,
        "rules": 2,
    },
    {
        "progress": 0.25,
        "rules": 3,
    },
    {
        "progress": 0.50,
        "rules": 4,
    },
    {
        "progress": 0.75,
        "rules": MAX_COMBINED_RULES,
    },
]
```

Calculer :

```gdscript
challenge_progress = (
    current_round - start_round
) / float(
    target_round - start_round
)
```

Puis prendre le palier correspondant.

## Sélection des règles

Réutiliser entièrement :

```text
SpecialRuleManager
SpecialRuleRegistry
```

Respecter :

* incompatibilités ;
* rounds minimum lorsque pertinent ;
* règles désactivées ;
* compatibilité avec le challenge ;
* `RULE BREAKER`.

Ne jamais forcer une combinaison invalide juste pour atteindre le nombre demandé.

Si le système ne trouve pas assez de règles compatibles après plusieurs tentatives :

1. utiliser le maximum de règles compatibles trouvé ;
2. logger un warning en debug ;
3. ne jamais bloquer le lancement du round.

## Variété

Eviter de répéter exactement le même ensemble de règles deux rounds consécutifs.

Conserver :

```gdscript
var previous_boss_rule_set: Array[StringName]
```

Lors de la sélection suivante :

* diminuer le poids des règles utilisées au round précédent ;
* chercher au moins une règle différente si possible.

Ajouter :

```gdscript
const BOSS_RUSH_REPEAT_WEIGHT := 0.35
```

## Difficulté des stats

La progression normale des statistiques continue.

Boss Rush ne doit pas simplement figer :

```text
piles
main
S
timer
```

Les nouvelles probabilités dirigées continuent à fonctionner normalement.

## Special Rule announcement

Comme plusieurs règles apparaissent à chaque round :

* afficher l'ensemble sur un même écran ;
* ne pas faire une longue animation séparée pour chaque règle.

Exemple :

```text
BOSS ROUND

LIGHTS OUT
+
HOT POTATOES
+
ROMAN HOLIDAY
```

L'écran reste skippable d'un seul clic.

Si une combinaison possède un nom spécial :

```text
TOO HOT TO HANDLE
```

afficher ce nom en priorité, puis les règles composant le combo en plus petit.

## Bonus

Les bonus normaux restent disponibles.

`RULE BREAKER` est particulièrement utile dans Boss Rush et doit conserver son comportement normal.

Ne pas augmenter artificiellement sa probabilité.

## Endless

Dans :

```text
BOSS RUSH - ENDLESS
```

chaque round utilise :

```gdscript
Difficulty.MAX_COMBINED_RULES
```

règles lorsque suffisamment de règles compatibles existent.

Pour créer de la variété :

* éviter les répétitions ;
* privilégier les combinaisons jamais rencontrées récemment ;
* conserver les incompatibilités.

---

# 4. No Looking Back

```text
NO LOOKING BACK
Once you grab it, commit.
```

Identifiant :

```gdscript
&"no_looking_back"
```

## Déblocage

Débloqué après avoir battu :

```text
BLIND DELIVERY
+
STICKY FINGERS
```

dans le même round.

Créer si nécessaire :

```text
NO RETURN
Beat Blind Delivery and Sticky Fingers together.
```

Identifiant :

```gdscript
&"blind_delivery_sticky_fingers"
```

## Concept

Une fois qu'une carte de la main est saisie :

* sa valeur disparaît ;
* elle ne peut plus être volontairement reposée dans la main ;
* elle reste attachée au pointeur jusqu'à ce qu'elle soit jouée ;
* le joueur doit se souvenir de sa valeur et s'engager.

C'est une version permanente et plus propre de :

```text
BLIND DELIVERY
+
STICKY FINGERS
```

## Prise d'une carte

Avant sélection :

```text
[ 4 ]
```

Après sélection :

```text
[   ]
  ↑
hidden
```

Dès que le drag commence :

```gdscript
selected_card.hide_value()
selected_card.lock_to_pointer = true
```

La valeur reste cachée pendant tout le drag.

Elle ne doit pas être révélée par :

* hover ;
* retour sur la zone de main ;
* changement de direction ;
* attente prolongée.

## Placement correct

Placement normal.

La carte est consommée.

Une nouvelle main est générée selon les règles habituelles.

## Placement incorrect

Si la carte est déposée sur une mauvaise pile :

1. déclencher l'erreur normale ;
2. révéler brièvement la valeur comme feedback, si le comportement normal le prévoit ;
3. replacer la carte dans la main uniquement après résolution de l'erreur.

Le verrou `commit` est alors supprimé.

Le joueur peut la sélectionner à nouveau.

## Relâchement dans le vide

Si le joueur relâche dans une zone vide :

* ne pas replacer la carte dans la main ;
* la carte reste attachée au pointeur ;
* aucune erreur ;
* le timer continue.

C'est le comportement Sticky Fingers permanent du challenge.

## Mobile

Le challenge doit rester jouable au tactile.

Une fois la carte sélectionnée :

* le joueur peut conserver le doigt appuyé et glisser normalement.

Si le doigt est relâché dans le vide :

* conserver la carte comme carte active ;
* afficher un léger indicateur visuel ;
* le prochain contact reprend immédiatement le drag de cette même carte.

Ne pas obliger le joueur à maintenir son doigt sur l'écran indéfiniment.

Etat conseillé :

```gdscript
enum CommitState {
    NONE,
    DRAGGING,
    WAITING_FOR_TOUCH,
}
```

Sur desktop :

```text
release in empty space
-> card remains attached to cursor
```

Sur tactile :

```text
release in empty space
-> card remains selected
-> next touch resumes movement
```

## Hot Potatoes

Compatible.

Lorsque Hot Potatoes expire :

* la carte est forcée de revenir dans la main ;
* aucun point de vie perdu ;
* le commit prend fin.

Hot Potatoes reste donc l'une des rares manières de "sauver" une carte engagée.

## The Floor Is Lava

Compatible.

Si la carte touche la lave :

* retour forcé dans la main ;
* pas d'erreur ;
* commit annulé.

## Peek-a-Card

`PEEK-A-CARD` reste compatible.

La carte peut être consultée avant sa sélection.

Dès que le drag réel commence :

* masquer immédiatement la valeur ;
* aucune grace period pendant le drag.

## Blind Delivery

Désactiver :

```text
BLIND DELIVERY
```

Le challenge fournit déjà cet effet.

## Sticky Fingers

Désactiver :

```text
STICKY FINGERS
```

Le challenge fournit déjà cet effet.

## Bring a Friend

Compatible.

Lorsqu'une carte principale est sélectionnée :

* la carte principale devient cachée ;
* les cartes accompagnatrices peuvent conserver leur comportement visuel habituel ;
* une accompagnatrice n'est pas considérée comme manuellement engagée.

Si cela crée trop d'ambiguïté, masquer également les valeurs des accompagnatrices dès qu'elles quittent la main.

Préférer cette seconde option pour la cohérence visuelle :

```text
main card hidden
companions hidden
```

## Double Down / Deja Vu

Compatibles.

Les cartes jouées automatiquement peuvent conserver leur reveal rapide habituel.

Le challenge concerne avant tout la carte choisie manuellement.

## Quick Peek

Quick Peek révèle les piles, mais jamais la valeur de la carte actuellement engagée.

## Endless

Aucun changement particulier.

Le challenge continue avec cette règle permanente pendant toute la run.

---

# Modificateurs supplémentaires

Etendre `ChallengeModifiers` :

```gdscript
class_name ChallengeModifiers
extends RefCounted

var shared_round_clock := false

var conveyor_hand := false
var conveyor_guaranteed_interval := 0

var force_special_rules_every_round := false
var forced_special_rule_count := 0

var commit_selected_cards := false
var hide_selected_card_value := false

var disabled_special_rules: Array[StringName] = []
var disabled_bonuses: Array[StringName] = []
```

Ne pas utiliser des checks du type :

```gdscript
if challenge_id == &"boss_rush":
```

dans les systèmes de gameplay.

Utiliser uniquement les modificateurs.

---

# Registre

Ajouter :

```gdscript
SHARED CLOCK
unlock = speedrun_10_rounds
start = 5
target = 20

CONVEYOR BELT
unlock = free_range_hot_potatoes
start = 5
target = 20

BOSS RUSH
unlock = beat_max_special_rules
start = 5
target = 20

NO LOOKING BACK
unlock = blind_delivery_sticky_fingers
start = 5
target = 20
```

Les valeurs restent configurables.

---

# Achievements de completion

Ajouter :

```text
AGAINST THE CLOCK
Complete Shared Clock.
```

```gdscript
&"complete_shared_clock"
```

```text
EXPRESS DELIVERY
Complete Conveyor Belt.
```

```gdscript
&"complete_conveyor_belt"
```

```text
BOSS SLAYER
Complete Boss Rush.
```

```gdscript
&"complete_boss_rush"
```

```text
COMMITTED
Complete No Looking Back.
```

```gdscript
&"complete_no_looking_back"
```

Ils comptent également pour :

```text
CHALLENGE ACCEPTED
Complete every standard Challenge Run.
```

`CHALLENGE ACCEPTED` doit vérifier dynamiquement tous les challenges activés dans `ChallengeRegistry`, y compris les quatre nouveaux.

---

# Tests

## Shared Clock

Tester :

* un seul timer pour tout le round ;
* changement de main sans reset du timer ;
* timeout retire bien une vie ;
* ajout du temps de secours après timeout ;
* bonus TIME BANK ;
* GRACE PERIOD ;
* Hot Potatoes indépendant ;
* timer suspendu pendant les écrans qui suspendent déjà le jeu.

## Conveyor Belt

Tester :

* déplacement constant ;
* spawn et despawn ;
* pas d'erreur lorsqu'une carte quitte l'écran ;
* garantie après trop de cartes non jouables ;
* direction gauche/droite ;
* Lucky Hand injecté dans les prochains spawns ;
* retour correct après drag annulé ;
* tactile ;
* aucun softlock lorsque plusieurs piles attendent des valeurs différentes.

## Boss Rush

Tester :

* règle spéciale à chaque round ;
* augmentation correcte du nombre de règles ;
* incompatibilités ;
* absence de répétition exacte lorsque possible ;
* comportement au nombre maximal ;
* Endless toujours au maximum ;
* RULE BREAKER ;
* une combinaison impossible ne bloque jamais le round.

## No Looking Back

Tester :

* disparition de la valeur au drag ;
* impossible de déposer volontairement dans la main ;
* Sticky Fingers intégré ;
* reprise tactile après release ;
* erreur normale sur mauvaise pile ;
* Hot Potatoes force le retour ;
* Lava force le retour ;
* Peek-a-Card avant drag ;
* valeur jamais révélée pendant le commit ;
* Blind Delivery et Sticky Fingers exclus du tirage.

---

# Priorité d'implémentation

Implémenter dans cet ordre :

1. `Shared Clock`
2. `Boss Rush`
3. `No Looking Back`
4. `Conveyor Belt`

Les trois premiers réutilisent principalement les systèmes existants et permettent de valider l'architecture des Challenge Modifiers.

`Conveyor Belt` vient ensuite car il nécessite le plus gros changement d'interface et de génération des cartes.

Après chaque challenge :

* ajouter les tests ;
* vérifier desktop ;
* vérifier Web ;
* vérifier tactile ;
* tester avec plusieurs Special Rules compatibles ;
* vérifier sa version Endless avant de passer au suivant.
