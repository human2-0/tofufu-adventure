# Honio skill effects

Generated on 2026-10-23 with the built-in `image_gen` tool, output
`exec-4642476d-0164-4202-aa50-89837d703362.png`. `skills.png` is the original RGBA
2×2 atlas: golden fist impact, turquoise/cream rush swoosh, tofu-crumb dust and
red-orange circular ground warning. Exact prompt is retained in
`assets/characters/honio_meniono/source/prompts.json` under `skills`.

HonioVFX applies these textures to four reusable Sprite3D nodes. Ground warning
scale is calibrated to the three-metre slam radius; rush warnings show the
committed lane. Only authority resolves contacts; none of these effects applies
damage. There are no attack-time node spawns, particles, lights or shadow passes.
Materials preserve occlusion and the common 140 m combat visibility cap.

The native `tests/preview_battle_honio.gd` fixture inspects applied alpha, size,
direction changes, rush, slam and impact beside the existing Royale environment.
