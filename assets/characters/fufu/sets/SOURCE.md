# Leaf set character art

The walking and standing sheets were supplied in `Tofufu_Standing_Pose_Sheets.zip`. The jump sheets were supplied in `Jumping_Sprites.zip` and copied unchanged:

- `green_leaf_knight_jump_sprite_sheet.png` is used with the Bright Leaf set.
- `dark_sprout_soldier_jump_sprite_sheet.png` is used with the Dark Leaf set.

Both jump sheets are 1254 × 1254 transparent PNGs containing five facing columns and five animation rows. The painted poses have uneven spacing, so runtime crops each full pose from its authored bounds. Columns are Back, Back 3/4, Side, Front 3/4 and Front; rows are anticipation, takeoff, rising, peak and landing/recovery. The existing ten jump phases reuse these authored stages while preserving the game’s jump timing and movement.

Each walking sheet is 1122 × 1402 pixels, arranged as four animation phases across five facing rows. The rows follow the standing sheet’s Back, Back 3/4, Side, Front 3/4 and Front order. The painted rows have uneven spacing, so runtime crops each complete pose from its authored position instead of dividing the image into equal rows. The cropped poses use a shared scale and calibrated foot offsets.
