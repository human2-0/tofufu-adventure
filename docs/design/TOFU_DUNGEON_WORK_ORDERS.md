# Tofu Dungeon — implementation orders

**Commission:** Gigalopolis factory puzzle dungeon  
**Status:** Implementation specification; gameplay changes are not implemented by this document.  
**Owner:** Lead integrator. Assign the work packages below to implementation agents; one agent owns shared contracts and integration.

## 1. Product contract

Create an enclosed, connected tofu factory that teaches its process through observation, physical interaction and combat. Preserve the eastern Gigalopolis location, multiple floors, existing player controls, offline play and host-authoritative co-op.

**Route:** arrival briefing → bean sorting/milling → coagulation laboratory → stone and mechanical presses → precision cutting → packaging → Dofufu boss → refinery unlock.

Entrance briefing, dismissible and available again in the recipe journal:

> “Your task is to make tofu. Follow the factory recipe: choose the right beans, make soy milk, discover the coagulant, set the firmness, cut equal portions and pack your batch. Other production lines are still running—check what each machine actually makes.”

Every stage needs readable environmental clues, inspectable objects and optional hints. Do not reveal puzzle answers through objective markers, inventory highlighting or automatic targeting. Use symbols, shape and text together; never require color discrimination alone.

### Lead decisions for this specification

- **Pacing:** target 12–18 minutes for a first clear, 7–10 minutes for an informed replay. The previous five-minute target is superseded by this proposed scope; do not rush passwords, twenty chemical choices and four precision tasks into five minutes. Measure with humans before declaring the target met.
- **Failure escalation:** each accepted production mistake creates a penalty wave. Its maximum HP and damage are `base × 1.2^k`, where `k` is the attempt's cumulative mistake count, starting at 1. Fixed enemy roster; keep movement speed, windups and projectile frequency readable. First penalty wave is 120%, second 144%, third 172.8%. Do not reset the counter between rooms or on death/rejoin/load.
- **Bounded attempts:** after the tenth penalty wave, disable further production submissions and offer evacuation/restart. A fresh attempt resets puzzles and difficulty, while retaining permanent rewards already claimed. Explain this before accepting the tenth mistake. This is a proposed limit to keep difficulty and numerical state bounded.
- **Reward conflict:** unlimited repeatable mistakes plus ten beans on every kill necessarily permits farming. Recommended resolution: ten edamame per first rewarded enemy identity, including penalty enemies; repeats of already-paid encounters grant neither currency nor EXP. Persist the ledger across aborts, retries and saves. Label exhausted rematches “Practice encounter — reward already claimed.” This intentionally qualifies “every defeat”; obtain product approval before shipping a different reward policy.
- Existing Soy Milk remains a support-slot item healing **50 HP**. Preserve its finite crate rewards and the refinery lock until the boss is defeated.

## 2. Orders by stage

### A. Bean sorting and the connected mill

Build **three distinct sack types and three intake machines**, all inspectable and usable. Each sack has a stable instance ID and bean type. Require all three correct assignments; only the mature-bean line supplies the tofu batch.

| Sack | Correct intake | Subtle identification | Output and locked continuation |
| --- | --- | --- | --- |
| Edamame | Chilled intake feeding a freezer | Plump green pods; harvest tag mentions fresh-picked beans. Intake has frost, pod trays and a cold-chain maintenance card. | Visible frozen-pod conveyor disappears behind a locked insulated door. |
| Mature beans | Tofu mill | Dry, pale round beans; grain tag emphasizes protein. Machine has soaked beans, filter cloth and protein-curd residue. | Wash/soak drum → grinder → filter → soy-milk pipe → coagulation tank. |
| High-fat beans | Oil mill feeding soy candle wax equipment | Oil-stained sack and a high-oil harvest grade. Intake has an oil gauge and a candle-mould sample. | Decorative wax line reaches a locked casting room. |

Order of correct deliveries is free. Picking up, inspecting or returning an item is never a mistake. A mistake occurs only after a deliberate **Load intake** action with an incompatible sack. The machine visibly rejects it, returns it to an accessible dock, increments escalation once and summons a wave. Lock production submissions during combat; retain correctly routed sacks. Spare quest sacks cannot enter personal inventories, become currency, block doors, stack into ladders or leave the dungeon.

