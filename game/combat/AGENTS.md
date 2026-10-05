# Combat

- Root tuning, damage receivers and vitals are shared contracts. Put melee, ranged, abilities, enemies, targets, effects and state translation in their named subdirectories.
- `PlayerCombat` owns the per-actor attack lifecycle. `MeleeSweep` resolves collision, occlusion and confirmed hits; `MeleePose` supplies the same pose to clash samples and weapon rendering.
- `TrainingMob` owns physical movement, health and lifecycle. `SnailSteering` computes its chase/wander intent; retain overridable hooks used by `ArmoredSnail`.
- Only authoritative physics resolves damage, resource spending and loot. Cosmetic projectiles and snapshot presentation cannot apply outcomes.
- Keep hit history, random streams, cooldowns and mutable state per actor. Shared Resources remain authored configuration.
