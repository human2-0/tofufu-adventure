# Whole-body Fufu unarmed contacts

The built-in ImageGen tool generated `base.png`, `bright_leaf.png`,
`dark_leaf.png` and `celestial.png` on 2026-10-17. All four 1122 by 1402 RGBA
sources are copied intact. `generation-prompts.json` retains the exact prompts,
reference paths and original output paths. No source pixels were edited.

Each sheet contains twenty full-character poses: columns jab, cross, uppercut,
kick; rows front/S, front-left/SW, left/W, back-left/NW, back/N. Mirroring the
three angled/profile rows supplies all eight observer-relative directions,
giving 128 body/outfit/attack views from eighty painted poses. Rear views keep
the face hidden. A few source poses looked back-right; per-pose `source_flip`
metadata corrects those views without altering their PNGs.

`calibrate.py` reads alpha-connected character shapes and writes `layout.json`.
It records clipped, individual sprite regions, planted-foot baselines, foot
centers and both wrist landmarks. Neighboring row boundaries follow the actual
transparent gutters, including the tightly spaced Celestial poses. Each outfit
uses one uniform pixel scale derived from its median painted height, retaining
pose proportions and the existing approximately 1.1 to 1.2 metre appearance.
The script reads PNGs and writes only JSON; it never modifies raster art.
The tight character atlases retain lossless alpha without mipmaps, and disable
automatic 3D compression changes, preventing distant frames from sampling a
neighboring pose across the smallest gutters.

`FufuUnarmedArt` presents the body pose for the same 0.16 base-second contact
window as `PunchImpact`, using the existing authoritative punch sequence and
cooldown. A small follow-through squash pivots around the planted foot. The
body and the existing matching mitt/boot effect share their four-style order.
Jump, dash, charge, riding, hurt, ranged and Bengal Paws presentations retain
their own priority. The rules, damage, cadence and save/wire formats are unchanged.

Runtime selection and wrist presentation live in `game/player/`; the existing
actor pose adapter injects combat presentation context for authority and peers.
`tests/test_unarmed_art.gd` exercises fast clicks, camera rotation, outfit art,
cosmetic replicas, expiry and competing pose priorities. The expanded
`tests/preview_punch_variations.gd` renders every style in every direction,
all sixteen body/effect combinations, and a real rapid-click burst in Godot.
