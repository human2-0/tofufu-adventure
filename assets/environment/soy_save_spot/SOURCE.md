# Soybean save-spot materials

`surfaces.png` is original generated artwork made with the built-in ImageGen tool
on 2026-10-17. It is applied to the finished 3D model in
`game/world/common/soy_save_spot.tscn` through explicit quadrant UV transforms.
Top left: leaves/stem; top right: fresh pods; bottom left: stone plinth; bottom
right: seed/owned golden pods and halo. UVs stay inset from atlas boundaries.
The mesh geometry is authored in `soy_save_spot_geometry.gd`; every spot uses
independent materials so local ownership cannot alter another model.

Prompt:

> Use case: stylized-concept. Asset type: square material texture atlas for a real 3D soybean checkpoint plant in a cozy anime farm adventure game. Create a 1024x1024 texture atlas of four equally sized square swatches in a precise 2x2 layout, each touching the image edges, no borders or gaps. Top left: lush jade green soybean leaf surface with a softly painted central leaf vein and branching veins, subtle organic brushwork. Top right: pale fresh green edamame pod skin with fine fuzzy organic speckles and long soft ridges. Bottom left: warm grey mossy carved shrine stone with muted gold-green mineral streaks and subtle roughness. Bottom right: golden cream magical soybean seed surface with delicate amber mottling. Each quadrant is a continuous closeup material, fills all its square; no silhouettes, no objects, no perspective, no text, no shadows cast by objects, no labels. Gentle hand-painted albedo, matte, soft painterly texture, restrained organic detail that reads on small low-poly props, coordinated mint and jade with warm gold and stone. This is a UV material atlas, not a concept drawing.

Generated source: `/Users/mat-dwor/.codex/generated_images/01a14750-b99b-7652-918b-c61d5ba886bf/exec-c2c2ad76-b755-4e8e-b6e0-275da7667211.png`.
The original generated resolution is 1254 x 1254; retained unchanged.
