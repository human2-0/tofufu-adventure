class_name DofufuRules
extends RefCounted
## Per-boss committed attack clock. Windups stay readable during the second phase.

enum Skill { GLAIVE, FAN, DRAGON_STEP, SLAM }
const NAMES: Array[String] = ["JADE GLAIVE · guard or dodge", "RETURNING FAN · use cover", "DRAGON STEP · sidestep", "GONG SLAM · leave the ring or jump"]
const WINDUPS: Array[float] = [0.65, 0.95, 0.8, 1.15]
var skill: Skill = Skill.GLAIVE
var windup: float = 0.0
var recovery: float = 1.2
var sequence: int = 0
var enraged: bool = false

func begin(distance: float) -> void:
	var pattern: Array[Skill] = [Skill.FAN, Skill.DRAGON_STEP, Skill.SLAM, Skill.GLAIVE]
	skill = pattern[sequence % pattern.size()]
	if skill == Skill.GLAIVE and distance > 4.0: skill = Skill.DRAGON_STEP
	sequence += 1
	windup = WINDUPS[skill]

func step(delta: float) -> bool:
	if windup > 0.0:
		windup = maxf(0.0, windup - delta)
		if windup == 0.0:
			recovery = 0.85 if enraged else 1.35
			return true
	else:
		recovery = maxf(0.0, recovery - delta)
	return false
