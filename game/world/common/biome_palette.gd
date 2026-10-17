class_name BiomePalette
extends RefCounted
## Broad noisy ecotones shared by terrain vertices and the cartographic image.

static func color_at(at: Vector2, height: float, noise_seed: int) -> Color:
	var drift := WorldContours.noise(at / 29.0, noise_seed + 123) * 11.0
	var detail := WorldContours.noise(at / 8.0, noise_seed + 391)
	var grass := Color("88a878").lerp(Color("b1bd83"), clampf(height * 0.07 + detail * 0.06, 0, 0.6))
	var sand := Color("d7b77e").lerp(Color("f0d39a"), (detail + 1.0) * 0.35)
	var jungle := Color("447353").lerp(Color("6a944f"), (detail + 1.0) * 0.28)
	var snow := Color("badce3").lerp(Color("edf5ed"), (detail + 1.0) * 0.35)
	var color := grass.lerp(sand, smoothstep(52.0, 124.0, at.y + drift))
	color = color.lerp(jungle, smoothstep(180.0, 258.0, at.y + drift))
	color = color.lerp(sand, smoothstep(76.0, 104.0, -at.y + drift))
	color = color.lerp(snow, smoothstep(200.0, 272.0, -at.y + drift))
	if at.y < -112 and at.y > -209 and height > 2.5:
		color = color.lerp(jungle.lightened(0.1), smoothstep(2.8, 4.6, height))
	return color
