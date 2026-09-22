# Audit fonctionnel de Pile Down

Audit du 20 septembre 2026, mis à jour après corrections. Les six défauts sont corrigés et validés par les tests ciblés. Les symptômes et fréquences ci-dessous décrivent les reproductions initiales.

| ID | Sévérité | Système | Résumé | Reproductibilité | Statut |
|---|---|---|---|---|---|
| BUG-001 | High | Restart / vies | Une ancienne séquence de mort termine la nouvelle partie | 3/3 | Corrigé et validé (tests ciblés) |
| BUG-002 | High | Seeds / règles | Restart au round 4 change la règle tirée pour la même seed | 3/3, deux seeds | Corrigé et validé (tests ciblés) |
| BUG-003 | Medium | Seed / endless | La difficulté personnalisée disparaît au passage en endless | 3/3 | Corrigé et validé (tests ciblés) |
| BUG-004 | Medium | Sauvegardes | L’import accepte un type invalide qui provoque une erreur au chargement | 3/3 imports | Corrigé et validé (tests ciblés) |
| BUG-005 | Low | Entrées / Mirror Match | Le test de position du bouton retour utilise un rectangle négatif | 3/3 ciblés + test existant | Corrigé et validé (tests ciblés) |
| BUG-006 | Low | Bonus / annulation | Une présentation Flawless annulée réapparaît | 3/3 sur composant ; 0/3 via restart | Corrigé et validé (tests ciblés) |

Les fréquences décrivent uniquement les essais effectués, pas une estimation statistique sur toutes les parties. Aucun crash natif ni perte de sauvegarde réelle n’a été observé. Les sauvegardes du joueur n’ont pas été utilisées.

## Méthode et architecture examinée

- Environnement : Windows, Godot **4.7.2 stable**, mode `--headless`, profils `APPDATA`/XDG séparés sous `.godot/audit-profiles/`. Aucun autoload déclaré dans `project.godot`.
- Entrée : `resources/scenes/Main.tscn`, qui contient `Game.tscn`. Le jeu reste dans cette scène ; menu, plateau, choix de bonus, annonces et résultats sont des couches de contrôles.
- Orchestration : `GameManager`, `GameSessionController`, `RoundFlowController`. Main/cartes/piles : `HandManager`, `Card`, `Pile`, contrôleurs de placement et de déplacement. Horloge : `TimerManager`.
- Difficulté : compte à rebours de 30 rounds en classique, progression croissante en endless, paliers et checkpoints. Les bonus sont proposés tous les quatre rounds ; les checkpoints arrivent tous les cinq rounds. Flawless ajoute un choix.
- Règles et défis : `SpecialRuleManager`, `ChallengeManager` et ressources des catalogues. La seed fournit des flux RNG séparés pour difficulté, mains, bonus, règles, mouvement, défis et cosmétiques.
- Persistance : `SaveConfig`, `RunRecordStore`, achievements, checkpoints, options et `SaveDataManager`. Présentation : options d’affichage, fonds, palettes, menus, transitions et entrées souris/tactiles/clavier.

Les scripts d’instrumentation ajoutés sont exclusivement dans `tests/audit/` : [functional_probe.gd](tests/audit/functional_probe.gd) et [run_audit.py](tests/audit/run_audit.py). Ils appellent les gestionnaires et signaux du jeu. Les injections d’état sont explicites : dernière vie, tableau terminé, victoire, choix de bonus ou configuration maximale. Une fin injectée valide la transition, **pas** la jouabilité de tout le round précédent.

Les preuves sont conservées dans [results.json](tests/audit/results.json) : sorties console, observations, paramètres, durées et erreurs. `completed` signifie que le scénario a atteint sa fin, **pas** que toutes ses observations sont conformes. Les observations munies de `matches: false` signalent les écarts à examiner.

Exemple de reproduction, avec `godot` dans le PATH ou son chemin fourni à `--godot` :

