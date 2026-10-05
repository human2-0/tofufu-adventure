class_name DungeonEncounterPresentation
extends RefCounted
## Exhausted rematches are visibly identified without altering enemy behavior.

static func practice(enemy: FactoryBean) -> void:
	var label := Label3D.new()
	label.text = "Practice encounter — reward already claimed."
	label.font_size = 19
	label.pixel_size = 0.007
	label.position.y = 2.3
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	enemy.add_child(label)
