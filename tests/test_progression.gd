extends SceneTree
## Curves, event gates, instance isolation, modifiers and bounded save/wire values.

var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var progress := CharacterProgress.new()
	var other := CharacterProgress.new()
	check(progress.level() == 1 and progress.skill("sword") == 1, "new characters start at one")
	check(progress.damage_multiplier("sword") == 1 and progress.walk_multiplier() == 1, "baseline gameplay preserved")
	for hit in 19: progress.weapon_hit("sword")
	check(progress.skill("sword") == 1, "rank requires its full practice cost")
	progress.weapon_hit("sword")
	check(progress.skill("sword") == 2 and progress.skill("fist") == 1, "twentieth hit ranks only the trained weapon")
	check(other.practice.sword == 0, "practice belongs to one character")
	progress.weapon_hit("magic")
	progress.weapon_hit("attack_speed")
	progress.award_experience(100)
	check(progress.level() == 2 and progress.experience == 100, "four slime kills reach character level two")
	check(progress.practice.magic == 0 and progress.practice.attack_speed == 0, "kills and weapon hits never train magic or speed")
	progress.mana_spent(19)
	progress.mana_spent(0)
	progress.mana_spent(-50)
	check(progress.practice.magic == 19 and progress.skill("magic") == 1, "only positive mana spent trains magic")
	progress.mana_spent(1)
	check(progress.skill("magic") == 2, "mana cost crosses magic threshold")
	for block in 20: progress.defended()
	check(progress.skill("defence") == 2 and progress.incoming_multiplier() < 1, "guards train useful defence")
	check(progress.damage_multiplier("sword") > progress.damage_multiplier("fist"), "weapon skill adds damage beyond character level")
	check(progress.walk_multiplier() > 1 and progress.attack_multiplier() > 1, "character level improves movement and attack rate")
	for level in range(2, 99):
		check(CharacterProgress.requirement(level) > CharacterProgress.requirement(level - 1), "skill curve grows at every rank")
		check(CharacterProgress.rank(CharacterProgress.threshold(level)) == level, "exact cumulative threshold ranks correctly")
		check(CharacterProgress.rank(CharacterProgress.threshold(level) - 1) == level - 1, "one point short never ranks early")
	progress.award_experience(100000000)
	progress.mana_spent(100000000)
	progress.speed_gear_trained(100000000)
	check(progress.level() == 99 and progress.skill("magic") == 99 and progress.skill("attack_speed") == 99, "large awards stop at 99")
	check(progress.walk_multiplier() <= 1.20 and progress.attack_multiplier() <= 1.50, "speed bonuses remain bounded")
	check(progress.incoming_multiplier() > 0.65 and progress.damage_multiplier("sword") < 3.5, "high ranks retain combat risk")
	var saved := progress.capture()
	other.restore(JSON.parse_string(JSON.stringify(saved)))
	check(other.capture() == saved, "all practice and EXP survive a JSON round trip")
	check(SaveStore.progression(saved) and ExplorationProtocol.progression(saved), "save and wire accept complete progression")
	for invalid: Variant in [-1, 1.5, INF, NAN, "20", 100000001]:
		var bad := saved.duplicate(true)
		bad.practice.sword = invalid
		check(not SaveStore.progression(bad) and not ExplorationProtocol.progression(bad), "both boundaries reject malformed counters")
	var missing := saved.duplicate(true)
	missing.practice.erase("magic")
	check(not SaveStore.progression(missing) and not ExplorationProtocol.progression(missing), "partial records cannot silently lose skills")
	other.restore({}, 100)
	check(other.level() == 2 and other.skill("magic") == 1, "legacy EXP migrates with fresh practice")
	var motor := PlayerMotor.new(PlayerTuning.new())
	motor.walk_multiplier = 1.196
	var command := PlayerCommand.new()
	command.move = Vector2.RIGHT
	var velocity := motor.step(command, Vector3.ZERO, true, 1)
	check(is_equal_approx(velocity.x, PlayerTuning.new().walk_speed * 1.196), "walk bonus is applied after input normalization")
	var melee := MeleeRules.new(CombatTuning.new())
	melee.cooldown = 0.6
	melee.step(false, 0.2, 1.5)
	check(is_equal_approx(melee.cooldown, 0.3), "attack rate accelerates cooldown without changing charge requirements")
	print("Progression: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
