# Système de bonus de partie

## Fonctionnement général

Tous les `N` rounds terminés, interrompre brièvement la partie et proposer deux bonus aléatoires.

Valeur de départ recommandée :

```gdscript
const BONUS_INTERVAL := 5
```

Les bonus choisis restent actifs jusqu'à la fin de la partie.

Le joueur sélectionne un seul des deux bonus. L'autre est abandonné.

Les bonus doivent améliorer les chances de survie sans supprimer complètement les mécaniques de mémoire et de rapidité.

## Ecran de sélection

Afficher deux grandes pièces ou cartes côte à côte.

Chaque proposition contient uniquement :

* un nom court ;
* une description d'une ligne ;

Exemple :

```text
OPEN BOOK
One stack stays face up.
```

```text
WILD CARD
Jokers may appear.
```

Le timer du jeu est suspendu pendant le choix.

Après sélection :

1. la carte choisie se soulève ;
2. l'autre s'efface ;
3. le bonus rejoint une petite barre d'icônes ;
4. le round suivant commence.

## Catégories de bonus

Séparer les bonus en quatre catégories :

* mémoire ;
* main ;
* temps ;
* survie.

Le tirage doit essayer de proposer deux bonus de catégories différentes.

# Bonus de mémoire

## Open Book

Une pile reste toujours face visible.

```text
OPEN BOOK
One stack never flips.
```

Au début de chaque round, choisir une pile aléatoire parmi les piles actives.

Sa dernière carte reste visible pendant tout le round.

La pile protégée doit être clairement identifiable avec une petite icône d'oeil ou une légère bordure dorée.

Améliorations possibles :

* niveau 1 : une pile visible ;
* niveau 2 : deux piles visibles ;
* niveau 3 : trois ;

---

## Quick Peek

Toutes les piles sont brièvement révélées au début de chaque nouvelle main.

```text
QUICK PEEK
Stacks flash before each hand.
```

Durées :

* niveau 1 : 0,25 seconde ;
* niveau 2 : 0,4 seconde ;
* niveau 3 : 0,6 seconde.

Le timer ne commence qu'après la fin du flash.

---

## Last Reminder

La dernière pile utilisée reste visible jusqu'à ce qu'une autre pile soit jouée.

```text
LAST REMINDER
Your last stack stays visible.
```

Une seule pile peut bénéficier de cet effet à la fois.

Ce bonus est compatible avec Open Book.

---

## Mistake Reveal

Après une erreur, toutes les piles sont révélées brièvement.

```text
LESSON LEARNED
Mistakes reveal every stack.
```

Le timer de la nouvelle main commence après la révélation.

# Bonus de main

## Wild Card

Chaque nouvelle main possède une chance de contenir un joker.

```text
WILD CARD
Jokers may appear.
```

Le joker peut être placé sur n'importe quelle pile active. Il prend automatiquement la valeur attendue par la pile ciblée.

Probabilités recommandées :

* niveau 1 : 5 % ;
* niveau 2 : 10 % ;
* niveau 3 : 15 %.

Une main ne peut contenir qu'un seul joker.

Un joker non joué reste dans la main et n'est pas remplacé,
il fini donc a gauche des cartes de la main apres le refill de cartes

Sa couleur change et passe par les couleur de toute les autres carte de maniere animé avec des transition smooth

Il porte l'inscription J

Apres avoir recupérer l"amélioratin la prcohaine main a toujours un joker
make 
Un joker ne doit jamais être la carte jouable garantie par le générateur. Il doit être ajouté comme avantage supplémentaire afin de ne pas remplacer systématiquement une vraie solution.

---

## Second Chance

Une fois par round, une nouvelle main peut être générée gratuitement.

```text
REDRAW
Replace one hand per round.
```

Ajouter un petit bouton discret près de la main.

Le nouveau tirage doit lui aussi garantir au moins une carte jouable.

Améliorations :

* niveau 1 : une relance ;
* niveau 2 : deux relances ;
* niveau 3 : une relance par erreur restante.

---

## Lucky Hand

Une main a une chance de contenir que des cartes identiques permetant de faire avancé la pile la plus avancé


```text
LUCKY Hand
Some hands offer answers.
```

Probabilités :

* niveau 1 : 20 % ;
* niveau 2 : 35 % ;
* niveau 3 : 45 %.

---

# Bonus de temps

---

## Time Bank

Le temps inutilisé est partiellement conservé pour la main suivante.

```text
TIME BANK
Save some unused time.
```

Exemple :

* le joueur pose une carte avec 2 secondes restantes ;
* 25 % de ce temps est transféré ;
* la main suivante reçoit 0,5 seconde supplémentaire.

Limiter le bonus accumulé à 2 secondes.

Améliorations :

* niveau 1 : conserve 20 % ;
* niveau 2 : conserve 35 % ;
* niveau 3 : conserve 50 %.


## Slow Start

Les trois premières mains de chaque round disposent de temps supplémentaire.

```text
WARM-UP
Early hands get extra time.

```

* niveau 1 : 3 permier +1 ;
* niveau 2 : 3 premier +2 puis 3 suivant +1;
* niveau 3 : 3 premier +3 puis 3 suivant +2 puis 3 suivant + 1;

Bonus recommandé :

```gdscript
+1.0 seconde
```

Le bonus aide à mémoriser le nouvel emplacement des piles au début du round.

# Bonus de survie

## Spare Life

Ajouter une erreur autorisée par round.

```text
SPARE LIFE
Gain one extra mistake.
```

* niveau 1 : + 1 vie;
* niveau 2 : + 2 vie;
* niveau 3 : + 3 vie;

Visuelmment n'ajoute pas de point de vie mes affiche en rouge les points de vie rendorcé avec un shader pour modifier leur couleur

