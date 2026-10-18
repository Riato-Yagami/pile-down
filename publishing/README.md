# Fichiers de publication

| Dossier | Contenu |
| --- | --- |
| `itch/` | Bannière, miniatures, GIF, image intégrée et description HTML itch.io. |
| `kofi/` | Bannière Ko-fi prête à importer : [`banner.png`](kofi/banner.png). |
| `trailer/` | MP4, aperçus et brouillons locaux ignorés par Git ; instructions de régénération versionnées. |
| `kofi/drafts/` | Ancienne proposition générée par imagegen et son prompt, conservés comme brouillon. |
| `sources/` | Source Photoshop de la bannière itch.io. |
| `scripts/` | Générateurs des visuels de publication. |
| `screenshots/` | Captures itch.io et séries Google Play dans `2.0/`. |
| `devlog/` | Textes des annonces de version. |

Les captures intermédiaires des trailers restent dans `wip/trailer/`, ignoré
par Git. Les scripts et réglages de montage sont conservés dans `scripts/`.
Les références temporaires de génération Ko-fi dans `wip/kofi-banner/` sont
également locales ; la bannière finale et ses sources restent versionnées.

## Bannière Ko-fi

`kofi/banner.png` est un PNG opaque de **1200 × 400 pixels** (ratio **3:1**),
inférieur à 8 Mo. « juels » est centré dans la police principale du jeu.
Les dix tuiles utilisent le sprite `resources/sprites/tiles/tile-face.png`,
les associations chiffre/couleur de `resources/data/palettes/00_arcade.tres`
et les couleurs d'interface de `resources/scripts/settings/colors.gd`.
Le masque vert est remplacé comme dans le shader des cartes ; les tuiles
sont agrandies et tournées sans lissage. Chaque chiffre apparaît sur une
seule tuile, sans copie superposée, et les contours restent espacés d'au
moins dix pixels.

Depuis la racine du dépôt, avec Python et Pillow installés :

```sh
python publishing/scripts/create_kofi_banner.py
```

La génération est déterministe et remplace uniquement `kofi/banner.png`.

## Miniature animée itch.io

Avec Bash et ImageMagick 7, depuis la racine :

```sh
./publishing/scripts/create_thumbnail_gif.sh --tiles 4
```

Le script utilise `itch/thumbnail.png` et `build/renders/tiles/`, puis écrit
`itch/thumbnail-animated.gif`. Les commandes de capture des screenshots
figurent dans le README principal et dans `screenshots/2.0/README.md`.