```powershell
python tests/audit/run_audit.py --godot godot --report .godot/audit-reproduction.json race:damage_restart seed_rule_restart:AUDIT-SEED-A seed_input save:import_wrong_types touch_mirror bonus_cancel
```

## BUG-001 - Game over provenant de la partie précédente après restart

**Sévérité :** High  
**Reproductibilité :** 3/3  
**Seed :** `AUDIT-RACE`  
**Challenge :** classique  
**Configuration :** Windows, headless, fenêtre demandée 512 × 640.

### Symptôme

Un restart lancé pendant la mort recrée un plateau et remet trois vies, mais la séquence précédente affiche ensuite l’écran de défaite. État constaté : `lives=3`, `overlay=true`, `locked=true`, aucune carte active et un compteur de 30 rounds restants. La nouvelle partie est interrompue avant de pouvoir être jouée.

### Comportement attendu

Les traitements de la partie abandonnée ne doivent plus modifier la partie redémarrée.

### Étapes de reproduction

1. Démarrer la seed indiquée et arriver à une vie, sans protection Safety Net disponible.
2. Provoquer une erreur fatale.
3. Ouvrir le menu et déclencher restart pendant l’animation de dégâts.
4. Attendre la fin du restart, puis environ 1,2 seconde.

Le scénario `race:damage_restart` injecte la dernière vie et déclenche le restart 20 ms après les dégâts. Il utilise les gestionnaires des actions ; la séquence de touches physiques n’a pas été rejouée manuellement.

### Fréquence

3 échecs sur 3. Le parcours dégâts → retour menu → nouvelle partie a fonctionné dans l’essai séparé.

### Cause probable

Cause étayée par le code : `handle_mistake()` attend plusieurs animations puis appelle `_finish_game()` sans vérifier si la génération de partie a changé. Le restart invalide des générations, mais cette coroutine ne les contrôle pas.

### Fichiers / systèmes probablement concernés

- `resources/scripts/gameplay/interaction/CardPlacementController.gd`, `handle_mistake()`.
- `resources/scripts/core/session/GameSessionController.gd`, `restart_current_mode()`.

### Piste de correction

Capturer la génération de partie et vérifier sa validité après les attentes de la résolution de dégâts, avant toute modification ou fin de partie.

### Statut

**Corrigé et validé par tests ciblés.** La résolution de dégâts vérifie la génération de partie après les attentes. Le restart fatal est revalidé. Validation précédente : [fix-001.json](tests/audit/fix-001.json). Preuves : [fix-validation.json](tests/audit/fix-validation.json).

## BUG-002 - Une seed rejouée change de règle spéciale

**Sévérité :** High  
**Reproductibilité :** 3/3  
**Seeds :** `AUDIT-SEED-A`, `AUDIT-SEED-B`  
**Challenge :** classique  
**Configuration :** même processus et mêmes paramètres entre les deux parties.

### Symptôme

Après avoir atteint le round 4 puis redémarré, les mêmes actions avec la même seed conduisent à une autre règle :

| Seed | Premier round 4 | Round 4 après restart |
|---|---|---|
| AUDIT-SEED-A | `sticky_fingers` | `musical_stacks` |
| AUDIT-SEED-B | `pile_up` | `lights_out` |

Pour B, la première main observée passe également de `[2, 1]` à `[1, 2]`. La difficulté de base reste identique.

### Comportement attendu

La seed et les mêmes décisions doivent reproduire les mêmes tirages de gameplay, indépendamment de la partie précédente.

### Étapes de reproduction

1. Lancer l’une des seeds sur un profil neuf.
2. Jouer les trois premiers rounds et noter la règle du quatrième.
3. Redémarrer dès le quatrième round, avant de le terminer.
4. Rejouer les trois premiers rounds et comparer la règle.

Scénario : `seed_rule_restart:<seed>`. Les cartes sont effectivement déposées par les gestionnaires de drag-and-drop ; les rounds ne sont pas déclarés terminés artificiellement.

