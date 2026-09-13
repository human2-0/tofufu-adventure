# Grounded charge-walk sprites

`soybean_fufu-charge-walk-source.png` preserves the user's supplied 1536 × 1024 RGBA sheet, including its printed direction cues. `FufuChargeAnimation` defines 24 cropped AtlasTexture regions, each with three pixels of edge padding; no label appears in a runtime frame and the source pixels are unchanged.

Rows are interpreted from the visible pose rather than the printed labels:

- Printed NW: face-visible south-west; mirror for south-east.
- Printed N: face-visible south.
- Printed W: west; mirror for east.
- Printed S: back-facing north.

There is no rear-diagonal row. Existing NW/NE idle and walking frames remain in use with the charge crouch for those directions. The new rows play all six frames while grounded movement actually occurs; stopped or blocked movement uses frame zero and follows aim. Focused attack aiming retains precedence over travel, as in normal walking.

The sprite uses 0.005 world units per source pixel, a shared foot baseline and per-row hand landmarks relative to each cropped frame. The held knife follows the hand, including mirroring; visible front/side hands draw the knife over the body, while the rear view hides overlap. Releasing the charged jump resumes the existing airborne and landing animation. Physics and charge timing are unchanged.
