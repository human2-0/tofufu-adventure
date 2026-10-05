# UI

- Use `hud/`, `menu/`, `map/`, `controls/`, `quests/`, `effects/` and `weather/` for the corresponding views.
- `HUD` is the presentation facade; `HUDLayout` constructs its controls and `HUDCombatView` formats combat readouts. Keep callbacks and control references explicit.
- Views accept display values and emit user intents. They do not import gameplay features or networking; app composition translates between them.
- Preserve anchors, mouse filters, focus behavior and pause processing when extracting layouts. Render a relevant preview after layout changes.
- Keep map exploration state outside the map canvas, and weather particles outside CanvasLayer UI.