### Fréquence

2/2 pour A et 1/1 pour B. Des replays démarrés plus tard peuvent produire les mêmes signatures : le défaut dépend de l’historique conservé, il ne change pas systématiquement chaque replay.

### Cause probable

Cause confirmée par la lecture : `set_run_rng()` remplace les flux mais ne réinitialise pas `_previous_drawn_rule_ids` ni `_last_special_rule_round`. La sélection évite les règles précédemment tirées ; ce passé appartient encore à la partie abandonnée.

### Fichiers / systèmes probablement concernés

- `resources/scripts/special_rules/SpecialRuleManager.gd`, initialisation et `select_special_rules()`.
- `resources/scripts/core/session/GameSessionController.gd`, début de partie.

### Piste de correction

Réinitialiser l’historique des règles au début d’une nouvelle run, sans effacer cet historique entre deux rounds d’une même run.

### Statut

**Corrigé et validé par tests ciblés.** Le changement des flux RNG réinitialise les deux champs d’historique des règles. Les replays des seeds AUDIT-SEED-A et AUDIT-SEED-B reproduisent leurs signatures attendues. Preuves : [fix-validation.json](tests/audit/fix-validation.json).

## BUG-003 - Difficulté personnalisée perdue en endless

**Sévérité :** Medium  
**Reproductibilité :** 3/3  
**Seed :** `AUDIT-CUSTOM`  
**Challenge :** classique vers endless  
**Configuration :** 2 piles, main de 2, valeur initiale 2, temps de 4 secondes.

### Symptôme

Après le bouton endless, `run_seed_difficulty` vaut `{}`. La seed est conservée, mais ses réglages de difficulté sont abandonnés.

### Comportement attendu

Le replay en endless doit conserver les paramètres de la seed personnalisée, comme le font déjà le restart et les paramètres de bonus/règles.

### Étapes de reproduction

1. Démarrer une seed avec les paramètres ci-dessus.
2. Atteindre l’écran de victoire.
3. Appuyer sur endless et comparer les paramètres de départ.

Le scénario `seed_input` injecte l’appel de victoire pour tester cette transition ; il ne joue pas 30 rounds pour chaque répétition.

### Fréquence

3/3 transitions ciblées.

### Cause probable

Cause confirmée : `_on_overlay_endless_pressed()` transmet seed, bonus et règles à `start_game()`, mais omet le dernier argument `run_seed_difficulty` dans ses deux branches.

### Fichiers / systèmes probablement concernés

- `resources/scripts/core/GameManager.gd`, `_on_overlay_endless_pressed()`.
- `resources/scripts/core/session/GameSessionController.gd`, paramètres de `start_game()`.

### Piste de correction

Transmettre une copie de la difficulté personnalisée et vérifier également le chemin challenge → endless. Cette dernière variante avec difficulté personnalisée n’a pas été reproduite séparément.

### Statut

**Corrigé et validé par tests ciblés.** Les deux branches du bouton endless transmettent une copie de la difficulté personnalisée. Les transitions depuis le classique et depuis un challenge conservent ces paramètres. Les victoires sont injectées pour tester les transitions. Preuves : [fix-validation.json](tests/audit/fix-validation.json).

## BUG-004 - Import accepté malgré une structure interne invalide

**Sévérité :** Medium  
**Reproductibilité :** 3/3 imports, plus 1 chargement direct  
**Seed / challenge :** sans objet  
**Configuration :** sauvegarde de test isolée.

### Symptôme

Un export au format reconnu, avec `challenges.highscores = "not a dictionary"`, est accepté avec le code `OK`. Au chargement suivant :

```text
Trying to assign value of type 'String' to a variable of type 'Dictionary'.
ChallengeManager.load_progress
```

Le menu apparaît encore ; un blocage total du jeu ou une destruction de progression réelle n’ont pas été observés. Le chargement des données de challenge est interrompu à cette affectation.

