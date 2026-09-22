class_name WorldItemVisuals
extends RefCounted
## Dropped weapons use compact, centered versions of their existing artwork.

static func build(drop: WorldItemDrop) -> void:
	if drop.item_id == "knife":
		var sprite := Sprite3D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = SwordVisual.ATLAS
		atlas.region = Rect2(0, 0, 460, 420)
		sprite.texture = atlas
		sprite.pixel_size = 0.0015
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(sprite)
	elif drop.item_id == "soy_gun":
		var sprite := Sprite3D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = SoyGunVisual.ABOVE
		atlas.region = SoyGunVisual.TOP_REGIONS[2]
		sprite.texture = atlas
		sprite.pixel_size = 0.0016
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(sprite)
	elif drop.item_id == "sotjet":
		var sprite := SotjetVisual.new()
		drop.add_child(sprite)
		sprite.set_process(false)
		sprite.visible = true
		sprite.frame = 2
		sprite.pixel_size = 0.0015
	else:
		var sprite := Sprite3D.new()
		sprite.texture = InventoryItem.create_soybean().icon
		sprite.pixel_size = 0.006
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(sprite)
