# Backgrounds dynamiques et thèmes de palette

Implémenter un système de **backgrounds procéduraux par shader** ainsi qu’un système de **theme global lié à la palette de tuiles active**.

Objectifs :

* varier visuellement les runs ;
* renforcer la sensation de progression ;
* faire en sorte que les palettes débloquées n’affectent pas seulement les tuiles, mais toute l’interface ;
* conserver un rendu léger, lisible, compatible Web et fidèle au pixel art.

# 1. Backgrounds procéduraux

Les backgrounds doivent être générés **par shader**, dans le même esprit que le shader de `stripes` déjà intégré au projet.

Ne pas utiliser de grandes images bitmap pour les fonds principaux.

Créer un système de presets de background shader-driven.

## Architecture

Créer :

```text id="eopk6t"
BackgroundThemeData.gd
BackgroundThemeRegistry.gd
BackgroundLayer.gd
BackgroundManager.gd
```

Créer une ressource :

```gdscript id="6i4q79"
class_name BackgroundThemeData
extends Resource

@export var id: StringName
@export var display_name: String
@export var shader_scene: PackedScene
@export var supports_morph := true
@export var base_speed := 1.0
@export var tint_strength := 1.0
```

Chaque background doit être instancié comme une couche dédiée derrière le plateau, mais devant une simple couleur unie de fallback.

Ordre recommandé :

```text id="t0gjxv"
SolidColor base
-> Shader background
-> Gameplay board
-> HUD
-> Menus / overlays
```

# 2. Changement de background par Tier Relief

Le background change à chaque `Tier Relief`.

Le changement doit être déterminé au moment où le nouveau tier commence, pas en plein round.

## Règle

Lorsqu’un nouveau tier est atteint :

1. choisir un nouveau background ;
2. lancer une transition visuelle ;
3. remplacer progressivement l’ancien shader par le nouveau.

Le changement peut être :

* cyclique ;
* pseudo-aléatoire basé sur le seed ;
* ou piloté par une table de progression.

Utiliser le seed de la run pour garder la reproductibilité.

Le choix du background doit utiliser :

```gdscript id="kdi6z2"
RunRNG.get_stream(&"cosmetic")
```

et jamais modifier les streams gameplay.

## Répétition

Eviter de retomber immédiatement sur le même background.

Conserver :

```gdscript id="chz1lp"
var last_background_id: StringName
```

et diminuer fortement son poids au tirage suivant.

# 3. Transition par morphing shader

Le changement de background ne doit pas être un simple cut brutal.

Créer une transition de type **morphing shader**.

## Principe

Au changement de tier :

* conserver l’ancien background visible ;
* instancier le nouveau background ;
* lancer une transition de 0.0 vers 1.0 ;
* faire disparaître progressivement l’ancien et apparaître le nouveau.

Créer un shader ou un wrapper de transition avec un paramètre :

```gdscript id="mjlwm5"
transition_t: float
```

Le morphing peut être :

* un mix simple avec bruit procédural ;
* un wipe doux basé sur une texture procédurale ;
* une dissolution pixelisée ;
* une interpolation de motifs avec masque animé.

Privilégier un rendu :

* propre ;
* lisible ;
* peu coûteux ;
* cohérent avec le pixel art.

Ne pas faire un effet trop flashy ou agressif.

## Configuration

Ajouter dans `difficulty.gd` :

```gdscript id="jvwrj5"
const BG_TRANSITION_DURATION := 0.8
const BG_MORPH_PIXELATED := true
```

La transition doit être skippable en même temps que l’annonce Tier Relief si l’annonce elle-même est skippée.

Le skip doit placer directement :

* le nouveau background à 100 % ;
* l’ancien supprimé ;
* les bons paramètres de theme appliqués.

# 4. Idées de backgrounds

Implémenter plusieurs backgrounds procéduraux simples mais distincts.

Ils doivent rester **discrets** : le gameplay reste prioritaire.

## Background 1 - Stripes

Réutiliser et intégrer proprement le shader déjà présent.

Motif :

* bandes diagonales ou horizontales ;
* mouvement lent ;
* léger parallax ou offset.

ID :

```gdscript id="5ew9jt"
&"stripes"
```

---

## Background 2 - Grid

Grille rétro / wireframe.

Motif :

* quadrillage fin ;
* lignes régulières ;
* déplacement très léger ou pulsation douce ;
* possibilité de perspective légère si cela reste lisible.

ID :

```gdscript id="n7khzq"
&"grid"
```

Ce background est une des priorités demandées.

---

## Background 3 - Dots

Trame de points.

Motif :

* petits points réguliers ;
* densité légère ;
* très faible dérive ou respiration.

ID :

```gdscript id="yinbbz"
&"dots"
```

---

## Background 4 - Waves

Ondulations douces.

Motif :

* lignes sinusoïdales ;
* déplacement lent ;
* très faible amplitude.

ID :

```gdscript id="ufwql5"
&"waves"
```

---

## Background 5 - Diamonds

