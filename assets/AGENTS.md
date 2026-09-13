# Assets

- Preserve original source art. Keep feature assets under descriptive directories and update all references when moving them.
- Fufu walk sheet: 4 columns x 3 rows; down row 0, up row 1, LEFT row 2. Flip row 2 for RIGHT.
- Eight-pose idle sheet: 4x2, S/SW/W/NW then N/NE/E/SE. Idle pixel size 0.00284; cardinal walk 0.005. Preserve per-frame center/foot offsets and apparent size.
- Diagonal sheet: original 1254px PNG, 4x4 frames; rows SE, SW, NE, NW. Keep calibrated pixel scale/foot baselines in `FufuVisuals`; keep source provenance with the art.
- Sword: retain generated RGBA atlas. `SwordVisual` calibrates eight steel-base/tip pivots against `CombatTuning`; rendering and damage must use the same world dimensions.
- Preserve text `.import` sidecars and their UIDs; `.godot/` caches are generated and ignored. Do not read PNGs or generated textures as text.
- Check billboarding, alpha edges, directional frames, shadows and scale in Godot after visual changes.
