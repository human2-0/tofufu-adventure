# Sotjet weapon art

`source/sotjet-atlas.png` is a new generated weapon atlas, made with the built-in image generator. The existing `../soy_gun/source/gun_back.png` was supplied as a style reference; it is unchanged.

The atlas has five columns (rear, rear-left, left, front-left, front) and two rows (above, near eye level). The other three directions are mirrored in `SotjetVisual`. The design uses an ivory body, mint trim, brass nozzle, soymilk reservoir and hose.

Generation requested ten isolated, equally spaced views of one consistent weapon, dark ink outlines and no labels. A second image-generation edit replaced the generated checkerboard with saturated magenta while preserving the weapons. The source is retained unchanged. `sotjet_visual.gdshader` removes the magenta at runtime, including inside the hose, while preserving the milk and ivory highlights. Hand and nozzle landmarks are calibrated per view in `SotjetVisual`.

The visible milk stream and impact droplets are procedural 3D ribbons driven by emitted ballistic parcels, not a painted straight beam. Their rendering does not decide collisions or damage.
