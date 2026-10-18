# Bannière Ko-fi — juels

- Brouillon archivé : `banner-imagegen.png`, 1200 × 400 pixels, ratio 3:1, PNG opaque.
- Remplacé par `publishing/kofi/banner.png`, composé par code avec les vraies couleurs du jeu.
- Composition : outil intégré **imagegen** ; export à la taille finale avec Pillow.
- Police de référence : `resources/fonts/VCR_OSD_MONO_1.001.ttf`, police principale du jeu.
- Références : mot « juels » rendu dans cette police, `publishing/itch/banner.png` et `resources/sprites/tiles/tile-face.png`.

## Prompt utilisé

```text
Use case: compositing / ads-marketing.
Edit image 1, the prepared 1200 x 400 wide Ko-fi banner canvas: preserve its central lowercase word "juels" exactly, including the precise VCR OSD MONO glyph shapes, letter spacing, charcoal #3c3c3c color, and geometric centering. The word is spelled j-u-e-l-s. This is the creator's name, and the only word that should appear.
Image 2 is a style reference only: Pile Down's existing game banner, demonstrating its authentic numbered game tiles with stepped pixel corners, light faces, colored borders, and short darker bottom edges that suggest 2D relief. Do not copy its PILE DOWN wording or its row composition.
Image 3 is a supporting sprite shape reference only: the game's original 34 x 37 tile-face sprite. Replace the green chroma color with the colored borders from the reference banner; do not use bright chroma green as a final color.
Add a playful but balanced scattering of eight numbered Pile Down tiles around the central word, concentrated in the outer left and right thirds, with a couple of small layered tile stacks. Mix blue, teal, green, gold, coral, orange, pink and violet borders from the game's palette. Each face has one legible VCR-style digit 0 through 9, centered. Some tiles may have a gentle tilt but retain the crisp pixel-art silhouette, restrained pseudo-volume and clean flat colors of the real game assets. Vary their scale subtly, keep them completely within the canvas, and leave generous quiet space around the word. The middle word must remain dominant, unobstructed, centered horizontally and vertically, and immediately readable.
Keep the original warm ivory #f7f6f2 background completely flat. No gradients, grain, blur, photorealistic materials, decorative shapes, extra words, Ko-fi logo, labels, frame, or watermark. No giant 3D toy blocks.
Output a polished, genuinely wide 3:1 banner, preferably 1200 x 400 pixels, or 1536 x 512 for exact downscaling. Keep all essential content within a 32-pixel safe margin at the final 1200 x 400 size.
```
