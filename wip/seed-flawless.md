# Codex - Ajout des seeds et du système Flawless

Implémenter deux nouveaux systèmes dans Pile Down :

1. un système de seed déterministe pour toutes les sources d'aléatoire ;
2. un système `FLAWLESS` donnant davantage de choix de bonus lorsque le joueur n'a subi aucune vraie erreur depuis le dernier choix de bonus.

Ces fonctionnalités doivent s'intégrer aux systèmes existants :

* Classic
* Checkpoints
* Endless
* Challenge Runs
* Special Rules
* BonusManager
* Difficulty
* progression/highscores
* sauvegarde `user://pile_down.cfg`

Ne pas dupliquer le gameplay pour les modes spéciaux.

# 1. Seed de run

Chaque run doit posséder un seed.

Le seed doit déterminer tout l'aléatoire influençant le gameplay.

Deux runs ayant :

* le même seed ;
* le même mode ;
* le même challenge éventuel ;
* les mêmes choix du joueur ;

doivent produire exactement les mêmes événements aléatoires.

## RunRNG

Créer :

```gdscript
class_name RunRNG
extends RefCounted
```

API minimale :

```gdscript
var seed_value: int
var seed_label: String
var streams: Dictionary[StringName, RandomNumberGenerator]

func initialize(value: int, label: String = "") -> void:
	pass

func get_stream(stream_id: StringName) -> RandomNumberGenerator:
	pass
```

# 2. Streams RNG séparés

Ne surtout pas utiliser un unique `RandomNumberGenerator` pour tout.

Créer au minimum les streams :

```gdscript
&"difficulty"
&"hands"
&"bonuses"
&"special_rules"
&"movement"
&"challenge"
&"cosmetic"
```

Chaque stream doit avoir un seed dérivé du seed principal.

Exemple :

```gdscript
func get_stream(stream_id: StringName) -> RandomNumberGenerator:
	if streams.has(stream_id):
		return streams[stream_id]

	var rng := RandomNumberGenerator.new()
	rng.seed = derive_stream_seed(seed_value, stream_id)

	streams[stream_id] = rng
	return rng
```

La fonction `derive_stream_seed()` doit être déterministe.

Le même :

```text
seed principal + stream_id
```

doit toujours donner le même seed secondaire.

## Pourquoi

Une modification cosmétique ne doit jamais modifier les mains futures.

Par exemple :

```text
ajout d'une particule aléatoire
```

ne doit pas changer :

```text
la prochaine main
la prochaine Special Rule
le prochain Bonus
```

# 3. Remplacer toutes les sources d'aléatoire gameplay

Inspecter le projet entier et remplacer les usages gameplay de :

```gdscript
randf()
randf_range()
randi()
randi_range()
pick_random()
shuffle()
randomize()
```

par le stream adapté.

Inclure notamment :

## Difficulty

```gdscript
RunRNG.get_stream(&"difficulty")
```

pour :

* augmentation de piles ;
* augmentation de main ;
* valeur de départ ;
* timer ;
* système de pity/drought ;
* tout choix de progression dirigé.

## Hands

```gdscript
RunRNG.get_stream(&"hands")
```

pour :

* génération des cartes ;
* carte jouable garantie ;
* jokers ;
* Lucky Hand ;
* Redraw ;
* Reload Required ;
* Conveyor Belt.

## Bonuses

```gdscript
RunRNG.get_stream(&"bonuses")
```

pour :

* choix des bonus proposés ;
* remplacement des bonus maxés ;
* tout choix aléatoire du système de bonus.

## Special Rules

```gdscript
RunRNG.get_stream(&"special_rules")
```

pour :

* sélection des règles ;
* choix des combinaisons ;
* poids ;
* variante d'une règle.

## Movement

```gdscript
RunRNG.get_stream(&"movement")
```

pour :

* direction Merry-Go-Stack ;
* patterns ;
* Shell Game ;
* choix des piles mobiles ;
* phases aléatoires ;
* Wavy Baby si nécessaire ;
* Shaking Piles ;
* sens Conveyor Belt.

## Challenge

```gdscript
RunRNG.get_stream(&"challenge")
```

uniquement pour des décisions spécifiques aux challenges qui ne relèvent pas directement d'un autre système.

## Cosmetic

```gdscript
RunRNG.get_stream(&"cosmetic")
```

pour :

* poussière ;
* petites variations visuelles ;
* VFX ;
* variations purement décoratives.

# 4. Seed généré automatiquement

