class_name WeaponEnhancementConfirmation
extends ConfirmationDialog
## Confirms a specific chunk and weapon; a changed slot cancels the operation.

var window: InventoryWindow
var _source: int = -1
var _destination: String = ""
var _destination_id: Variant
var _chunk: ItemStack
var _weapon: ItemStack

func _ready() -> void:
	confirmed.connect(_approve)
	canceled.connect(clear)
	close_requested.connect(clear)
	get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_label().custom_minimum_size.x = 400
	_update_text()

func intercept(src: String, src_id: Variant, dst: String, dst_id: Variant) -> bool:
	if not InventoryTransfer.valid_slot(src, src_id) or not InventoryTransfer.valid_slot(dst, dst_id): return false
	var chunk := window.inventory.get_slot(int(src_id)) if src == "inventory" else null
	var weapon := _stack(dst, dst_id)
	if chunk == null or chunk.item.id != MagicalTofufu.ID or weapon == null or weapon.item.category != "combat": return false
	if weapon.enhanced:
		window._conversion_status.text = "Already enhanced · Once per weapon."
		return true
	_source = int(src_id)
	_destination = dst
	_destination_id = dst_id
	_chunk = chunk
	_weapon = weapon
	_update_text()
	popup_centered(Vector2i(520, 300))
	return true

func _stack(source: String, id: Variant) -> ItemStack:
	return window.inventory.get_slot(int(id)) if source == "inventory" else window.equipment.get_slot(str(id))

func _approve() -> void:
	if _chunk == null or window.inventory.get_slot(_source) != _chunk or _stack(_destination, _destination_id) != _weapon:
		window._conversion_status.text = "Items changed. Apply the chunk again."
		clear()
		return
	var source := _source
	var destination := _destination
	var id: Variant = _destination_id
	clear()
	window.commit_transfer("inventory", source, destination, id)

func clear() -> void:
	hide()
	_source = -1
	_destination = ""
	_chunk = null
	_weapon = null

func _update_text() -> void:
	title = tr("Enhance weapon?")
	get_ok_button().text = tr("Enhance permanently")
	cancel_button_text = tr("Cancel")
	if _weapon == null: return
	var bonus := tr(MagicalTofufu.bonus_text(_weapon.item.id))
	dialog_text = tr("Permanently enhance %s?\n\nConsumes 1 Magical Tofufu Chunk.\n%s\n\nThis weapon can only be enhanced once.") % [tr(_weapon.item.name), bonus]

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready(): _update_text()
