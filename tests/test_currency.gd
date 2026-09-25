extends SceneTree
## Currency rules: exact ratios, bounded stacks, and no loss/duplication on failed refine.

var failures := 0

func _init() -> void:
	_test_exact_upgrade()
	_test_selected_stack_and_full_bag()
	_test_terminal_tier()
	_test_shop_tender()
	_test_non_currency_restore_is_rejected()
	_test_stack_art_cap()
	_test_art_dividers()
	_test_restore_bounds()
	print("Currency tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	push_error("FAIL: " + message)

func _test_exact_upgrade() -> void:
	var inventory := PlayerInventory.new()
	inventory.add_item(InventoryItem.create_edamame(), 100)
	check(CurrencyExchange.convert(inventory, 0, "edamame").begins_with("Refining is illegal"), "refinement locked before dungeon completion")
	inventory.refining_unlocked = true
	check(CurrencyExchange.convert(inventory, 0, "press_edamame").begins_with("That currency"), "edamame cannot bypass mature beans")
	check(CurrencyExchange.convert(inventory, 0, "edamame").begins_with("Refined"), "100 edamame refines")
	check(inventory.count_item("edamame") == 0 and inventory.count_item("mature_bean") == 1, "refining conserves exact value")
	check(CurrencyExchange.convert(inventory, 0, "edamame").begins_with("Currency changed"), "spent stack cannot be refined twice")

func _test_selected_stack_and_full_bag() -> void:
	var inventory := PlayerInventory.new()
	inventory.refining_unlocked = true
	inventory.set_slot(0, ItemStack.new(InventoryItem.create_edamame(), 100))
	for slot in range(1, PlayerInventory.CAPACITY):
		inventory.set_slot(slot, ItemStack.new(InventoryItem.currency("mature_bean"), 100))
	check(CurrencyExchange.convert(inventory, 1, "edamame").begins_with("Currency changed"), "selected slot and expected tier must agree")
	check(CurrencyExchange.convert(inventory, 0, "edamame").begins_with("Refined"), "full bag can refine in place")
	var before := inventory.capture()
	check(not CurrencyExchange.convert(inventory, 0, "edamame").begins_with("Refined"), "replayed conversion cannot mint another output")
	check(inventory.capture() == before, "rejected replay changes neither source nor target")

func _test_terminal_tier() -> void:
	var inventory := PlayerInventory.new()
	inventory.refining_unlocked = true
	inventory.add_item(InventoryItem.currency("mature_bean"), 100)
	check(CurrencyExchange.convert(inventory, 0, "mature_bean").begins_with("Refined"), "mature beans refine to white tofu")
	check(inventory.count_item("tofu_white_chunk") == 100 and inventory.count_item("mature_bean") == 0, "100 mature beans yield 100 white tofu chunks")
	check(CurrencyExchange.convert(inventory, 0, "tofu_white_chunk").begins_with("Refined"), "white tofu refines to toasted tofu")
	check(inventory.count_item("toasted_tofu_chunk") == 1, "100 white tofu yields 1 toasted tofu")
	inventory.add_item(InventoryItem.currency("toasted_tofu_chunk"), 99)
	check(CurrencyExchange.convert(inventory, 0, "toasted_tofu_chunk").begins_with("Refined"), "toasted tofu refines to golden tofu")
	check(inventory.count_item("golden_tofu_chunk") == 1, "100 toasted tofu yields 1 golden tofu")
	check(CurrencyExchange.convert(inventory, 0, "golden_tofu_chunk").begins_with("That currency"), "golden tofu is terminal")
	var single := PlayerInventory.new()
	single.refining_unlocked = true
	single.add_item(InventoryItem.currency("mature_bean"), 1)
	check(CurrencyExchange.convert(single, 0, "mature_bean").begins_with("Refined") and single.count_item("tofu_white_chunk") == 1, "one mature bean yields one white tofu chunk")
	check(not CurrencyExchange.convert(single, 0, "tofu_white_chunk").begins_with("Refined"), "one white tofu cannot skip the 100-block cost")

func _test_shop_tender() -> void:
	var inventory := PlayerInventory.new()
	check(WeaponTrade.purchase(inventory, "knife").begins_with("Bought"), "shop gear is free for testing without Mature Beans")
	check(inventory.count_item("mature_bean") == 0 and inventory.count_item("knife") == 1, "free purchase grants one weapon without minting tender")
	inventory.add_item(InventoryItem.currency("mature_bean"), 1)
	check(WeaponTrade.purchase(inventory, "soy_gun").begins_with("Bought"), "shop accepts a purchase while carrying Mature Beans")
	check(inventory.count_item("mature_bean") == 1 and inventory.count_item("soy_gun") == 1, "free purchase leaves Mature Beans untouched")
	check(WeaponTrade.sell(inventory, 0, "knife").begins_with("Sold"), "shops sell combat equipment for mature beans")
	check(inventory.count_item("mature_bean") == 2 and inventory.count_item("knife") == 0 and inventory.count_item("soy_gun") == 1, "shop sale cannot duplicate the sold weapon")

func _test_stack_art_cap() -> void:
	check(CurrencyVisuals.icon("edamame", 5) == CurrencyVisuals.icon("edamame", 100), "5+ edamame uses fifth art frame")
	check(CurrencyVisuals.icon("toasted_tofu_chunk", 5) == CurrencyVisuals.icon("toasted_tofu_chunk", 100), "5+ toasted tofu uses fifth art frame")
	check(CurrencyVisuals.icon("golden_tofu_chunk", 5) == CurrencyVisuals.icon("golden_tofu_chunk", 100), "5+ golden tofu uses fifth art frame")
	var golden := CurrencyVisuals.icon("golden_tofu_chunk", 100) as AtlasTexture
	check(golden != null and golden.region.size.y < 600, "transparent golden art is cropped to fill a backpack tile")
	var thumbnail := InventoryIconQuality.for_slot(InventoryItem.backpack("traveler_backpack").icon)
	check(thumbnail.get_width() <= InventoryIconQuality.THUMBNAIL_EDGE and thumbnail.get_image().has_mipmaps(), "backpack UI art is high-quality downsampled with mipmaps")
	var staff_thumbnail := InventoryIconQuality.for_slot(InventoryItem.weapon("sproutwood_staff").icon)
	check(staff_thumbnail.get_width() > 0 and staff_thumbnail.get_height() > 0, "staff UI art remains visible after downsampling")
	if "--preview" in OS.get_cmdline_user_args(): staff_thumbnail.get_image().save_png("/tmp/tofufu-staff-thumbnail.png")

func _test_art_dividers() -> void:
	var art: Array = [
		[CurrencyVisuals.BEANS, CurrencyVisuals.BEAN_EDGES, ["edamame", "mature_bean"]],
		[CurrencyVisuals.WHITE, CurrencyVisuals.WHITE_EDGES, ["tofu_white_chunk"]],
		[CurrencyVisuals.TOASTED, CurrencyVisuals.TOASTED_EDGES, ["toasted_tofu_chunk"]],
		[CurrencyVisuals.GOLDEN, CurrencyVisuals.GOLDEN_EDGES, ["golden_tofu_chunk"]],
	]
	for entry in art:
		var sheet: Texture2D = entry[0]
		var edges: Array[int] = entry[1]
		var ids: Array = entry[2]
		var image := sheet.get_image()
		check(edges.size() == 6 and edges[0] == 0 and edges[5] == image.get_width(), "currency sheet has five valid crop regions")
		for divider in range(1, 5):
			var opaque := false
			for y in image.get_height():
				if image.get_pixel(edges[divider], y).a > 0.01:
					opaque = true
					break
			check(not opaque, "%s divider %d stays between drawings" % [ids[0], divider])
		for id in ids:
			for frame in range(1, 6):
				var icon := CurrencyVisuals.icon(id, frame) as AtlasTexture
				check(icon != null and icon.region.position.x >= edges[frame - 1] and icon.region.end.x <= edges[frame], "%s frame %d contains no neighbour" % [id, frame])

func _test_restore_bounds() -> void:
	var mature := ItemStack.restore({"id": "mature_bean", "count": 100})
	check(mature != null and mature.item.id == "mature_bean", "currency saves restore canonical tiers")
	check(ItemStack.restore({"id": "golden_tofu_chunk", "count": 101}) == null, "oversized currency saves are rejected")

func _test_non_currency_restore_is_rejected() -> void:
	check(ItemStack.restore({"id": "minted_currency", "count": 1}) == null, "unknown saved item IDs cannot mint a currency-like stack")