After sorting, show soaked beans entering the grinder, pulp moving to the filter, and milk visibly travelling through inspection windows into the next room. One batch ID follows this sequence. No milk appears in an isolated tank before the mill has produced it.

**Pass:** all nine sack/intake combinations tested; three succeed, six fail exactly once per committed submission. Simultaneous users cannot duplicate or double-consume a sack.

### B. Coagulation lab, hidden password and chemical choice

Entering the laboratory triggers a mandatory opening encounter. After clearance, unlock chemical handling and the terminal. Install **at least twenty separately inspectable containers** on reachable racks. Each uses a fixed content ID; shelf positions may shuffle once per adventure and must persist.

Starter label set: Nigari; gypsum; citric acid; vinegar; lemon concentrate; glucono-delta-lactone; calcium chloride; table salt; baking soda; sodium carbonate; sugar; starch; agar; gelatin; yeast; pectin; potassium citrate; sodium citrate; distilled water; mineral oil.

**Only Nigari passes this fictional factory's recipe.** Some other listed substances can be coagulants in real food production: terminal wording must explain that this batch specification requires Nigari, rather than claiming all alternatives cannot make tofu. Use sealed game props, with no real chemical-handling instructions.

Terminal interaction:

1. Move smoothly to a close view of the computer screen. Keep a clear Back/Cancel control.
2. Show password field, Submit and a **?** hint button. Keyboard input works immediately; controller input opens an in-game virtual keyboard with D-pad/stick navigation, confirm, delete, space and cancel. Do not rely solely on an OS keyboard.
3. Password is **Tofufu**. Accept surrounding whitespace and case variations; the paper displays the canonical spelling. Password attempts alone do not spawn enemies. Apply a short bounded submit cooldown and input-length limit.
4. The question-mark hint says: “The last operator dropped the shift note below the service return.” It does not disclose the password.
5. Place an interactable folded paper on the floor behind the service-return rack, reached by a short side route with a low step and narrow but capsule-safe passage. It must remain reachable with default controls, on controller and in co-op, without a special ability or a combat exploit. Discoverable from a deliberate inspection angle; subtle nearby focus prompt, no permanent glowing arrow.
6. Inspecting the note opens legible text: “Shift operator: Tofufu. Terminal access still matches the operator name.” Record the discovered clue in the journal; do not consume the paper for other players.
7. Successful login reveals the batch formula: **“Coagulant: Nigari”**, an ingredient silhouette and the correct dosing action. Do not send authoritative success from a client UI.

Permit chemical inspection freely. Picking a bottle is reversible; **Pour into batch** commits a choice after the formula is unlocked. Wrong contents cause a rejected-batch effect and a penalty wave at the next 20% escalation. After clearance, flush and refill the slurry from the upstream buffer without replaying completed sorting. Correct Nigari starts a visible pour, curd formation and the normal Dofu emergence encounter; only its defeat releases the batch to pressing.

During terminal use the actor remains in the world: damage, death, disconnect or leaving interaction range closes the view and releases control. Pause no shared combat clock. No camera lock can confer invulnerability.

**Pass:** every decoy fails; Nigari alone succeeds. Test password entry, focus changes, cancellation and controller reconnect. No hidden answer is embedded in selection highlights or client-provided success flags.

### C. Firmness: traditional stones and precision machinery

Produce and certify **soft, firm and extra-firm** samples. Soft and firm are quality-control portions; the certified extra-firm run produces the single large block used in the cutting stage. Use a finite curd batch that can be reconstituted after failure. The precision settings below are game tuning, not a real tofu recipe.

**Traditional station:** one cloth-lined vessel and three carryable stones, each one weight unit. An inspectable craft card illustrates surface texture and drainage; a fold-out hint explains the controls without selecting the answer.

- Soft sample: one stone, hold for 3 seconds, then explicitly lift/release.
- Firm sample: two stones, hold for 5 seconds, then release.
- Timing tolerance: ±0.75 seconds around each target, measured by authority. A third stone or the wrong release window rejects the current sample.
- Sample selector chooses the requested firmness. Show compression and whey runoff continuously; never use unstable rigid-body mass as the scoring system.

**Modern station:** use levers to start pressure and stop at the right moment for extra-firm tofu. A monotonic calibrated gauge traverses 0–100 over approximately eight seconds. Successful stop is **82–90 inclusive**; overshoot, premature release or abandoning an active press rejects the sample. Telegraph the target band through the machine's calibration plate and texture reference. Controller and keyboard use the same action edges and authority timing.

