# Audit complet des performances du jeu

Je veux que tu réalises une **phase d'analyse des performances du jeu**, séparée de l'analyse fonctionnelle des bugs.

Cette passe doit se concentrer uniquement sur :

- FPS ;
- frametime ;
- stutters ;
- CPU ;
- GPU ;
- mémoire ;
- allocations ;
- temps de chargement ;
- shaders ;
- backgrounds ;
- draw calls ;
- nodes ;
- ressources ;
- fuites ;
- dégradation au fil du temps.

Le but principal est de mesurer, comparer et référencer les problèmes de performance pour pouvoir les corriger plus tard.

---

# 1. Ne pas optimiser pendant cette passe

Cette tâche est une phase de diagnostic.

Ne lance pas une refactorisation ou une optimisation générale pendant l'audit.

Tu peux ajouter une instrumentation temporaire si nécessaire pour mesurer correctement un système.

Le résultat principal attendu est un rapport de performance fiable.

---

# 2. Établir une baseline

Commence par analyser :

- la version de Godot ;
- le renderer utilisé ;
- les export presets ;
- les réglages graphiques ;
- les scènes principales ;
- les shaders ;
- les backgrounds ;
- les animations ;
- les tweens ;
- les particules ;
- l'UI ;
- l'audio ;
- les autoloads ;
- les systèmes exécutés à chaque frame ;
- les ressources chargées dynamiquement.

Mesure une situation de référence.

Lorsque les outils disponibles le permettent, relève :

- FPS moyen ;
- FPS minimum ;
- frametime moyen ;
- pics de frametime ;
- CPU ;
- GPU ;
- RAM ;
- VRAM si accessible ;
- nombre de nodes ;
- nombre d'objets ;
- draw calls ;
- changements de matériau ;
- temps de chargement ;
- temps de changement de scène.

---

# 3. Tester plusieurs configurations d'affichage

Teste si possible :

- fenêtré ;
- plein écran ;
- petites résolutions ;
- 1280x720 ;
- 1920x1080 ;
- grandes résolutions ;
- 4:3 ;
- 16:9 ;
- 16:10 ;
- ultrawide ;
- fenêtre très étroite ;
- redimensionnement continu ;
- VSync activée/désactivée si accessible ;
- FPS limités/non limités si accessible.

Compare les performances entre ces configurations.

---

# 4. Tester les renderers

Si supportés par le projet et l'environnement, compare :

- Forward+ ;
- Mobile ;
- Compatibility.

Ne prétends pas avoir testé un renderer impossible à exécuter.

---

# 5. Comparer les environnements d'exécution

Lorsque possible, compare :

- exécution depuis l'éditeur ;
- build Debug ;
- build Release.

Ne considère pas automatiquement un ralentissement uniquement visible dans l'éditeur comme un problème du build final.

---

# 6. Tester les différentes situations de gameplay

Mesure les performances pendant :

- menu principal ;
- démarrage d'une partie ;
- round normal ;
- choix de bonus ;
- flawless ;
- perte de vie ;
- reload ;
- changement de tier ;
- transition de background ;
- pause ;
- reprise ;
- game over ;
- restart ;
- retour menu ;
- challenge ;
- endless ;
- longue partie.

Cherche les différences entre états.

---

# 7. Chercher les stutters

Surveille particulièrement les pics de frametime.

Cherche s'ils apparaissent :

- au lancement ;
- au premier affichage d'un shader ;
- au premier chargement d'un background ;
- lors du changement de tier ;
- lors d'une transition ;
- lors du choix d'un bonus ;
- au début d'un round ;
- lors d'une sauvegarde ;
- lors d'un restart ;
- lors d'un changement de scène ;
- lors du retour au menu.

Essaie d'identifier si la cause est liée à :

- compilation de shader ;
- chargement synchrone ;
- instanciation de nodes ;
- création/destruction massive ;
- calcul important sur une frame ;
- allocation mémoire ;
- accès disque ;
- génération procédurale.

---

# 8. Analyser les shaders et backgrounds

Le projet utilise plusieurs backgrounds générés par shaders.

Teste chaque background disponible.

Pour chacun, mesure si possible :

- FPS ;
- frametime ;
- GPU ;
- draw calls ;
- différences selon résolution.

Teste aussi :

- background seul ;
- transition entre backgrounds ;
- morphing ;
- changement de palette ;
- plusieurs transitions successives ;
- tiers différents.

Cherche :

- boucles coûteuses ;
- calculs constants refaits par pixel ;
- overdraw ;
- effets fullscreen coûteux ;
- ShaderMaterial recréés inutilement ;
- recompilation ;
- uniforms mis à jour inutilement.

---

# 9. Analyser l'UI

Vérifie si l'interface provoque un coût anormal.

Cherche notamment :

- calculs à chaque frame ;
- rebuild fréquent ;
- création répétée de Controls ;
- labels mis à jour sans nécessité ;
- signaux provoquant trop de travail ;
- animations UI coûteuses ;
- éléments invisibles toujours actifs ;
- redraw excessif.

Mesure les différences entre :

- gameplay seul ;
- menu pause ouvert ;
- écran de bonus ;
- autres écrans UI importants.

---

# 10. Faire des stress tests

Teste des sessions longues.

Par exemple :

- beaucoup de rounds ;
- endless prolongé ;
- nombreux restarts ;
- nombreux retours menu / nouvelles parties ;
- nombreuses transitions ;
- nombreux changements de tier ;
- nombreuses ouvertures/fermetures du menu pause ;
- nombreux changements de backgrounds.

Cherche une dégradation progressive des performances.

---

# 11. Chercher les fuites mémoire

Compare la mémoire :

