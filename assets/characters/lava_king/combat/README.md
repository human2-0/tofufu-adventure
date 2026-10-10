# King Lava combat poses

Five generated RGBA sheets retain the north, north-east, east, south-east and south character views. Each has left/right walking, channel, release, recoil and alive kneeling defeat poses; western views mirror their eastern counterparts. The original idle PNGs remain in the parent directory.

Generated with the built-in `image_gen.imagegen` tool from the corresponding original directional PNG only. `generation.json` records the exact final prompts, settings and generated source paths. First attempts with wrong rear orientation were rejected. Final rear views were visually checked to retain the blank tofu back and crimson cape.

`frame_bounds.json` records alpha-threshold silhouette bounds and foot anchors measured with native Godot Image data. Atlas crops follow each complete character silhouette, including staff extensions beyond the nominal cell. `KingCombatFrames` keeps common standing scale per direction and retains the smaller kneeling silhouette. Runtime world spell effects are separate bounded meshes and a fire shader under `game/combat/castle/`.