Une nouvelle run classique utilise par défaut un nouveau seed aléatoire 64 bits.

Créer :

```gdscript
func generate_run_seed() -> int:
	pass
```

Le seed doit rester fixe pendant toute la run.

Ne jamais appeler `randomize()` en cours de partie.

# 5. Seed texte

Permettre au joueur d'entrer aussi bien :

```text
739572984
```

que :

```text
PILE-DOWN
```

ou :

```text
hello-world
```

Conserver deux valeurs :

```gdscript
var seed_label: String
var seed_value: int
```

Si l'entrée est un entier valide :

```gdscript
seed_value = parsed_integer
seed_label = original_text
```

Sinon utiliser un hash déterministe 64 bits.

Ne pas utiliser une fonction dont le résultat peut varier entre plateformes ou versions.

Créer une fonction dédiée :

```gdscript
func seed_string_to_int(text: String) -> int:
	pass
```

Même texte -> même entier sur :

* Linux
* Windows
* Web
* Android.

# 6. Seed dans le menu Escape

Pendant une run, afficher dans le menu Pause/Escape :

```text
SEED
PILE-DOWN-49382
```

ou :

```text
SEED
739572984
```

Ajouter un bouton :

```text
COPY
```

qui copie le seed dans le presse-papier si la plateforme le supporte.

Le seed doit rester accessible pendant :

* Classic ;
* Checkpoint ;
* Endless ;
* Challenge Run ;
* Challenge Endless.

# 7. Play a Seed

Dans l'onglet `CHALLENGES`, ajouter une section :

```text
PLAY A SEED
```

Elle permet de saisir :

```text
SEED
[________________]
```

puis de choisir :

```text
MODE
CLASSIC
```

ou un Challenge débloqué.

Exemples :

```text
CLASSIC
RELOAD REQUIRED
ONE SHOT
POOL PARTY
TRUE COLORS
SHARED CLOCK
CONVEYOR BELT
BOSS RUSH
NO LOOKING BACK
```

Un challenge verrouillé ne peut jamais être lancé simplement parce que son seed est connu.

Ajouter :

```text
PLAY
RANDOM SEED
```

`RANDOM SEED` génère un nouveau seed et remplit le champ.

# 8. Retry Seed

Sur l'écran de mort ou de victoire, ajouter :

```text
RETRY SEED
```

Cette action relance exactement :

```text
même seed
même mode
même challenge
```

Tous les streams RNG doivent être complètement réinitialisés.

Ne pas réutiliser leur état courant.

# 9. Seed et Checkpoints

Une run démarrée depuis un checkpoint possède également un seed.

Le checkpoint détermine :

```text
état de difficulté initial
round initial
droughts initiaux
```

Le seed détermine ensuite l'aléatoire à partir du lancement de cette run.

Ne pas essayer de reproduire la run historique ayant permis de débloquer le checkpoint.

# 10. Seed dans les highscores

Lorsque cela est pertinent, sauvegarder le seed associé au record.

Exemple :

```gdscript
{
	"round": 73,
	"time": 1523.4,
	"seed": 739572984,
	"seed_label": "PILE-DOWN"
}
```

Ajouter aux records de :

* Classic ;
* Classic no mistake ;
* Endless ;
* Challenges ;
* Challenge Endless.

Pour les checkpoints, continuer de ne pas enregistrer le temps, mais conserver le seed du record.

# 11. Flawless

Ajouter un système global :

```text
FLAWLESS
```

Flawless n'est pas un bonus du pool.

C'est une récompense automatique.

Le principe :

```text
aucune vraie erreur depuis le dernier choix de bonus
->
plus de bonus proposés au prochain écran
```

Le joueur choisit toujours un seul bonus.

# 12. Configuration

Ajouter dans `difficulty.gd` :

```gdscript
const BONUS_CHOICE_COUNT := 2
const FLAWLESS_BONUS_CHOICE_COUNT := 3
const ENABLE_FLAWLESS_BONUS_CHOICE := true
```

Ne pas coder directement `2` ou `3` dans `BonusManager`.

# 13. Etat Flawless

Ajouter dans l'état de run :

```gdscript
var flawless_since_last_bonus := true
```

Après chaque sélection normale de bonus :

```gdscript
flawless_since_last_bonus = true
```

Lorsqu'une vraie erreur est commise :

```gdscript
flawless_since_last_bonus = false
```

# 14. Ecran de bonus

Lorsqu'un bonus doit être proposé :

