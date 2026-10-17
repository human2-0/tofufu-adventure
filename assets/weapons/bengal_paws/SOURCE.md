# Bengal Paws asset sources

Generated with the built-in imagegen tool on 2026-10-15. Original RGBA outputs are preserved: `paws.png` for inventory/world drops, `glove.png` for each worn and first-person glove, and `reality-rift.png` for normal claw trails and the initial Super Claw rake. These alpha-textured sprites use the project's painted chibi style. No generated output was repainted or resampled.

The charge tell, dash trail and first-person charged claws also reuse the original `reality-rift.png` texture, with per-sprite scale/tint/alpha animation. The final rift retains the generated open-tear material.

## Open reality tear texture

`rift-open.png` is an additional original RGBA image generated with the built-in imagegen tool on 2026-10-15. `BengalRiftEffect` applies it to a brief animated cosmic slit and twelve batched textured fragments; `BengalParalysisSeal` uses small copies for the enemy's fractured bonds. The local shader animates UV ripples, a slight chromatic edge shift and emission; it does not sample or distort the full screen.

Exact generation prompt:

Use case: stylized-concept. Asset type: transparent game VFX texture for Bengal Paws Super Claw, painted chibi 2.5D action RPG. A SINGLE jagged reality tear hanging vertically in empty space, like a claw has ripped a narrow opening through glass. The tear is tapered at top and bottom with an uneven zigzag outline; a deep midnight indigo and violet cosmic interior shows tiny stars and one small swirling nebula. Very bright crisp ivory/cyan torn rim with violet highlights, a few short thin forked cracks branching only immediately from the rim, chipped translucent turquoise crystalline edges. Centered full effect, tall slit occupies the middle 55% width and 85% height of square canvas, generous transparent margins, no ground, no scenery. Hand-painted clean game illustration, bold cel shading, restrained luminous edge glow that stays close to the crack. The entire slit and small branching cracks must stay inside the canvas. No creature, no weapon, no circular portal ring, no UI, no lettering, no border, no opaque background or rectangular fog. Actual transparent alpha.

## Paws icon prompt

Use case: stylized-concept. Asset type: transparent inventory weapon icon and wearable paw-gauntlet game asset for a cute hand-painted chibi 2.5D RPG. Primary request: Bengal Paws, a PAIR of charming oversized golden Bengal-cat paw gauntlets arranged diagonally together, one shows dark brown rosette-spotted top of paw with three gleaming ivory retractable claws; the other turned slightly reveals soft peach toe pads. These are plush magical claw GLOVES with open dark wrist cuffs, not severed animal parts. Honey-gold fur, brown ring rosettes, cream fluffy cuff trim, subtle tiny cyan/violet magical seams around the claws suggesting they can rip a reality rift. Bold warm dark outlines, soft clean cel shading, polished game collectible art, matches the adorable golden Bengal sprite style. Composition: pair fills center 78% of square with generous transparent margin; entire item visible. No text, no UI frame, no background, no ground, no cast shadow. Real transparent alpha.

## Single glove prompt

Use case: stylized-concept. Asset type: a SINGLE wearable Bengal cat PAW GLOVE sprite for a chibi RPG, isolated transparent cutout, clean small game sprite. Show one whole small plush golden Bengal paw gauntlet, top of hand faces viewer, wrist at bottom and three tapered ivory claws point upward, straight vertical front view. Chubby honey-gold cat paw, distinct dark brown rosettes, cream furry wrist cuff, small dark opening at bottom. Cute confident silhouette and bold dark brown outline, warm painted cel shading, crisp at small sizes. Three small cyan highlights on ivory claws imply magical reality tearing. This is a crafted furry glove, no severed body part. Large empty transparent margin, whole glove visible centered and occupying 75% canvas. No arm, no second glove, no background, no text, no frame. Real transparent alpha.

## Rift prompt

Use case: stylized-concept. Asset type: transparent magical combat VFX texture, cute hand-painted chibi 2.5D RPG. Primary request: REALITY RIFT claw slash: three parallel diagonal jagged claw tears ripping through space from upper right to lower left, slender elegant arcs, bright white/cyan crystalline torn edges, deep indigo cosmic interior with violet starlight, a handful of sharp turquoise and purple reality shards suspended close around the tears. Reads immediately as a Bengal cat super-claw attack that shattered reality. Bold crisp painted contour, clean cel shaded glow, extremely readable dark negative space between the three slashes. Centered effect fills 85% square, transparent empty margins all sides; entire effect inside canvas. Texture only, no cat, no glove, no scenery, no text, no border, no background panel. Real alpha transparent background around and between the slash tears.


## Fitted worn glove variant

`glove-worn.png` is the original transparent output from the built-in imagegen edit tool on 2026-10-16, using `glove.png` as its edit target. The original loose glove is preserved. The worn variant removes the hollow opening and adds a fitted wrist section. `BengalPawVisual` registers its cuff to the wrist; first-person gloves share the sleeve endpoint and forearm direction through punch, charge and dash poses.

Exact generation prompt:

Use case: precise-object-edit. Asset type: transparent wearable glove sprite for a painted chibi 2.5D RPG. Edit target: the supplied single golden Bengal paw gauntlet. Preserve the same three ivory claws with small cyan glints, honey-gold Bengal rosette fur, proportions, outline and painted style. Change ONLY the wrist/cuff construction: this is the BACK OF A GLOVE ALREADY WORN on a hand, viewed from above/back of the hand; its wrist must be a snug closed silhouette, with NO visible empty opening or dark socket. Replace the hollow oval at the bottom with continuous golden rosette fur tapering down as a short fitted wrist section; keep a small cream fur trim across the top of that fitted wrist, with the wrist section extending below it and ending in a clean narrow straight cutoff that can tuck into an in-game sleeve. Entire silhouette visible centered with transparent margin. No hand or arm outside the glove, no second glove, no scenery, no letters, no shadow background. Real transparent alpha. The result must look like a paw glove on a wrist, never a loose empty mitten facing its own opening.
