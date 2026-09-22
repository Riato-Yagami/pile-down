# Captures Pile Down 2.0

Quatre séries de huit captures directes, sans chronomètre global, en PNG RGB 24 bits sans transparence :

- **android/** : **1080 × 1920**, mode adaptatif, ratio **9:16**.
- **classic/** : **1280 × 1600**, mode classique, ratio **4:5**, agrandissement exact ×5 du canevas 256 × 320.
- **tablet-7/** : **1440 × 2560**, mode adaptatif, portrait **9:16**, série destinée à la rubrique tablette 7 pouces.
- **tablet-10/** : **1800 × 3200**, mode adaptatif, portrait **9:16**, série destinée à la rubrique tablette 10 pouces.

Les deux séries tablette partagent le cadrage portrait 9:16 de la série Android, avec un rendu natif à une résolution supérieure. Ces formats sont des préréglages de capture, pas une simulation de la densité physique d'un appareil.

Interface anglaise du jeu, sans retouche, cadre de téléphone ou texte promotionnel. Le compte à rebours de chaque tour reste visible. Les anciens PNG à la racine sont conservés comme première série ; utiliser les sous-dossiers pour les nouvelles publications.

La vue `01-gameplay` utilise le fond **Stripes** et `08-gameplay-bonuses` le fond **Dots**, dans tous les formats. Ajouter `gameplay-only` après le nom du format dans la commande de capture pour ne régénérer que ces vues, ou `bonus-only` pour la vue avec bonus uniquement.

Ordre conseillé pour la fiche Play Store (mêmes noms de fichiers dans chaque sous-dossier) :

| Ordre | Fichier | Contenu |
| --- | --- | --- |
| 1 | [08-gameplay-bonuses.png](android/08-gameplay-bonuses.png) | Joker, bonus actifs et piles révélées par Open Book |
| 2 | [01-gameplay.png](android/01-gameplay.png) | Plateau de quatre piles et main de trois cartes |
| 3 | [02-bonus-choice.png](android/02-bonus-choice.png) | Choix entre Quick Peek, Wild Card et Time Bank |
| 4 | [03-special-rules.png](android/03-special-rules.png) | Annonce de la règle Hot Potatoes |
| 5 | [04-challenges.png](android/04-challenges.png) | Défis déverrouillés |
| 6 | [06-customization.png](android/06-customization.png) | Polices, palettes et aperçu des cartes |
| 7 | [05-achievements.png](android/05-achievements.png) | Succès et récompenses |
| 8 | [07-home.png](android/07-home.png) | Écran d'accueil |

Format choisi selon les [consignes officielles Google Play](https://support.google.com/googleplay/android-developer/answer/9866151?hl=fr), consultées le 21 septembre 2026. Les fichiers sont destinés à la rubrique des captures pour téléphone. Ils n'ont pas été téléversés.

Captures produites avec Godot 4.7.2, rendu Compatibility, fenêtre portrait, disposition adaptative ou classique selon le dossier. Il s'agit du rendu du projet sur ordinateur, pas d'une capture sur appareil Android. Un profil de démonstration isolé révèle les succès, défis, polices et palettes existants ; les parties utilisent les options de seed et de bonus du jeu. Aucune sauvegarde personnelle n'a été utilisée.

## Régénérer sous PowerShell

Depuis la racine du dépôt, avec Godot dans le PATH, utiliser un nouveau profil isolé :

```powershell
$env:APPDATA = Join-Path (Get-Location) ('.godot/test-profiles/screenshots-v2-' + [guid]::NewGuid().ToString('N'))
godot --path . --script tests/capture_v2_screenshots.gd -- android
$env:APPDATA = Join-Path (Get-Location) ('.godot/test-profiles/screenshots-v2-' + [guid]::NewGuid().ToString('N'))
godot --path . --script tests/capture_v2_screenshots.gd -- classic
$env:APPDATA = Join-Path (Get-Location) ('.godot/test-profiles/screenshots-v2-' + [guid]::NewGuid().ToString('N'))
godot --path . --script tests/capture_v2_screenshots.gd -- tablet-7
$env:APPDATA = Join-Path (Get-Location) ('.godot/test-profiles/screenshots-v2-' + [guid]::NewGuid().ToString('N'))
godot --path . --script tests/capture_v2_screenshots.gd -- tablet-10
```

Le script attend la fin du rendu, contrôle les dimensions, le mode de disposition et l'absence du chronomètre global, puis exporte sans canal alpha. Chaque commande remplace les huit PNG du sous-dossier correspondant. `.gdignore` empêche leur import dans les ressources du jeu.
