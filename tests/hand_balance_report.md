# Analyse du tirage des mains — Pile Down

L'analyse initiale comprend 97 800 rounds, 326 cas et 3 051 600 mains stratégiques simulés sous Godot 4.7.2. Les sondes ajoutent 1 260 000 mains, à raison de 20 000 par cas. La version intégrée est comparée sur 36 000 rounds supplémentaires ci-dessous.

Les stratégies ont une mémoire parfaite et choisissent toujours un coup légal. « Série » privilégie la pile jouable la plus avancée ; « alignement » privilégie la moins avancée. À égalité, la première pile est choisie.

## Version intégrée

La version retenue conserve les freins `0.4 / 0.6` et ajoute une préférence
de plateau de force `0.3`, calculée par `PileDrawBias`. Elle vise un écart
`min(0.4 × S, 2.5)` après un coup simple. Les scores quadratiques sont
normalisés relativement au meilleur coup avant l'exponentielle, avec un
plancher de `0.05`. Cela évite de perdre toute préférence sur un plateau
très déséquilibré. Les valeurs non jouables gardent leur poids de base.

La comparaison du générateur réel ajoute 36 000 rounds, répartis en 120 cas :
forces `0 / 0.2 / 0.3 / 0.4`, mains de 1, 2 et 4 cartes, 2, 4 et 8 piles,
valeurs initiales 2, 3, 5, 7 et 9 et Lucky Hand I / III. Chaque cas comporte
300 seeds. Les données sont dans `hand_balance_production_results.json`.

Scénario central : quatre piles à 7, quatre cartes, aucun bonus.

| Force du plateau | Autre pile intacte, stratégie en série | Presque aligné, stratégie d'alignement | Une seule valeur utile, stratégie d'alignement |
|---|---:|---:|---:|
| 0, anciens freins seuls | 62.7 % | 37.6 % | 65.3 % |
| 0.2 | 3.7 % | 29.9 % | 65.6 % |
| **0.3, retenue** | **1.3 %** | **26.8 %** | **66.4 %** |
| 0.4 | 0.0 % | 24.2 % | 66.3 % |

La force 0.3 réduit nettement les longues séries tout en restant moins
contraignante que 0.4. La stratégie en série rencontre toutefois davantage
de mains à une seule valeur utile : 60.5 % à 66.8 %. C'est un compromis de
choix, pas une preuve que le ressenti sera meilleur.

Sur les rounds très courts, les essais avec cible 1 ou 1.2 n'empêchaient pas
les fins prématurées et facilitaient légèrement l'alignement. Le biais est
donc désactivé à `S <= 3`. Il disparaît également avec une seule pile restante
ou une seule valeur jouable. Les autres freins restent actifs.

Lucky Hand garde ses coups bonus. Avec Lucky Hand III, les fins en série avec
une autre pile intacte restent possibles : 94.7 % avec les seuls freins,
68.0 % avec la force 0.3 dans le scénario central. Préserver ce bonus limite
volontairement l'effet anti-stratégie. Reload Required conserve exactement
son tirage antérieur et les cartes conservées ne sont pas retouchées.

Les tests vérifient aussi la symétrie Pile Up, l'absence de modification des
piles, le plancher relatif et la jouabilité de rounds complets avec une
seule carte, même avec des freins à 1 et une force de plateau extrême.
Le tapis roulant utilise le même calcul de poids ; cette comparaison ne
simule pas ses contraintes de temps ni les chaînes automatiques de bonus.

Reproduction :

```sh
godot --headless --path . --script tests/analyze_hand_balance.gd -- --production
godot --headless --path . --script tests/test_pile_draw_bias.gd
```

## Recommandation initiale et prototypes

Pour conserver les deux constantes, `0.7 / 0.7` est un compromis à essayer : il freine mieux les séries et diminue l’alignement, mais offre moins de choix qu’actuellement. `0.6 / 0.8` donne davantage de priorité à l’anti-alignement. Les deux valeurs à `0.9` rendent le tirage très contraignant, sans prouver que le jeu devient plus amusant.

Le meilleur candidat testé sur les rounds à grandes valeurs est une préférence souple suivant l’écart après le coup possible. Le prototype doux utilise une force de 0.3 et une cible de 2.5. Sa cible fixe peut cependant favoriser une fin rapide sur les petits rounds : ce prototype demande un calibrage suivant la plage de valeurs et une validation humaine.

