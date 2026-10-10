# Tofufu frontend art and theme

`tofufu-world.png` is original anime/manga world key art generated with the built-in imagegen tool on 2026-10-06. The source character sheet `assets/characters/fufu/soybean_fufu-idle-eight.png` was used as an identity reference. The full production prompt is in [generation-prompt.txt](generation-prompt.txt). The original output is retained in Codex generated images; the runtime asset is copied here so exports are self-contained.

The image contains no UI text. Landing and loading controls, labels and progress are native Godot controls. `tofufu_theme.tres` is the project default Theme: dark green ink, cream text/frames, mint hover, gold focus and progress. Compact feature styles preserve readable resource colours and inventory icons.

Render the interface with `tests/preview_frontend.gd` and `tests/preview_menu.gd`. Loading progress reports real resource progress followed by named construction/restoration milestones. Godot scene construction still occurs on the main thread.

The `icons/` SVGs are original, code-authored menu symbols. Their white source strokes are tinted with the same ink/cream palette by native controls. Co-op discovers peers on entry, remembers the local nickname, and uses a bounded activity pulse during discovery and joining; it shows no invented connection percentage.
