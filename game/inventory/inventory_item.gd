class_name InventoryItem
extends Resource
## Authored definition for inventory and equipment items.

static var _jet_icon: Texture2D

@export var id: String = ""
@export var name: String = ""
@export var icon: Texture2D
@export var max_stack: int = 100
@export var category: String = "general"
@export var healing_amount: float = 25.0
@export var heal_duration: float = 2.5
@export var cooldown: float = 2.0

static func create_soybean() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "soybean"
	item.name = "Soya Bean"
	item.icon = preload("res://assets/combat/soybean.svg")
	item.max_stack = 999
	item.category = "healing"
	item.healing_amount = 25.0
	item.heal_duration = 2.5
	item.cooldown = 2.0
	return item

static func create_rare_soybean() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "rare_soybean"
	item.name = "Rare Soybean"
	item.icon = preload("res://assets/combat/rare_soybean.svg")
	item.max_stack = 99
	item.category = "quest"
	item.healing_amount = 0.0
	return item

static func weapon(id: String) -> InventoryItem:
	if id not in ["knife", "soy_gun", "sotjet"]: return null
	var item := InventoryItem.new()
	item.id = id
	item.name = {"knife": "Knife", "soy_gun": "Soybean gun", "sotjet": "Soyjet"}[id]
	item.category = "combat"
	item.max_stack = 1
	item.healing_amount = 0
	if id == "sotjet": item.icon = _soyjet_icon()
	else:
		var atlas := AtlasTexture.new()
		atlas.atlas = preload("res://assets/weapons/sword/sword-eight-directions.png") if id == "knife" else preload("res://assets/weapons/soy_gun/source/gun_above.png")
		atlas.region = Rect2(0, 0, 460, 420) if id == "knife" else Rect2(534,348,380,370)
		item.icon = atlas
	return item

static func _soyjet_icon() -> Texture2D:
	if _jet_icon != null: return _jet_icon
	var image := preload("res://assets/weapons/sotjet/source/sotjet-atlas.png").get_image()
	if image.is_compressed(): image.decompress()
	image = image.get_region(Rect2i(793, 0, 397, 397))
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			pixel.a *= 1.0 - smoothstep(0.15, 0.35, minf(pixel.r, pixel.b) - pixel.g)
			image.set_pixel(x, y, pixel)
	_jet_icon = ImageTexture.create_from_image(image)
	return _jet_icon
