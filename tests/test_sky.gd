extends SceneTree

func _initialize() -> void:
	var first := SkyEffects.new()
	var second := SkyEffects.new()
	root.add_child(first)
	root.add_child(second)
	var environment := Environment.new()
	first.setup(environment)
	second.setup(Environment.new())
	assert(first.material != second.material, "Each world owns its atmosphere")
	assert(environment.fog_sky_affect < 0.2, "Distance fog must not hide the sky")
	assert(first.present(20.0, 0.5, 1.0, 0.72) == 0.0, "Overcast never creates lightning")
	first._next_strike = 0.0
	assert(first.present(0.0, 0.5, 1.0, 1.0) > 0.0, "Rain storms create a flash")
	assert(first._thunder_delay > 1.0, "Thunder follows distant lightning")
	assert(first.present(0.3, 0.5, 1.0, 1.0) == 0.0, "Flash fades quickly")
	assert(second._thunder_delay < 0.0, "Other worlds do not inherit thunder")
	assert(first._audio.stream.get_length() == 3.0, "Thunder stream is bounded")
	first.free()
	second.free()
	print("Sky isolation, storm threshold, flash decay and thunder: PASS")
	quit()
