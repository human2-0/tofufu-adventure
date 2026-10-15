# Dofufu

Generated with the built-in imagegen tool on 2026-10-13 using the original Fufu eight-pose idle atlas as a style and silhouette reference. The untouched RGBA source is `dofufu-directions.png` (1254 x 1254). It depicts a fictional wuxia tofu master with crimson robes, jade ornament, cloud embroidery, a curling mustache and a crescent glaive.

Four columns, four rows, with individually calibrated AtlasTexture regions because generated cell spacing is approximate. The first 1312 x 1199 draft is preserved in `source/atlas-v1.png`. Idle directions occupy the first eight cells: S, SW, W, NW, N, NE, E, SE. The following eight cells use the same order for weapon poses. All directions are independently authored; none rely on mirroring. `DofufuVisuals` selects frames relative to the camera and calibrates each frame's foot baseline. Movement uses the weapon stance with procedural stride bob; this is a sixteen-pose atlas, not a four-frame walk cycle.

Generation constraints: full bodies, consistent identity, rounded pale yellow Fufu silhouette and sprout, dark outlines, natural expressive eyes, alpha transparency, separate equally spaced cells, no labels or scenery. The original reference and other character art were preserved.
