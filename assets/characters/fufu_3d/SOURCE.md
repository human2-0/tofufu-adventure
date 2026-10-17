# Fufu 3D study

Implemented: a fully volumetric, textured Fufu model with rigid articulated pivots,
embedded materials, `Walk` (1.25 seconds) and `Idle` (3 seconds) glTF animations.
The village scene loops the walk in place on a low display base at X/Z (40, -13.5),
beside the courtyard path west of Grandma's house. This is a cosmetic exhibit.

`fufu.glb` is self-contained and reusable outside Godot. `build_model.py` is the
authored geometry/UV/animation source, using only Python's standard library.
Rebuild with `python3 assets/characters/fufu_3d/build_model.py`. The model uses
node articulation, not a skinned skeleton. Front is +Z; Y is up; units are metres.
Godot's display scene scales the model to 0.78 and provides the textured base.
The smooth skin is shaded as a real volume; facial marks follow the surface and
do not cast raised-sticker shadows. Hands are tucked around the lower belly.
Dark forest-green manga contours outline the body, hands, feet, stem and leaves.
Reversed inflated hulls use the existing generated ink texture and share each
part's animation pivot. The contours are embedded in the portable GLB. Body ink
is 0.012 m thick, with finer 0.0045–0.009 m contours on the smaller parts.
Automatic GLB mesh decimation is disabled to preserve the small painted facial
details and rounded mitten tips. The model includes separate contour surfaces.

Identity references (preserved unchanged):

- `assets/characters/fufu/soybean_fufu.png`
- `assets/characters/fufu/soybean_fufu-idle-eight.png`
- [Sproutling by elodworek on Meshy](https://www.meshy.ai/s/Q9J3p6), inspected in
  the interactive viewer from multiple angles. The page identifies CC BY 4.0.
  This is a visual reference only: no Meshy geometry or texture was imported.

The cream soybean body, dark oval eyes and cream glints, brows, smile,
peach cheeks, golden spots, curled hands and two-leaf sprout follow those references.
Facial marks follow the curved surface; leaves have thickness and mapped veins.
The body is a plump oval: approximately 1.18 m wide, 1.40 m high and
0.92 m deep before the village display scale, with short tucked feet. Its broad
rounded shoulders, full lower belly and gently curved centreline follow the
reference's proportions, while a shallow inner waist retains the bean shape.

## Generated texture provenance

`material-atlas-smooth.png` is the model's current albedo atlas, generated with
OpenAI imagegen on 2026-10-16. Original output:
`/Users/mat-dwor/.codex/generated_images/01a1442e-4ee0-7d83-ad9f-b1250afe6948/exec-d00b4d37-6326-4a73-a449-7099a84ec4bd.png`.
Copied unchanged into the project. Its four UV-mapped quadrants provide clean
cream skin, subtle spring-green veins, warm gold for freckles/blush, and dark
forest ink. The atlas is embedded in the portable GLB; Godot extracts its import
copy as `fufu_Fufu painted surfaces.png`, preserving the existing import UID.
Flat facial paint samples the centre of its generated material quadrant to avoid
atlas mipmap bleed at polar UV seams in the small eyes and rounded stroke ends.

Current atlas generation prompt:

> Use case: stylized-concept
> Asset type: production 2x2 albedo texture atlas for a smooth cute pale-yellow 3D bean character with a green two-leaf sprout.
> Primary request: create one square image divided into exactly four equal square quadrants, completely filled with flat surface colors and exceptionally subtle texture. No gutters, no borders, no labels. This is a material texture image to UV-map onto a modeled character, NOT a character drawing or a rendered material ball.
> Top-left quadrant: exceptionally smooth pale buttery cream soybean skin, base color approximately #fff0b3, very faint creamy natural color variation only. Satin toy-like clean surface. NO spots, pores, dots, grain, mottling, flecks, cracks, baked shadows, shiny painted highlights, or recognizable shapes.
> Top-right quadrant: soft bright spring-green leaf material, base color approximately #9fc839, a single very subtle green central vein vertically down the center and extremely faint lateral veins. Almost uniform smooth green, no contrasty stripes or painted brush strokes, no leaf outline or background. Entire square is green leaf surface.
> Bottom-left quadrant: uniform warm soft golden yellow #ffd080 with a trace of soft color variation, no dots, no mottling, no patterns; for tiny freckles and tinted peach blush.
> Bottom-right quadrant: uniform very dark warm forest-black #132319, only the faintest subtle color variation, no pattern or texture grain; for eyes, brows and mouth.
> Style: polished stylized 3D game character materials, clean and softly colored. Flat orthographic evenly diffuse albedo only. Exactly four equal square panels. No objects, character, text, watermark, borders, perspective, spheres, or cast shadows.

`material-atlas.png` is the preserved original atlas, still used on the village
display base. OpenAI imagegen, generated 2026-10-16 using both identity
references. Original output:
`/Users/mat-dwor/.codex/generated_images/01a1442e-4ee0-7d83-ad9f-b1250afe6948/exec-47b8eccd-b38d-4ada-b6e8-a4851b1de7b6.png`.
Copied into this feature without modifying the generated image. Four material
quadrants (cream skin, veined green leaf, golden skin, forest-green ink) are UV
mapped with inset margins to prevent quadrant bleed under filtering. Every model
material in the original version used this atlas. No external art pack.

Original atlas generation prompt:

> Use case: stylized-concept
> Asset type: production albedo material atlas for an actual 3D Fufu game character, not a character illustration.
> Input images: Image 1 and Image 2 are identity, palette, and surface-style references only. Preserve the warm custard-yellow soybean skin, lime-green sprout and dark forest-green ink palette.
> Primary request: generate one square texture atlas in a perfectly even 2 by 2 grid, with NO gutters, NO borders, NO labels. All four squares must be completely filled by the requested flat surface, orthographic flat texture scans without any 3D objects or lighting.
> Top-left quadrant: seamless very pale cream-yellow bean skin, subtle softly painted warm yellow organic grain, tiny mottling and a few extremely faint pores, matching Fufu's buttery smooth illustrated skin. NO face, freckles, limbs or silhouettes.
> Top-right quadrant: a single lime-green leaf surface filling the complete square, dark green central vein running vertically from bottom center to top center with fine branching veins, lightly hand-painted, leafy chartreuse center with deep green sides. No outer leaf outline or background, just continuous leaf material to UV-map onto modeled leaves.
> Bottom-left quadrant: warm golden custard-yellow skin variation, softly painted smooth grain, intended for soles and small golden freckles, no large pattern.
> Bottom-right quadrant: a continuous very dark forest-green ink surface, subtle brush-paper texture, same almost-black green as Fufu's drawn outlines.
> Style: clean charming hand-painted cartoon game material, restrained detail readable at small scale, evenly diffuse and no baked cast shadows or bright specular highlights. Exactly 4 equal square panels. Do not draw a character or render a model. No text, no watermark.

## Visual inspection

`tests/preview_fufu_3d.gd` renders front, three-quarter, side and rear views, eight
walking poses and the real village placement through Godot. Outputs live under
`.codex/visualizations/2026/10/16/fufu-3d/manga-outlines/`. Check the ink contours, oval volume,
smooth shoulders, subtle leaf veins, flush facial paint, tucked hands, foot
support and grass/base alignment. Earlier renders remain in the parent folder
and its `meshy-reference/` subdirectory.
