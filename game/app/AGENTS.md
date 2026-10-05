# App composition

- `bootstrap/` owns app/session lifecycle; `adventure/` owns playable-scene composition. Construct dependencies in the explicit `AdventureSetup` order.
- Use `actors/`, `coop/`, `inventory/`, `quests/`, `world/` and `presentation/` for their named responsibilities. Do not collect new features in the scene root.
- Root nodes retain lifecycle, signals and per-instance state. Focused stateless helpers may receive a typed owner; do not duplicate state or introduce registries.
- Keep co-op replica presentation separate from authoritative commands and outcomes. Preserve replica process priority before weapon rendering.
- Main/actor callback facades are used by scenes, signals and tests. Check callers before changing them; preserve callback connection order during refactors.
- Read `docs/architecture/COOP.md` for session, snapshot or authority changes; keep offline composition usable.
