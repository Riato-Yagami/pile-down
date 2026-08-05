# Checklist des implémentations post-jam

## Terminé

### Sauvegarde et structures

- [x] Ajouter `save/schema_version`.
- [x] Migrer les anciennes sauvegardes sans supprimer leurs données.
- [x] Fournir des valeurs par défaut pour les découvertes, achievements et polices.
- [x] Créer `CheckpointSnapshot`.
- [x] Sérialiser les snapshots en dictionnaires simples.
- [x] Sauvegarder les checkpoints débloqués, snapshots et highscores.
- [x] Conserver les highscores et le déblocage Endless existants.

### Difficulté dirigée

- [x] Ajouter `STAT_PITY_RATE`.
- [x] Ajouter `MAX_STAT_DROUGHT`.
- [x] Ajouter `STARTER_STAT_MULTIPLIER`.
- [x] Maintenir un compteur de drought pour chaque statistique.
- [x] Augmenter progressivement le poids des statistiques non sélectionnées.
- [x] Multiplier le poids lorsqu'il ne reste qu'une pile ou une carte en main.
- [x] Garantir une statistique lorsque son drought atteint la limite.
- [x] Exclure les statistiques ayant atteint leur maximum.
- [x] Réinitialiser le compteur de la statistique sélectionnée.
- [x] Simuler les droughts pendant une progression debug avancée.

### Checkpoints — logique interne

- [x] Ajouter `CHECKPOINT_INTERVAL` et `ENABLE_CHECKPOINTS`.
- [x] Capturer le snapshot avant les règles, la main et les modifications temporaires.
- [x] Débloquer un checkpoint uniquement après la victoire du round concerné.
- [x] Conserver le premier snapshot ayant débloqué un checkpoint.
- [x] Restaurer les statistiques et droughts d'un checkpoint.
- [x] Ajouter le mode `CHECKPOINT`.
- [x] Calculer le nombre de bonus de départ.
- [x] Enchaîner les choix de bonus avant le gameplay.
- [x] Maintenir des highscores indépendants par checkpoint.
- [x] Ne pas utiliser le temps pour classer les runs checkpoint.

### Highscores sans erreur

- [x] Ajouter `run_mistake_count`.
- [x] Compter une vraie erreur même lorsqu'elle est absorbée par `SAFETY NET`.
- [x] Sauvegarder un highscore Classic sans erreur avec départage au temps.
- [x] Sauvegarder un highscore Endless sans erreur.
- [x] Sauvegarder un highscore sans erreur propre à chaque checkpoint.
- [x] Séparer les trois modes dans la sauvegarde.

### Progression persistante

- [x] Découvrir un bonus lorsqu'il est sélectionné.
- [x] Découvrir une règle lorsqu'elle est activée.
- [x] Sauvegarder les bonus et règles découverts.
- [x] Créer `AchievementData`.
- [x] Créer `AchievementRegistry`.
- [x] Créer `AchievementManager`.
- [x] Déclarer les neuf achievements demandés.
- [x] Débloquer définitivement et une seule fois chaque achievement.
- [x] Créer `FontData`.
- [x] Créer `FontRegistry`.
- [x] Créer `FontManager`.
- [x] Utiliser uniquement les polices déjà présentes dans le projet.
- [x] Débloquer des polices via les achievements.
- [x] Sauvegarder et restaurer la police sélectionnée.
- [x] Créer la scène de base `AchievementPopup.tscn`.

### Gameplay

- [x] Déclencher Quick Peek périodiquement aux intervalles 4, 3 et 2.
- [x] Appliquer les durées 0,10, 0,20 et 0,25 seconde.
- [x] Remettre le compteur Quick Peek à zéro à chaque round.
- [x] Suspendre le timer pendant Quick Peek.
- [x] Ajouter une première version du rework Lucky Hand.
- [x] Faire cibler à Lucky Hand une valeur immédiatement jouable.
- [x] Prendre initialement en compte Double Down et Deja Vu.
- [x] Séparer les mouvements de piles en trois règles.
- [x] Transformer Merry-Go-Stack en mouvement orbital.
- [x] Créer `SHAKING PILES`.
- [x] Créer `WAVY BABY`.
- [x] Déclarer leurs incompatibilités principales.

### Debug et documentation

- [x] Ajouter les nouvelles constantes debug demandées.
- [x] Documenter le pity, Quick Peek, les checkpoints et les mouvements dans le README.
- [x] Valider le chargement de l'éditeur Godot.
- [x] Valider le démarrage headless.

## Partiellement terminé

### Checkpoints

- [x] Ajouter le bouton `CHECKPOINT` au menu principal.
- [x] Ajouter un bouton compact `FROM <round>` à côté de `PLAY`, sélectionnable
  avec haut/bas ou la molette.
- [x] Afficher le round de départ sélectionné et le meilleur score checkpoint
  global.
