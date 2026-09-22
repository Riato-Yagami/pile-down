# Audit complet des bugs du jeu

Je veux que tu réalises une **phase d'analyse fonctionnelle complète du jeu**, dont l'objectif est de trouver, reproduire et référencer les bugs existants.

Cette passe est dédiée aux **bugs de fonctionnement**, pas aux performances.

Ne cherche pas ici à optimiser les FPS, la mémoire, les shaders ou les temps de chargement, sauf si un problème de performance provoque directement un bug fonctionnel.

Le but principal est de construire une cartographie fiable des bugs afin de pouvoir les corriger plus tard.

---

# 1. Ne pas corriger les bugs pendant cette passe

Cette tâche est avant tout une phase de diagnostic.

Ne corrige pas automatiquement tous les bugs trouvés.

Tu peux faire une modification temporaire uniquement si elle est nécessaire pour :

- instrumenter un système ;
- reproduire un bug ;
- automatiser un scénario ;
- accéder plus facilement à un état précis du jeu.

Ces modifications doivent rester minimales et être clairement signalées.

Le résultat principal attendu est un fichier de rapport.

---

# 2. Comprendre le projet avant de tester

Commence par analyser le projet afin d'identifier :

- les scènes principales ;
- les autoloads ;
- les systèmes de gameplay ;
- la gestion des rounds ;
- les tiers ;
- les bonus ;
- les vies ;
- le reload ;
- le safety net ;
- le flawless ;
- les challenges ;
- l'endless ;
- le système de seed ;
- les sauvegardes ;
- les menus ;
- la pause ;
- le restart ;
- les transitions ;
- les backgrounds ;
- les palettes et thèmes ;
- les entrées utilisateur ;
- les différents états possibles du jeu.

Identifie les systèmes qui peuvent interagir entre eux et qui doivent être testés ensemble.

---

# 3. Tester tous les parcours principaux

Teste au minimum :

- lancement du jeu ;
- arrivée au menu ;
- lancement d'une partie ;
- progression normale ;
- plusieurs rounds successifs ;
- changement de tier ;
- sélection de bonus ;
- flawless ;
- perte de vie ;
- safety net ;
- reload ;
- victoire si applicable ;
- défaite ;
- restart ;
- retour au menu ;
- lancement d'une nouvelle partie ;
- pause ;
- reprise ;
- fermeture du menu pause ;
- endless ;
- challenges ;
- seed personnalisée ;
- relance d'une seed identique.

Teste aussi les parcours inhabituels.

---

# 4. Tester les interactions entre systèmes

Un système peut fonctionner correctement seul mais casser lorsqu'il est combiné avec un autre.

Teste notamment les interactions entre :

- challenges et bonus ;
- challenges et vies ;
- challenges et reload ;
- challenges et flawless ;
- challenges et safety net ;
- challenges et endless ;
- challenges et seeds ;
- bonus et changement de tier ;
- pause et animations ;
- pause et transitions ;
- restart et sauvegarde ;
- restart et challenges ;
- retour menu et reprise d'une nouvelle partie ;
- changement de background et changement de tier.

Construis une matrice de tests si nécessaire.

---

# 5. Tester les challenges

Teste chaque challenge existant.

Inclure notamment, si présents :

- Shared Clock ;
- Conveyor Belt ;
- Boss Rush ;
- No Looking Back ;
- challenges modifiant les rounds de début/fin ;
- challenges modifiant les vies ;
- challenges modifiant le reload ;
- challenges modifiant les cartes disponibles ;
- challenges modifiant les règles de gameplay.

Pour chaque challenge, vérifie :

- activation correcte ;
- désactivation correcte ;
- règles appliquées ;
- fin du challenge ;
- restart ;
- retour menu ;
- nouvelle partie ;
- combinaison avec les bonus ;
- combinaison avec les seeds ;
- combinaison avec l'endless.

---

# 6. Tester le système de seed

Le jeu doit être reproductible lorsque cela est attendu.

Vérifie que :

- une seed donnée produit les mêmes éléments aléatoires ;
- deux parties avec la même seed restent cohérentes ;
- restart ne casse pas le déterminisme attendu ;
- les challenges n'introduisent pas d'aléatoire non seedé ;
- les bonus n'introduisent pas d'aléatoire non seedé ;
- les backgrounds ou autres systèmes aléatoires utilisent la bonne source de random ;
- une seed saisie depuis le menu challenge est bien celle réellement utilisée ;
- la seed affichée dans le menu pause correspond bien à la partie en cours.

