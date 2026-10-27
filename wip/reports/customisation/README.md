# Points typographiques et performance de CUSTOMISATION

## Points

Les points sont dessinés avec le caractère « . » de la police choisie, par
la texture rasterisée par Godot, recadrée sur son encre visible. Sa densité et
son centre de masse servent à dimensionner et centrer les points. Le bitmap,
la texture et les métriques sont mis en cache par police et taille.
L’audit complet est dans [pip-fonts](../pip-fonts/README.md).

Si la police principale n’a pas de point ou si sa taille rendue est vide, le
point de VCR, la police de base, est utilisé. Le repli ne choisit pas une police système
arbitraire. Les couleurs de la palette, le masquage, les jokers et les règles
restent indépendants. Les copies des animations Snake conservent aussi la police.

Référence des API natives : [CanvasItem / draw_char](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-char),
[TextServer / métriques de glyphes](https://docs.godotengine.org/en/stable/classes/class_textserver.html#class-textserver-method-font-get-glyph-offset).

## Optimisation

Les listes POLICES et PALETTES sont créées uniquement lorsqu’on les consulte,
à raison d’une entrée par frame lors de leur première construction. L’en-tête
et l’aperçu peuvent ainsi apparaître sans attendre la liste entière. Les listes
sont ensuite conservées, y compris si on quitte la page ; une construction
interrompue reprend là où elle s’était arrêtée.

Le changement NOMBRES/LETTRES/POINTS réutilise les boutons et les tuiles existants.
Il ne reconstruit plus tout le snapshot ni toutes les listes de cosmétiques.
Les caches tiennent compte des choix, des déblocages, des filtres et de la langue.
Les pages masquées désactivent le traitement de leurs contrôles.

## Mesures

Benchmark headless avec 23 polices débloquées, même scène et profil isolé.
Les durées ci-dessous mesurent le travail synchrone de la commande ; le coût
GPU, la cadence d’affichage et le remplissage progressif complet sont exclus.

| Opération | Avant | Après |
| --- | ---: | ---: |
| Première ouverture de CUSTOMISATION | 1 404 ms | 5,94 ms puis remplissage progressif |
| Réouverture, médiane | 1 236 ms | 0,71 ms |
| Changement de type, médiane | 1 262 ms | 3,06 ms |

Les mesures brutes sont dans [before.json](before.json) et [after.json](after.json).
Ces chiffres dépendent de la machine ; les tests vérifient la réutilisation des
nœuds plutôt qu’un seuil temporel fragile.

## Validation

- Styles et aperçu : police réelle du point, repli si le point manque, métriques
  réutilisées, masquage et copie Snake/Lights Out.
- Cache : arrêt/reprise d’une construction, annulation d’une ancienne génération,
  filtres, changement de langue et destruction de la scène.
- Régressions : onglets, sélection des cosmétiques, animation de repas Snake et
  première ouverture des menus.
- Import éditeur Godot et démarrage headless de 240 frames.

Les rapports sont [tests.json](tests.json), [glyph-tests.json](glyph-tests.json)
et [cache-tests.json](cache-tests.json).

Pour reproduire le benchmark :

```sh
PILE_DOWN_CUSTOMISATION_BENCHMARK=/tmp/customisation-benchmark.json \
python3 tests/run_godot_tests.py --timeout 100 test_customisation_performance.gd
```

Les neuf tests ciblés passent (six dans `tests.json`, le test de cache et les
tests de filtre et de disposition adaptative). Le contrôle élargi
`test_progression_menu.gd` reste bloqué par son attente historique de 35 palettes,
qui ne correspond pas au catalogue activé actuel. Cette attente a été laissée
inchangée. Les parties du test qui accèdent aux listes sont adaptées à leur
construction progressive. Détail : [progression-tests.json](progression-tests.json).

## Correction de largeur des noms de polices

`SelectableText` réappliquait sa largeur minimale de 70 pixels pendant le
traitement des lignes sans ajustement au contenu. Les lignes expansibles
conservent maintenant la largeur attribuée par leur conteneur. Le test de cache
vérifie cette largeur après plusieurs frames, en plus des dimensions du titre.

Validation de cette correction : cache, sélection des cosmétiques, performance
et disposition adaptative passent, ainsi que l’import et le démarrage Godot.
Le contrôle supplémentaire `test_progression_lock_filter.gd` échoue à la
ligne 49 sur la détection de la pose intermédiaire de son animation de cadenas ;
ce composant n’est pas modifié par la correction de largeur.
