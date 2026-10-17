# Fallen Tofufu angel archer

`archer.png` was generated with the built-in ImageGen tool on 2026-10-13, using
`assets/characters/cloud_court/angel-directions.png` as a visual reference.
The original reference remains unchanged. The runtime consumes four directions
in each of two rows (idle and bow draw) through calibrated atlas regions in `ArcherVisuals` to exclude adjacent glow.

Prompt: transparent four-column, two-row sprite atlas; ivory tofu cube character,
bold ink outlines, cream/gold/lavender Olympian cel shading, lavender feather wings,
cracked gold halo, dark plum tunic with gold laurel trim, ivory-gold bow firing
Tofufu groats. Full-body front, back and two side views at consistent scale;
second row drawing the bow. No labels, environment or external shadow.

Ground, ivory/gold ruin cover and golden groat projectile meshes are generated
by the owning Godot scripts. Collision remains independent from sprite art.

## Eight-direction walking atlas

`archer-walk-eight.png` was generated with the built-in ImageGen tool on
2026-10-15, using `archer.png` as the identity reference. Original art is preserved.

Prompt: exact same ivory tofu cube angel, cracked gold halo, lavender wings, plum
tunic with gold laurels and sandals; transparent 4-by-4 atlas with eight walking
views S/SW/W/NW/N/NE/E/SE and two alternating strides, consistent scale and sole
baselines, relaxed empty hands, no text, grid, scenery or cast shadows. Back views
show no face. Match the original cel shading and outlines.

`ArcherVisuals` isolates alpha-bounded atlas regions with clipped filtering and
measured body centres/sole pivots. West views mirror their matching east views.
The original atlas still supplies committed bow-draw poses.