Lorsqu'un bug est lié à une seed, conserve cette seed dans le rapport.

---

# 7. Tester les entrées utilisateur inhabituelles

Cherche les bugs provoqués par des actions rapides ou inattendues :

- double clic ;
- clic très rapide ;
- clic sur plusieurs boutons successivement ;
- clic pendant une transition ;
- clic pendant une animation ;
- ouverture/fermeture rapide du menu pause ;
- pause pendant un changement de tier ;
- restart pendant une animation ;
- retour menu immédiatement après une action ;
- spam raisonnable de boutons ;
- perte et reprise de focus ;
- utilisation clavier et souris simultanément si applicable ;
- utilisation manette si supportée.

Cherche notamment :

- actions exécutées deux fois ;
- état bloqué ;
- écran inaccessible ;
- mauvaise scène ;
- éléments UI superposés ;
- boutons restant désactivés ;
- actions possibles alors qu'elles ne devraient pas l'être.

---

# 8. Tester les états limites

Teste les valeurs extrêmes ou rares :

- dernière vie ;
- zéro vie ;
- safety net utilisé au dernier moment ;
- maximum de reload ;
- aucun reload ;
- flawless puis dégâts ;
- plusieurs bonus successifs ;
- maximum de bonus possible ;
- début du premier round ;
- dernier round d'un challenge ;
- passage challenge -> endless si applicable ;
- gros numéro de round ;
- longue partie ;
- seed minimale/maximale si format numérique ;
- valeurs vides ou invalides dans les champs de saisie.

---

# 9. Tester les menus et l'UI

Cherche les bugs fonctionnels de l'interface :

- mauvais texte ;
- texte non actualisé ;
- mauvais état de bouton ;
- boutons cliquables alors qu'ils devraient être désactivés ;
- boutons désactivés à tort ;
- mauvais écran affiché ;
- popup bloquée ;
- focus clavier incorrect ;
- éléments qui restent visibles après changement de scène ;
- éléments superposés ;
- valeurs anciennes conservées ;
- seed incorrectement affichée ;
- mauvais état d'un challenge ;
- sélection visuelle différente de l'état réel.

Teste également différentes tailles et ratios de fenêtre pour détecter les bugs d'UI, mais ne fais pas ici une analyse de performance.

---

# 10. Tester les transitions d'état

Les changements d'état sont souvent une source de bugs.

Teste particulièrement :

- menu -> partie ;
- partie -> pause ;
- pause -> partie ;
- partie -> game over ;
- game over -> restart ;
- game over -> menu ;
- partie -> tier suivant ;
- tier -> choix de bonus ;
- bonus -> partie ;
- challenge -> fin ;
- challenge -> restart ;
- partie -> endless ;
- retour menu -> nouvelle partie.

Cherche :

- état précédent non nettoyé ;
- variables non réinitialisées ;
- anciens nodes encore actifs ;
- mauvais challenge encore appliqué ;
- ancienne seed réutilisée ;
- bonus conservé à tort ;
- vie/reload incorrectement restauré.

---

# 11. Tester les sauvegardes et données persistantes

Si le jeu stocke des données, vérifie notamment :

- sauvegarde ;
- chargement ;
- fermeture puis relance ;
- données manquantes ;
- fichier de sauvegarde inexistant ;
- fichier incomplet ;
- ancienne version de sauvegarde si pertinent ;
- progression des achievements ;
- challenges débloqués ;
- options ;
- seed si elle est persistée ;
- données remises à zéro correctement.

Ne détruis pas de sauvegarde utilisateur réelle.

Utilise des données de test séparées si nécessaire.

---

# 12. Examiner les erreurs et warnings

Pendant les tests, surveille systématiquement :

- erreurs Godot ;
- warnings pertinents ;
- accès à une référence nulle ;
- signaux invalides ;
- signaux connectés plusieurs fois ;
- chemins invalides ;
- ressources manquantes ;
- erreurs de parsing ;
- erreurs de shader pouvant casser visuellement le jeu ;
- exceptions ;
- erreurs au changement de scène ;
- erreurs à la fermeture du jeu.

Un bug visible sans erreur console doit bien sûr aussi être référencé.

---

# 13. Automatiser ce qui peut l'être

Lorsque cela est raisonnable, crée des tests ou scripts temporaires permettant de répéter des scénarios.

Par exemple :

