# Diagonal walking art

Runtime source: `soybean_fufu-diagonal.png`, the user's supplied original `diagonal movements.png`, copied without image edits. It is a 1254 × 1254 RGBA PNG (881,206 bytes), with four columns and four rows. It retains about six times the pixel count of the 512 × 512 WebP preview retrieved from the [shared image](https://chatgpt.com/s/m_6a9f41d67b208191ad08d0169fccf777).

Rows, top to bottom: southeast, southwest, northeast, northwest. Each row contains four walking frames. Because 1254 is not divisible by four, Godot's frame regions use a 313.5-pixel pitch. `FufuVisuals` calibrates the sixteen foot baselines in source pixels and uses a pixel size of `0.0112 × 512 / 1254` to match the original cardinal art. No resampling or background replacement was applied.

The WebP is retained as a source reference; runtime rendering uses the PNG. Cardinal walking uses the original walk image. All stationary directions now use the dedicated eight-pose idle sheet documented in `IDLE_SOURCE.md`.
