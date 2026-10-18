# Trailer Pile Down

- Français : [`portrait`](pile-down-portrait-fr.mp4), [`paysage`](pile-down-landscape-fr.mp4).
- English: [`portrait`](pile-down-portrait-en.mp4), [`landscape`](pile-down-landscape-en.mp4).
- Portrait : 1080 × 1920, 9:16 ; paysage : 1920 × 1080, 16:9.
- `preview-<format>-<langue>.jpg` : aperçu des séquences du montage.
- `drafts/` conserve la première proposition du trailer.

Les MP4, aperçus et brouillons de ce dossier sont des résultats générés locaux,
ignorés par Git. Seuls ce README et le fichier `.gdignore` sont versionnés ici.
Les scripts et réglages sont conservés dans `publishing/scripts/` ; toutes les
captures et étapes intermédiaires de `wip/trailer/` sont également ignorées.
Le générateur crée les fichiers `.gdignore` pour éviter l'import des captures
et des aperçus dans Godot, y compris après un nouveau clone.

Petit montage à 30 images/s, en MP4 H.264 avec audio AAC : phrases d'accroche
en plein écran alternant avec quatre séquences de gameplay réel, sans cadre
ni titre autour du jeu. Les mots arrivent successivement avec un rebond,
les tuiles apparaissent en cascade. Les accroches restent génériques, sans
sous-titre ni nom de bonus ou de règle : « Chaque geste compte »,
« Attention aux règles spéciales », « Relève le défi ».
Les trois cartes décoratives changent selon l'écran : 8/5/2 à l'introduction,
6/3/1, 7/4/0, 5/2/0 pour les accroches et 3/1/0 à la conclusion.
La conclusion dure 4,2 secondes : le texte remonte, puis 36 cartes de valeurs
variées arrivent en deux vagues, tombent, rebondissent et s'empilent en bas.
Le texte reste visible au-dessus de cette cascade finale.
Pendant sa remontée, le titre « PILE DOWN » apparaît en grand dans la partie
inférieure, derrière les cartes, avec un fondu, un déplacement et un léger rebond.
Son centre est placé à 53 % de la hauteur (5 % plus haut que le placement précédent).
Les deux animations démarrent ensemble à 0,9 seconde dans la conclusion.
Par défaut, des glissements de dix images relient les écrans sans passage au noir ;
le type, le sens et la durée de chaque raccord sont configurables.
Les deux orientations sont capturées séparément en mode adaptatif, sans recadrer
le plateau. Bring a Friend est montré au **niveau 1** : une seule carte voisine
accompagne la carte déplacée ; Shell Game échange réellement les positions des piles.
La quatrième séquence montre le véritable défi Conveyor Belt : les tuiles
défilent sur le tapis roulant et sont attrapées pour être jouées.
Les captures vérifient les poses supplémentaires, les permutations,
le déplacement réel des tuiles et deux poses réussies sur le tapis roulant.

Chaque plateau utilise des paramètres issus de la progression réelle de sa seed,
sans remplacer les valeurs de difficulté. Le HUD conserve le compte à rebours
normal des rounds :

| Séquence | Progression | Compteur affiché | Piles | Tuiles en main | Valeur initiale des piles |
| --- | --- | --- | --- | --- | --- |
| Classique | 3 | 28 | 2 | 2 | 3 |
| Bonus | 8 | 23 | 3 | 3 | 4 |
| Permutations | 15 | 16 | 5 | 4 | 5 |
| Défi tapis roulant | 5 | 15 | 3 | Flux continu | 4 |

Le temps par main provient également de la progression de chaque seed.
Le défi utilise son compteur natif : 15 rounds pour aller de la progression 5 à 20.
Les titres et l'interface du jeu sont localisés en français ou en anglais.
Les titres utilisent la police principale, le sprite et la palette du jeu.
La musique du jeu (`resources/audio/musics/section-1.wav`) joue en continu
du premier au dernier écran, y compris pendant les textes et les transitions.
Seule la fin du trailer comporte un fondu sonore. Les captures isolent les
bruitages du jeu, puis le montage les synchronise avec les séquences de gameplay.