Avec Sudden Death actif, ce bonus ne doit pas annuler la règle. Deux solutions possibles :

* Sudden Death force toujours une seule erreur ;

La première option est plus cohérente : les règles spéciales doivent pouvoir contrer temporairement les bonus.

---

## Safety Net

La première erreur de chaque round n'est pas comptabilisée.

```text
SAFETY NET
Ignore the first mistake.
```

Afficher l'icône du bonus qui se brise lorsqu'il est consommé.

Le bonus se recharge au début du round suivant.

Permet de survire a une erreur avec sudden death

---

## Clean Slate

Terminer une pile restaure une erreur perdue.

```text
CLEAN SLATE
Finish a stack, recover a mistake.
```

* niveau 1 : marche 1 fois par round;
* niveau 2 : marche 2 fois par round;
* niveau 3 : marche 2 fois par round et met full life a chaque fois;

Ne jamais dépasser le maximum d'erreurs du round.

# Bonus liés aux règles spéciales

## Rule Breaker

Au début d'un round spécial, permettre de supprimer une des règles actives.

```text
RULE BREAKER
Cancel one special rule.
```

Lorsque plusieurs règles sont actives, afficher leurs icônes et laisser le joueur en désactiver une.

Lorsque le round ne contient qu'une règle, le bonus ne fait rien

---

## Adaptation

Après avoir subi une règle spéciale, le joueur reçoit un petit avantage thématique jusqu'à la fin du round.

```text
ADAPTATION
Special rules become slightly easier.
```

Exemples :

* Lights Out : rayon lumineux plus large ;
* Hot Potatoes : temps de drag augmenté ;
* Floor Is Lava : zones légèrement plus petites ;
* Stack Attack : régénération plus lente ;
* Musical Stacks : mouvement plus lent ;
* Blind Delivery : retournement retardé de 0,15 seconde.

Ce bonus doit centraliser les multiplicateurs d'intensité :

```gdscript
special_rule_intensity_multiplier = 0.8
```

* niveau 1 : + ou - 20% d'effet;
* niveau 2 : + ou - 30% d'effet;
* niveau 3 : + ou - 40% d'effet;


# Niveaux et doublons

Lorsqu'un bonus déjà possédé est proposé, le sélectionner augmente son niveau.

Exemple :

```text
WILD CARD II
Joker chance: 10 %
```

Chaque bonus définit :

```gdscript
var max_level: int
var current_level: int
var stackable: bool
```

Si un bonus est déjà à son niveau maximal, il ne doit plus apparaître dans le tirage.

Les bonus non cumulables doivent être retirés du pool après sélection.

# Sélection des deux propositions

Le tirage doit éviter :

* deux bonus identiques ;
* deux bonus déjà au niveau maximal ;
* deux bonus presque équivalents ;
* un bonus inutilisable avec l'état actuel ;
* deux bonus légendaires simultanément, sauf très tard dans la partie.

```gdscript
func generate_bonus_choices() -> Array[BonusData]:
    var first := weighted_pick(get_available_bonuses())
    var second_pool := get_available_bonuses().filter(
        func(candidate: BonusData) -> bool:
            return candidate.id != first.id \
                and candidate.category != first.category
    )

    var second := weighted_pick(second_pool)
    return [first, second]
```

Autoriser exceptionnellement deux bonus de la même catégorie si aucun autre choix valide n'existe.

# Données des bonus

Créer une ressource `BonusData`.

```gdscript
class_name BonusData
extends Resource

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var category: BonusCategory
@export var rarity: BonusRarity
@export var max_level := 1
@export var weight := 1.0
@export var minimum_round := 1
```

Etat du bonus dans la partie :

```gdscript
class_name ActiveBonus
extends RefCounted

var data: BonusData
var level := 1
```

Gestionnaire :

```text
BonusManager.gd
BonusData.gd
BonusSelection.tscn
BonusChoiceCard.tscn
```

`BonusManager` doit :

* détecter les rounds multiples de `N` ;
* suspendre la partie ;
* générer deux choix valides ;
* appliquer ou améliorer le bonus sélectionné ;
* conserver les bonus jusqu'au game over ;
* réinitialiser tous les bonus au début d'une nouvelle partie.

# Ordre entre difficulté, bonus et règles spéciales

Calculer les valeurs d'un round dans cet ordre :

1. valeurs de difficulté permanentes `P`, `M`, `S`, `T` ;
2. bonus permanents de la partie ;
3. règles spéciales temporaires ;
4. effets visuels et paramètres finaux.

Exemple :

```gdscript
var effective_time := difficulty_time
effective_time += bonus_manager.get_extra_time()
effective_time *= special_rule_manager.get_time_multiplier()
```

Les règles spéciales doivent généralement avoir priorité sur les bonus.

Exemples :

* Sudden Death conserve une seule erreur malgré Spare Life ;
* Colorblind rend les bordures grises malgré un bonus de couleur ;
* Blind Delivery cache une carte même si Open Book agit sur les piles ;
* Pile Up inverse toujours le sens de progression ;
* Grace Period masque le timer même si Extra Second augmente sa durée.

# Valeurs recommandées

```gdscript
const BONUS_INTERVAL := 5
const CHOICE_COUNT := 2
const MAX_ACTIVE_BONUS_TYPES := 8
```

Ne pas limiter trop vite le nombre total de bonus. Le système doit donner la sensation que le joueur construit progressivement une combinaison puissante.

Après avoir atteint la limite de types différents, les propositions ne contiennent plus que :

* des améliorations de bonus déjà possédés ;
* ou un remplacement volontaire d'un ancien bonus, si cette mécanique est ajoutée plus tard.
#!/bin/bash