Motif losange / harlequin / grille oblique.

Motif :

* losanges fins ;
* légère variation de taille ou d’intensité ;
* pas de rotation rapide.

ID :

```gdscript id="z79hi6"
&"diamonds"
```

---

## Background 6 - Checker Drift

Damier très léger, presque textile.

Motif :

* checkerboard discret ;
* deux teintes proches ;
* déplacement diagonal très lent.

ID :

```gdscript id="uvnpq4"
&"checker_drift"
```

---

## Background 7 - Concentric

Cercles ou anneaux concentriques.

Motif :

* anneaux centrés ;
* respiration lente ;
* léger décalage du centre possible.

ID :

```gdscript id="bd4wxy"
&"concentric"
```

---

## Background 8 - Starfield Minimal

Champ d’étoiles / points en profondeur, version très minimaliste.

Motif :

* quelques points très discrets ;
* scrolling lent ;
* pas d’effet spatial trop prononcé.

ID :

```gdscript id="es4sni"
&"starfield"
```

Ne pas faire un background trop chargé.

# 5. Contraintes visuelles des backgrounds

Tous les backgrounds doivent respecter :

* contraste faible à moyen ;
* lisibilité maximale des piles, cartes et HUD ;
* pas de clignotement agressif ;
* pas de couleur trop proche des bordures de tuiles ;
* compatibilité avec les palettes colorées ;
* rendu acceptable en petite taille sur mobile.

Le fond ne doit jamais concurrencer les cartes.

Limiter :

* l’amplitude ;
* la vitesse ;
* le contraste ;
* la fréquence des détails fins.

Créer un mode fallback si les shaders échouent ou sont désactivés :

```text id="gy4k52"
solid color background only
```

# 6. Backgrounds et palettes

Les backgrounds doivent être **teintés** par la palette active.

Le joueur choisit une palette de tuiles, et cette palette influence aussi :

* la couleur de fond ;
* le background shader ;
* les boutons ;
* les cadres ;
* certains accents UI.

Cela ne signifie pas utiliser directement les dix couleurs partout.

Il faut dériver un **theme global** cohérent à partir de la palette.

# 7. Theme global dérivé de la palette

Créer un système de thème :

```text id="4zv6d3"
ThemePaletteData.gd
ThemePaletteRegistry.gd
ThemeManager.gd
```

Créer une ressource :

```gdscript id="l19go8"
class_name ThemePaletteData
extends Resource

@export var id: StringName
@export var display_name: String
@export var tile_colors: Array[Color]

@export var ui_bg_color: Color
@export var ui_panel_color: Color
@export var ui_panel_alt_color: Color
@export var ui_text_color: Color
@export var ui_muted_text_color: Color
@export var ui_button_color: Color
@export var ui_button_hover_color: Color
@export var ui_button_text_color: Color
@export var ui_accent_color: Color
@export var bg_base_color: Color
@export var bg_secondary_color: Color
```

Ne pas essayer de générer 100 % du theme uniquement par calcul automatique.

Recommandation :

* chaque palette débloquée stocke explicitement ses `tile_colors` ;
* mais aussi un petit ensemble de couleurs de thème dérivées à la main ou semi-automatiquement.

Ainsi chaque palette reste jolie et lisible.

# 8. Ce que la palette doit affecter

Quand une palette est sélectionnée, elle doit adapter :

## Gameplay

* bordures de tuiles ;
* chiffres ;
* dos des cartes ;
* halo de drag ;
* certains effets de combo.

## Background

* couleur de base du fond ;
* teinte du shader ;
* intensité secondaire.

## UI

* fond des panneaux ;
* fond des menus ;
* boutons ;
* états hover/focus ;
* titres ;
* textes secondaires ;
* séparateurs ;
* cartes d’achievements ;
* cartes de bonus ;
* cartes de challenges ;
* Progression menu.

## Feedback

* popups `FLAWLESS`
* `CHECKPOINT UNLOCKED`
* `NEW BONUS`
* `NEW SPECIAL RULE`
* `TIER RELIEF`

sans casser la lisibilité.

# 9. Adaptation du shader au theme

Chaque background shader doit recevoir au minimum :

```gdscript id="d8hg93"
uniform vec4 color_a;
uniform vec4 color_b;
uniform float intensity;
uniform float speed;
uniform float time;
```

`color_a` et `color_b` doivent provenir du thème global.

Exemple :

```gdscript id="djbj69"
shader_material.set_shader_parameter("color_a", theme.bg_base_color)
shader_material.set_shader_parameter("color_b", theme.bg_secondary_color)
```

Cela permet d’utiliser les mêmes shaders avec différentes palettes.

Les palettes deviennent ainsi de vrais thèmes complets.

# 10. Exemples de thèmes dérivés

Pour une palette vive type `VAPORWAVE` :

* fond principal violet foncé désaturé ;
* secondaire cyan/rose faible ;
* boutons plus saturés ;
* texte clair.

Pour une palette `MONOCHROME` :

