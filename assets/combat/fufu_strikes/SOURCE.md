# Fufu varied unarmed strikes

`strikes.png` is the original transparent RGBA atlas produced by the built-in
ImageGen tool on 2026-10-16. It is copied intact; no pixels were repainted or
background-removed. Source output:
`/Users/mat-dwor/.codex/generated_images/01a1456e-d1ff-7ce3-8bdb-892fff096d9d/exec-98cdc92b-98ba-45b9-ba02-c7d77b65bec4.png`.

References: Fufu's `soybean_fufu-idle-eight.png`, the Bright/Dark Leaf standing
atlases under `assets/characters/fufu/sets/`, and `celestial/idle.png`.
Their cream/leaf/ivory materials, dark outlines and painted highlights guide the
cutouts. The source art remains unchanged.

The atlas has four rows (base, Bright Leaf, Dark Leaf, Celestial) and four
columns (jab, cross, uppercut, kick). `PunchImpact` uses rounded integer columns
and calibrated row boundaries (0, 314, 627, 924, 1254) with clipped AtlasTextures.
The last separator follows the actual transparent gutter, keeping the Celestial
uppercut out of the Dark Leaf cell. The 1254px source stays intact.
The actor's existing punch sequence cycles through all four columns equally;
the outfit comes from the existing complete-set equipment state on authority
and replicas. A kick is a cosmetic strike variation with the existing fist rules.
No save or wire fields are added.

The matching full-character contact sheets now live in
`assets/characters/fufu/unarmed/`; their `SOURCE.md` records generation and
ground/wrist calibration. Both body and impact use the same contact window.

Godot preview: `tests/preview_punch_variations.gd` renders all sixteen poses,
eight observer-relative attack directions per outfit, and a rapid-click burst.

## Generation prompt

```text
Use case: stylized-concept
Asset type: one production RGBA combat-effect sprite atlas for the Godot game Tofufu Adventure.
Input images: the four reference images show base Fufu, Bright Leaf armour, Dark Leaf armour, and Celestial armour. Use them ONLY as style and material references. Draw isolated striking mitts and boots, NOT full characters.
Primary request: a precisely aligned 4 columns by 4 rows sprite sheet, sixteen separated action cutouts, on a genuinely transparent background. Square canvas, preferably 2048x2048. Equal square cells. Each sprite fully inside the middle 76% of its cell with a wide transparent gutter on every edge. No grid lines, no labels, no text.
Rows from top to bottom:
1. Base Fufu: buttery cream rounded bean mitts with dark forest-green outlines; cream bean foot.
2. Bright Leaf: glossy lime-green layered leaf gauntlets with yellow-green raised rims and leaf veins; matching green leaf boot.
3. Dark Leaf: deep olive-black layered leaf gauntlets with muted olive-gold rims and veins; matching dark olive boot.
4. Celestial: ivory mitts with gold Greek trim, tiny cyan diamond cuff accents; ivory and gold winged boot.
Columns from left to right (distinct silhouettes, consistent across all four rows):
1. JAB: short compact left mitt punch viewed slightly from above, closed rounded knuckles pointing upper-right, short wrist entering lower-left.
2. CROSS: opposite right mitt, broad frontal three-quarter foreshortened knuckles pointing upper-left, wrist entering lower-right; different pose, NOT just the first sprite duplicated.
3. UPPERCUT: closed mitt seen from its side, bent little cuff at bottom, knuckles rising almost vertically, curved small motion swoosh.
4. KICK: cute stout boot or bare bean foot kicking diagonally upper-right, short ankle at lower-left and clearly readable heel/toe shape; NOT a fist.
Style/medium: match the references' polished hand-painted chibi fantasy game art, dark crisp outlines, soft warm shading, glossy highlights. Strong small-scale readable silhouettes, no realistic human anatomy. Small cream motion streaks near wrist/ankle are fine but keep them compact and within cell.
Composition: one and only one isolated limb in each tile, each about 60-70% of the tile's width and height, carefully centered, no body, head, floating equipment, background, cast shadow, spark explosions or large aura. Preserve transparent alpha.
```
