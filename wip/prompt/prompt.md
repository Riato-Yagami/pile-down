Consigne permanente : à chaque utilisation de ce fichier, suivre les demandes avec des cases `- [ ]` et les cocher `- [x]` dès que leur implémentation est terminée et vérifiée. Laisser décochée toute demande incomplète ou non vérifiée et conserver ce suivi dans le fichier, sans attendre un rappel.

- [x] ajouter un systeme de code secret (nouveau resource/data)
quand tapé dans l'input de partie seedé et partie lancé permet de débloqué un deblocable secret (pas montré en ??? dans les progressions) avec un pop up et ne lance pas de partie

peut avoir des condition spéciale

code piledown-beta (pour les beta testeurs) condition de validation avoir débloqué un achievment avant le 21 octbore 2026

code earlybird dispo jusqu'en 2026

- [x] ajouter au font la possibilité d'etre hd
implémenté la font comics sans hd déblocable avec piledown-beta
+ https://fontmeme.com/fonts/pixel-comic-sans-font/ avec early bird

Précision acceptée : remplacer les polices à licence restrictive par une police
libre redistribuable sur le Play Store (jeu free-to-play).
- [x] Utiliser Comic Relief (SIL OFL 1.1) : Regular HD pour `piledown-beta`,
  Bold sans lissage pour `earlybird`, avec licence incluse.


Vérifié : import éditeur Godot, démarrage headless (240 frames),
`tests/test_secret_codes.gd` (dates limites, input seed, popup, récompenses cachées,
persistance, rendu HD dans les cartes et piles) et `tests/test_seed_replay.gd`.
Les polices initiales à licence restrictive ont été retirées du projet.

- [x] Donner aux popups de codes secrets le fond commun des achievements et l’icône des polices.

- [x] Affecter la variante « Comic Relief Pixel » à `piledown-beta` et la nommer simplement « Comic Relief ».
- [x] Remplacer la récompense `earlybird` par Papyrus, avec une licence compatible avec le Play Store (ou une alternative libre validée).

Choix final : une police classique libre à la place de Papyrus ou Arial.
- [x] Attribuer Liberation Sans (SIL OFL 1.1) à `earlybird`, avec licence
  dans les exports et conservation des anciens déblocages.

Vérification du choix final : import éditeur et démarrage 240 frames sans erreur ;
`test_secret_codes.gd` réussi, y compris la migration de l’ancienne récompense.

- [x] Ajouter SNAKE : piles en serpent sur grille invisible, main placée sur la grille, poursuite des tuiles, régénération de la dernière pile active (+1 plafonné au maximum du round) et réapparition ailleurs des tuiles mangées.

- [x] Renommer la page de polices « CUSTOMISATION », séparer POLICES et PALETTES en sous-onglets extensibles et animer le changement d’onglet.

Validations Snake et Customisation : import éditeur, démarrage headless
240 frames, tests dédiés `test_snake_rule.gd` et `test_customisation_tabs.gd`,
sélection des cosmétiques, disposition mobile, règles spéciales, réparation
de main après régénération et replay des seeds réussis.

- [x] Animer le glissement des piles Snake entre les cases.
- [x] Si toutes les tuiles sont tenues, poursuivre leur ancienne case puis tourner autour.
- [x] Passer la tête au-dessus d’une tuile relâchée sur le serpent pour la manger, en conservant les dépôts valides.
- [x] Interdire au Snake de traverser son corps, y compris la case quittée par sa queue.

Vérifié : tests Snake de base et de glissement/patrouille/dépôts/collisions,
replay des seeds, import éditeur et démarrage headless 240 frames réussis.

- [x] Garder les onglets de customisation lisibles : bleu sélectionné ou survolé, texte sombre au repos.

- [x] Corriger le Snake figé après un repas qui régénère une pile et provoque le remplacement d’une main injouable.

Validation : blocage reproduit avant correction ; `test_snake_after_meal.gd`
vérifie la nouvelle main jouable, le déverrouillage, le timer et la reprise
du mouvement. Tests Snake et glissement, import éditeur et démarrage 240 frames réussis.

- [x] Ralentir Snake et exposer ses durées dans difficulty.gd.
- [x] Rétablir l’animation d’erreur sur les dépôts invalides et suspendre Snake pendant le retour d’erreur.

Vérifié : tests Snake, glissement, repas et erreur (animation, pause/reprise),
import éditeur et démarrage headless 240 frames réussis.


