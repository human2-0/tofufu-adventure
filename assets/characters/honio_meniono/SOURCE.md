# Honio Meniono — Royale Easter egg

Created on 2026-10-23 with the built-in `image_gen` tool. The existing Firm Tofufu
locomotion atlas was a style/species reference. This is a new muscular cream tofu
block in burgundy gym shorts and wristbands, with a sprout and green headband.
Honio is a finite melee enemy composed only by Battle Royale; he is not a player
skin or an Adventure spawn.

- [idle.png](idle.png): eight authored views, 4 columns × 2 rows.
- [run.png](run.png): two alternating strides in eight views, 4 × 4.
- [melee.png](melee.png): extended punch/rush and overhead slam poses in eight views, 4 × 4.
- [sprite-layout.json](sprite-layout.json): cell regions, per-pose cream-torso centroids and planted-foot
  baselines. No mirroring is used. Order is S, SW, W, NW, N, NE, E, SE.
  Horizontal anchors use the largest opaque cream torso component, avoiding the
  shifting gloves, headband bow and moving toes.
- [source/prompts.json](source/prompts.json): exact production prompt set, including the skill effects.

Original tool output names: `exec-74299061-6efb-4138-9277-91d82c3d62fb.png` (idle),
`exec-1e477d4c-8904-4106-9f60-1425d2be4e9e.png` (run),
`exec-79507d78-4413-453a-bf76-697b936c61bc.png` (melee).
The unmodified generated RGBA files are retained here at their original resolution.
The [generated skill VFX atlas](../../combat/honio_meniono/skills.png) and its
[SOURCE.md](../../combat/honio_meniono/SOURCE.md) live under the combat asset folder.
Lossless texture import, alpha discard and clipped atlas sampling prevent stray
low-alpha paint and neighbouring poses from appearing. Mipmaps reduce distant shimmer.
HonioVisuals registers every frame; the physical body stays at scale one, with a
0.58 m radius / 1.7 m tall capsule and a 1.35 m headshot threshold.

Native inspection: `tests/preview_battle_honio.gd` (or its `art-only` argument for
the studio) renders all forty directional
poses and the real Royale encounter/VFX in English and Polish at 1280×720 and
640×360. Evidence is stored under `.codex/visualizations/2026/10/23/honio-meniono/`.
