class_name CurrencyVisuals
extends RefCounted
## Currency art is authored in one-to-five stacks; five represents every larger stack.

const BEANS: Texture2D = preload("res://assets/currency/source/edamame-mature-transparent.png")
const WHITE: Texture2D = preload("res://assets/currency/source/white-tofu-transparent.png")
const TOASTED: Texture2D = preload("res://assets/currency/source/toasted-tofu-transparent.png")
const GOLDEN: Texture2D = preload("res://assets/currency/source/golden-tofu-transparent.png")
# The supplied drawings are not laid out on an even five-column grid. Each
# divider sits in transparent space between complete stack illustrations.
const BEAN_EDGES: Array[int] = [0, 290, 598, 895, 1208, 1536]
const WHITE_EDGES: Array[int] = [0, 350, 780, 1230, 1695, 2172]
const TOASTED_EDGES: Array[int] = [0, 310, 700, 1100, 1500, 1916]
const GOLDEN_EDGES: Array[int] = [0, 300, 570, 915, 1260, 1672]
static var _icons: Dictionary = {}

static func icon(id: String, count: int) -> Texture2D:
	if id not in ["edamame", "mature_bean", "tofu_white_chunk", "toasted_tofu_chunk", "golden_tofu_chunk"]: return null
	var frame := clampi(count, 1, 5) - 1
	var key := "%s:%d" % [id, frame]
	if _icons.has(key): return _icons[key]
	var sheet: Texture2D = BEANS if id in ["edamame", "mature_bean"] else (WHITE if id == "tofu_white_chunk" else (TOASTED if id == "toasted_tofu_chunk" else GOLDEN))
	var edges: Array[int] = BEAN_EDGES if sheet == BEANS else (WHITE_EDGES if sheet == WHITE else (TOASTED_EDGES if sheet == TOASTED else GOLDEN_EDGES))
	var row := 1 if id == "mature_bean" else 0
	var height := int(sheet.get_height() / (2 if sheet == BEANS else 1))
	var cell := Rect2i(edges[frame], row * height, edges[frame + 1] - edges[frame], height)
	var image := sheet.get_image().get_region(cell)
	# Ignore imperceptible alpha fringe; otherwise several frames scale down to
	# tiny dots because their nominal bounds cover most of the source sheet.
	var used := _visible_rect(image, 0.01)
	if used.has_area(): used = used.grow(4).intersection(Rect2i(Vector2i.ZERO, cell.size))
	else: used = Rect2i(Vector2i.ZERO, cell.size)
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(cell.position + used.position, used.size)
	_icons[key] = atlas
	return atlas

static func _visible_rect(image: Image, alpha_limit: float) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= alpha_limit: continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	if right < left: return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)