```gdscript
var choice_count := Difficulty.BONUS_CHOICE_COUNT

if Difficulty.ENABLE_FLAWLESS_BONUS_CHOICE \
and flawless_since_last_bonus:
	choice_count = Difficulty.FLAWLESS_BONUS_CHOICE_COUNT
```

Exemple standard :

```text
CHOOSE A BONUS

[ BONUS A ]
[ BONUS B ]
```

Flawless :

```text
FLAWLESS!

[ BONUS A ]
[ BONUS B ]
[ BONUS C ]
```

Le joueur n'en choisit toujours qu'un.

Après sélection :

```gdscript
flawless_since_last_bonus = true
```

Le cycle recommence immédiatement.

# 15. Définition d'une vraie erreur

Ne pas utiliser simplement :

```gdscript
lives_lost > 0
```

Il faut distinguer :

```text
erreur de gameplay
```

et :

```text
événement non punitif
```

Créer ou réutiliser un système central d'erreurs.

Exemple :

```gdscript
enum DamageType {
	WRONG_PLACEMENT,
	TIMER_TIMEOUT,
	SUDDEN_DEATH,

	HOT_POTATO_RETURN,
	LAVA_RETURN,
	EMPTY_DROP,
	CONVEYOR_MISSED_CARD,
	RELOAD
}
```

Créer :

```gdscript
func breaks_flawless(damage_type: DamageType) -> bool:
	match damage_type:
		DamageType.WRONG_PLACEMENT:
			return true

		DamageType.TIMER_TIMEOUT:
			return true

		DamageType.SUDDEN_DEATH:
			return true

		_:
			return false
```

# 16. Safety Net

Une erreur absorbée par `SAFETY NET` casse quand même Flawless.

Exemple :

```text
wrong placement
->
Safety Net absorbe
->
aucune vie réellement perdue
->
FLAWLESS perdu quand même
```

C'est volontaire.

Flawless signifie :

```text
aucune vraie erreur
```

et pas :

```text
aucune vie perdue
```

# 17. Spare Life

Le fait de posséder des vies supplémentaires ne change rien.

Une erreur qui retire une vie casse Flawless.

# 18. Evénements qui ne cassent pas Flawless

Ne pas casser Flawless pour :

* Hot Potatoes timeout ;
* retour provoqué par Floor Is Lava ;
* carte relâchée dans le vide sans erreur ;
* Reload dans Reload Required ;
* carte Conveyor Belt quittant l'écran ;
* retour forcé explicitement non punitif ;
* déplacement annulé sans erreur.

# 19. Shared Clock

Dans `SHARED CLOCK` :

```text
timer global atteint 0
->
vraie erreur
->
Flawless perdu
```

# 20. One Shot

Dans `ONE SHOT`, toute vraie erreur termine déjà la run.

Donc tout écran de bonus atteint naturellement sans mourir est Flawless.

Ne pas ajouter de logique spéciale supplémentaire.

# 21. Checkpoints

Lorsqu'une run commence depuis un checkpoint, elle peut recevoir plusieurs choix de bonus initiaux.

Ces choix gratuits de départ ne doivent pas utiliser Flawless.

Ils utilisent toujours :

```gdscript
Difficulty.BONUS_CHOICE_COUNT
```

Exemple :

```text
Checkpoint donne 4 bonus de départ

Bonus 1 -> 2 choix
Bonus 2 -> 2 choix
Bonus 3 -> 2 choix
Bonus 4 -> 2 choix

Gameplay commence

flawless_since_last_bonus = true
```

Après le début du gameplay, Flawless fonctionne normalement.

# 22. Feedback Flawless

Lorsqu'un écran Flawless est obtenu, afficher brièvement :

```text
FLAWLESS!
+1 BONUS CHOICE
```

Puis afficher les cartes.

L'animation doit être :

* courte ;
* skippable ;
* cohérente avec les autres annonces.

Ne pas afficher une longue animation à chaque fois.

# 23. HUD

Par défaut, ne pas ajouter de texte permanent supplémentaire.

Option recommandée :

afficher un petit symbole discret indiquant que Flawless est toujours actif.

Exemple :

```text
◆
```

Lorsque le joueur fait une erreur :

```text
◆ disparaît
```

Lorsqu'un nouveau cycle commence après un choix de bonus :

```text
◆ réapparaît
```

Ajouter une constante permettant de désactiver cet indicateur :

```gdscript
const SHOW_FLAWLESS_HUD_INDICATOR := true
```

# 24. Interaction avec BonusManager

Adapter la génération des propositions pour supporter un nombre variable de choix :