### Comportement attendu

Refuser les données incompatibles avant de remplacer la sauvegarde, ou les traiter explicitement au chargement avec une récupération contrôlée.

### Étapes de reproduction

1. Dans un profil de test, construire un JSON `pile-down-save`, version 1, avec des sections encodées via `JSON.from_native()`.
2. Mettre une chaîne à la place du dictionnaire `challenges.highscores`.
3. Importer ce fichier, puis charger la scène principale.

Scénario : `save:import_wrong_types`. `save:wrong_types` teste directement le ConfigFile équivalent.

### Fréquence

3/3 imports retournent `OK` puis déclenchent l’erreur ; 1/1 chargement direct déclenche la même erreur.

### Cause probable

Cause confirmée : l’import valide les enveloppes et dictionnaires de sections, mais pas le type de chaque valeur. Le lecteur de challenges assigne ensuite la valeur à un `Dictionary` typé sans validation.

### Fichiers / systèmes probablement concernés

- `resources/scripts/settings/SaveDataManager.gd`, `import_json()`.
- `resources/scripts/challenges/ChallengeManager.gd`, `load_progress()`.

### Piste de correction

Valider les types et plages des champs connus avant remplacement, et rendre les chargeurs tolérants aux données anciennes ou invalides. Conserver la sauvegarde précédente si la validation échoue.

### Statut

**Corrigé et validé par tests ciblés.** L’import refuse les structures et valeurs invalides des champs connus de challenges avant toute écriture. Le chargeur ignore les champs invalides sans erreur de script. Le refus conserve la sauvegarde précédente ; les données valides et les seeds signées restent compatibles. Cette validation concerne les challenges, pas un schéma exhaustif de toutes les sections de sauvegarde. Preuves : [fix-validation.json](tests/audit/fix-validation.json).

## BUG-005 - Rectangle négatif dans les entrées de Mirror Match

**Sévérité :** Low  
**Reproductibilité :** 3/3 ciblés et test existant  
**Seed :** `AUDIT-MIRROR` ; le défaut dépend de la transformation  
**Challenge :** classique avec miroir vertical injecté  
**Configuration :** entrées tactiles synthétiques.

### Symptôme

Le contrôle global du bouton retour émet `Rect2 size is negative`. Une pression au centre visuel du bouton renvoie `false` dans `_is_gameplay_back_pointer_event()`. Le survol utilise le même type de calcul.

Le test tactile existant finit néanmoins avec ses assertions satisfaites. Le chemin GUI propre au bouton peut prendre le relais : il n’est donc **pas établi** que le bouton soit totalement inutilisable avec un vrai périphérique.

### Comportement attendu

Le miroir ne doit ni générer d’erreur sur les entrées ni invalider la détection du centre visuel du bouton.

### Étapes de reproduction

1. Lancer une partie.
2. Appliquer le miroir vertical via `MirrorMatchRuleController`.
3. Envoyer une pression tactile au centre transformé du bouton retour.
4. Examiner le retour du détecteur et la console.

Scénario : `touch_mirror`. Reproduction indépendante existante : `test_touch_drag.gd`.

### Fréquence

3/3 scénarios ciblés ; même erreur dans 1/1 exécution de la suite existante.

### Cause probable

Cause confirmée : `get_global_rect().has_point()` est appelé sur un contrôle dont l’échelle héritée est négative. Les autres éléments de gameplay utilisent déjà des rectangles normalisés ou des coordonnées locales.

### Fichiers / systèmes probablement concernés

- `resources/scripts/core/GameManager.gd`, `_is_button_pointer_press()` et fonctions de survol du bouton retour.
- `resources/scripts/special_rules/rules/MirrorMatchRuleController.gd`.

### Piste de correction

Tester le point dans l’espace local du bouton, ou normaliser le rectangle si les transformations prises en charge le permettent. Revalider souris et tactile avec le routage GUI complet.