- enchaîner des rounds ;
- répéter restart ;
- répéter retour menu / nouvelle partie ;
- parcourir plusieurs seeds ;
- tester tous les challenges ;
- tester certaines combinaisons ;
- déclencher des transitions répétées.

L'automatisation doit aider à découvrir les bugs, pas modifier le comportement normal du jeu.

---

# 14. Vérifier la reproductibilité

Avant de référencer un bug :

- essaie de le reproduire ;
- note le nombre d'occurrences ;
- identifie les conditions nécessaires ;
- note la seed lorsqu'elle est pertinente ;
- note le challenge lorsqu'il est pertinent ;
- précise si le bug est déterministe ou intermittent.

Exemples :

- Toujours ;
- 8 fois sur 10 ;
- 1 fois sur 20 ;
- uniquement avec telle seed ;
- uniquement après plusieurs restarts.

---

# 15. Créer un rapport dédié

Crée à la racine du projet :

`BUG_AUDIT.md`

Ce fichier doit contenir tous les bugs trouvés.

Au début du fichier, ajoute un tableau de synthèse :

| ID | Sévérité | Système | Résumé | Reproductibilité | Statut |
|---|---|---|---|---|---|
| BUG-001 | High | Challenges | ... | Toujours | À corriger |

Utilise des identifiants stables :

- `BUG-001`
- `BUG-002`
- etc.

---

# 16. Format de chaque bug

Utilise cette structure :

```md
## BUG-001 - Titre court

**Sévérité :** High  
**Reproductibilité :** Toujours  
**Seed :** 123456 si applicable  
**Challenge :** Nom si applicable  
**Configuration :** Windows / 1920x1080 / etc. si pertinent

### Symptôme

Description précise de ce qui se passe.

### Comportement attendu

Ce qui devrait normalement se passer.

### Étapes de reproduction

1. ...
2. ...
3. ...

### Fréquence

Exemple : 5 fois sur 5.

### Cause probable

Uniquement si elle est réellement identifiable.

Sinon :

`Cause à déterminer.`

### Fichiers / systèmes probablement concernés

- `...`
- `...`

### Piste de correction

Une piste éventuelle, sans effectuer la correction maintenant.

### Statut

À corriger.
```

---

# 17. Sévérité

Utilise les niveaux suivants.

## Critical

- crash ;
- sauvegarde corrompue ;
- progression perdue ;
- jeu totalement bloqué ;
- partie impossible à continuer.

## High

- règle importante cassée ;
- challenge incorrect ;
- partie fortement impactée ;
- softlock ;
- erreur fréquente affectant le gameplay.

## Medium

- comportement incorrect mais contournable ;
- bug limité à certaines situations ;
- problème UI ayant un impact fonctionnel.

## Low

- petit problème visuel ;
- texte incorrect ;
- état visuel incohérent sans impact gameplay ;
- bug rare et peu gênant.

Ne gonfle pas artificiellement la sévérité.

---

# 18. Distinguer faits et hypothèses

Pour chaque bug, sépare clairement :

- ce qui a été observé ;
- ce qui était attendu ;
- la reproduction ;
- la cause confirmée ;
- la cause supposée.

Ne présente jamais une hypothèse comme une certitude.

---

# 19. Documenter la couverture

Ajoute à la fin du rapport :

`## Couverture des tests`

Liste :

- scènes testées ;
- challenges testés ;
- bonus testés ;
- seeds utilisées ;
- parcours testés ;
- configurations d'affichage testées ;
- systèmes persistants testés ;
- durée ou nombre approximatif de sessions effectuées.

Ajoute aussi :

`## Éléments non testés`

avec les raisons :

- environnement indisponible ;
- fonctionnalité non accessible ;
- plateforme non disponible ;
- système non présent ;
- test impossible à automatiser proprement.

---

# Résultat attendu

À la fin, je veux :

1. un audit fonctionnel large du jeu ;
2. des bugs reproductibles autant que possible ;
3. des tests de combinaisons de systèmes ;
4. des tests de challenges ;
5. des tests de seeds ;
6. des tests d'entrées utilisateur inhabituelles ;
7. des tests des transitions d'état ;
8. un fichier `BUG_AUDIT.md` clair et exploitable ;
9. aucune grosse correction effectuée pendant cette passe ;
10. une distinction claire entre bugs confirmés, hypothèses et éléments non testés.

Cette phase doit servir de base à une future passe de correction des bugs.
