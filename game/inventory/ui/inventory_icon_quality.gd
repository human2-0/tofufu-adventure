class_name InventoryIconQuality
extends RefCounted
## Keep authored textures intact while making crisp, isolated UI thumbnails.

const THUMBNAIL_EDGE: int = 192

static func for_slot(source: Texture2D) -> Texture2D:
	if source == null: return null
	var pixels: Image
	if source is AtlasTexture:
		var atlas := source as AtlasTexture
		pixels = atlas.atlas.get_image()
		if pixels.is_compressed(): pixels.decompress()
		var region := Rect2i(atlas.region).intersection(Rect2i(Vector2i.ZERO, pixels.get_size()))
		if not region.has_area(): return source
		pixels = pixels.get_region(region)
	else:
		pixels = source.get_image()
		if pixels.is_compressed(): pixels.decompress()
	if pixels == null or pixels.is_empty(): return source
	var used := pixels.get_used_rect()
	if used.has_area():
		pixels = pixels.get_region(used.grow(2).intersection(Rect2i(Vector2i.ZERO, pixels.get_size())))
	var edge := maxi(pixels.get_width(), pixels.get_height())
	if edge > THUMBNAIL_EDGE:
		var scale := float(THUMBNAIL_EDGE) / float(edge)
		pixels.resize(maxi(1, int(round(pixels.get_width() * scale))), maxi(1, int(round(pixels.get_height() * scale))), Image.INTERPOLATE_LANCZOS)
	if pixels.get_format() != Image.FORMAT_RGBA8: pixels.convert(Image.FORMAT_RGBA8)
	var square_edge := maxi(pixels.get_width(), pixels.get_height())
	var square := Image.create(square_edge, square_edge, false, Image.FORMAT_RGBA8)
	square.fill(Color.TRANSPARENT)
	square.blit_rect(pixels, Rect2i(Vector2i.ZERO, pixels.get_size()), Vector2i((square_edge - pixels.get_width()) / 2, (square_edge - pixels.get_height()) / 2))
	if square_edge > 1: square.generate_mipmaps()
	return ImageTexture.create_from_image(square)