A rejected sample triggers one penalty wave. Preserve already-certified samples. Block another press cycle until combat ends; reissue the failed sample's curds afterwards. Persist stone placement and sample certificates. A disconnect releases the station lease, safely halts the machine and restores the unfinished sample without creating a free certificate.

**Pass:** boundary-time tests, frame-rate independence, spammed Start/Stop, simultaneous operation, disconnect mid-press and latency simulation. Accessibility may widen timing windows through an explicit preset; changing presets cancels the current trial and cannot yield duplicate rewards.

### D. Six-piece cutting and packaging

Present one large rectangular block on a cutting carriage. Five parallel cuts must yield six equal slabs. Use a close interactive view: mouse/keyboard or controller moves the guide, confirm previews the cut, and a separate **Commit cuts** action submits all five together. Permit guide adjustments before submission.

Let total usable block length be `L`, target piece width `T = L/6`. From five sorted internal cuts, calculate all six resulting widths, including both end pieces. Accept only when **every width is within `[0.95T, 1.05T]`**. This is ±5% of an ideal piece, not ±5% of the entire block. Reject crossed, duplicate, non-finite, external or insufficiently separated cuts before gameplay evaluation.

A valid but inaccurate committed plan produces one penalty wave and a fresh quest block after clearance. Invalid/replayed network packets produce no waves and no rewards. The view may show ticks and a movable ruler, but must not snap all cuts automatically to the solution.

After success, instantiate exactly six individually identifiable slabs. Carry each into one of six empty packaging slots, then seal each slot. Reserve transfer ownership atomically; no two players may move the same slab or fill the same slot. A filled slot refuses extra input without punishment. Packed pieces remain quest props, never sellable inventory items.

The sixth sealed package transitions to the boss encounter **once**. Close the arena gates after safely relocating any player standing in a doorway. Keep an explicit abandon-run route through a menu; never leave actors physically crushed or trapped in geometry.

### E. Dofufu boss and completion

Dofufu is an unmistakable hostile clone of Fufu, wearing a **Nori set and a katana**. Match the main character's silhouette and billboard presentation; use a distinct face, aura, nameplate and boss health bar so co-op players cannot confuse it with a teammate.

Boss composition must be independent of player inventory and controls. Equip a non-lootable weapon model and authored Nori appearance; do not accidentally inherit player equipment procs or access an actual player's mutable state.

- Katana three-hit combo with a readable final recovery.
- Telegraph a short dash slash; stop against world collision and sealed doors.
- At half health, add a telegraphed Nori slam and shorter recovery, while preserving dodge opportunities. No unavoidable entrance strike, infinite stun chain or attacks through machinery.
- Suggested starting tune: 800 solo HP; add 50% base HP per additional combat participant, locked when the encounter starts. Tune damage against the actual starting loadout; target a 60–90-second solo fight. Joins wait outside an active encounter until a wipe/restart so party-size changes cannot alter scaling mid-fight.

Death commits boss defeat, reward eligibility and refinery completion atomically before showing victory. Grant **10 Mature Beans** for the boss's first eligible defeat, replacing its ordinary bean payout. Preserve an authored boss EXP reward; pay it once through the same ledger.

Show a skippable 6–8-second unlock animation:

> **Refinery skill unlocked — bean currency can now be refined.**

Animate the actual current rules: **100 Edamame → 1 Mature Bean → 1 White Tofu block**. Explain the inventory refinement action and show its configured input binding. Preview tokens are cosmetic; the tutorial never debits or mints real currency. Preserve subsequent currency tiers and existing exchange costs. Make the tutorial replayable from the recipe journal. Unlock every participating character who completed the encounter, including a disconnected participant through the host's saved entitlement record; do not unlock an uninvolved late joiner automatically.

## 3. Non-negotiable robustness orders

### Containment and safe recovery — ship gate

The current `TofuFactory.contains()` is an X/Z rectangle and omits height. It cannot certify a legal location or prevent a player reaching an unearned room. Replace reliance on this predicate with explicit legal room volumes, floor/deck ranges, permitted transitions and authored recovery anchors.

