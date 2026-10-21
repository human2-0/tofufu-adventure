# Gigalopolis coastal city materials

Generated 2026-10-19 with the built-in ImageGen tool. Original output is preserved
as `city-materials-source.png`; its four equal quadrants are extracted and resized
to 512 px as `limestone.png`, `teal-metal.png`, `paving.png`, and `canvas.png`.
No external artwork or licensed texture pack is used.

Materials use world triplanar mapping at consistent metre scales. Cream limestone,
oxidized teal metal and ochre canvas are shared by the legacy district, factory
exterior, southern wards, stair terraces, rooftop camps and coastal watch posts.
Paving also supplies fine ground grain. Static ornaments are spatially batched;
their physical bodies remain intact.

Godot-rendered references are saved in `previews/city-overview.png` and
`previews/rooftop-camp.png`. Reproduce the camera views with
`tests/preview_gigalopolis.gd`. Material imports retain mipmaps and anisotropic
filtering for readable streets and roofs at a distance.

The eastward expansion uses companion roof, glass, artisan brick and stone
frieze textures documented with their exact prompt in `east/SOURCE.md`.
Its rendered references are `previews/east-overview.png`,
`previews/east-market.png`, `previews/east-hall.png` and
`previews/east-clocktower.png`. The same preview script reproduces all views.

## Exact generation prompt

Use case: stylized-concept
Asset type: production game material texture atlas for Tofufu Adventure's Gigalopolis coastal industrial city.
Primary request: Create one square 2048x2048 texture sheet with EXACTLY four equal square quadrants arranged 2x2, edge to edge, NO gutters or borders. Each quadrant is a seamless tileable flat orthographic material, evenly lit with no perspective and no baked directional shadows.
Top-left: pale warm cream limestone brick masonry, large squared blocks, restrained chips and warm grey mortar.
Top-right: muted oxidized deep teal painted industrial sheet metal, subtle panels, sparse brass rivets, hand-painted scuffs, no rust orange dominance.
Bottom-left: warm sandy grey small rectangular cobblestone pavement, worn smooth edges, orderly offset rows, subtle grains.
Bottom-right: ochre tan tightly woven canvas fabric, delicate seams and weathering, suitable for small scout tents and market awnings.
Style/medium: high quality hand-painted textured cozy manga 2.5D adventure game, simple robust readable surfaces, soft restrained grain, not photorealistic, not pixel art.
Color palette: coordinated ivory cream, desaturated teal, sandstone, ochre and subtle brass.
Constraints: precisely four equally sized seamless material tiles; no objects, buildings, writing, labels, icons, watermarks, lighting gradients, framing, or cast shadows. Each tile fills its full quadrant.