### Statut

**Corrigé et validé par tests ciblés.** La pression et le survol utilisent les coordonnées locales du bouton. Sous miroir, le centre est détecté en souris et tactile synthétiques, un point extérieur est rejeté et le popup s’ouvre. Le test test_touch_drag passe sans erreur de rectangle. Les périphériques physiques restent à vérifier. Preuve complémentaire : [fix-mirror-input.json](tests/audit/fix-mirror-input.json). Preuves : [fix-validation.json](tests/audit/fix-validation.json).

## BUG-006 - Une présentation Flawless annulée redevient visible

**Sévérité :** Low  
**Reproductibilité :** 3/3 au niveau composant  
**Seed / challenge :** sans objet  
**Configuration :** annulation 40 ms après `present(..., true)`.

### Symptôme

Le panneau de bonus réapparaît après l’annulation alors que `_presentation_mode` reste à zéro. Le bouton skip ne peut plus traiter cet état normalement. Il s’agit d’un contrat d’annulation incorrect du composant.

### Comportement attendu

Une présentation annulée reste masquée et ses traitements différés cessent.

### Étapes de reproduction

1. Appeler `BonusSelection.present()` avec trois choix et Flawless activé.
2. Après 40 ms, appeler `cancel()`.
3. Attendre 650 ms et vérifier visibilité et mode.

Scénario : `bonus_cancel`. **Limite importante :** les trois essais `bonus_integration` utilisant le restart complet pendant Flawless n’ont pas reproduit cette réapparition. La durée du masque de transition décale l’annulation réelle. Aucun softlock joueur n’est revendiqué ici.

### Fréquence

Composant : 3/3. Intégration par restart : 0/3.

### Cause probable

Cause confirmée : `present()` attend `_show_flawless_feedback()` sans recontrôler la génération après cette attente, puis remet `visible=true`. `cancel()` a déjà changé la génération, remis le mode à zéro et émis le signal d’annulation.

### Fichiers / systèmes probablement concernés

- `resources/scripts/bonuses/BonusSelection.gd`, `present()` et `cancel()`.

### Piste de correction

Vérifier la génération après le feedback et interrompre la présentation annulée. Ajouter une reproduction par un parcours joueur accessible avant d’augmenter la sévérité.

### Statut

**Corrigé et validé par tests ciblés.** La présentation vérifie sa génération après le feedback Flawless et retourne -1 après annulation. Le panneau reste masqué et son mode reste nul ; le restart intégré reste conforme. Le parcours joueur reproduisant le défaut initial reste à établir. Preuves : [fix-validation.json](tests/audit/fix-validation.json).

## Qualification des tests existants

Résultat historique avant corrections : **38/52 réussis, 14 en échec**. La suite complète n’a pas été relancée. Les cinq tests ciblés (sauvegarde, tactile, replay de seed, erreurs et endless) passent : [fix-regressions.json](tests/audit/fix-regressions.json). Un échec de test n’est pas automatiquement un bug du jeu.

| Test en échec | Qualification |
|---|---|
| `test_touch_drag` | Corrigé avec BUG-005 ; test désormais réussi sans erreur de rectangle |
| `test_active_bonus_grid` | Hauteur incorrecte dans le montage isolé `Game.tscn` ; non reproduite via `Main.tscn` dans les 36 mesures ciblées de tooltip |
| `test_bonus_system` | Attend un bonus de debug alors que le debug est désactivé ; la suite s’arrête avant les assertions suivantes |
| `test_debug_shortcuts` | Attend une aide de debug visible avec debug désactivé |
| `test_selectable_data_catalog` | Attend un choix de fond lié à une configuration de debug inactive |
| `test_sticky_hand_lock` | Attend une règle forcée qui n’est pas activée dans ce démarrage |
| `test_challenges` | Parcourt une ancienne hiérarchie de boutons de bonus et trouve un nœud nul |
| `test_new_challenge_modes` | Attend un challenge désactivé dans le catalogue courant |
| `test_new_special_rules` | Attend des règles retirées de la liste active |
| `test_progression_menu` | Attend exactement 35 palettes, alors que le catalogue a évolué |
| `test_screen_size_options` | Attend d’anciennes dimensions de marges |
| `test_progression_game_integration` | Attend `show_editor_preview=false` ; ce n’est pas la visibilité réelle du menu au lancement |
| `test_high_score` | Attend un temps arrêté à un round précédent ; le code courant enregistre le temps de run |
| `test_victory_display` | Appelle une ancienne méthode `_position_overlay_result_extras` qui n’existe plus |