## Régénérer

Installer Godot 4, Python avec Pillow et FFmpeg, puis lancer à la racine :

```sh
python publishing/scripts/create_trailer.py
```

Si Godot n'est pas dans le PATH :

```sh
python publishing/scripts/create_trailer.py --godot "chemin/vers/godot"
```

Les quatre combinaisons format/langue sont créées par défaut. `--format portrait`
ou `--format landscape` choisit une orientation ; `--language fr` ou
`--language en` choisit une langue. `--ffmpeg` permet de choisir l'exécutable
FFmpeg. Pour remonter le dernier enregistrement sans relancer le jeu :

```sh
python publishing/scripts/create_trailer.py --reuse-capture
python publishing/scripts/create_trailer.py --language en --format landscape
```

`--reuse-capture` exige les quatre séquences, dont le défi avec tapis roulant,
leurs configurations variées,
Bring a Friend au niveau 1 et les bruitages seuls. Après une modification des
séquences ou des profils, relancer sans cette option pour renouveler les captures.
Les anciens enregistrements contenant des séquences supplémentaires restent
utilisables s'ils contiennent ces quatre séquences : les autres sont ignorées.

La capture utilise le mode Movie Maker de Godot pour l'audio et le script
`resources/scripts/tools/CaptureTrailer.gd`. Elle nécessite un rendu graphique
disponible (le mode headless ne produit pas les images du jeu).
Les images sont enregistrées après le rendu depuis le viewport complet :
le changement de ratio ne coupe donc ni le HUD ni la main. Le montage les
agrandit sans lissage et conserve leur orientation.
Le mode debug du jeu doit être désactivé. Les sauvegardes et préférences sont
écrites dans un profil temporaire distinct, pas dans celui du joueur.
Les enregistrements et images intermédiaires restent dans
`wip/trailer/<format>-<langue>/`. Les seeds reproductibles sont sélectionnées
pour montrer le bonus avec une voisine jouable sans modifier les valeurs des cartes.
`capture.json` atteste du niveau du bonus, du nombre de compagnons et des poses ;
il conserve aussi les configurations, les seeds et les compteurs de rounds.
`edit.json` décrit les instants des transitions, les accroches, les cartes des
titres, la cascade finale, l'apparition du titre du jeu et la musique utilisée.

Le déroulé du gameplay se modifie dans `CaptureTrailer.gd`. Les textes, la mise
en page, les animations et les transitions se modifient dans
[`trailer_config.py`](../scripts/trailer_config.py), à côté du générateur
`publishing/scripts/create_trailer.py`. Les vidéos finales sont remplacées
lors d'une régénération ; les autres fichiers de publication sont conservés.

## Ajuster le montage manuellement

Tous les réglages du montage sont dans `publishing/scripts/trailer_config.py`.
Ils s'appliquent aux quatre vidéos et fonctionnent avec `--reuse-capture` :

| Réglage | Effet |
| --- | --- |
| `COPY` | Accroches françaises et anglaises ; `\n` impose un retour à la ligne. |
| `TITLE_DURATIONS`, `TITLE_TILES` | Durée de chaque écran de texte et valeurs de ses tuiles. |
| `TITLE_DEFAULTS["headline"]` | Placement, taille, marges, interligne et arrivée des mots. |
| `TITLE_DEFAULTS["accent"]` | Placement, taille, couleur et apparition du trait. |
| `TITLE_DEFAULTS["tiles"]` | Placement, taille, espacement, rebond et rotation des tuiles. |
| `TITLE_DEFAULTS["lift"]` | Début, durée et distance de remontée de l'accroche finale. |
| `TITLE_DEFAULTS["brand"]` | Placement, taille, fondu et mouvement du « PILE DOWN » final. |
| `TITLE_DEFAULTS["cascade"]` | Nombre, taille, répartition, départ et vitesse des cartes finales. |
| `FORMAT_OVERRIDES`, `TITLE_OVERRIDES` | Ajustements pour une orientation ou un écran précis. |
| `TRANSITION_DEFAULTS`, `TRANSITION_SEQUENCE`, `TRANSITION_OVERRIDES` | Type, style, direction et durée des raccords. |
| `MUSIC`, `AUDIO` | Musique, volume et fondus sonores. |

