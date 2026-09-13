# Jump, falling and landing frames

The ten 1254 × 1254 RGBA PNGs are copied unchanged from the user-supplied `soybean_jump_sprite_frames.zip`. All depict a frontal pose; no other directions are claimed or generated.

`FufuJumpAnimation` uses takeoff/push-off/ascent while rising, apex near zero vertical speed, fall-start/mid-fall while descending, pre-landing near the ground, then impact/rebound/settled on contact. Long falls hold their falling pose; landing never plays on a timer while airborne. Directional idle/walk resumes after recovery.

Pixel size is 0.0012, with authored frame-center, foot-baseline and hand-grip landmarks. The original image pixels remain intact, including motion marks. The held knife follows the frontal hand and draws over the body.

Grounded charging now uses the separate directional charge-walk sheet through `FufuChargeAnimation`, with existing rear-diagonal art as a fallback. See [charge-walk source](../CHARGE_SOURCE.md).