Ces tests n’ont pas été modifiés pour rendre la suite artificiellement verte. Leurs portions non exécutées ne constituent pas une couverture réussie.

## Observations et pistes non confirmées

- **Fermeture après progression injectée :** 1 erreur `_record_stable_hand_layout` sur objet libéré et quatre instances signalées à la destruction de la scène après les 30 transitions. Cela concerne `HandDragController.return_drag_companions()`. Le plateau final avait atteint la victoire. Il faut reproduire par une fermeture/recharge accessible, sans injection de fins de round, avant de conclure à un bug joueur. Ce cas reste visible dans les preuves.
- **Seed numérique hors 64 bits :** `9223372036854775808` est accepté comme libellé et converti en `-9223372036854775808`. Pas de crash. La règle produit à choisir — rejet, hachage textuel ou conversion — n’est pas documentée ; validation de format à préciser, sans assimiler toute collision de seed à un bug.
- **Replay de huit rounds :** les deux scénarios initiaux ont atteint la limite de 180 secondes, après avoir enregistré les signatures des huit rounds des deux tentatives. Ils ne sont pas comptés comme scénarios entièrement réussis. Le défaut BUG-002 a ensuite été isolé avec des scénarios courts terminés.
- **Fonds et seed :** les flux cosmétiques sont séparés. Le choix de fond utilise aussi un historique pour réduire les répétitions. L’identité visuelle de deux replays n’est pas certifiée ; le rapport ne présente pas cette préférence comme un défaut de gameplay.
- **Menu dit pause :** les horloges continuent volontairement pendant la confirmation de sortie, conformément au code et à la documentation. Vérifié dans les parcours de la matrice, non classé comme bug.
- **Premier round des challenges sans règle :** l’exemption est configurée explicitement, y compris pour Boss Rush. Le round suivant de Boss Rush applique bien des règles. Le contraste éventuel avec sa description relève d’une clarification de conception.
- Le seul message commun aux lancements sains est l’accès refusé au magasin de certificats Windows dans cet environnement isolé. Il ne provient pas d’un chemin de ressource ou d’un script du jeu. Les avertissements de bonus interdits dans certains challenges sont attendus et leur rejet a été vérifié.

## Couverture des tests

### Volume et validations

- **52 tests existants** et **61 scénarios de diagnostic conservés**, dont 59 terminés et deux limités à 180 secondes. Les 61 comprennent les répétitions de confirmation ; certains lancent plusieurs parties. Le scénario de persistance lance deux processus successifs avec le même profil isolé.
- Environ **22 minutes cumulées de processus de diagnostic**, exécutés en partie en parallèle ; ce n’est ni une session humaine continue ni une mesure de performance.
- Import éditeur `godot --headless --path . --editor --quit` et démarrage `godot --headless --path . --quit-after 240` terminés sans erreur de parsing, de ressource ou de script. Message de certificats distinct mentionné ci-dessus.
- Les premiers essais dont le pilote simulait incorrectement un clic de pile ont été écartés des preuves finales et les parcours concernés relancés avec les gestionnaires de drag-and-drop. Le contrôle d’option persistée a également été relancé avec la vraie clé de configuration.

### Scènes et parcours

