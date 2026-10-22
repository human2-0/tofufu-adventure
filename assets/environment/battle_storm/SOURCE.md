# Royale storm curtain

`storm_mist.png` was generated with the built-in imagegen tool on 2026-10-22 for this feature. The original is retained in the Codex generated-image library (exec-c546658b-043f-4d7e-a32b-edb76b4bff21.png).

Prompt: seamless flat material tile of turbulent billowing mist, broad soft flowing cloud bands, hand-painted storybook/anime watercolor style, muted violet/indigo with lavender/cyan highlights. Even diffuse lighting; no perspective, horizon, objects, text, border or watermark. Opaque source; the storm shaders derive alpha from luminance.

Applied to the final curved 3D storm wall and local edge-mist overlay by `game/app/presentation/battle_storm_view.gd`. Both animate from the accepted match clock and freeze during paused recovery. The ground band uses the map's terrain query. This artwork has no collision or gameplay authority.

The wall uses blended world-space X/Y and Z/Y projection at 24 metres per tile, avoiding a cylindrical UV seam. It has no caps or shadows. Native Godot 4.7.2/Metal previews at 1280×720 and 640×360 are retained in `.codex/visualizations/2026/10/22/battle-hud/`, including inside/outside views; the safe aiming centre remains visible.
