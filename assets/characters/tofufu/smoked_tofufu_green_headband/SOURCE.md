# Firm Tofufu sprite source

Attachment 2: ivory tofu, green headband, scallion rings and sprig. The received upload had a clipboard UUID filename.
The character is Firm Tofufu; its historical directory remains the stable asset ID.
`source/walk-original.png` preserves the attachment byte for byte.

Created 2026-10-19 using the built-in ImageGen tool. Exact initial prompts, reference
paths and generated output paths are recorded in `../generation-prompts.json`.
The original sheet is the identity reference in every generation request. Fufu's
`jump/directional/atlas.png` supplies the ten jump phase reference, and Fufu's
`unarmed/base.png` supplies jab/cross/uppercut/kick pose references. Fufu is never
the appearance reference for these tofu characters.

New PNGs are copied intact from generated outputs, with real transparent alpha.
No source PNG is cropped, resampled, recolored or procedurally redrawn. Where
appearance corrections were needed, built-in ImageGen edited the sheet; the prior
version and exact correction prompt are retained under `source/`.

The row order is N/NW/W/SW/S for every new atlas. `locomotion.png` has standing
plus four walking columns, `jump.png` has ten Fufu-compatible phases, and
`melee.png` has four contact-pose columns. NE/E/SE use horizontal mirroring.
The requested art library includes 95 authored poses for this character.

`../build_library.py` reads alpha-connected figures and writes `sprite-layout.json`
and `animations.tres`. One uniform pixel size per sheet gives approximately 1.12
world-unit neutral height. Crop regions and transparent resource margins register
feet without changing pixels or mixing neighboring poses. Use the per-sheet pixel
size when switching categories. The preview compares every angle with Fufu.

The meadow 3D Fufu display now offers a session-only local test selector using
these assets. Gameplay rules, equipment, saves and network messages stay unchanged. See `../README.md` for browsing and preview commands.

The user clarified the character name as Firm Tofufu. Initial generation logs retain
the historical working directory `scallion_headband`; the asset directory remains
`smoked_tofufu_green_headband`.

Horizontal atlas registration uses the solid torso center, excluding swinging
feet, hands and accessories. Foot positions determine only the vertical baseline.
The retained `foot_center` records the original toe measurement. Source PNG pixels
are unchanged; `build_library.py` reproduces the corrected JSON/TRES registration.
