# Inventory

- `items/` defines values/art; `state/` owns contents; `rules/` owns transactions; `drops/` owns physical world drops; `ui/` presents them.
- Windows emit intents or use injected transaction callables. Scene-specific grants, actors and networking belong in `game/app/inventory/` or `game/app/coop/`.
- Layout helpers only build controls and connect existing window callbacks. They do not mutate inventory or decide transaction results.
- Preserve stack counts, reserve values, backpack contents and atomic transfers. Save restoration and live snapshots share validation contracts.
- Avoid rebuilding slot resources for unchanged snapshots. Keep authored icons and their import settings stable when moving code.
