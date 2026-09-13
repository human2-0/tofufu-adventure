# Snail animation art

User-supplied `idle_snail.png`, `walking_snail.png`, and `attack_snail.png` are
preserved unchanged in `source/`. Each contains five poses in five labeled rows.
`tools/prepare_snail.py` extracts the character silhouettes, omits sheet labels,
and packs 256px cells with a shared foot baseline; it requires Pillow.

The source's “North” row shows the face, so it is used toward the camera (+Z).
Rows run front, front-right, right, back-right, back. Horizontal mirroring supplies
the left-facing angles. Original source labels and filenames are retained.
