# M1 rendering budget

The target is **120 FPS at 2560 × 1440 output**, or 8.33 ms per frame. The tested
Mac mini has Apple M1, 16 GB RAM and a 144 Hz display. Its saved local profile is
a 120 FPS cap, native maximum 3D resolution, adaptive resolution enabled and
VSync off. The display stays at 144 Hz, as requested. UI stays at output
resolution when the 3D scene scales down.

**Locked 120 FPS is not achieved across all views.** Open horizons and demanding
four-player scenes remain above the 8.33 ms budget. The FPS cap is a ceiling;
resolution scaling cannot remove CPU bottlenecks.

## Implemented strategy

- Both seas now use the original Ocean biome water shader through a shared
  `OceanMaterial`. Authored swells, shore foam, shallow/deep colors and lighting
  remain. Water uses encoded seabed depth rather than framebuffer copies or
  screen-space reflection tracing. The downloaded MIT SSR package was already
  inactive at the start of this pass and remains reference source. Its download
  alone was not the remaining runtime cost.
- Water is indexed and split into independently culled 64-metre tiles, replacing
  whole-sea draws. Terrain retains its 24-metre visual tiles and original physical
  surfaces. This is particularly useful around the enlarged volcanic island.
- Grass retains its density and near ribbon geometry; medium/far index sets use
  six/two triangles per tuft instead of ten. Distant tree leaves flatten their
  folds without dropping leaf silhouettes. Decorative soy/wheat fields retain
  1,800 plants each, using simpler shared meshes in 16-metre tiles with at most
  512 instances per batch and no tiny individual shadows.
- Existing bounded tree shadow meshes, 32-metre directional shadows, FXAA,
  quarter-resolution weather sky, regional reef-wildlife updates and cached
  immutable map textures remain in use.
- Opaque castle walls, ramps, gates and farm building shells carry inset box
  occluders. They follow the actual visible geometry, including cutaways and
  opened gates. Cloud terrain uses its exact triangles in 24-metre occlusion
  tiles; each tile disables below its top so an invisible floor cannot hide the
  sky from below. This is a local rendering policy, following Godot's
  [occlusion guidance](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html).
  It never deactivates host gameplay, collisions or another player's simulation.
- Immutable ornaments in Meadow, Jungle, Desert, Ocean and Frost bake into
  16-metre spatial tiles. Material storage properties, textures, lighting, cull
  layers and shadow modes must match. Authored vertices, inverse-transpose
  normals, UVs and the original scaled ink extrusion survive the bake.
  Scripted/named views, cutaway pieces, range-controlled geometry and unsupported
  vertex effects retain their own nodes. Plain static collider children keep
  their original parent and transform while their visual joins a batch.
- Through-wall labels and depth-independent effects explicitly bypass occlusion
  to preserve their existing presentation contracts. Depth-tested world objects
  use normal visibility culling.
- Offscreen enemies skip cosmetic pose updates. Gameplay still runs at 60 Hz.
  A stationary grounded snail can reuse its confirmed contact on terrain marked
  by `TerrainSupport` as permanent. Movement intent, knockback, vertical motion,
  relocation or support changes wake normal collision work immediately. The
  permanent contract requires immutable collision geometry after construction;
  mutable platforms and props do not opt in.
- The camera and each existing Fufu sprite interpolate physics poses on render
  frames. Camera collision rays stay on physics ticks. Camera presentation runs
  before sprite/hand presentation and weapon views. There is one Fufu sprite per
  actor; teleport, respawn and transport changes reset its history. Physics
  capsules, combat poses, input and authority remain at 60 Hz.
- Remote actors use up to eight snapshots with 75 ms interpolation delay and at
  most 100 ms extrapolation. Guests skip rebuilding unchanged world views using
  a per-session value cache. Host packets share immutable captured values in
  shallow recipient envelopes before transport serialization. Actor/world
  publication rates remain 20/10 Hz; see [co-op contracts](architecture/COOP.md).
- Adaptive resolution starts at the selected ceiling, waits three seconds and
  reacts to sustained slow frame intervals in two-second windows. It drops five
  percentage points at a time to an 85% floor and recovers one step after fifteen
  stable seconds. Explicit 85%/75% ceilings, disabling adaptation and uncapped
  rendering are respected. A single loading stall does not lower quality. The
  temporary scale is local and is not saved as the user's new preference.

