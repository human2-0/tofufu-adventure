# Royale supply chests

`painted_wood.png` was generated with the built-in imagegen tool on 2026-10-23.
Source: `exec-5d0c9226-554e-4ce8-991b-b23ad269a0c2.png` in the Codex generated image library.

Prompt: "Use case: stylized-concept. Asset type: seamless 3D prop material texture for Tofufu Adventure, a cozy cel-shaded chibi fantasy game. Generate a square seamless tileable hand-painted warm walnut wooden plank surface used on basic, rare and legendary treasure chests. Broad horizontal honey-brown planks with subtle grain, soft painted wear, a few small knots, gently shaded grooves. Front-on orthographic flat albedo texture, entire canvas filled, no perspective, no treasure chest object, no metal, no trim, no text, no lighting gradients or cast shadows, no border. Readable at a small size, stylized rather than photoreal, not noisy. Applied directly to three chest variants with colored metal bands and separate modeled crests."

`BattleChestModel` applies the image with triplanar mapping at 0.7 repeats/metre.
Basic: walnut, bronze straps, flat lid. Rare: blue wood, silver-blue corner braces,
raised lid and diamond seal. Legendary: plum wood, gold bindings, crown and wings.
The retained source imports at a maximum 1024 pixels with mipmaps for distant sampling.
All variants share collision and reach. Meshes cull at 65 metres, labels at 16.
Closed chests have no per-frame animation, particles or dynamic light.

Native inspection: English/Polish, 1280×720 and 640×360 chest renders are retained
in .codex/visualizations/2026/10/23/royale-loot/chests-*.png. The applied wood grain,
face seams, shared scale and distinct lids/crests were inspected in Metal renders.
