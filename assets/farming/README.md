# Soybean crop art

`source/vegetation.png` and `source/pods.png` are unchanged user-supplied sheets. The pod sheet is sampled as four columns and three rows, ending with the harvested pod on the ground. The vegetation artwork has a shorter first row (400px), not equal-height cells.

`vegetation-keyed.png` was prepared with the built-in imagegen tool. Final prompt: “Create game-ready cutouts of these exact six soybean stages. Background MUST be flat solid magenta #FF00FF everywhere outside the soil and plants, including spaces between stems/leaves. Remove ALL brown/green gradients and glow. Keep plants, soil and black outlines. Equal 3x2 grid 1536x1024, 512x512 cells. Fit each full plant inside its cell with bottom of soil at 490. No text. Solid magenta background essential for chroma key.”

The result preserved the original unequal row heights; runtime regions account for that. The crop shader removes the magenta matte without changing source files. A first transparency attempt retained the painted background and is not used. Vegetation phase changes and a subtle cosmetic scale animation precede timed pod atlas frames; the final frame presents harvesting.