- [x] Brancher `start_from_checkpoint()` sur cette interface.
- [x] Afficher l'annonce skippable `CHECKPOINT N — UNLOCKED`.
- [ ] Tester complètement les redémarrages depuis chaque checkpoint.
- [x] Brancher `START_FROM_CHECKPOINT` et `UNLOCK_ALL_CHECKPOINTS`.

### Achievements et polices

- [ ] Instancier et animer les popups en haut de l'écran.
- [ ] Mettre les popups en attente pendant les annonces importantes.
- [ ] Garantir que les popups ne cachent jamais le timer.
- [ ] Construire l'interface de sélection des polices.
- [ ] Vérifier visuellement chaque police dans toutes les tuiles.
- [ ] Ajuster les textes trop larges selon la police.
- [ ] Brancher toutes les options debug associées.

### Lucky Hand

- [x] Déterminer la pile la plus avancée directement depuis les piles.
- [x] Respecter exactement l'ordre des cartes aux niveaux II et III.
- [x] Réserver précisément les suites Double Down.
- [x] Limiter précisément les copies Deja Vu aux piles compatibles.
- [x] Protéger explicitement le joker conservé.
- [x] Protéger l'unique carte garantie pendant tous les remplacements.
- [x] Ajouter les tests exhaustifs empêchant les cartes mortes.

### Animations skippables

- [x] Créer l'interface commune `SkippableSequence`.
- [x] L'intégrer à l'augmentation de statistique.
- [x] L'intégrer aux annonces de règles spéciales.
- [x] L'intégrer aux annonces de combinaisons.
- [x] L'intégrer à `TIER RELIEF`.
- [x] L'intégrer aux checkpoints et autres déblocages.
- [x] Empêcher systématiquement la traversée du clic.
- [x] Vérifier que les choix interactifs ne peuvent pas être skippés.

## Pas encore réalisé

### Menu Progression

- [x] Ajouter le bouton `PROGRESSION`.
- [x] Assurer la navigation à la souris, au clavier et au tactile.
- [x] Retourner au menu avec `Escape`.
- [x] Créer la page `HIGHSCORES`.
- [x] Créer la page `ACHIEVEMENTS`.
- [x] Créer la page `BONUSES`.
- [x] Créer la page `SPECIAL RULES`.
- [x] Créer la page `FONTS`.
- [x] Afficher l'état découvert ou inconnu des bonus et règles.
- [x] Afficher les highscores Classic, Endless et Checkpoints.

### Écran de fin

- [ ] Afficher les nouvelles découvertes après le score.
- [ ] Présenter uniquement les catégories non vides.
- [ ] Afficher successivement bonus, règles, achievements, polices et checkpoints.
- [ ] Permettre de passer ces notifications.
- [ ] Conserver l'écran actuel lorsqu'il n'y a rien de nouveau.

### Peek-a-Card tactile

- [ ] Ajouter les états tactiles `IDLE`, `REVEALED` et `DRAGGING`.
- [ ] Révéler la carte au premier contact.
- [ ] Attendre un court délai avant le drag.
- [ ] Déclencher le drag après la distance minimale.
- [ ] Continuer le drag sans demander un second tap.
- [ ] Maintenir brièvement la face visible après le début du drag.
- [ ] Masquer la carte avec un délai après un simple tap.
- [ ] Ajouter le comportement spécifique à Blind Delivery.
- [ ] Ajouter les tests tactiles automatisés.

### Effets visuels

- [ ] Ajouter un halo pixelisé pendant le drag.
- [ ] Utiliser un halo neutre en mode Colorblind.
- [ ] Réduire le halo des cartes Bring a Friend.
- [ ] Créer un pool léger de poussière.
- [ ] Déplacer la poussière au passage des cartes.
- [ ] Appliquer une impulsion réduite au passage des piles mobiles.
- [ ] Ajouter une option pour désactiver la poussière.
- [ ] Brancher le mode debug de visualisation de la poussière.

### Tests

- [ ] Ajouter les tests de difficulté dirigée.
- [x] Ajouter les tests de base des checkpoints (déblocage après victoire,
  snapshot initial conservé et nombre de bonus de départ).
- [ ] Ajouter les tests des highscores séparés.
- [x] Ajouter les tests des animations skippables.
- [ ] Ajouter les tests des découvertes et achievements.
- [ ] Ajouter les tests de restauration des polices.
- [ ] Ajouter les tests Peek-a-Card mobile.
- [x] Ajouter les tests Lucky Hand complets.
- [ ] Ajouter les tests Quick Peek périodique.
- [ ] Ajouter les tests des trois mouvements.
- [ ] Ajouter les tests du halo et de la poussière si pertinent.
- [ ] Vérifier l'export Web.
- [ ] Vérifier la version desktop.
- [ ] Vérifier le comportement sur un appareil tactile réel.

## Validation actuelle

- [x] `godot --headless --path . --editor --quit`
- [x] `godot --headless --path . --quit-after 240`
- [ ] Faire passer toute la suite automatisée. Elle bloque actuellement dans
  `tests/test_debug_shortcuts.gd:16` : le test attend le panneau debug visible,
  alors que `DebugSettings.ENABLED` vaut `false`.