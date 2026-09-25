class_name InventoryItem
extends Resource
## Authored definition for inventory and equipment items.

static var _jet_icon: Texture2D

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var max_stack: int = 100
@export var category: String = "general"
@export var storage_slots: int = 0
@export var healing_amount: float = 25.0
@export var heal_duration: float = 2.5
@export var cooldown: float = 2.0
@export var weapon_level: int = 0
@export var weapon_power: int = 0
@export var required_level: int = 1
@export var damage_reduction: float = 0.0

static func create_edamame() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "edamame"
	item.name = "Edamame"
	item.description = "Fresh soybean currency gathered from plants and enemies. Refine 100 into 1 Mature Bean."
	item.icon = CurrencyVisuals.icon(item.id, 1)
	item.max_stack = 100
	item.category = "currency"
	item.healing_amount = 0.0
	return item

static func shell_piece() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "piece_of_shell"
	item.name = "Piece of Shell"
	item.description = "A sturdy fragment from a defeated shell-bearing creature."
	item.icon = preload("res://game/inventory/icons/combat.svg")
	item.max_stack = 50
	item.category = "material"
	item.healing_amount = 0.0
	return item

static func soy_milk() -> InventoryItem:
	var item := InventoryItem.new()
	item.id = "soy_milk"
	item.name = "Soy Milk"
	item.description = "A support drink that restores 50 health over 2.5 seconds."
	item.icon = preload("res://assets/factory/soy_milk.svg")
	item.max_stack = 10
	item.category = "support"
	item.healing_amount = 50.0
	item.heal_duration = 2.5
	item.cooldown = 2.0
	return item

static func currency(id: String) -> InventoryItem:
	if id == "edamame": return create_edamame()
	if id not in ["mature_bean", "tofu_white_chunk", "toasted_tofu_chunk", "golden_tofu_chunk"]: return null
	var item := InventoryItem.new()
	item.id = id
	item.name = {"mature_bean": "Mature Bean", "tofu_white_chunk": "White Tofu Chunk", "toasted_tofu_chunk": "Toasted Tofu Chunk", "golden_tofu_chunk": "Golden Tofu Chunk"}[id]
	item.description = {
		"mature_bean": "Shop currency. Each Mature Bean can be refined into 1 White Tofu Chunk.",
		"tofu_white_chunk": "Refine 100 White Tofu Chunks into 1 Toasted Tofu Chunk.",
		"toasted_tofu_chunk": "Refine 100 Toasted Tofu Chunks into 1 Golden Tofu Chunk.",
		"golden_tofu_chunk": "The highest-value tofu currency. It cannot be refined further.",
	}[id]
	item.icon = CurrencyVisuals.icon(id, 1)
	item.max_stack = 100
	item.category = "currency"
	item.healing_amount = 0.0
	return item

static func weapon(id: String) -> InventoryItem:
	if id not in ["knife", "soy_gun", "sotjet", "sproutwood_staff"]: return null
	var item := InventoryItem.new()
	item.id = id
	item.name = {"knife": "Knife", "soy_gun": "Soybean gun", "sotjet": "Soyjet", "sproutwood_staff": "Sproutwood Staff"}[id]
	item.description = {
		"knife": "A close-range blade for quick strikes and guarding.",
		"soy_gun": "A ranged weapon that fires soybeans.",
		"sotjet": "A ranged sprayer that uses a limited milk reserve.",
		"sproutwood_staff": "A melee staff with a broad secondary sweep.",
	}[id]
	item.category = "combat"
	item.max_stack = 1
	item.healing_amount = 0
	if id == "knife":
		item.weapon_level = 2
		item.weapon_power = 10
	elif id == "sproutwood_staff":
		item.weapon_level = 1
		item.weapon_power = 5
	if id == "sotjet": item.icon = _soyjet_icon()
	elif id == "sproutwood_staff": item.icon = preload("res://game/inventory/icons/sproutwood_staff.png")
	else:
		var atlas := AtlasTexture.new()
		atlas.atlas = preload("res://assets/weapons/sword/sword-eight-directions.png") if id == "knife" else preload("res://assets/weapons/soy_gun/source/gun_above.png")
		atlas.region = Rect2(0, 0, 460, 420) if id == "knife" else Rect2(534,348,380,370)
		item.icon = atlas
	return item

static func backpack(id: String) -> InventoryItem:
	if id not in ["factory_backpack", "seed_satchel", "traveler_backpack"]: return null
	var item := InventoryItem.new()
	item.id = id
	item.name = {"factory_backpack": "Factory Backpack", "seed_satchel": "Seed Satchel +4", "traveler_backpack": "Soypod Backpack"}[id]
	item.description = {
		"factory_backpack": "A standard backpack for carrying your items.",
		"seed_satchel": "Adds four storage slots to your backpack.",
		"traveler_backpack": "A roomy Soypod Backpack with twenty storage slots.",
	}[id]
	item.icon = preload("res://game/inventory/icons/soypod_backpack.png") if id == "traveler_backpack" else preload("res://game/inventory/icons/backpack.svg")
	item.category = "backpack"
	item.max_stack = 1
	item.storage_slots = {"factory_backpack": PlayerInventory.CAPACITY, "seed_satchel": PlayerInventory.CAPACITY + 4, "traveler_backpack": PlayerInventory.MAX_CAPACITY}[id]
	item.healing_amount = 0.0
	return item

static func apparel(id: String) -> InventoryItem:
	if not id.begins_with("bright_leaf_") and not id.begins_with("dark_leaf_"): return null
	var set_id := ApparelSetBonus.SOYPOD if id.begins_with("bright_leaf_") else ApparelSetBonus.NORI
	var set_name := ApparelSetBonus.name_for(set_id)
	var slot := id.trim_prefix("bright_leaf_").trim_prefix("dark_leaf_")
	if slot not in ["helmet", "armor", "legs", "boots"]: return null
	var item := InventoryItem.new()
	item.id = id
	item.name = "%s %s" % [set_name, slot.capitalize()]
	item.description = "Requires level 5. This piece reduces damage taken by 1%%. %s" % ApparelSetBonus.details(set_id)
	var set_folder := "res://assets/equipment/bright_leaf_set/" if id.begins_with("bright_leaf_") else "res://assets/equipment/dark_leaf_set/"
	item.icon = load(set_folder + slot + ".png") as Texture2D
	item.category = slot
	item.max_stack = 1
	item.healing_amount = 0.0
	item.required_level = 5
	item.damage_reduction = 0.01
	return item

static func from_id(id: String) -> InventoryItem:
	if id in ["edamame", "mature_bean", "tofu_white_chunk", "toasted_tofu_chunk", "golden_tofu_chunk"]: return currency(id)
	if id in ["knife", "soy_gun", "sotjet", "sproutwood_staff"]: return weapon(id)
	if id in ["factory_backpack", "seed_satchel", "traveler_backpack"]: return backpack(id)
	if id.begins_with("bright_leaf_") or id.begins_with("dark_leaf_"): return apparel(id)
	if id == "piece_of_shell": return shell_piece()
	if id == "soy_milk": return soy_milk()
	return null

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