Les constantes du jeu restent `0.4 / 0.6`. Les prototypes sont isolés dans le banc de simulation. La correction fonctionnelle livrée maintient une pondération relative lorsque le second frein vaut zéro ; auparavant, ce cas basculait vers une autre méthode de tirage. Un test couvre la continuité près de zéro. Les deux freins nuls préservent le tirage uniforme et sa séquence RNG.

## Sens des deux freins initiaux

Le poids d’une valeur dans la carte garantie est :

`nombre de piles compatibles × facteur de continuation × facteur de répétition`

Chaque facteur vaut `1 - suppression` et s’applique seulement à sa valeur cible. Les poids sont ensuite normalisés. Dans les autres emplacements, chaque valeur commence avec un poids 1.

Ainsi, `0.6` réduit le poids de 60 %. Ce n’est ni une réduction de 60 % de la probabilité finale, ni une chance de 40 % de trouver cette valeur dans la main.

La continuation cible la prochaine valeur attendue de la dernière pile jouée. La répétition cible sa valeur courante, après d’éventuelles chaînes automatiques.

Sur le plateau `[6, 6, 6, 5]`, dernière pile à 5, la carte 5 aligne les autres et la carte 4 continue la dernière. Avec les paramètres actuels, leurs poids garantis sont `3 × 0.4 = 1.2` et `1 × 0.6 = 0.6`. La carte garantie favorise donc encore l’alignement à raison de 2 contre 1.

Si une valeur a une probabilité `q` dans la carte garantie et `r` dans chacun des autres emplacements, sa disponibilité dans une main de `M` cartes vaut `1 - (1 - q) × (1 - r)^(M - 1)`. Cette formule exclut Lucky Hand, les jokers et les cartes conservées.

## Rounds complets

Scénario central : 4 piles initialement à 7, main de 4, aucun bonus, 300 seeds par configuration et stratégie.

- « Autre pile intacte » : la première pile atteint zéro alors qu’au moins une autre est encore à sa valeur initiale. Cela ne signifie pas que toutes les autres piles sont intactes.
- « Presque aligné » : après le coup, le maximum moins le minimum de toutes les piles, terminées comprises, est inférieur ou égal à 1.
- « Une seule valeur utile » : la main propose une seule valeur légale, éventuellement sur plusieurs piles. Ce n’est pas une main injouable.

| Réglage | Autre pile intacte, stratégie en série | Presque aligné, stratégie d’alignement | Une seule valeur utile, stratégie d’alignement |
|---|---:|---:|---:|
| Sans biais | 71.3 % | 54.2 % | 61.9 % |
| Actuel 0.4 / 0.6 | 62.7 % | 37.6 % | 65.3 % |
| 0.7 / 0.7 | 46.0 % | 32.6 % | 71.3 % |
| 0.9 / 0.9 | 29.3 % | 22.3 % | 78.8 % |
| 0.6 / 0.8 | 59.7 % | 28.2 % | 69.0 % |
| 0.8 / 0.9 | 46.0 % | 21.6 % | 74.3 % |
| Valeurs distinctes + actuel | 72.7 % | 33.4 % | 65.5 % |
| Adaptation à la main | 46.3 % | 28.1 % | 70.9 % |
| Écart fort, cible 2 | 0.0 % | 29.9 % | 74.3 % |
| Écart doux, cible 2.5 | 0.0 % | 26.1 % | 67.7 % |
| Écart croissant | 0.0 % | 35.8 % | 73.5 % |

Zéro événement sur 300 rounds ne constitue pas une interdiction. Sous un modèle binomial, la borne supérieure unilatérale à 95 % est d’environ 1 % par round. Les différences de quelques points ne suffisent pas à prouver un meilleur ressenti. Les coups d’un même round sont corrélés.

## Taille de la main

Sonde sur `[6, 6, 6, 5]`, dernière pile à 5, valeurs 0 à 6, réglages actuels, sans bonus.

| Cartes | Carte 5 disponible pour aligner | Carte 4 disponible pour continuer |
|---|---:|---:|
| 1 | 66.5 % | 33.5 % |
| 2 | 68.6 % | 40.2 % |
| 4 | 73.2 % | 51.3 % |

Les deux taux peuvent dépasser 100 % au total : la main peut proposer les deux valeurs. Avec une seule carte, le joueur n’a aucun choix de valeur.

## Plage de valeurs

Sonde équivalente, trois piles au même niveau et la dernière un cran plus bas, main de 4. Pour la plage 0 à 1, le plateau est `[2, 2, 2, 1]`.