- [x] lorsque les tilles se font manger shrink de maniere centré, deplace les vers le milieu de la tete, puis grossis legerement la tete et les autres tiles de son corps dans l'ordre pour faire genre la tille se déplace dans son corps
- [x] En règle Snake, faire apparaître les tuiles loin de la tête avec un grossissement centré et un fondu sur place ; en fin de round, les faire rétrécir et disparaître en fondu.
Validation du repas animé : `test_snake_meal_animation.gd` réussi (rétrécissement
centré, suivi du centre de la tête, pulsation après absorption puis dans l’ordre
du corps, hitboxes inchangées et nettoyage). Import éditeur et démarrage
headless 240 frames réussis sans erreur.

Validation : `test_snake_tile_lifecycle.gd` (distance, apparition sur place,
interruption et disparition), `test_snake_rule.gd` et `test_snake_after_meal.gd`
réussis sans erreur. Import éditeur et démarrage headless 240 frames réussis.

- [x] Si un repas soigne une pile Snake, arrêter la vague sur cette pile et appliquer le soin lorsqu’elle grossit.

Validation : `test_snake_digestion_heal.gd` vérifie le soin différé au sommet
de la pulsation, l’arrêt de la vague sur la cible et l’annulation au nettoyage.
Tests Snake, repas et animation réussis ; import éditeur et démarrage headless
240 frames sans erreur.

- [x] Avec Bonneteau + Snake, réaffecter les segments après les échanges pour éviter leur retour aux positions précédentes.

Validation : `test_snake_shell_game.gd` réussi (échanges de deux/trois piles,
glissement interrompu, pile terminée et reprise sans retour aux anciennes cases).
Tests Snake et replay des seeds, import éditeur et démarrage 240 frames réussis.

- [x] Vérifier Snake avec toutes les règles : tirage compatible, géométrie miroir, repas, soin, dépôt valide et nettoyage.

- [x] Ajouter en bas à droite de la fin de partie une icône de partage qui copie le résultat (manches restantes, temps, liens itch.io et Google Play).

Validation : 20 associations Snake vérifiées, 13 paires autorisées et deux
combinaisons de six règles testées en jeu, avec les trois miroirs. Suite Snake
13/13 et suite partage 3/3 réussies ; import éditeur et démarrage headless
240 frames sans erreur. Détails et échecs des tests généraux hors de ces suites :
`tests/snake_compatibility_report.md`.

- [x] Corriger le décalage du menu pendant l’animation Quitter sous Jeu de miroir.

- [x] Utiliser `links.png` pour l’icône de partage.

Validation Quitter : bug reproduit avant correction ; test des trois miroirs
et des deux dispositions adaptatives réussi, ainsi que les tests de fenêtre
Quitter, partage et canevas semi-adaptatif. Import et démarrage 240 frames sans erreur.

Icône `links.png` vérifiée : partage, mise en page de fin de partie et transition
Quitter miroir 3/3 ; import éditeur et démarrage 240 frames sans erreur.

- [x] Retirer le texte au survol du partage et décaler `links.png` de 8 pixels vers la gauche dans le popup.

Vérifié : partage et taille de popup 2/2 ; import éditeur et démarrage
headless 240 frames sans erreur.

- [x] Utiliser `checked.png` à la place de `share-copied.svg` pour confirmer la copie du partage.

Vérifié : test du partage réussi ; import éditeur et démarrage headless
240 frames sans erreur. Ancien SVG supprimé.

- [x] Ajouter au partage une grille textuelle des piles restantes et les tuiles en main.

Validation : test du partage avec plateau 2×2, pile terminée masquée, main
avec joker, cas vide et instantané figé après modification des valeurs ;
test de taille du popup, import éditeur et démarrage 240 frames réussis.

- [x] Retirer la légende « ✅ PILE TERMINÉE » du texte partagé (test du partage, import et démarrage 240 frames réussis).

- [x] Respecter les nombres de piles supérieurs à 4 choisis dans les parties seedées.

Validation : lancement depuis le menu et rejeu à 5, 12 et 25 piles (dont sans
fin), plafonnement au maximum du jeu et conservation d’AUTO ; tests de
progression seedée et Snake réussis (3/3). Import éditeur et démarrage
headless 240 frames sans erreur.

- [x] Conserver les tuiles en main dans le partage avant leur défausse à la défaite.

Validation : reproduction par le véritable chemin de défaite (timeout, partie
par étapes, carte sélectionnée en défausse), conservation des valeurs et joker
après nettoyage, remise à zéro au nouvel essai. Tests main partagée, partage
et nouvelle tentative après erreur 3/3 ; import et démarrage 240 frames réussis.

- [x] Préserver les positions relatives des piles dans le partage, avec cases vides et centrage du triangle à trois piles.

Validation : triangle centré, grille régulière, Snake coudé, miroir, trous et
25 piles serrées/éloignées sans perte. Tests disposition, partage et main finale
3/3 ; import éditeur et démarrage 240 frames sans erreur.

- [x] Utiliser uniquement des espaces pour les trous et les piles terminées dans la grille partagée, sans carrés ni coches.

