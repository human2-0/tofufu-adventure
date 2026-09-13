# Player feature

- `Player` only orchestrates input -> motor -> move_and_slide -> visuals/signals.
- `PlayerMotor` owns movement timers and returns velocity. It accepts grounded state; it never queries physics or nodes. Keep it independent of Input, presentation, and networking.
- `PlayerCommandSource.sample()` produces one fresh command per tick. Edge actions are one-tick pulses. Remote adapters must validate input before this boundary.
- `PlayerTuning` holds defaults. Do not mutate it as runtime actor state.
- `FufuVisuals` owns eight-way facing, atlas frames, foot baselines and scale. `DashGhost` owns ghost creation/lifetime. The scene's collider does not scale with the sprite.
- Existing dash starts after walk/jump on its trigger tick; subsequent dash ticks freeze vertical velocity. Preserve this feel unless explicitly changing mechanics.
- When adding abilities, use focused components only when responsibility demands them; avoid a growing player coordinator or deep character inheritance tree.
