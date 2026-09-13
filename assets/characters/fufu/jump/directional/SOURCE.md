# Directional jump atlas

Created with the built-in image generation tool using the existing eight-direction Fufu idle sheet and original front-facing apex/impact sprites as identity and pose references. Two requests total: one 40-pose atlas generation and one background-extraction attempt. No additional requests for right-facing views.

The tool returned 1983×793 RGB artwork with a baked checkerboard, including after cleanup. The selected output is retained unchanged as `atlas.png`. `game/player/jump_atlas.gdshader` removes its neutral matte when rendered; the PNG itself is not transparent. Tight atlas regions follow actual sprite bounds rather than assuming equal grid cells. `DirectionalJumpArt` aligns feet, calibrates scale and hands, and mirrors E/SE/NE at runtime. The original ten front-facing jump images remain in use for S. Rows contain SW, W, NW and N. Each row covers takeoff, push-off, ascent, apex, fall start, mid-fall, pre-landing, impact, rebound and settled phases.

## Generation prompt

Use case: stylized-concept. Create ONE transparent production sprite atlas for the existing Fufu soybean game character. Reference image 1 is the exact character identity and directional silhouette reference; images 2 and 3 are apex/landing pose references. Preserve the pale creamy-yellow plump bean body, tiny yellow speckles, extremely dark green bold smooth outlines, green two-leaf sprout, tiny arms and oval feet; cute clean 2D shaded illustration, not 3D. No weapons, accessories, shadows, labels, typography, grid lines, ground or background.
Output a wide 3200x1280 PNG with true transparent alpha: exactly 10 equal columns and 4 equal rows, 40 separate full-body sprites. Every sprite centered horizontally within its equal cell, generous transparent gutter, no clipping. Feet bottoms consistently at 88% of each cell height, including airborne poses (the engine moves the sprite). Sprout and hands fully within cell. Consistent natural body size: standing/apex height about 78% cell height; squash genuinely shorter/wider, stretch taller/narrower. Exactly one character per cell.
ROW 1: three-quarter front LEFT view (SW), eyes visible, looks left/down toward viewer.
ROW 2: pure LEFT profile (W), only near eye visible, looks left.
ROW 3: three-quarter BACK LEFT (NW), facing left/away, no eyes or mouth visible.
ROW 4: straight BACK (N), symmetric back, no face/eyes/mouth.
Every row has this same 10-column jump animation sequence:
1 crouched takeoff, knees bent and arms ready;
2 strong upward push-off, elongated torso feet pushing down arms beginning to rise;
3 rising, legs tucked and arms lifted;
4 joyous floating apex, arms spread upward/out, feet tucked;
5 begins descent, arms slightly out and feet lower;
6 fast fall, body vertically stretched, hands alongside body, feet downward;
7 pre-landing, feet forward/down with arms bracing;
8 landing impact, body very short and wide squash, low arms, flat splayed feet;
9 small recovery bounce, medium height with bent knees;
10 settled standing, neutral proportions and arms bent beside torso.
Match the reference artwork closely. The four rows must be clearly distinct viewing angles with correct anatomical silhouettes. Back-facing rows must have NO face. This single atlas will be mirrored horizontally at runtime to supply right-facing directions. Do not generate any right-facing or front-only row.

## Cleanup prompt

Use case: background-extraction. Edit ONLY the background of this existing sprite atlas. Remove the ENTIRE baked-in grey checkerboard and replace it with ACTUAL TRANSPARENT ALPHA, not a drawn checkerboard pattern. Preserve exactly all 40 character drawings, all colors, outlines, poses, spacing, the 10-column 4-row layout, dimensions and edges. Do not redraw, recolor, resize, rearrange, add or remove any part of any character. No shadows, grid, text or matte. Output an RGBA transparent PNG. Pixels outside every character must have alpha 0.
