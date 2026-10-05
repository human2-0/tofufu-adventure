# Village Fufu sprites

Generated with the built-in imagegen tool on 2026-10-03, using the existing
`assets/characters/fufu/soybean_fufu-idle-eight.png` as a species/style reference.
Original generated PNGs are preserved here with transparent backgrounds.
Grandma wears Polish folk clothing; Grandpa wears countryside work clothes.
Original single-pose art is retained as the identity reference.

On 2026-10-05 the built-in imagegen tool generated `grandma-directions.png` and
`grandpa-directions.png` from those references. Each original RGBA atlas contains
five full-body standing views: N, NE, E, SE and S. `MeadowResidentArt` measures
individual silhouettes, selects a camera-relative view and mirrors western views.
Residents turn toward the local player within four metres; their authored facing
remains the fallback when the player is farther away. This is local presentation.
The generated SE portraits face left, so presentation mirrors that cell to keep
its screen direction consistent. These are directional idle views, not walking
animation sheets. Source PNGs are preserved without pixel edits.

Prompt set: preserve the referenced Fufu identity, sprout, clothes, accessories,
illustrated 2D style and transparent background; generate one horizontal strip
of five complete neutral standing views, ordered N/back, NE/rear three-quarter,
E/profile, SE/front three-quarter, S/front, with matching scale and foot baseline,
no text, borders, scenery or shadows. Grandma retains Polish floral headscarf,
glasses, embroidered blouse/apron, vest and Łowicz skirt. Grandpa retains flat
cap, moustache, embroidered shirt, overalls, boots, tool pouch and spanner.