## Verified 1440p perspective measurements

Rendered local measurements use Godot 4.7.2, Metal / Forward Mobile, VSync off,
uncapped FPS and native 3D resolution. A fixed 2560 × 1440 SubViewport and its PNG
captures verify the render target. Each stationary case warms for 90 frames and
samples 240 wall-clock intervals. Daylight, placement and camera angles are fixed;
encounters and ambience continue. Loading and screenshot readback are outside
sampling. Desktop background applications remain running.

`tests/performance/m1_perspectives_before.json` is an isolated copy of the same
world with this pass's regional batching and occlusion disabled.
`m1_perspectives.json` records the optimized version. Both contain fifteen cases
across overhead, shoulder (behind Fufu) and first-person views. The engine draw
counters show the major waste: close castle cameras submitted thousands of
hidden props beyond the walls. Open Cloud Realm horizons retain visible scenery
and still exceed the 8.33 ms target.

| Location / view | Control median ms | Optimized median ms | Optimized p95 ms | Draws before → after |
| --- | ---: | ---: | ---: | ---: |
| Village / behind | 9.58 | 8.88 | 13.13 | 1704 → 938 |
| Village / first person | 10.47 | 9.52 | 13.96 | 1845 → 1121 |
| Dense grass / behind | 11.12 | 10.45 | 15.20 | 2260 → 1784 |
| Dense grass / first person | 12.44 | 11.39 | 16.65 | 2606 → 2065 |
| Reef / behind | 9.76 | 8.32 | 14.28 | 571 → 502 |
| Reef / first person | 8.88 | 8.78 | 13.88 | 628 → 544 |
| Castle / behind | 19.13 | 9.70 | 13.51 | 4988 → 610 |
| Castle / first person | 22.21 | 9.15 | 14.15 | 5649 → 689 |
| Cloud Realm / behind | 23.69 | 17.71 | 22.28 | 5096 → 3544 |
| Cloud Realm / first person | 24.71 | 19.64 | 24.10 | 5259 → 3777 |

Earlier `m1_native.json`, `m1_coop_host.json`, `m1_coop_guest_stress.json` and parrot
snapshots lack verified render dimensions. Their previous timing tables are
withdrawn as native-1440p evidence. Requesting a native window size did not prove
the final framebuffer size during display sleep/fullscreen transitions.

