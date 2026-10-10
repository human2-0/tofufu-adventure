class_name CloudCourt
extends Node3D
## Shared court placement; the Goddess, residents and twelve angels use local sprite views.

var residents: Array[CloudResident] = []
var angels: Array[CloudResident] = []
var merchant: CloudResident
var goddess: CloudResident
var elapsed: float = 0.0

func _ready() -> void:
	name = "RoyalCourt"
	goddess = _resident(Vector2(-3, 271), "goddess", "Tofufu Goddess · Lady of the Clouds", "Welcome to our sky kingdom.\nThe little angels bring joy to our gardens.", "goddess", 3.0)
	for at in [Vector2(-14, 255), Vector2(-2, 255), Vector2(11, 274), Vector2(-27, 277), Vector2(-3, 315), Vector2(12, 315)]:
		_resident(at, "guardian", "Tofufu Cloud Guardian", "We keep watch over Godfufu's kingdom.\nFollow the golden lamps to the royal court.")
	merchant = _resident(Vector2(43, 287), "merchant", "Nimbus · Royal Outfitter", "Equipment for the king's travellers.\nCome closer to browse the gear shop.", "nimbus", 2.3)
	_resident(Vector2(-54, 296), "gardener", "Petal · Cloud Gardener", "I tend the king's blossom garden.\nOur little angels love these flowers.", "petal", 2.2)
	_resident(Vector2(34, 301), "steward", "Mallow · Royal Steward", "A warm cup after your flight?\nThe court is just across the cloud bridge.", "mallow", 2.2)
	_resident(Vector2(-4, 329), "steward", "Lumen · Shrine Keeper", "Listen to the breeze among the bells.\nMay your journey be gentle.", "lumen", 2.3)
	_resident(Vector2(-43, 335), "gardener", "Pearl · Halo Tender", "Every halo needs a little polish.\nThe angels bring us morning light.", "pearl", 2.2)
	for i in 12:
		var angel := CloudResident.new()
		angel.role = "angel"
		angel.phase = i * 2.4
		angel.scale = Vector3.ONE * (0.32 + i % 3 * 0.035)
		add_child(angel)
		angels.append(angel)
	_update_angels()

func _resident(at: Vector2, role: String, title: String, greeting: String, art_key: String = "guardian", height: float = 2.6) -> CloudResident:
	var resident := CloudResident.new()
	resident.name = title.replace(" · ", "")
	resident.title = title
	resident.role = role
	resident.art_key = art_key
	resident.art_height = height * 0.85
	resident.greeting_text = greeting
	resident.phase = residents.size() * 1.4
	resident.position = CloudTerrain.point(at.x, at.y)
	add_child(resident)
	residents.append(resident)
	return resident

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_squared_to(CloudTerrain.point(-8, 290)) > 24000: return
	elapsed += delta
	_update_angels()

func _update_angels() -> void:
	for i in angels.size():
		var island: Vector3 = CloudTerrain.ISLANDS[i % CloudTerrain.ISLANDS.size()]
		var center := CloudTerrain.CENTER + Vector2(island.x, island.y)
		var angle := elapsed * (0.18 + i % 3 * 0.025) + i * 2.4
		var at := center + Vector2(cos(angle), sin(angle)) * (island.z * 0.55)
		angels[i].position = CloudTerrain.point(at.x, at.y, 3.0 + i % 3 * 0.6)
		angels[i].rotation.y = -angle
