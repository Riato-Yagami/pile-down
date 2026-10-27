# Vérification des points, police par police

Les 27 ressources FontData ont été vérifiées, avec les valeurs 0 à 9, y compris
les polices secrètes et celles hors du catalogue actif. Les planches utilisent
les cercles pixel ou les pixels réels du point rasterisé par Godot, selon le
réglage de chaque police, et les rectangles de dessin de
TilePips ; elles sont composées sur CPU, et ne sont pas des captures GPU du jeu.

Voir [toutes les polices](index.html) et les planches [1](page-1.png),
[2](page-2.png), [3](page-3.png). Chaque rangée montre 0 à 9 à taille double.
Les mesures par police figurent dans [fonts.json](fonts.json).

Le rendu retire les marges transparentes de l’atlas du glyphe et dimensionne
le point sur son encre visible. Les glyphes ajourés ou peu opaques sont agrandis
suivant leur densité, en conservant leur forme et un espace entre les points.
La position tient compte du centre de masse de l’encre. Les décalages optiques
propres aux chiffres de chaque police sont annulés pour le motif de points ;
le relief de deux pixels et les déplacements animés de la carte sont conservés.
Sur une tuile de 34 × 37 pixels, le grand côté visible fait 5 pixels pour les cercles et 6 à 8 pour les glyphes.
Les 20 polices à point simple utilisent un cercle pixel. Les glyphes sont
conservés pour Edit Undo Dot, Upheaval, Digitalix, Gothic Pixels, Pixelated Pusab,
Comic Relief et Liberation. Le choix est explicite dans chaque FontData :
`pip_shape = 0` pour le cercle, `pip_shape = 1` pour le glyphe. `pip_scale`
contrôle la taille relative. Les cercles sont rasterisés à leur diamètre entier
final, sans anticrénelage, puis filtrés en nearest.

Le bitmap recadré, ses métriques et sa texture sont mis en cache par police et
taille. Les copies Snake et Lights Out conservent le même placement.

Reproduire les images :

```sh
PILE_DOWN_PIP_AUDIT=/tmp/pile-down-pip-audit \
python3 tests/run_godot_tests.py --timeout 100 test_pip_font_audit.gd
```

Le contrôle vérifie chaque ressource, le repli, les marges transparentes,
le centrage malgré les décalages des polices, les dix motifs et leur encombrement.
API Godot : [TextServer, texture et UV du glyphe](https://docs.godotengine.org/en/stable/classes/class_textserver.html#class-textserver-method-font-get-glyph-uv-rect).
