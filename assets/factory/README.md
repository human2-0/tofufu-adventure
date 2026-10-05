# Factory art sources

`build_prop_scenes.py` is editable source geometry authored for Tofufu Adventure.
`build_surface_assets.py` supplies original editable SVG brush/grain paths at 1K
and six deterministic synthesized WAV machine sounds. Both preserve the source
recipe; no external texture or sound samples are used.
It generates the original Godot scenes in `game/world/factory/props/`; no external
models or texture libraries were used. Regenerate from the repository root with
`python3 assets/factory/build_prop_scenes.py`.

The scenes use metres, static collision proxies, separate `MovingParts`, and named
interaction/input/output/service sockets. Carryable quest props have their
collision layers disabled by the room presenter. Fufu's current capsule is 0.8 m
wide and 1.1 m tall; the preview includes the actual player scene for comparison.

The room presenter binds labels to the host's persisted chemical shelf order.
Bottle silhouette/cap variants do not identify the recipe solution. Visual batch
flow waits for a mature-bean assignment, then shows soaking, grinding, filtering
and a finite pulse travelling from the mill to the laboratory. The tank waits for
the pulse to arrive. Rejected slurry lowers and drains; clearing rejection raises
the replacement milk over two seconds from the upstream buffer. These effects do
not advance or score production.

Run `tests/test_factory_presentation.gd` with Godot headless for identity/ownership
presentation checks. Run `tests/preview_factory_production.gd` with a graphical
Godot process for overhead/first-person PNGs and a 32-frame render sample per view.
The Apple M1 / Metal / Godot 4.7.2 sample at 1280×720 observed 6.9–7.6 ms mean
render-loop intervals and 60–331 draw calls, with no combat or co-op simulation.
The textured/outlined/audio revision, with legacy overlays hidden, observed
6.9–7.6 ms render-loop intervals and 51–301 draw calls.
This does not establish complete-game frame cost; the process monitor refreshes
less frequently than the sampled loop and is printed separately.

Current machines are geometric Godot props with original vector brush, wood grain,
linen weave and surface-scuff texture treatment, soft colors and a shared thin ink
outline. They use synthesized positional motor, pressure, pour, flush, blade and
film sounds. Cosmetic blade and film cycles follow confirmed cut/seal snapshots.
These are authored programmatic assets; no claim is made that an external artist
has painted or approved final hero-machine art. Human aesthetic/audio review and
complete-game profiling remain unverified. All source scenes remain editable. 

Floor presentation uses one outline-free surface for each deck plus a disjoint
landing extension. Foundation, room-floor and landing collision solids stay
active but invisible. The ramp retains its existing collision and uses a material
without an expanded ink pass. Regression checks assert no coplanar visible floor
rectangles overlap. The native Metal camera sweep samples a fixed exposed floor
point over 24 moving camera positions; the corrected surface produced zero channel
variation. Machine and sack lettering now uses fixed planes separated from its
backing; chemical captions sit above caps rather than rotating into the bottle.