| Valeurs tirables | Carte d’alignement disponible | Carte de continuation disponible |
|---|---:|---:|
| 0 à 1 | 92.5 % | 95.8 % |
| 0 à 2 | 83.4 % | 77.0 % |
| 0 à 6 | 73.2 % | 51.3 % |
| 0 à 8 | 71.4 % | 47.1 % |

Lorsque les deux seules valeurs possibles sont toutes deux jouables, réduire leurs poids dans les mêmes proportions ne change rien après normalisation. Le prototype divisant les poids résiduels par `sqrt(M)` rencontre cette limite.

Vérification sur des rounds complets, 4 piles et 4 cartes :

| Valeur initiale | Autre pile intacte : actuel / prototype doux | Presque aligné : actuel / prototype doux |
|---|---:|---:|
| 2 | 100.0 % / 100.0 % | 90.6 % / 78.8 % |
| 3 | 100.0 % / 100.0 % | 74.1 % / 59.2 % |
| 5 | 91.0 % / 65.7 % | 52.2 % / 36.9 % |
| 7 | 62.7 % / 0.0 % | 37.6 % / 26.1 % |
| 9 | 35.0 % / 0.0 % | 29.5 % / 20.5 % |

## Lucky Hand

Le vrai code de Lucky Hand est utilisé, avec ses probabilités actuelles : 20 % au niveau I et 45 % au niveau III. Ses emplacements spéciaux gardent la priorité sur les biais.

| Niveau | Autre pile intacte : actuel / prototype doux | Presque aligné : actuel / prototype doux |
|---|---:|---:|
| 0 | 62.7 % / 0.0 % | 37.6 % / 26.1 % |
| 1 | 83.0 % / 15.3 % | 29.1 % / 20.6 % |
| 3 | 94.7 % / 53.0 % | 59.1 % / 46.2 % |

Lucky Hand III réintroduit beaucoup d’alignement et de séries : cela correspond à son avantage volontaire. Les tests du dépôt couvrant Lucky Hand et ses interactions passent également.

## Protocole et limites

Le banc appelle `HandManager.generate_hand()` et `_apply_lucky_hand()` du jeu. Une sous-classe remplace uniquement l’instanciation visuelle par une capture des valeurs. Les variantes expérimentales surchargent le choix d’une valeur.

Les cas de base utilisent 2, 4 et 8 piles, valeur initiale 7, mains de 1, 2 et 4, et 300 seeds. Les rounds supplémentaires couvrent les valeurs initiales 2, 3, 5 et 9, avec 4 piles et 4 cartes. Les seeds 10000 à 10299 sont réinitialisées pour chaque cas ; les sondes utilisent la seed 9001.

Chaque main vérifie la présence d’une valeur jouable et les bornes. Chaque round est vérifié terminé après le nombre attendu de coups. Le modèle joue une carte puis redemande une main complète.

Les variantes comparent les poids fixes symétriques et asymétriques, les valeurs distinctes plutôt que leur multiplicité, les freins adaptés à la main et les biais d’écart. L’adaptation à la main utilise `1 - (1 - suppression) / sqrt(M)`.

Le prototype doux multiplie le poids d’une valeur jouable par `exp(-0.3 × (écart_après_coup - 2.5)^2)`. Il garde la multiplicité et les freins actuels. Ce facteur est positif et n’interdit aucune pile. Le prototype croissant fait varier la cible de 1 à 3 ; il ne gagne pas sur les deux stratégies simultanément dans le scénario central.

Le modèle exclut le temps de réaction, les erreurs, les jokers conservés, la défausse interactive, les chaînes Double Down/Deja Vu, les règles spéciales et Conveyor. Le rendement des combos Lucky Hand n’est pas quantifié. Reload Required est couvert par le test existant, mais sa stratégie de redraw n’est pas simulée. Ces mesures ne prouvent ni la difficulté mémorielle humaine, ni le plaisir de jouer.

## Reproduire

```sh
godot --headless --path . --script tests/analyze_hand_balance.gd
godot --headless --path . --script tests/analyze_hand_balance.gd -- --extra
godot --headless --path . --script tests/analyze_hand_balance.gd -- --soft
godot --headless --path . --script tests/analyze_hand_balance.gd -- --ranges
godot --headless --path . --script tests/analyze_hand_balance.gd -- --value-games
godot --headless --path . --script tests/test_last_pile_suppression.gd
godot --headless --path . --script tests/test_lucky_hand.gd
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 240
```

Les données brutes sont dans les quatre fichiers `hand_balance*_results.json` et `hand_balance_value_games.json`. Les configurations sont définies dans `analyze_hand_balance.gd`.
