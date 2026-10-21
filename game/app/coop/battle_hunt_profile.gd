class_name BattleHuntProfile
extends Resource
## Match-only ranged roles; adventure enemy resources are never edited.
var damage: float = 18
var speed: float = 32
var windup: float = 0.55
var cooldown: float = 2.2
var reach: float = 108

static func make(kind: int) -> BattleHuntProfile:
	var profile := BattleHuntProfile.new()
	profile.damage = [18.0, 26.0, 16.0][kind]
	profile.speed = [32.0, 30.0, 38.0][kind]
	profile.windup = [0.55, 0.85, 0.45][kind]
	profile.cooldown = [2.2, 2.8, 1.6][kind]
	return profile
