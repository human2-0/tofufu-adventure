# Tofufu Royale match loop

## Audit and delivered changes

The existing mode already had a strong foundation: equal starting kits, authored
adventure movement/combat, seeded random chests, temporary RPG equipment,
soybean deployment, Duos, up to fifty CPUs, enemy gunfire pings and paused host
migration. The weakest part was the connection between those systems.

| Gap found | Implemented response |
| --- | --- |
| Every storm ended at the same nursery point | Seeded dry, collision-cleared finale sites; smoothly moving, nested circles |
| Players could not plan the next rotation | Dashed next-circle preview, shortest safe entry line, hold/closing countdown and distance |
| Little feedback on a successful fight | Confirmed damage hit markers, gold elimination confirmation and incoming-damage border |
| Armour stayed depleted for the rest of the match | Shared recovery to the starting 50 armour, five per second after eight quiet seconds; damage including storm resets the delay |
| Looting and surviving had little purpose beyond winning | Three visible round goals: open three chests, deal 100 actual damage, survive 90 seconds |
| No useful recap or continuing motivation | Placement, KOs, actual damage, opened chests, survival time, goals and cosmetic XP; isolated local career levels and separate practice/peer records |
| Playing again broke the group flow | Explicit ready/cancel-ready rematch using the current room and direct connections; all connected humans must agree |
| No quick silent coordination | G marks a route and H marks danger; private duo world/map callouts expire after eight seconds |
| CPUs chased distant targets and fired into cover | Bounded perception, duo regrouping, staggered cover/ground sensing and blocked-fire suppression |

The intended loop is **choose a plant → scavenge and complete goals → fight and
recover → plan the next rotation → contest the final clearing → review the round
and ready up again**. Ordinary chest contents use the same rarity weights in every region. Career XP changes neither starting equipment nor combat stats.

## Pacing and fairness

The seven 20-second holds and 120/100/60/50/40/40/40-second closes allow a bounded
ten-minute active match across the expanded map. After the circle closes completely, storm damage increases by
two HP per second each second, preventing milk/apple heal-offs from extending the
finale indefinitely. The next circle is always inside the current one. Finale anchors
come from supported plant sites within 900 metres of the original centre and
pass an additional six-metre clearance / eight-metre dry-ground check. Eligible
mainland, northern, southern, western, city and volcanic regions have equal
selection odds; a seeded site is then chosen within that region. The authored nursery
is the fallback. The final three circles share the dry finale anchor.

The same quiet-armour rule applies to every human and CPU. Health still requires
finite food. Damage goals count HP and armour actually removed after mitigation,
excluding friendly fire and overkill. Surviving alone does not grant stronger
future equipment. Round XP rewards survival (capped), KOs, goals and placement.
It is an editable local cosmetic record, not a trusted competitive ranking.

Stats, circle anchors and armour recovery clocks are authoritative bounded values
in battle protocol 8 and checkpoints. Migration discards pending rematch votes.
A next round changes the epoch, readiness barrier, match world and temporary
inventory, while retaining connected identities, skins, team mode and CPU choice.
Replay refuses insufficient rosters rather than silently changing CPU settings.
Departed humans stop occupying a human seat on the next round.

Career writes occur when leaving with an established personal placement or
starting the next round. The current outcome is recomputed after recovery before
it is banked. Recent epoch IDs prevent duplicate claims. Bounded JSON records use
an atomic replacement and validated backup recovery, independently of adventures.

CPU collision sensing runs on the authority at ten Hz per CPU, staggered across
six physics ticks, with at most five rays per decision. Steering still distributes
over existing peers. This is local obstacle avoidance, not a navigation mesh or
a guarantee that every authored structure has an optimal CPU route.

## Finite PvE hunting

Up to 24 roaming adventure enemies add a contestable risk/reward choice beside chest
routes. Snails reward food and armour; armored snails and bees offer stronger equipment
rewards. Shooting exposes the hunter through the existing gunfire radar rules. Other
survivors can contest the drops. CPUs participate through the same weapons and finite
inventories. Hunt credit appears separately in the recap; it cannot farm PvP goals.
Enemies never respawn, and storm deaths give no loot. Pending rewards survive host
recovery, including a full world-drop ledger. Ordinary chest rarity weights are the same in every region.
Population, health, distances and rewards are initial tuning; human playtests should
measure whether hunts are worth the ammunition, noise and rotation time.

## Ranged hunt and gear balance

All three hunt types now shoot across the common gun's 90m range, acquiring within
108m and 32m of vertical difference. Snails have 100 HP and fire 18-damage beans;
armored snails have 170 body HP plus their original 65-HP shell and fire 26-damage
beans; bees have 110 HP and fire 16-damage beans. Warnings last 0.55 / 0.85 / 0.45
seconds, with cooldowns of 2.2 / 2.8 / 1.6 seconds. Straight projectiles lead constant
movement but commit aim during the warning; changing direction, cover, dash and
normal guard reflection provide counterplay. Fired attacks outlive the shooter. NPC shots also use the existing stationary
100m / two-second enemy gunfire markers.
One shot per hunt and four-Hz blocked-sight retries bound authority work. Existing
Adventure enemy tuning and bee stings remain unchanged.

