# Équilibrage speedrun — 18 septembre 2026

Objectifs : strictement moins de **5 min / 20 min / 45 min** pour terminer
respectivement 10 / 20 / 30 rounds d'une partie normale depuis le début.
Les anciens seuils étaient 5 / 10 / 30 minutes. Les IDs et les récompenses
restent identiques, donc les succès déjà acquis sont conservés.

## Méthode

`benchmark_speedrun.gd` joue les cartes dans la scène `Game.tscn`, avec la
génération normale des mains, de la difficulté et des règles spéciales. Aucun
round n'est sauté, aucune pile n'est modifiée directement, aucun bonus n'est
accordé artificiellement et le mode invincible est désactivé dans la configuration
testée. Le mode par défaut refuse les bonus ; l'argument `bonuses` choisit
systématiquement la première offre, y compris pour le retrait d'une règle.

Le délai de 0,9 s après chaque déverrouillage représente une cadence rapide
de reconnaissance et de déplacement ; 1,8 s sert de comparaison plus lente.
Les animations s'ajoutent à ces délais. La mesure additionne les deltas Godot
uniquement quand le chrono de run est actif : présentation du round et animations
de pose incluses, transitions entre rounds et choix de bonus exclus.

Il s'agit de parties automatisées, **pas d'un test humain à la souris** : le
solveur consulte les valeurs internes, dispose d'une mémoire parfaite et appelle
la pose après le début du drag, sans simuler sa trajectoire. Les obstacles visuels,
la poursuite des piles mobiles et les erreurs de mémoire ne sont donc pas
réellement évalués. Les délais sont des hypothèses de rythme, pas des mesures
humaines. Trois seeds ne couvrent pas tous les tirages possibles.

`--fixed-fps 20` accélère l'exécution ; les durées ci-dessous sont du temps actif
simulé, pas le temps mural des achievements pendant le benchmark. Vérification
à 60 images simulées/s sur les 10 premiers rounds : PACE-01 donne 240,63 s
contre 243,44 s à 20, et PACE-02 186,83 s contre 187,44 s. Cet écart est petit
devant les marges retenues ; les événements dépendant du temps peuvent modifier
la suite d'une partie.

## Résultats sans bonus

| Seed | Délai par décision | 10 rounds | 20 rounds | 30 rounds | Poses sur la partie |
|---|---:|---:|---:|---:|---:|
| PACE-01 | 0,9 s | 4:03,44 | 18:03,84 | 38:58,89 | 1068 |
| PACE-02 | 0,9 s | 3:07,44 | 15:17,59 | 37:12,49 | 1029 |
| PACE-03 | 0,9 s | 4:21,24 | 15:35,99 | 32:54,94 | 892 |
| PACE-01 | 1,8 s | 5:48,24 | 26:03,69 | 55:24,24 | 1077 |

Les trois parties rapides se terminent sans erreur. Le seuil de 5 minutes
laisse au moins 39 secondes de marge sur cet échantillon ; celui de 20 minutes,
1 min 56 ; celui de 45 minutes, 6 min 01. Cela ménage des hésitations et des
erreurs sans demander un build de bonus particulier. Ces marges ne garantissent
pas la réussite sur toutes les seeds.

Le rythme lent échoue aux trois seuils malgré zéro erreur : la cadence reste
nécessaire. Le nombre de poses légèrement différent vient des règles qui
évoluent avec le temps de jeu.

Essai complémentaire avec les bonus proposés normalement, PACE-02 à 0,9 s :
**3:07,44 / 15:11,99 / 36:51,94**, 1029 poses et zéro erreur. Bonus obtenus :
Time Bank III, Safety Net, Open Book, Lucky Hand et Lesson Learned. Cet essai
ne couvre pas les builds optimisés de poses automatiques, qui peuvent aller
plus vite.

Validation : cinq parties complètes, tests des achievements, import éditeur
et démarrage headless. Aucune erreur de script ou de ressource manquante
observée. L'environnement Windows signale un échec de lecture du magasin
de certificats racine ; quatre benchmarks signalent également quatre objets
encore présents à la fermeture. Les processus terminent avec le code 0.

## Reproduction

Utiliser un profil de test : les parties écrivent des sauvegardes et des succès.
Exemple PowerShell, avec `godot` dans le PATH :

```powershell
$env:APPDATA = Join-Path $PWD 'build/speedrun-test-profile'
godot --headless --path . --fixed-fps 20 --script tests/benchmark_speedrun.gd -- 0.9 PACE-01
godot --headless --path . --fixed-fps 20 --script tests/benchmark_speedrun.gd -- 1.8 PACE-01
godot --headless --path . --fixed-fps 20 --script tests/benchmark_speedrun.gd -- 0.9 PACE-02 bonuses
```

Répéter avec `PACE-02` et `PACE-03` pour comparer les tirages. Le script retourne
un code non nul si la partie échoue ou si le jeu reste bloqué. Les tests de
`test_achievements.gd` vérifient séparément que la limite exacte ne débloque pas
le succès, mais qu'un temps inférieur d'une milliseconde le débloque, ainsi que
l'exclusion des checkpoints et la prise en compte des seuils des ressources.
