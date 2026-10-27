# Audit Snake et partage — 25 octobre 2026

## Compatibilité des règles

`test_snake_compatibility.gd` vérifie les exclusions dans les deux sens pour
les 20 autres ressources de règles, puis les 13 associations autorisées en jeu :

- SHELL GAME, LIGHTS OUT, PEEK-A-CARD, STACK ATTACK, ROMAN HOLIDAY ;
- STICKY FINGERS, HOT POTATOES, BLIND DELIVERY, MIRROR MATCH ;
- SUDDEN DEATH, GRACE PERIOD, COLORBLIND, PIXELATED.

Les repas, le soin différé, les réapparitions sans collision, le dépôt valide et
le nettoyage sont exercés pour chaque paire. MIRROR MATCH est testé avec les
miroirs horizontal, vertical et double. Deux combinaisons de six règles passent :

- Snake, Mirror Match, Shell Game, Stack Attack, Roman Holiday, Grace Period ;
- Snake, Mirror Match, Sticky Fingers, Hot Potatoes, Blind Delivery, Peek-a-Card.

Les sept exclusions sont maintenues : Merry-Go-Stack, Shaking Piles, Wavy Baby,
Free-Range Cards, Musical Stacks, Pile Up et Floor Is Lava. Cette dernière règle
est également désactivée dans le catalogue actuel. Les motifs sont décrits dans
le README. Les verrous debug peuvent contourner ces exclusions.

Corrections : calcul des rectangles depuis les coins transformés (les rectangles
Godot décomposés étaient incorrects sous certains miroirs), prise en compte des
cases traversées sous miroir, collisions de nourriture sur le corps, et stockage
de la position de grille indépendamment du pivot de retournement d’une pile.

## Partage

`test_result_share.gd` vérifie le résultat réel de fin de partie, les 30 manches
restantes, le temps de 2 s 672 ms, les deux liens, l’absence de BBCode, la copie
via un récepteur injecté, la confirmation visuelle, le résultat figé et le pied
de fenêtre avec une seed longue, repliée, dépliée ou masquée.

Les tailles testées sont 256 × 320, 636 × 323 et 752 × 640. Le lien itch.io pointe
sur la page du jeu ; le lien Google Play utilise l’identifiant Android existant
`dev.juels.piledown`. La disponibilité publique du listing Google Play n’a pas
pu être confirmée par la consultation web. Aucun message n’est publié en ligne :
le joueur colle le texte copié sur le réseau social de son choix.

## Vérifications

La suite ciblée Snake comprend 13 scripts et passe entièrement : tests Snake,
Special Rules, régénération de main, replay des seeds et Sticky Hand Lock.
La suite partage ajoute Result Share, End Screen Size et Mistake Timer Freeze.
L’import éditeur Godot et le démarrage headless de 240 frames sont également
contrôlés. Le test de glissement Snake a été adapté au soin désormais différé.

Le contrôle élargi a aussi rencontré des échecs dans d’autres tests :

| Test | Attente en échec dans l’état actuel du dépôt |
| --- | --- |
| `test_new_special_rules.gd:32` | Attend Floor Is Lava dans le catalogue activé, alors que cette règle est désactivée. |
| `test_special_rule_effects.gd:192` | Interdit la surcharge de material de PixelationOverlay déjà présente dans Game.tscn. |
| `test_lights_out_afterglow.gd:30` | Le démarrage dépend du verrou debug Snake actif et le comptage initial des rémanences échoue. |
| `test_game_start.gd:50` | Attend le chronomètre global visible par défaut. |
| `test_victory_display.gd:24` | Attend le titre anglais littéral `YOU WIN`, alors que la partie utilise la localisation configurée. |

Ces tests généraux n’ont pas été modifiés. Leurs échecs ne sont pas masqués par
les rapports des suites ciblées. L’audit headless ne remplace pas une vérification
visuelle des shaders ni un essai du presse-papier sur chaque plateforme exportée.

## Complément : sortie sous Mirror Match

Le décalage de Quitter a été reproduit par `test_mirror_quit_transition.gd`
avant correction. La destination du menu est désormais calculée sans la réflexion
du plateau, qui reste inchangée pendant le glissement. Les trois axes de miroir
passent en dispositions semi-adaptative et menu-adaptative, y compris lors des
rafraîchissements de layout et du réattachement du menu à Screens.

Les tests Quit Popup Layout, Result Share et Semi Adaptive Canvas passent aussi.
Le contrôle supplémentaire `test_shared_menu_orientation.gd:38` échoue sur son
attente d’afficher simultanément les listes de polices et de palettes ; le menu
actuel utilise deux sous-onglets. Ce test n’a pas été modifié.

L’icône de partage utilise désormais la ressource existante `links.png`.