- `Main.tscn`, `Game.tscn`, cartes, piles, bonus, panneaux de progression, options, challenges et checkpoints à travers les tests existants ou leurs scènes hôtes.
- Menu → partie ; progression par dépôts valides ; restart simple et doublé ; retour menu → nouvelle partie ; double lancement ; menu de sortie et reprise ; ouverture/fermeture répétée 20 fois.
- Dégâts, Safety Net consommé, Flawless interrompu par une erreur, reload sans perte de vie ni de Flawless, dernière vie et timeout terminal.
- Actions de restart/retour pendant reload, placement et dégâts. Seul le restart pendant les dégâts fatals a reproduit BUG-001 dans ces essais.
- Choix de bonus normal et Flawless : deux et trois choix, attribution unique, fermeture du panneau ; deux répétitions. Bonus tous maximisés : l’offre suivante retourne sans attente bloquée.
- 30 fins de round injectées : checkpoints, propositions de bonus ignorées par Skip, quatre changements de tier/fond, état final de victoire. Les valeurs et fonds de chaque étape figurent dans les preuves.
- Victoire injectée → endless et nettoyage après retour menu pour les huit challenges et le classique.

### Matrice des challenges

Pour chaque ligne : activation, paramètres initiaux, seed affichée, double restart, premier round réellement résolu, passage au suivant, fin injectée, endless, retour menu puis classique sans modificateurs ni bonus résiduels. Une passe séparée ajoute dégâts, Safety Net lorsqu’autorisé, reload lorsqu’autorisé, Flawless et dernière vie.

| Challenge | Disponibilité | Particularités exercées | Résultat des parcours ciblés |
|---|---|---|---|
| Reload Required | Menu actif | Main non garantie, reload propre au défi, Redraw interdit | Parcours terminés |
| Shared Clock | Menu actif | Budget commun, dégâts, reprise du compteur, timeout | Parcours terminés |
| Conveyor Belt | Menu actif | Main convoyée, dépôts, Redraw interdit | Parcours terminés |
| Boss Rush | Menu actif | Exemption initiale puis règles combinées | Parcours terminés |
| True Colors | Menu actif | Modificateur de valeurs cachées, cycle de cartes | Parcours terminés ; lisibilité visuelle non certifiée |
| One Shot | Menu actif | Une seule vie, rejet de Safety Net, défaite au premier dégât | Parcours terminés |
| Pool Party | Désactivé dans le catalogue | Ressource chargée directement, physique activée | Parcours terminés ; toutes les collisions physiques non couvertes |
| No Looking Back | Désactivé dans le catalogue | Ressource chargée directement, sélection engagée | Parcours terminés ; gestes physiques non couverts |

La terminaison d’un parcours n’implique pas que toutes les combinaisons possibles de règles et bonus du challenge soient validées.

### Bonus et limites

- Les **18 bonus du registre** sont attribués ensemble à leur niveau maximal dans un scénario : clamp des paramètres, six vies, trois Redraw, reload épuisé sans changement de main et nettoyage en nouvelle partie.
- Effets ciblés : Safety Net, Redraw, Flawless, Rule Breaker, Lucky Hand, Bring a Friend, Pile Mover, Deja Vu et les interactions couvertes par les tests existants réussis. Attribuer tous les bonus ne valide pas chacun de leurs effets en combinaison.
- Paramètres de seed excessifs ramenés à 4 piles, 4 cartes, valeur 9 et 3 secondes ; l’interface de seed limite volontairement les piles à 4, distinctement du plafond général de progression.
- Seed vide, espaces, `0`, minimum et maximum signés 64 bits, dépassement du maximum. Seeds de diagnostic : `AUDIT-2026`, `AUDIT-RACE`, `AUDIT-AFTER-RACE`, `AUDIT-SEED-A`, `AUDIT-SEED-B`, `AUDIT-LONG`, `AUDIT-DAMAGE`, `AUDIT-UI`, `AUDIT-CUSTOM`, `AUDIT-MIRROR`, `AUDIT-FLAWLESS`, `AUDIT-MAX`, `AUDIT-BONUS`, `AUDIT-FROM-MENU`, `AUDIT-PERSIST`, `AUDIT TEXT`.
- Champ de seed de la sélection de challenges → lancement → libellé dans le menu de sortie, avec suppression des espaces aux extrémités.