- Build a continuous collision shell: foundation, external walls, roof, floor edges, ramp undersides, landings and locked side-line doors. Hiding roof/wall meshes for the camera must never disable collision.
- Overlay adjoining collision solids slightly; test every seam, machine-wall junction and stair/ramp landing with the real capsule. Extend sealed door colliders to prevent jumping over them.
- Use fixed collision for quest machines. Bags, bottles, stones, crates and corpses cannot create climbing stacks, wedge gates or push a character through walls.
- Keep a per-actor last legal grounded anchor, updated only in an unlocked room with capsule clearance. Before publishing authoritative movement, detect illegal room transitions and out-of-volume positions; restore the last safe anchor, zero velocity and return carried quest props to their recovery docks. Use redundant catch volumes beneath and around the building. Recovery is a correction, not a reward or death.
- Do not infer “left the dungeon” from an escaped coordinate: run membership survives boundary recovery and only changes through a validated exit/abandon transition.
- Sweep fast projectiles/streams against world geometry; enemies, effects and drops must not hit actors across sealed walls. Clamp drop placement to reachable floor anchors.
- Test jump, charged jump, dash, super dash, knockback, enemy shove, crowded co-op doorways and reconnect at seams. Include legal route coverage plus deliberate attacks on every perimeter segment, not just a walk along the intended path.

### Authority, state and transactions

Define explicit states for each stage: locked, combat, ready, operating, rejected, complete. Final packaging and boss completion are separate states. An enum alone is insufficient: transitions require the correct batch, cleared encounter, input ownership and stage prerequisite.

Typed commands carry bounded intent: action, target ID, object ID, run/attempt ID, sequence and expected revision. Authority validates membership, actor alive/control state, stage, range, line of sight, station lease and revision. Derive chemical identity, cuts, reward counts and success on authority. Never accept client health, success, quality score or difficulty multipliers.

Each valid mistake is one transaction: reject input, increment escalation, allocate encounter IDs, release station and spawn the wave. No input queue during penalty combat. Replayed, stale, impossible or malicious requests are rejected without punishment or enemy creation. Restrict submissions to an alive actor's explicit commit action.

### Rewards, death and persistence

- An eligible ordinary enemy drops **one stack of 10 Edamame**, once. In co-op this is one shared drop, not ten per peer. Use unique reward/drop IDs; duplicate death callbacks and late snapshots cannot pay again. Boss drops one shared stack of 10 Mature Beans.
- Persist encounter-slot reward identities separately from attempt IDs. Repeating or restarting an already-paid slot never refreshes its currency, EXP, crates or Soy Milk. Failure encounters use fixed wave/slot IDs within the bounded attempt design above.
- Dungeon death retains every personal bag item, nested backpack content and equipped item. Apply the exception before existing solo and co-op `drop_on_death` calls, using authoritative run membership. Restore no already-consumed healing items or ammunition; otherwise death becomes an item duplication tool. Preserve existing outside-dungeon death rules.
- In co-op, an individual death spectates until the active encounter ends; no repeated respawn/heal loop against a living boss. A full wipe resets that encounter to full HP using its existing reward IDs. Solo death likewise resets the unresolved encounter.
- Respawn at the current cleared checkpoint. Return carried quest objects to valid docks, retain stage certificates and mistakes, and restart unresolved encounters using the same reward identities. No monsters remain on the respawn anchor.
- Save stage/substate, batch, recipe discoveries, terminal unlock, assignments, chemical submission, firmness certificates, cut result, package slots, encounter IDs, mistake count, rewards and completion entitlements. Checkpoint these transactions together; restoration must never retain loot while resetting its claim record.
- Release station leases on disconnect/death. Rejoin restores host state. Freeze precision trials when offline-paused; on reload cancel an unfinished trial safely. Do not simulate offline pressing time. Co-op menus do not pause the authority clock.
- Version and migrate legacy dungeon saves explicitly. Retain previously earned refinery unlocks; restart incompatible unfinished puzzles at safe entry without deleting personal inventory. Reject malformed snapshots before constructing actors or props.

**Threat-model limit:** prevent in-game farming, replay and guest-authority exploits. A player-controlled host or manually edited local save is outside the trusted-host model; do not promise tamper-proof currency without changing the product's architecture.

## 4. 3D asset orders

### Shared art and technical specification

