class_name FufuRightHand
extends RefCounted
## Anatomical right wrist landmarks in source pixels, BEFORE Sprite3D mirroring.
## A mirrored pose needs the opposite source arm; mirroring one wrist swaps hands.

const IDLE: Array[Vector2] = [Vector2(321,305), Vector2(174,305), Vector2(186,301), Vector2(138,297), Vector2(117,309), Vector2(350,292), Vector2(363,286), Vector2(116,292)]
const WALK: Array[Vector2] = [Vector2(112,212), Vector2(112,208), Vector2(112,208), Vector2(110,210), Vector2(218,205), Vector2(217,203), Vector2(212,204), Vector2(214,199), Vector2(120,205), Vector2(123,204), Vector2(119,204), Vector2(119,206)]
const DIAGONAL: Array[Vector2] = [Vector2(120,226), Vector2(121,222), Vector2(119,225), Vector2(118,224), Vector2(100,218), Vector2(99,219), Vector2(100,219), Vector2(102,219), Vector2(235,184), Vector2(232,183), Vector2(234,186), Vector2(230,184), Vector2(219,180), Vector2(219,177), Vector2(220,180), Vector2(218,178)]

static func point(sprite: FufuVisuals) -> Vector2:
	if not sprite.worn_set.is_empty():
		return sprite.worn_appearance.hand_point(sprite, sprite.anim_timer > 0.0, sprite._using_jump_frame, sprite.jump_animation.frame, int(sprite.current_facing))
	if sprite._using_charge_frame:
		return sprite.charge_animation.hand
	if sprite._using_jump_frame:
		return sprite.jump_animation.hand
	if sprite.texture == sprite.idle_texture:
		return IDLE[int(sprite.current_facing)]
	return DIAGONAL[sprite.frame] if sprite.texture == sprite.diagonal_texture else WALK[sprite.frame]

static func tint(set_id: String) -> Color:
	return Color("fff0bd") if set_id.is_empty() else (Color("91bf38") if set_id == "bright_leaf" else Color("42604b"))
