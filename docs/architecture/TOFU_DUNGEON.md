# Tofu Dungeon production revision

Status: the revised factory is the default playable route. Legacy six-station tests retain an explicit compatibility fixture; new adventures use the puzzle route.

## Authority and transitions

`TofuPuzzleCommand` carries bounded intent: action, authored target/object IDs, run/attempt IDs, monotonic sequence and expected station revision. Gameplay protocol 27 requires matching peers. Guests open local station views and send typed intent; only the host binds the authenticated sender to an alive run participant and checks stage, ownership, range, world occlusion and revision. IDs are allocated by the host and persisted separately from peer keys, including collision resolution.

| Current state | Accepted event | Result |
| --- | --- | --- |
| Sorting ready | All three compatible assignments | Mandatory laboratory encounter |
| Laboratory combat | Confirmed opening clearance | Inspection, note and terminal handling |
| Laboratory ready | Committed Nigari pour, with or without login | Pressing ready, without a monster release |
| Pressing ready | Leased sample start | Operating |
| Pressing operating | Authority timing certifies all three samples | One cutting block |
| Cutting ready | Five valid cuts satisfy all six width tolerances | Six identifiable slabs |
| Packaging ready | Sixth unique slot sealed | Arena relocation and one boss encounter |
| Boss combat | Confirmed boss death | Reward claim, participant entitlements and completion |
| Any production state | Accepted production mistake | One fixed penalty wave at `1.2^mistakes` |
| Tenth penalty clearance | Attempt exhausted | Submissions locked; explicit evacuation/restart |

Invalid, stale and replayed requests do not create waves. Submissions are disabled during combat. Default pressing uses the specified timings and 82–90 band. The explicitly selected wider timing preset uses ±1.25 seconds and 78–94; changing it cancels an active trial and preserves certificates. The authority physics clock freezes in an offline pause. Co-op menus do not stop it. Modern overshoot and leaving an active station reject once; damage/death/disconnect release unfinished trials safely.

## Recovery, rewards and persistence

The recipe password is an optional clue, as requested in the usability revision. Bottles can be poured after the opening encounter without login. A correct Nigari choice forms curds and proceeds to pressing without another monster encounter; incorrect choices still create one escalating penalty wave. Stone-press controls show the action order, required weights, elapsed time and certificates; timing begins only when the required stones are placed. The modern stop band is visibly outlined.

Authored room/deck volumes, permitted adjacent transitions, capsule-clear recovery anchors and a continuous collision shell replace coordinate-only membership. Roof cutaways hide meshes without disabling collision. Recovery zeroes movement, returns carried quest props and preserves membership, personal inventory and health. Boss gates close after actors move clear of the doorway.

Each first eligible ordinary encounter-slot death creates one shared stack of 10 Edamame and its authored EXP. The boss creates one shared stack of 10 Mature Beans, with 250 EXP once. Encounter-slot claims, twelve finite crate identities and refinery entitlements persist across attempts and checkpoints. Exhausted enemies show the practice label. Dungeon deaths retain personal bags and equipment without restoring consumed items. Individual co-op deaths spectate; full wipes restart the same unresolved encounter with the same reward IDs. Rejoining during combat waits for encounter resolution.

Boss participants are recorded when the arena starts; scaling and completion entitlements use that record, including disconnected participants. Uninvolved late joiners are excluded. The skippable journal tutorial displays the current inventory binding and cosmetic `100 Edamame → 1 Mature Bean → 1 White Tofu block` preview.

Live snapshots preserve active leases, revisions and clock values. Saved-game restores cancel unfinished trials, return props and retain certificates. App preflight validates nested puzzle/reward data and stage prerequisites before world mutation; malformed records are rejected. Legacy completed saves retain refinery entitlements; incompatible unfinished legacy puzzles restart at safe entry with personal inventory preserved. Local saves are trusted-host data, not tamper-proof currency storage.

## Presentation and evidence

The authored factory includes twenty reachable labelled chemical props, a floor note behind a service rack, connected milk transit, three distinct sack/intake lines, guarded presses, measured cutting pieces and six docks. Editable art/audio sources are under `assets/factory/`; owning scenes are under `game/world/factory/props/`. Inspection clues and optional hints reopen in the recipe journal.

Decks render once with disjoint surfaces; overlapping foundation and landing collision solids remain active but invisible. Floor materials have no expanded outline pass. Fixed machine and sack lettering clears its backing, and bottle captions sit above their caps. The presentation regression checks these constraints; a 24-position graphical camera sweep also checked the corrected floor.

`test_tofu_dungeon_active.gd` covers the integrated station-to-boss route. `test_tofu_dungeon_active_coop.gd` uses JSON fake peers for guest controls, ownership, replay, leases, death, rejoin, checkpoint restoration and malformed inputs. `test_factory_route.gd` walks the real route and attacks perimeter segments with the real capsule and movement abilities in both cutaway modes. `test_factory_recovery.gd` checks safe correction and retained inventory. Focused rule and view tests cover production boundaries and controller keyboard intents. Graphical Godot previews have been rendered on Metal and inspected.

Release acceptance still requires a real-controller session, at least three first-time human clears and an informed replay, human art/audio review, and full-game combat/co-op performance measurement. The 12–18 minute first-clear and 7–10 minute replay targets are not yet measured. Automated route execution does not establish human pacing.