Build stylized, hand-painted industrial props matching the current soft colors, outlines and 2.5D characters. Machines must read from overhead and first-person. Treat one Godot unit as approximately one metre; verify scale beside Fufu's actual collision capsule before final export.

Supply source files plus `.glb`/Godot scenes, correct pivots, simple collision proxies and named sockets: `input`, `output`, `carry_grip`, `interaction`, `fluid_in`, `fluid_out`, `service_access`. Separate moving parts from static bodies. Floors, railings, walls and doors need independent collision and camera-cutaway groups. Reuse materials and instancing for rack bottles; start at 1K textures for small props and 2K for hero machines, profiling on the existing Mac target before increasing detail.

| Asset family | Required design / states |
| --- | --- |
| Three sacks | Different silhouettes, stitched harvest tags, visible representative beans; resting/carried/rejected states. Edamame pods, dry protein beans and oily high-fat beans must read without relying on color. |
| Three intakes | Distinct hopper shapes and inspection panels. Add freezer compressor/insulated door, tofu wash-grind-filter assembly, and oil extraction/candle-mould sample. Side lines have visible output but physically sealed continuations. |
| Connected milk line | Traceable pipe joints between actual mill outlet and tank inlet, pump housing, filter mesh, drip tray and transparent sight-glass sections. Animated milk moves along a continuous path; no decorative pipe may falsely imply a playable shortcut. |
| Lab | Rack modules with twenty legible label variants and bottle shapes/caps; controller selection highlights the focused object only. Nigari is visually plausible among peers, not a glowing prize. Terminal has a screen surface suitable for interactive UI. Folded note is a real floor prop with an inspect view. |
| Coagulation tank | Milk level, dispensing spout, curd growth, rejected batch and rinse/refill states. Enemies emerge from accessible tank-side spawn points; their movement never begins embedded in a collider. |
| Traditional press | Wooden/stone frame, cloth-lined vessel, three keyed stones with grip areas, compression plate and visible whey channel. Sockets accept stones; arbitrary physics stacking is unnecessary. |
| Modern press | Metal frame, two readable levers, large calibrated pressure gauge, guarded moving plate, emergency stop, compression/release animations. Cosmetic plate movement cannot crush or launch actors. |
| Cutter and packer | One intact block, five guides, six correctly proportioned slabs, blade-down/up cycle, six packaging docks and sealing film. Cut meshes reflect measured slice widths, not six identical props after a failed cut. |
| Ordinary enemies | Factory-specific soy/Dofu bodies; each has a visible Soyjet/Sotjet emitter and a knife grip with clean switch animations. Ranged stance, empty/reservoir recovery, knife windup, hit, stagger and death must be readable. Use shared weapon rules through composition; give the sprayer a finite reservoir/recovery cycle, separate melee/ranged cooldowns and line-of-sight checks. Never fire a full stream and swing the knife simultaneously. |
| Dofufu | Original hostile-clone variant of Fufu, Nori costume pieces, katana, distinct face/aura and boss portrait. Preserve the established billboard character convention; model costume/weapon props in 3D where appropriate rather than silently replacing Fufu's art pipeline. |
| Building kit | Continuous shell, two decks, guarded service route, clear arena, thick sealed doors, ramps with flush landings and readable emergency exit. Minimum clear corridors should accommodate two actual player capsules plus margin. |

**Machine design advice:** construct each machine around a visible input → transformation → output, then add its motor, maintenance access, drain and safety guard. Route pipes above walkways or inside guarded channels. Keep interaction positions clear of collision and animation sweeps. Use sounds and moving parts to explain state; large floating answer text is not a substitute for an understandable machine.

## 5. Worker assignments and handoff order

All proposed filenames below are suggestions, not existing APIs. Read the applicable scoped `AGENTS.md` before work. Runtime GDScript must remain **at most 200 lines per file**; extract responsibilities, never compress statements to evade the limit.

