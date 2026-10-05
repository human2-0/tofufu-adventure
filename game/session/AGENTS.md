# Session values and room lifecycle

- `PlaytestRoom` owns per-room roster, epoch, lifecycle and signals. `RoomMessages` validates and applies authenticated room messages through that owner.
- Protocol validators and `InputWindow` handle bounded values only. Transport implementations belong under `networking/`; app composition injects packet delivery.
- Preserve version/epoch checks, identity binding, capacity, replay bounds, reconnect deadlines and host-loss behavior when reorganizing handlers.
- Do not deserialize remote objects or make presentation authoritative. Read `docs/architecture/COOP.md` before changing packet shapes or session behavior.
