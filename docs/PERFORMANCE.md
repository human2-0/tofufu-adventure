# M1 rendering budget

The local target is **120 FPS at 2560 × 1440 output**: each frame has 8.33 ms.
The default is native 3D resolution with a 120 FPS cap and VSync off. Settings
also offer 85% (2176 × 1224) and 75% (1920 × 1080) internal 3D resolution;
UI remains at output resolution. VSync can be enabled separately. The inspected
M1 Mac mini has 16 GB RAM and a 144 Hz 1440p display. A 120 FPS cap does not
change the display's refresh rate.

## Confirmed costs and changes

- In the original village, shadow passes submitted about 17.2 million triangles.
  Single-projection 32-metre shadows and small shared canopy/trunk shadow meshes
  retain detailed tree art while removing most of that shadow work.
- Original coastal water approximately doubled frame time in the ocean-channel
  ablation: 26.17 ms with water versus 12.71 ms hidden. That first sweep's window
  was constrained by macOS to 2560 × 1324. Runtime coastal water now uses authored
  vertex depth, analytic swells, foam and sky lighting, without framebuffer copies,
  depth probes or screen-space reflection tracing. The original MIT shader is
  retained for reference. Screen-space refraction/reflections are a visual tradeoff.
- Terrain visuals now use indexed 24-metre tiles. Off-camera terrain triangles
  can be culled; original collision meshes and authored vertex data remain intact.
- The weather sky computes detailed clouds once at quarter resolution and uses
  a simple gradient for the lighting cubemap. FXAA replaces desktop 4× MSAA.
- CPU instrumentation found approximately 0.85 ms per rendered frame spent on
  distant reef wildlife in the village. It now stops updating outside the region
  and samples the retained seabed grid while nearby. The water mesh reuses that
  grid at startup; co-op worlds share a bounded cache of immutable seeded map
  textures. Headless worlds skip rendering-only terrain tiling, which the focused
  geometry test exercises explicitly.
- Armored-snail movement remains a CPU cost. Lower-vertex convex envelopes retain
  the original dimensions, and unchanged shell offsets avoid redundant shape
  updates. Combat and movement still use the 60 Hz physics tick.

## Native 1440p measurements

Rendered locally on Apple M1, Godot 4.7.2, Metal / Forward Mobile, VSync off and
FPS uncapped. Each location warms for 90 frames, then samples 240 wall-clock
frame intervals. Daylight is fixed; the player and camera are stationary while
encounters and local ambience continue. Scene loading and screenshot readback
are outside the sampling window. GPU timestamp readback returned zero on this
Metal run, so GPU execution time cannot be claimed independently.

| Location | Median ms | 95th percentile ms | Median equivalent FPS |
| --- | ---: | ---: | ---: |
| Village | 5.45 | 9.62 | 183 |
| Dense grass | 8.14 | 12.05 | 123 |
| Northern reef | 7.07 | 11.08 | 141 |
| Waterfall | 7.33 | 11.48 | 136 |
| Volcanic channel | 6.02 | 10.12 | 166 |
| Castle entrance | 4.34 | 8.17 | 231 |
| Cloud Realm | 6.95 | 10.85 | 144 |

The earlier full-screen native village diagnostic measured 13.81 ms median and
19.51 ms at the 95th percentile. Village triangle submissions fell from about
17.18 million to 254,026. Reported video-memory allocation fell from roughly
956 MB to 810 MB. These are engine rendering counters, not total process RAM.
A local memory-pressure check reported 75% system-wide free memory during this
work; there was no observed memory-pressure emergency in that snapshot.

All sampled medians meet the 120 FPS budget, but **sustained locked 120 FPS is
not established**: most 95th-percentile frames still exceed 8.33 ms. Moving
cameras, combat, storms, shader warmup, long sessions and a populated co-op party
need separate performance validation. Optional 3D scaling offers GPU headroom;
it does not remove physics cost. Physics interpolation is not enabled by this
change, so the existing movement/camera presentation cadence also remains a
separate smoothness consideration.

## Repeat the benchmark

Architecture checks, `git diff --check`, and the complete `tools/verify.py`
suite passed with this implementation. Rendered 1440p checks covered the village,
waterfall, volcanic coastline and display/settings layout. Real moving gameplay,
cross-device performance and NAT behavior remain separate checks.

From the project root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/benchmark_rendering.gd
```

Use `-- --ablation` to hide coastal water, grass and shadows separately and
measure 75% 3D scaling. `-- --diagnose` compares scripts and simple sky rendering.
Do not run headless or alongside the verification suite when comparing timings.
The script writes `/tmp/tofufu-benchmark.json` and rendered location captures.
Run `python3 tools/verify.py` separately for automated gameplay validation.

The rendering choices follow Godot's [GPU optimization guidance](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
and [viewport scaling documentation](https://docs.godotengine.org/en/stable/classes/class_viewport.html).
The engine counter distinction is documented in [RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html).
