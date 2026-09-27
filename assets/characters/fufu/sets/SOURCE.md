# Soypod and Nori character art

The walking sheets come from `Tofufu_Equipment_Assets.zip` (`Character_References/*_leaf_character_reference.png`), the standing sheets from `Tofufu_Standing_Pose_Sheets.zip`, and the jump sheets from `Jumping_Sprites.zip`. The imported art is copied unchanged. The internal `bright_leaf` and `dark_leaf` IDs remain for saved items:

- `green_leaf_knight_jump_sprite_sheet.png` is used with Soypod.
- `dark_sprout_soldier_jump_sprite_sheet.png` is used with Nori.

`bright_leaf_standing.png` is the supplied green `chibi_leaf_knight_turnaround_sprite_sheet.png`; `dark_leaf_standing.png` contains the dark Nori turnaround. The original content of these two destination files was reversed before the direction correction. Source profile and three-quarter poses face left, so runtime mirrors them for screen-right facings. Each standing pose uses its painted boot baseline and horizontal center.

Both jump sheets are 1254 × 1254 transparent PNGs containing five facing columns and five animation rows. The painted poses have uneven spacing, so runtime crops each full pose from its authored bounds. Columns are Back, Back 3/4, Side, Front 3/4 and Front; rows are anticipation, takeoff, rising, peak and landing/recovery. The existing ten jump phases reuse these authored stages while preserving the game’s jump timing and movement.

Each walking sheet is 1122 × 1402 pixels, arranged as four animation phases across five facing rows. The rows follow the standing sheet’s Back, Back 3/4, Side, Front 3/4 and Front order. The painted rows have uneven spacing, so runtime crops each complete pose from its authored position instead of dividing the image into equal rows. The cropped poses use a shared scale and calibrated foot offsets.