Validation : espaces insécables pour les cases vides et terminées ; triangle,
Snake, miroirs, partage et main finale vérifiés (3/3). Import éditeur et
démarrage 240 frames sans erreur.

- [x] Simplifier le partage : `.Pile Down.`, grille sans main ni libellé, score et temps, puis liens bruts sans titre.

Validation : ordre titre/grille/score/temps/liens, absence de main et de
libellés, conservation de la disposition et instantané de défaite testés
(3/3). Le partage des parties par étapes inclut le temps. Import éditeur
et démarrage 240 frames sans erreur.

- [x] Régulariser les cercles dans le partage sans déformer les autres dispositions.

Validation : anneau de 12 piles avec pile centrale à trois angles de rotation,
symétries horizontale/verticale et conservation des 13 piles. Triangles, Snake,
miroirs et instantané final restent vérifiés ; partage 3/3, import éditeur
et démarrage 240 frames sans erreur.

- [x] Auditer le rendu du partage avec les règles et bonus de déplacement des piles et améliorer les approximations esthétiques.

Validation : 28 scénarios et 198 instantanés (3/13/25 piles), déplacements
réels, échanges en cours, miroirs, piles terminées, Pile Mover et Adaptation III.
Corrections : espacement entre voisins alignés, anneaux en paires symétriques
et 11 lignes pour 24 piles autour du centre. Six tests dédiés réussis, import
éditeur et démarrage 240 frames sans erreur. Rapport et aperçus avant/après :
`wip/reports/share-movement/README.md` et `index.html`.

- [x] Ajouter CHIFFRES à CUSTOMISATION : nombres, lettres et points façon Punto, avec aperçu immédiat et sauvegarde du choix.

Validation CHIFFRES : nombres, lettres A–J et points 0–9, aperçu direct avec
police/palette, sauvegarde et chargement, passage au round suivant, masquage,
jokers, Roman Holiday, copie des points dans Snake et rémanence Lights Out.
Les trois onglets tiennent aux tailles testées, y compris en français.
Six tests ciblés réussis ; import éditeur et démarrage 240 frames sans erreur.
Contrôle élargi : `test_secret_codes.gd:71` attend encore « LIBERATION SANS »,
mais la ressource actuelle est nommée « LIBERATION » ; ressource et test laissés
inchangés, car indépendants de cet ajout.

- [x] Utiliser le glyphe « . » de la police choisie pour les points, avec repli sur la police de base si nécessaire.
- [x] Optimiser l’ouverture de CUSTOMISATION et le changement de type de chiffres, avec mesures avant/après.

Validation : glyphe de la police choisie, repli sur VCR (y compris
si une autre fallback est déclarée), métriques réutilisées, copie Snake et
masquage Lights Out ; boutons et aperçu conservés pendant les changements.
Chargement initial progressif, interruption/reprise, invalidation des générations,
filtres et langue testés. Benchmark 23 polices : changement médian 1262 ms →
3,06 ms ; ouverture initiale synchrone 1404 ms → 5,94 ms, listes chargées ensuite.
Neuf tests ciblés réussis ; import et démarrage 240 frames sans erreur.
Le test général `test_progression_menu.gd` conserve son ancienne attente de
35 palettes et échoue avant les contrôles de customisation. Rapport détaillé :
`wip/reports/customisation/README.md`.

- [x] Corriger les noms de polices coupés dans CUSTOMISATION et agrandir les points typographiques.

- [x] Définir les styles de chiffres en ressources/data et ajouter les chiffres romains.
- [x] Succès CIRCUS MAXIMUS : terminer une manche combinant Rome et Manège, récompense chiffres romains.
- [x] Succès DE A À Z : lancer chaque défi au moins une fois, récompense lettres.

- [x] Corriger la largeur des lignes de polices : SelectableText rétablissait 70 px à chaque traitement au lieu de conserver la largeur du conteneur.

- [x] Vérifier les points sur chacune des 27 polices : recadrer le glyphe, augmenter sa taille visible et corriger le centrage indépendamment des offsets des chiffres. Planches 0 à 9 dans wip/reports/pip-fonts/.

- [x] Configurer les points dans FontData : cercles pixel pour 20 polices aux points simples, glyphes conservés pour 7 polices distinctives ; pip_shape et pip_scale dans chaque ressource.

- [x] Réduire légèrement les cercles : pip_scale = 0.85, soit 5 px dans l’aperçu standard.

- [x] Roman Holiday affiche les chiffres classiques si le style romain est déjà sélectionné, puis restaure les romains à la fin de la règle.

- [x] Lier POINTS au succès BRELAN DE JOKERS : trois jokers simultanément en main, comptés à l’ajout d’un joker et selon les conditions d’éligibilité des succès.
