# Eight-direction idle art

`soybean_fufu-idle-eight.png` is the user's supplied resting-pose sheet, copied unchanged as a 1774 × 887 RGBA atlas. It has four columns and two rows, intended as S, SW, W, NW / N, NE, E, SE. The supplied NE slot repeats a rear view; at the user's request, NE instead mirrors the NW cell at runtime, including its center offset and hand landmark. The original sheet is unchanged.

`FufuVisuals` uses these poses whenever Fufu is stationary, including aiming and charging. Walking still uses the separate cardinal/diagonal animation sheets. The idle sheet is displayed at 0.00284 world units per pixel, with source-pixel center/foot offsets for each frame to match the walking character's footprint and height. Original art remains preserved.

Hand landmarks in `FufuVisuals` follow each sheet's frame, mirror, offsets and animated scale. They are presentation data only, connected to the resting weapon by the app.