The map holds up to 192 dry, clear chests with 28-metre minimum spacing.
Basic / rare / legendary chest quotas are 65 / 27 / 8 percent, mixed across
shuffled cells. Each provides four distinct choices: weapon, armour/storage,
food and a flexible item. Basic quality weights are 72/25/3; rare 20/65/15;
legendary guarantees a legendary weapon and armour, with 0/25/75 for its flexible
choice. Food is guaranteed in all tiers. A fifth Magical Tofufu Chunk appears
with a separate 10% / 35% / 70% tier roll. These chances never depend on region,
skin, career, host identity or opening order.
Starter weapons and Soypod armor are Common; specialized weapons, Nori
armor and expanded bags are Rare; Celestial weapons and armor are Legendary.
Hunts guarantee food and use their own bounded reward pools: snail armor grades
55 / 40 / 5, armored armor 20 / 60 / 20, hunt weapons 80 / 20 Rare / Legendary.
Bees can still supply an upgraded backpack. No region secretly improves these odds.

Weapon tooltips show actual match bonuses and existing role advantages. Legendary
weapons gain 45% sword power / 12% attack rate, or 65% staff power with
faster sweeps than the rare staff. The raygun gains 22% shot damage and 15%
speed/range, trading 6% fire rate. Rare tools retain reach, area control, mobility or precision.
Common guns still deal 18 body / 27 head damage and keep nine-shot magazines.
Royale gun bullets travel at 150 m/s (Raygun 172.5 m/s), 2.5 times their former
speed. A 0.6-second flight retains the existing 90/103.5-metre ranges and swept
collision, including reflected shots and replicas. Adventure speed is unchanged.
A complete Celestial outfit adds 25% protection, 20% damage, 12% attack/fire speed
and 10% movement. Complete Soypod/Nori sets give 12%/20% protection with their
existing offensive/mobility tradeoffs. Each partial piece grants a quarter of its family’s complete modifiers: 3%/5%/6.25%
protection plus that family’s proportional bonuses and tradeoffs. Partial pieces
have 50 durability. Actual combat damage, including hits absorbed by the armour
bar, is split evenly among worn pieces; broken pieces disappear and lose their
modifiers. Four matching pieces suspend wear without repairing prior wear;
removing a piece resumes it. Weapon and outfit bonuses compose; swaps retain resources and cooldowns.
CPUs upgrade through grades and do not replace legendary gear with weaker items.
These are explicit initial tuning values, pending repeated human playtests.

## Compact HUD, camera and storm presentation

The Royale starts behind Tofufu. C alternates between behind and overhead test
views; it never enters first person. Middle click swaps shoulders behind, or
cycles North/East/South/West overhead, using Adventure's camera and screen-relative
movement/aim adapters. Deployment, inventory, Help, results and paused host recovery
release the cursor and block camera changes. Adventure's camera cycle is unchanged.

Health, armour and stamina use small colour-coded bars. The loadout shows actual
weapon/food art, grade borders, magazine pips and reload/special clocks. Small
objective medallions replace the permanent goal paragraph. F1 or ? opens controls.
The minimap follows the watched survivor, shades and hatches unsafe ground and
shows facing; Tab retains the full map and next-circle preview.

A generated mist texture covers one curved storm wall, with a terrain-following
bright inner rim and purple outer band. An edge vignette warns near/outside the
boundary while preserving the aiming centre. All effects derive position and
animation phase from the accepted match clock, including paused recovery; none
owns damage, collision or networking. The wall is one shadow-free mesh, and the
bounded 192-segment rim resamples at four Hz. Confirmed damage triggers a brief
pulsing red edge vignette with a clear aiming centre, including while
inventory/loot is open. Paused recovery cancels transient flashes. Four small worn-item
icons show integrity, or shields when a matching full set is unbreakable. English/Polish native screenshots
and focused camera/HUD/storm scenarios live beside the existing Royale checks.
Human comprehension and target-device performance remain separate acceptance.

Esc / F1 → Graphics offers live resolution, frame limit, VSync, adaptive resolution,
scenery distance, dynamic shadows and local effects. It releases combat input and
keeps the match running. Near/Balanced/Far scenery uses native camera-distance
culling on existing tiles; bounds include each visual's radius, preserve shorter
authored foliage ranges, and leave collisions, actors, projectiles, loot and the
storm active. Combatant visuals share a 140-metre cap at every quality, beyond
weapon reach and inside the near-cover range. Full map restores authored scenery
ranges. With atmospheric fog enabled, distance haze softens the cutoff before
scenery disappears; full-map scenery restores the original atmosphere. The Performance preset selects
65% 3D, 60 FPS, 160-metre scenery and no dynamic shadows; players can choose 50%
3D manually. These controls reduce rendering load, not authoritative CPU counts
or physics frequency. Settings persist on the device and close during recovery.