| Order / owner | Work boundary | Required handoff / acceptance |
| --- | --- | --- |
| **P0 Lead integrator — contracts first** | Inspect `game/quest/tofu_dungeon_state.gd`, `game/app/quests/{tofu_dungeon,dungeon_stage,dungeon_interaction}.gd`; define typed puzzle commands, stage data, encounter/reward IDs and content Resources. | A small compiling contract and transition table; single owner for shared schema, scene wiring and migrations. Freeze these before dependent workers begin. |
| **P0 World engineer — containment** | `game/world/factory/`, authored legal volumes and recovery anchors; app wiring through the lead. | Sealed shell and safe service route; adversarial perimeter test with repeatable coordinates; no progression skips or inventory loss on recovery. |
| **P1 Puzzle engineer — sorting and lab** | New focused rules under `game/quest/`; interaction adapters under `game/app/quests/`. | Nine sorting cases, twenty chemicals, formula gate, rejection transactions, milk-batch continuity and co-op ownership tests. No UI-owned outcomes. |
| **P1 UI/input engineer — terminal and trials** | `game/ui/quests/` plus app presentation adapters. Coordinate bindings with existing input/settings code. | Keyboard/controller terminal, note inspection, accessible clues, cutter controls, camera cancellation and complete focus restoration. |
| **P1 Production engineer — pressing/cutting/packing** | Independent pressure/cut/package rules and station adapters. | Three certificates; exact six-width tolerance tests; lossless ownership transfer; one boss trigger. |
| **P1 Combat engineer — enemies and Dofufu** | `game/combat/enemies/`, existing `combat/ranged/` Sotjet and melee components, app encounter composition. | Visible Soyjet + knife enemies; guarded escalating wave parameters; boss telegraphs/world collision; confirmed defeat events only. Do not grant inventory rewards inside enemy visuals. |
| **P1 Economy/session engineer** | `game/app/coop/`, `game/session/`, `game/persistence/`, inventory/death adapters; read `docs/architecture/COOP.md`. | Persistent payout ledger, retained death inventory, bounded schemas, save migration, replay/rejoin/host-checkpoint tests. Coordinate schema edits with lead. |
| **P1 Asset artist / technical artist** | `assets/factory/` and owning scenes under `game/world/factory/`. Read `assets/AGENTS.md`. | Asset checklist above, sockets/collision proxies, overhead and first-person previews, original source/provenance, measured performance. Begin blockouts after contract dimensions are fixed. |
| **P2 QA and lead integration** | Existing dungeon tests plus focused new scenario tests. | Evidence below; tuning report; map/architecture documentation updated only for implemented changes. |

Parallelize feature work after P0 contracts. Workers must not independently rewrite shared coordinators, protocol files or entry scenes. Each handoff contains changed files, behavior, test command/results and a short unresolved-risk list; no session diaries.

## 6. Release acceptance checklist

- [ ] First-time testers can explain why each sack belongs to its line; recipe clues remain discoverable without revealing answers automatically.
- [ ] At least twenty chemicals exist; paper is reachable; password and controller keyboard work; milk visibly reaches the laboratory from the mill.
- [ ] All three firmness certificates require the specified actions; cutting validates six individual widths; six packages trigger one boss.
- [ ] Wrong committed choices cause one increasingly strong wave; invalid network requests cause none. Input remains locked until clearance.
- [ ] Ordinary first-eligible kills drop exactly 10 Edamame; boss drops exactly 10 Mature Beans. Replay, rejoin, simultaneous pickup and reload cannot duplicate currency or EXP.
- [ ] Death/abandon/recovery preserves personal bag and equipment, never restores consumed items, and cannot reset paid rewards.
- [ ] No tested movement ability, prop, enemy shove or reconnect can escape the shell or skip a locked stage. Record perimeter cases and recovery assertions, including both floors and roof cutaway modes.
- [ ] Co-op tests use actual guest commands through local fake peers; cover simultaneous submissions, stale revisions, latency, late joins, disconnects and restored checkpoints. All peers run the revised protocol.
- [ ] `python3 tools/check_architecture.py` and `python3 tools/verify.py` pass. Extend `tests/test_tofu_dungeon.gd`, `test_tofu_dungeon_coop.gd`, `test_factory_route.gd`; add focused rules tests where useful. Report unrelated blockers precisely; do not mark the full suite green after skipping failures.
- [ ] Render and interact in Godot with keyboard/mouse and a real controller. Check billboard silhouettes, labels, floor seams, camera transitions, machine timing and frame cost.
- [ ] Test at least three first-time players and one informed replay. Record time by stage, hint use, errors and deaths; adjust tuning against the proposed pacing targets.

**Completion means evidence-backed integration of these orders—not an asset drop, a mock-up or a sequence of teleport-only tests.**