Les coordonnées `x`, `y` et les distances `*_ratio` sont relatives à la vidéo :
`0` correspond au bord gauche/haut, `0.5` au centre et `1` au bord droit/bas.
**Diminuer `y` remonte un élément.** `x` centre le bloc horizontalement ; `y`
désigne le haut de l'accroche sur une ligne (le bloc multiligne s'étend autour)
et le centre du titre final/des tuiles. Les tailles, espacements et décalages
`offset_x`, `offset_y` sont en pixels de sortie. Les temps sont en secondes ;
les durées des écrans et des transitions sont arrondies à l'image la plus proche.
Une durée d'animation de zéro affiche directement son état final.

L'ordre de priorité est : réglages communs → orientation → titre → orientation
de ce titre. Chaque surcharge conserve les propriétés non précisées. Exemple
pour remonter davantage le titre final en portrait et déplacer une accroche :

```python
TITLE_OVERRIDES = {
    "intro": {"headline": {"font_size": 190}},
    "friends": {"headline": {"y": 0.40, "offset_x": -20}},
    "outro": {
        "portrait": {"brand": {"y": 0.50, "font_size": 200}},
        "landscape": {"brand": {"y": 0.53}},
    },
}
```

`brand.start = None` synchronise l'apparition du titre final avec `lift.start` ;
un nombre définit un départ indépendant. Les propriétés `visible` masquent
séparément le trait, les tuiles, le titre final ou la cascade.

Les transitions proposent trois types : `fade` (fondu enchaîné), `swipe`
(balayage) et `cut` (coupe franche). Pour un swipe, `direction` vaut `left`,
`right`, `up` ou `down`, et `style` vaut `smooth` (glissement doux), `slide`
(glissement) ou `wipe` (volet). La direction indique le sens du déplacement
ou du balayage. Le fondu ignore le style et la direction ; la coupe ignore
aussi la durée et ne chevauche pas les plans.

`TRANSITION_SEQUENCE` surcharge les raccords dans l'ordre, puis recommence
au début de la liste. Une liste vide applique uniquement les réglages communs.
Pour tout passer en fondu de 0,4 seconde :

```python
TRANSITION_DEFAULTS = {"type": "fade", "duration": 0.4}
TRANSITION_SEQUENCE = []
TRANSITION_OVERRIDES = {}
```

Un raccord précis peut recevoir une surcharge prioritaire :

```python
TRANSITION_OVERRIDES = {
    "game:conveyor->title:outro": {"type": "fade", "duration": 0.5},
    "title:intro->game:gameplay": {
        "type": "swipe", "style": "wipe", "direction": "left", "duration": 0.3,
    },
}
```

Les noms des plans sont indiqués dans le fichier de configuration. Pour
réactiver un swipe après avoir supprimé `style`/`direction` des réglages communs,
préciser ces deux propriétés dans sa surcharge. Les fondus et balayages doivent
durer au moins une image ; les chevauchements entrant et sortant doivent laisser
du temps au plan entre eux. Le générateur rejette les raccords incompatibles
avant l'encodage. Les bruitages, la musique et les aperçus suivent automatiquement
les nouvelles durées. `edit.json` conserve les réglages résolus de chaque écran
et de chaque transition.

Pour vérifier rapidement un ajustement sur une seule vidéo :

```sh
python publishing/scripts/create_trailer.py --reuse-capture --format portrait --language fr
```

Les tests du placement et du montage (dont un rendu FFmpeg avec fondu, coupe
et balayage) se lancent avec :

```sh
python -m unittest discover -s tests -p test_trailer.py
```

Référence : [mode Movie Maker de Godot](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html).