GPU timestamp readback returned zero, so independent GPU execution time is not
available. Engine draw/triangle counters are diagnostic signals, not exact GPU
work or total process RAM. In particular, the Forward Mobile mesh-LOD counter
path does not multiply its selected index count by MultiMesh instance count;
LOD grass can therefore be substantially undercounted. Use frame intervals,
actual mesh/instance budgets and visual inspection together. The relevant APIs
are [ArrayMesh LODs](https://docs.godotengine.org/en/stable/classes/class_arraymesh.html),
[mesh LOD behavior](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html)
and [rendering counters](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html);
the counter limitation is visible in the engine's
[Forward Mobile implementation](https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp).

## Moving co-op measurements

The host benchmark renders one world containing four moving/firing players and
publishes actual JSON packets to three joined fake peers. It warms each case for
240 frames and samples 600 wall-clock intervals. `--perspectives` covers both
shoulder and first-person views at village, grass, rain camp, reef and castle.
Native runs are uncapped at 100% 3D scale. Adaptive runs use the requested
120 FPS cap and an 85% floor, with full-resolution output/UI. There is no separately
rendered guest in the host-only benchmark. Actors reset health/stamina between
cases and are protected from defeat while enemy AI and projectiles continue.
Relocation and end-position guards reject a case if any actor leaves its named
location; actor end coordinates are retained in JSON. Combat damage/respawn
correctness is covered separately by the full gameplay verifier.

`tests/performance/m1_coop_perspectives_before.json` records the control;
`m1_coop_perspectives.json` records optimized native rendering;
`m1_coop_perspectives_adaptive.json` records the local adaptive profile.
Camera/sprite subtick counters verify render interpolation while the party moves.
Engine physics/script timing windows overlap frame measurements and must not be
added as independent components. A stationary capture cannot establish that the
original character doubling symptom is resolved on a live two-device connection.

| Four-player location / view | Control native median ms | Optimized native median ms | Adaptive median / p95 ms | Lowest 3D scale |
| --- | ---: | ---: | ---: | ---: |
| Village / behind | 10.38 | 9.30 | 10.59 / 13.91 | 90% |
| Village / first person | 11.28 | 10.10 | 9.86 / 14.75 | 85% |
| Dense grass / behind | 13.83 | 12.70 | 13.25 / 18.28 | 85% |
| Dense grass / first person | 14.79 | 14.01 | 14.32 / 18.75 | 85% |
| Rain camp / behind | 13.07 | 12.65 | 13.02 / 17.40 | 85% |
| Rain camp / first person | 14.45 | 13.68 | 14.95 / 18.78 | 85% |
| Reef / behind | 10.74 | 10.73 | 11.08 / 17.90 | 85% |
| Reef / first person | 11.32 | 11.65 | 11.40 / 17.46 | 85% |
| Castle / behind | 22.13 | 10.98 | 11.12 / 17.76 | 85% |
| Castle / first person | 27.35 | 12.04 | 11.74 / 17.17 | 85% |

Castle draw submissions fell from about 5,500–5,800 to 680–730 in the native
four-player run. Camera and sprite movement between physics ticks returned in
those faster cases. Dense grass still spends roughly 9 ms per physics step;
adaptive resolution cannot solve that CPU cost. Cloud horizons remain expensive
in solo close views. None of these medians or p95 values establish locked 120 FPS.
The native comparator passed all fifteen solo and ten co-op cases, including its
25% median/p95 and 20% geometry/draw regression limits. The ten adaptive cases
completed at verified 1440p output with the selected 120 FPS cap.

The optional `--guest` harness keeps a hidden authority world and a rendered guest
world in one process. It checks joined-session readiness, remote movement and
unchanged-view skips under deliberate two-world CPU stress. It does not predict
guest FPS on a separate computer. Earlier `m1_coop_guest_stress.json` lacks verified
render dimensions. Real two-device latency, packet jitter and extended play
remain manual validation. Host gameplay is never deactivated based on one
player's camera.

With the current 144 Hz display, a blank-scene check measured about 72 FPS when
combining VSync with the 120 FPS cap, versus about 120 FPS with VSync off. The
saved profile follows the requested cap with VSync off. A cap alone cannot
guarantee tear-free presentation on an unsynchronized display.

## Parrot rear-view presentation

The ridden macaw now uses the same rendered ground position as Fufu. Physics,
flight authority and collision remain at 60 Hz; local and replica mount views
apply only the presentation offset. A 300-frame moving rear-view preview measured
less than 0.000001 m separation from the rider and zero camera-sample separation.
Heading turns continuously and wing poses
blend between flight and rest. Textured body, mirrored wings and tail reuse four
immutable mesh surfaces across all birds, with bounded distant visibility.

Compatible static village ornaments are baked into 16-metre tiles by material
and shadow mode. Textured surfaces also retain texture identity, projection scale
and roughness in that grouping; world-space triplanar coordinates keep the painted
brick, timber, tile and concrete proportional after baking. Cutaway trim is excluded
from baking and follows its owning wall or roof. Their exact vertices, lighting normals, UVs and scaled outline extrusion remain.
Scripted views, visibility-controlled roofs, colliders and interactive objects
retain their original nodes. This reduces the many small draws seen together from behind.

Armored snails share one immutable mesh for curved plates, a dark lining and
raised side spirals (under 4,096 triangles). Bees share a shaped striped body
(under 1,500 triangles) and two-surface veined wing meshes (under 180 triangles).
Hit/warning materials remain per actor; only wing membranes and veins render
both sides. These geometry limits are checked by `test_meadow_meshes.gd` and do
not establish a frame-rate guarantee.

`tests/benchmark_parrot_rendering.gd` now uses the same fixed 2560 × 1440 render
target. Earlier `m1_parrot_unbatched.json` and `m1_parrot_batched.json` snapshots
lack verified render dimensions and do not establish native-1440p mounted FPS.
Hiding the bird, hiding grass and increasing mesh LOD bias made little difference
in those diagnostic runs. A shorter far plane helped modestly, but is not applied;
authored distant terrain and landmarks retain their existing view. Automated
travel checks cover offline/authority/replica state. Extended live flight on a
separate guest machine remains manual.

## Budgets for future features

| Responsibility | Reusable policy |
| --- | --- |
| Large terrain/water visuals | Spatial tiles; original collision retained; no full-scene water copies |
| Decorative repeated objects | Shared meshes and explicit segment counts; at most 512 instances per MultiMesh batch |
| Immutable prop baking | 16-metre tiles, complete material identity, retained normals/UVs/ink, preserve named and scripted controls |
| Opaque architecture | Inset occluders follow visible geometry; preserve openings and cutaways; never gate authority |
| Detailed foliage | Keep near art; authored distant indices; verify silhouettes and wind |
| Cosmetic activity | Bound pools and visibility work; never gate host gameplay by local visibility |
| Resting collision | Reuse only confirmed permanent support; wake on motion/support changes |
| Actor presentation | One existing sprite, render interpolation, relocation reset, ordered hand/weapon views |
| Guest replication | Bounded snapshot history, per-session changed-view cache, authoritative host state |
| Local quality | Measured adaptive pixel budget within user-selected limits; full-resolution UI |

Profile new features with overhead, shoulder and first-person views, dense
foliage, water, rain, active enemies and a moving four-player party. Preserve the
same locations and deterministic benchmark input when comparing revisions.
Quality ceilings do not replace investigating CPU work, draw submissions and
network serialization. Do not raise a baseline to hide an unexplained regression.
Rendered benchmarks use a fixed 2560 × 1440 SubViewport and record its actual
texture dimensions. Window/fullscreen transitions and display sleep previously
changed native window buffers despite a 1440p size request. Historical JSON files
without render dimensions are retained as diagnostic snapshots and are not
validated native-1440p baselines. The comparator rejects them.

## Repeat and validate

The complete automated verifier passed, including architecture, import,
interpolation/contact rules, combat, co-op response, saves, menus and scene smoke
checks (108 stages, with 468 runtime scripts checked). Rendered checks cover
all three camera modes at five locations, moving/firing four-player close views,
protected-fixture location guards, and native/adaptive 1440p targets. Paired
culling-off/on captures cover castle walls/cutaways, village/barn interiors,
cloud islands and the view below clouds. Scaled-prop before/after captures differ
by at most one RGB unit, with identical silhouettes, lighting and ink extrusion.
Live two-device smoothness, NAT behavior and long-session performance remain
separate validation.

Run rendered benchmarks separately from the verifier and other benchmarks:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/benchmark_perspectives.gd
python3 tools/check_render_budget.py /tmp/tofufu-perspectives.json --check-timings
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/benchmark_coop_rendering.gd -- --perspectives --adaptive
python3 tools/check_render_budget.py /tmp/tofufu-coop-host-adaptive-perspectives.json --baseline tests/performance/m1_coop_perspectives_adaptive.json --check-timings
```

The comparator rejects mismatched render dimensions and missing, unexpected,
duplicate or invalid cases. It flags increases above
20% in engine geometry/draw counters. Optional timing checks flag median/p95
increases above 25%; use them on the same device under comparable load. Counter
checks cannot detect every LOD/MultiMesh regression. Focused tests therefore also
assert crop instance/mesh limits, retained collision, water shader contracts,
interpolation resets, bounded remote extrapolation, adaptive limits and permanent
support wake conditions.

`benchmark_rendering.gd` also accepts `-- --ablation` for water/grass/shadow and
75% scaling comparisons, or `-- --diagnose` for script/sky isolation. The co-op
benchmark accepts `--guest` for the two-world guest stress case. Scripts write
JSON and PNG captures under `/tmp`. Retain useful results outside `/tmp` when
reviewing a feature. Run `python3 tools/check_architecture.py`,
`git diff --check` and `python3 tools/verify.py` separately for source and gameplay
validation. Headless success does not establish visual quality or locked FPS.