```gdscript
func generate_bonus_choices(count: int) -> Array[StringName]:
	pass
```

Le système doit respecter :

* bonus déjà maxés ;
* bonus désactivés ;
* restrictions Challenge ;
* absence de doublons dans un même écran ;
* nombre insuffisant de bonus disponibles.

Si seulement deux bonus sont disponibles alors que Flawless en demande trois :

```text
afficher seulement les deux disponibles
```

Ne jamais générer un doublon artificiel.

# 25. Seed et Flawless

Le nombre de choix de bonus fait partie des décisions déterministes.

Avec le même seed :

```text
run A : flawless
run B : flawless
```

doivent proposer les mêmes trois bonus.

Mais :

```text
run A : flawless
run B : erreur avant bonus
```

peuvent naturellement diverger ensuite puisque le joueur n'a pas consommé le même nombre de résultats du système de bonus.

Pour limiter les divergences artificielles, `BonusManager` doit utiliser uniquement le stream :

```gdscript
&"bonuses"
```

# 26. Sauvegarde

Ajouter si nécessaire au schéma :

```text
save/schema_version
```

Le seed d'une run active n'a besoin d'être sauvegardé que si le jeu supporte déjà la reprise d'une partie interrompue.

Les highscores doivent conserver leur seed.

Ne pas sauvegarder `flawless_since_last_bonus` entre différentes runs.

# 27. Debug

Ajouter dans `debug.gd` :

```gdscript
const FORCE_RUN_SEED := ""
const FORCE_FLAWLESS := false
const DISABLE_FLAWLESS := false
```

`FORCE_RUN_SEED` vide :

```text
seed normal
```

Exemple :

```gdscript
const FORCE_RUN_SEED := "TEST-SEED"
```

doit forcer toutes les nouvelles runs debug à utiliser cette valeur.

`FORCE_FLAWLESS` permet de tester les écrans à 3 choix.

Il ne doit pas modifier une sauvegarde permanente.

# 28. Tests seed

Ajouter des tests automatisés.

## Même seed

Deux simulations identiques avec le même seed doivent produire :

```text
mêmes progressions de stats
mêmes mains
mêmes Bonus Choices
mêmes Special Rules
mêmes variantes de déplacement
```

## Streams indépendants

Test critique :

```text
Run A
-> seed X
-> génération main

Run B
-> seed X
-> consommer 100 valeurs du stream cosmetic
-> génération main
```

La main doit être identique.

Même test pour :

```text
special_rules
bonuses
difficulty
```

## Retry

Tester :

```text
run
-> mourir
-> Retry Seed
```

Les premières séquences doivent être strictement identiques.

## Texte

Tester :

```text
PILE-DOWN
```

sur plusieurs appels.

Le `seed_value` doit toujours être identique.

# 29. Tests Flawless

Tester :

## Cas normal

```text
aucune erreur
-> bonus
-> 3 choix
```

## Mauvaise carte

```text
wrong placement
-> bonus
-> 2 choix
```

## Safety Net

```text
wrong placement
-> Safety Net
-> bonus
-> 2 choix
```

## Hot Potatoes

```text
Hot Potatoes timeout
-> bonus
-> 3 choix
```

## Lava

```text
Floor Is Lava return
-> bonus
-> 3 choix
```

## Nouveau cycle

```text
erreur
-> bonus à 2
-> sélectionner
-> flawless reset
-> aucun dommage
-> bonus suivant à 3
```

## Checkpoint

Les bonus initiaux du checkpoint restent à :

```text
2 choix
```

puis Flawless est activé pour le gameplay.

# 30. Ordre d'implémentation

Procéder dans cet ordre :

1. créer `RunRNG` ;
2. créer les streams séparés ;
3. migrer tout le gameplay vers `RunRNG` ;
4. ajouter les tests de reproductibilité ;
5. afficher le seed dans Escape ;
6. ajouter `PLAY A SEED` ;
7. ajouter `RETRY SEED` ;
8. sauvegarder les seeds des highscores ;
9. centraliser la notion de vraie erreur ;
10. ajouter l'état Flawless ;
11. rendre `BonusManager` compatible avec un nombre variable de choix ;
12. ajouter l'interface Flawless ;
13. gérer Checkpoints et Challenges ;
14. ajouter les tests Flawless ;
15. documenter les nouveaux systèmes dans le README.

Ne pas considérer l'implémentation terminée tant qu'un même seed ne permet pas de reproduire réellement une run sur deux lancements séparés.