### Affichage et persistance

- Modes classic, semi adaptive, adaptive ; pixel art activé et désactivé ; tailles demandées 512 × 640, 1068 × 1808 et 1908 × 968. Mesures de rectangles en headless, **pas captures visuelles**. Les deux passes finales donnent 36 popups et 36 tooltips contenus dans leurs limites.
- Tests existants de dimensions de fin de partie, popup, canvas semi adaptive, grille pixel, boutons tactiles, sliders, thèmes et sélection cosmétique exécutés. Les tests en échec sont qualifiés séparément.
- Sauvegarde inexistante, ancienne clé de meilleur temps, fichier incomplet avec identifiant de police absent, type invalide et import invalide.
- Export/import/suppression sur données de test via la suite existante. Deux processus successifs vérifient la conservation d’un challenge complété, de son temps et de sa seed, d’un achievement, du meilleur temps enregistré et de l’option d’affichage du timer.
- Checkpoints, récompenses, achievements or et déblocages de challenges couverts par les tests existants réussis ; pas par une partie humaine exhaustive.

## Éléments non testés

- **Rendu réel GPU et déplacement de fenêtre sur le bureau**, notamment le centrage image par image de l’animation semi adaptive signalée précédemment : headless ne permet pas de certifier ce résultat visuel. Les mesures et le test de canvas ne le remplacent pas.
- Entrées physiques souris/tactile, clavier et souris simultanés, perte/reprise du focus OS, presse-papiers réel et dialogues natifs : uniquement handlers, signaux et événements synthétiques testés ici.
- Manette : aucun parcours dédié validé. Plateformes Web, Android/iOS, Linux/macOS et builds exportés indisponibles dans cette passe.
- Partie complète de chacun des challenges jusqu’à sa cible **sans injection**, longues sessions humaines, rounds endless très élevés et endurance de plusieurs heures : non réalisés. Les premiers rounds et transitions de fin sont couverts séparément.
- Toutes les permutations des 18 bonus, des règles combinées, des fonds et des palettes ; toutes les trajectoires du convoyeur ou de la physique Pool Party : espace de cas trop vaste pour conclure exhaustivement à leur correction.
- Compatibilité de toutes les versions historiques de sauvegarde, interruption du processus pendant l’écriture, disque plein et droits d’écriture révoqués : seul un échantillon de données anciennes/incomplètes/invalides a été testé.
- Atteinte manuelle de tous les achievements, intégralité des niveaux de checkpoints et effets non exécutés après les assertions obsolètes de la suite : couverture partielle déclarée ci-dessus.
- Aucun audit de performances, de FPS, mémoire ou compilation visuelle de tous les shaders n’a été effectué.

## Validation des corrections du 20 septembre 2026

- Dix scénarios dans `fix-validation.json`, tous terminés sans observation `matches: false` ni erreur de script ; un passage supplémentaire souris/tactile dans `fix-mirror-input.json`.
- Import malformé refusé avec `ERR_INVALID_DATA`, sauvegarde précédente conservée ; chargement direct malformé et persistance interprocessus vérifiés.
- Import éditeur (`--headless --editor --quit`) et démarrage (`--headless --quit-after 240`) terminés avec code 0, sans erreur de parsing, ressource manquante ou erreur d’exécution du jeu. Godot émet une erreur d’accès au magasin de certificats Windows dans cet environnement isolé.
- Les sauvegardes du joueur n’ont pas été utilisées. Les limites de rendu et de périphériques physiques restent applicables.
