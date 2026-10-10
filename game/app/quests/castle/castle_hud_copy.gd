class_name CastleHudCopy
extends RefCounted
## Short contextual instructions; the full puzzle inscription remains in the room.

const CLUES: Array[String] = ["Ash + Crown lit · Tide dark", "Ash → Tide → Crown → Spark", "Tide = 2×Ash · Crown = Ash+Tide · Sum 6"]

static func text(flow: CastleAdventure, deck: int, focused: bool) -> String:
	var king := flow.encounter.king
	var result := ""
	if king.active:
		result = LavaKingFighter.SKILL_NAMES[king.skill] if king.cast > 0 or king.burst > 0 else "Recovery · strike now"
	elif flow.notice_time > 0:
		result = flow.state.message
	elif focused and flow.game.world_items.focused_plot >= 13:
		result = "Golden Tofu ×3 · each adventurer can claim this treasure once"
	elif focused and deck < 3:
		result = CLUES[deck]
		if deck == 1: result += " · %d/4" % flow.state.sequence_step
	elif deck == 3:
		result = flow.state.message if focused else "Speak to King Lava when ready"
	elif deck < 3:
		var kills := 0
		for i in 3:
			if flow.state.defeated_guards & (1 << (deck * 3 + i)): kills += 1
		result = "Ward %s · Guardians %d/3" % ["restored" if flow.state.solved[deck] else "sealed", kills]
	var burn: Array = flow.party.burns.get(flow.party.key(flow.game.player), [])
	if not burn.is_empty(): result += "\nBurning %.1fs · reach a spring" % burn[0]
	return result
