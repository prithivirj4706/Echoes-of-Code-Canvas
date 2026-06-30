## airborne_melee_test.gd — an AIRBORNE drone ignores melee but takes ranged.
##   godot --headless --path . --script res://tools/airborne_melee_test.gd
extends SceneTree

var _level: Node


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _process(_delta: float) -> bool:
	var drone := _level.get_node("SentinelDrone0")
	var hp: HealthComponent = drone.get_node("Health")
	var hb = drone.get_node("Hurtbox")
	drone.set("_phase", 1)  # force HIGH (airborne)
	var hp0 := hp.current

	# Melee-style hit (no launch() on source) -> should be IGNORED while flying.
	hb.hurt.emit({"damage": 5, "is_crit": false, "knockback": Vector2.ZERO, "source": null})
	var after_melee := hp.current

	# Ranged-style hit (source has launch()) -> should DAMAGE.
	var bolt := (ResourceLoader.load("res://Scenes/Effects/PlayerBolt.tscn") as PackedScene).instantiate()
	hb.hurt.emit({"damage": 5, "is_crit": false, "knockback": Vector2.ZERO, "source": bolt})
	var after_ranged := hp.current
	bolt.free()

	print("airborne: hp %d -> melee %d -> ranged %d" % [hp0, after_melee, after_ranged])
	var ok := after_melee == hp0 and after_ranged < after_melee
	print("AIRBORNE MELEE TEST: %s" % ("PASS" if ok else "FAIL"))
	if not ok:
		push_error("Expected melee ignored + ranged damaging while airborne.")
	quit(0 if ok else 1)
	return true