* fond gris bleuté ;
* panels légèrement plus clairs ;
* accents blanc cassé ;
* hover gris moyen.

Pour une palette `RAINBOW` :

* fond sobre neutre légèrement coloré ;
* accents arc-en-ciel réservés aux boutons ou highlights ;
* ne pas transformer tout le HUD en carnaval.

Le thème doit **suggérer** la palette, pas répéter dix couleurs partout.

# 11. Menu de sélection des palettes

Dans `PROGRESSION > FONTS` ou une nouvelle section :

```text id="oz8sc1"
PALETTES
```

afficher pour chaque palette :

* nom ;
* aperçu des 10 couleurs ;
* miniature du thème global ;
* état verrouillé/déverrouillé ;
* palette actuellement sélectionnée.

Ajouter une preview du thème :

```text id="2orhpj"
tile colors
+
button sample
+
background sample
```

Ne pas seulement afficher dix carrés colorés.

# 12. Palette active et transitions

Lorsqu’une palette est changée dans le menu :

* mettre à jour instantanément les éléments UI ;
* mettre à jour le fond preview ;
* mettre à jour la preview des cartes ;
* ne pas nécessiter de redémarrage.

En jeu, si le joueur change la palette depuis un menu externe ultérieur, le changement peut être appliqué :

* soit immédiatement ;
* soit au prochain retour au menu ;
* soit au prochain round.

Pour la première version, appliquer :

```text id="sryx18"
nouvelle palette active au prochain lancement de run
```

ou au retour au menu principal, pour éviter des complications inutiles.

# 13. API ThemeManager

Créer un singleton ou service :

```gdscript id="vzhy5y"
class_name ThemeManager
extends Node
```

Fonctions recommandées :

```gdscript id="9b7bjp"
func get_active_theme() -> ThemePaletteData:
	pass

func set_active_theme(theme_id: StringName) -> void:
	pass

func apply_theme_to_control(root: Control) -> void:
	pass

func apply_theme_to_background(background: Node) -> void:
	pass
```

Le but est d’éviter d’avoir des dizaines de scripts UI appliquant eux-mêmes les couleurs.

# 14. Sauvegarde

Sauvegarder :

```text id="xpntm6"
progression/unlocked_palettes
settings/selected_palette
```

Migration :

* si aucune palette sélectionnée, utiliser la palette de base actuelle ;
* cette palette de base doit être débloquée par défaut ;
* toutes les anciennes sauvegardes doivent rester compatibles.

# 15. Debug

Ajouter dans `debug.gd` :

```gdscript id="8bme1u"
const FORCE_BACKGROUND_ID := ""
const FORCE_THEME_PALETTE := ""
const DISABLE_SHADER_BACKGROUNDS := false
const DISABLE_BG_MORPH_TRANSITION := false
```

`FORCE_BACKGROUND_ID` permet de tester un background précis pendant une run.

`FORCE_THEME_PALETTE` permet de tester rapidement un thème global précis.

# 16. Performance

Les shaders doivent être :

* légers ;
* sans boucle coûteuse ;
* compatibles Web ;
* stables sur mobile.

Ne pas utiliser plusieurs backgrounds animés simultanément.

Un seul background shader actif à la fois.

Pendant une transition morphing :

* ancien background ;
* nouveau background ;
* shader de transition simple ;

mais seulement pendant la durée de la transition.

Si les performances sont insuffisantes :

* désactiver le morphing ;
* fallback vers un fade simple ;
* conserver malgré tout le changement de background.

# 17. Tests

Ajouter des tests ou vérifications manuelles pour s’assurer que :

* le background change bien à chaque Tier Relief ;
* le même background n’est pas sélectionné deux fois d’affilée quand cela peut être évité ;
* la transition est skippable ;
* le skip place bien le background final dans le bon état ;
* la palette modifie bien le background et l’UI ;
* le thème reste lisible avec plusieurs palettes extrêmes ;
* les shaders n’empiètent pas sur le gameplay ;
* le fallback fond uni fonctionne si les shaders sont désactivés ;
* le seed ne change pas si un background cosmétique consomme du RNG ;
* les performances restent acceptables en Web build.

# 18. Ordre d’implémentation

Procéder dans cet ordre :

1. créer `ThemePaletteData` et `ThemeManager` ;
2. faire en sorte que les palettes affectent déjà l’UI globale ;
3. créer `BackgroundThemeData` et `BackgroundManager` ;
4. intégrer `stripes` comme premier background officiel ;
5. implémenter `grid` comme deuxième background ;
6. ajouter 2 à 3 autres backgrounds simples (`dots`, `waves`, `diamonds`) ;
7. implémenter le changement au Tier Relief ;
8. implémenter la transition morphing ;
9. ajouter les previews dans le menu Progression ;
10. ajouter sauvegarde, debug et tests.

Ne pas commencer par 8 backgrounds complexes. Il vaut mieux :

* 2 bons backgrounds propres ;
* un système de theme global solide ;
* une transition fiable ;

puis étendre ensuite la variété.