Eliminations atomically release the entire bag and worn kit, including backpacks,
with exact remaining durability and milk. Airborne kills land the kit on the
collision surface below rather than leaving floating loot. A saturated ledger retains the kit for
retry; recovery distinguishes this pending kit from a completed empty release.

## Remaining larger systems

- Duos still use elimination and spectating. A downed/revive or plant-rescue system
  needs explicit bleed-out, interrupt, team-wipe, inventory and recovery rules.
- Contextual item callouts, acknowledgement and controller bindings would extend the implemented keyboard squad markers.
- Contested supply events and additional objective types need playtested rewards;
  the current goals grant cosmetic progress without changing ordinary item odds.
- Weapon roles, time to kill, small/large-roster pacing and CPU navigation need
  repeated human playtests. Automated correctness is not evidence that a mode is fun.
- Ranked matchmaking, a trusted ladder, server-side anti-cheat, broad NAT/device
  coverage and production load acceptance are not supplied by player authority.
  No automatic central service or gameplay relay has been introduced.

These are future features, not implemented claims.

## Human playtest acceptance (proposed, not measured)

Use Solo and Duos at small, default and fifty-CPU populations, with all three
difficulties. Check that an ordinary player can find a chest or make an equipment
choice in the first 30 seconds after emergence, that rotation information is
understood without a tutorial, and that losing players have a clear next action.
Record first-fight time, time spent without a useful objective, weapon choice,
placement distribution, storm deaths, stuck CPUs, replay uptake and frame times.
These observations should drive the next tuning pass; the automated scenarios
verify rules and recovery, not those human experience targets.

## Genre references

The prioritisation is informed by the official [Apex beginner guide](https://help.ea.com/au/help/apex-legends/apex-legends/how-to-play-apex-legends/)
on squad coordination and the official [Warzone update](https://www.callofduty.com/patchnotes/2026/03/call-of-duty-bo7-warzone-season-02-reloaded-patch-notes)
on match activities, loot, armour and elimination feedback. Tofufu's tuning and
implementation above are project design choices rather than those games' rules.


## Temporary upgrades and visual results

Drag/click one Magical Tofufu Chunk onto a weapon in B and confirm its match-only
bonus. One upgrade per weapon gives +20% damage and +10% attack/fire rate.
Magazine guns gain five capacity, 20% faster bullets and 25% tighter spread
without extra reach; reload to fill the new capacity. Soyjet gains 25% continuous
firing duration and 20% stream speed. Bow reload rate increases 10%. Guarding with
an enhanced melee weapon reduces reflection SP cost by 35%; weapons with a
special RMB keep that special rather than gaining a new guard. CPUs obey the
same transactions. Upgrades follow dropped weapons and host recovery, then reset
with every new round. Adventure drop chances and enhancements remain independent.

The recap highlights placement, six icon-led statistics and three goal medals.
An animated XP bar shows the actual cosmetic level before/after this round and
celebrates level crossings. Four reward sources add to the exact existing career
award; showing the animation does not save or grant a duplicate reward.


### Rare melee hunt: Honio Meniono

One optional Honio replaces an ordinary hunt in 25% of seeded rounds, at a random
existing dry hunt site. He is a muscular Tofufu Easter egg with generated eight-view
idle, two running strides, punch/rush and overhead-slam art. Only Royale composes
him. He does not consume a survivor seat or decide victory.

- 320 HP; 25% resistance while chasing/committing, no resistance during recovery.
- Chase 8.4 m/s, acquire within 28 m, return home beyond a 38 m leash; no heal reset.
- Jab: 0.5 s warning, 1.95 m forward cone, 18 damage, 0.65 s recovery.
- Protein Express: 0.8 s committed lane warning, physical 13 m/s rush for up to
  0.58 s, one 26-damage close contact, 1.25 s recovery. No ranged damage.
- Tofu Tenderizer: 1 s warning, 3 m circular melee impact, 32 damage, 1.15 s recovery.
- Specials share a 4.5 s cooldown. World cover, dodging, guarding/SP and dash
  immunity all work. Close melee interrupts a committed skill for 0.7 s, followed
  by 2.5 s interrupt resistance to prevent permanent stunlock. Paralysis still works.
- Milk, two apples, one Magical Tofufu Chunk and one random legendary armour piece
  drop once. They are public, contestable, temporary match loot; no Adventure XP or
  gear. Normal cosmetic Royale hunt credit still applies. A full ledger keeps the whole bounty pending; storm/void kills
  pay nothing. Migration preserves the claim and cancels unfinished attacks.

Four generated, occluded sprite effects reuse fixed nodes rather than spawning
particles/lights. Torso/foot anchors, full eight-direction art, the visible upper
headshot region and collision capsule are calibrated together. Honio has localized
short jokes and a compact health bar; attack warnings and recovery colour expose
his openings without adding a permanent HUD panel.
