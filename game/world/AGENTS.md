# World

- Keep each region's world, terrain and props together: `farm/`, `factory/` and `biomes/<region>/`. Shared scenery is in `common/`.
- `river/` owns the continuous river profile/surface; biome terrain must use its shared height and water queries at seams.
- `weather/` owns clocks and local atmosphere. Rules do not read input or networking; app composition supplies synchronized weather and player focus.
- Weather uses bounded depth-tested 3D instances. Preserve stable cell seeds and reuse unchanged cells; do not add full-screen rain/wind overlays or per-drop simulation nodes.
- Keep collision terrain and visual terrain aligned. Decoration and sky effects never decide gameplay outcomes.