- au lancement ;
- après une partie ;
- après plusieurs parties ;
- après plusieurs restarts ;
- après une session longue ;
- après plusieurs retours menu.

Surveille :

- RAM ;
- VRAM si possible ;
- nombre de nodes ;
- nombre d'objets ;
- ressources ;
- textures ;
- matériaux ;
- tweens ;
- timers ;
- signaux ;
- arrays/dictionaries qui grossissent ;
- anciennes instances conservées.

Une augmentation persistante doit être référencée.

---

# 12. Chercher les allocations et créations inutiles

Identifie les zones qui créent beaucoup d'objets de manière répétée.

Cherche notamment :

- objets créés dans `_process()` ;
- tableaux recréés ;
- dictionnaires recréés ;
- strings générées chaque frame ;
- resources chargées plusieurs fois ;
- nodes instanciés puis détruits très fréquemment ;
- ShaderMaterial recréés ;
- textures rechargées ;
- connexions de signaux répétées.

---

# 13. Tester différentes seeds

Utilise plusieurs seeds fixes pour rendre les benchmarks reproductibles.

Vérifie si certaines seeds provoquent :

- plus d'éléments affichés ;
- plus d'animations ;
- plus de calculs ;
- des scénarios particulièrement lourds.

Conserve les seeds intéressantes dans le rapport.

---

# 14. Tester les challenges

Mesure les performances des challenges existants.

Compare notamment :

- partie normale ;
- Shared Clock ;
- Conveyor Belt ;
- Boss Rush ;
- No Looking Back ;
- autres challenges disponibles.

Cherche les challenges provoquant un coût disproportionné.

---

# 15. Automatiser les benchmarks

Lorsque cela est pertinent, crée des scripts de benchmark permettant de :

- lancer des scénarios reproductibles ;
- utiliser une seed fixe ;
- enchaîner des rounds ;
- répéter des transitions ;
- répéter des restarts ;
- relever régulièrement les métriques ;
- comparer plusieurs configurations.

Les scripts de benchmark doivent rester séparés du code de production autant que possible.

---

# 16. Répéter les mesures

N'utilise pas une seule mesure.

Pour les problèmes importants :

- répète le test ;
- relève plusieurs valeurs ;
- calcule éventuellement moyenne, minimum et maximum ;
- distingue performance normale et pics.

Attention au coût du profiler lui-même.

---

# 17. Créer un rapport dédié

Crée à la racine du projet :

`PERFORMANCE_AUDIT.md`

Ajoute en début de fichier un tableau :

| ID | Sévérité | Type | Résumé | Configuration | Mesure | Statut |
|---|---|---|---|---|---|---|
| PERF-001 | Medium | Stutter | Pic au changement de tier | Win / Forward+ | 82 ms | À optimiser |

Utilise des identifiants :

- `PERF-001` pour les problèmes généraux ;
- `MEM-001` pour les fuites ou accumulations mémoire.

---

# 18. Format de chaque problème

Utilise cette structure :

```md
## PERF-001 - Titre court

**Type :** Stutter / CPU / GPU / Loading / etc.  
**Sévérité :** Medium  
**Plateforme :** Windows  
**Renderer :** Forward+  
**Configuration :** 1920x1080, fullscreen  
**Seed :** 123456 si utile

### Situation testée

Description du scénario.

### Mesures

- FPS moyen : ...
- FPS minimum : ...
- frametime moyen : ...
- pic maximum : ...
- CPU : ...
- GPU : ...
- RAM : ...
- autres métriques : ...

### Observation

Description factuelle du problème.

### Cause probable

Uniquement si elle est suffisamment étayée.

Sinon :

`Cause à déterminer.`

### Fichiers / systèmes concernés

- `...`
- `...`

### Piste d'optimisation

Suggestion pour une future passe.

### Statut

À optimiser.
```

---

# 19. Sévérité

## Critical

- performance rendant le jeu injouable ;
- fuite mémoire majeure ;
- freeze long ou crash lié aux ressources.

## High

- chute majeure de FPS ;
- stutters importants et fréquents ;
- forte dégradation au fil d'une session ;
- consommation mémoire anormale.

## Medium

- stutter perceptible ;
- coût notable limité à certains systèmes ;
- problème dépendant d'une configuration.

## Low

- optimisation potentielle ;
- coût mesurable mais peu perceptible ;
- petite allocation évitable.

Ne gonfle pas artificiellement la sévérité.

---

# 20. Distinguer mesures et hypothèses

Sépare clairement :

- les métriques mesurées ;
- le comportement observé ;
- la cause confirmée ;
- la cause probable ;
- la piste d'optimisation.

Ne transforme pas une intuition en conclusion.

---

# 21. Documenter la couverture

Ajoute :

`## Couverture des benchmarks`

avec :

- plateformes ;
- renderers ;
- résolutions ;
- modes d'affichage ;
- builds Debug/Release ;
- backgrounds ;
- challenges ;
- seeds ;
- scénarios ;
- durée ou nombre de rounds des stress tests.

Puis :

`## Configurations non testées`

avec la raison.

---

# Résultat attendu

À la fin, je veux :

1. une baseline claire ;
2. des benchmarks reproductibles ;
3. une analyse FPS/frametime ;
4. une analyse CPU/GPU ;
5. une analyse mémoire ;
6. une recherche de stutters ;
7. une analyse des shaders et backgrounds ;
8. des stress tests ;
9. une comparaison Debug/Release lorsque possible ;
10. un fichier `PERFORMANCE_AUDIT.md` complet ;
11. aucune grosse optimisation effectuée pendant cette passe ;
12. des pistes de correction conservées pour une future phase d'optimisation.

Cette phase doit servir de base à une future passe dédiée exclusivement à l'optimisation.
