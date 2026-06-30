## airborne_melee_test.gd — flying drone: grounded melee deflects, AIRBORNE melee
## lands, ranged lands.
##   godot --headless --path . --script res://tools/airborne_melee_test.gd
extends SceneTree

var _level: Node
var _player: Player
var _drone: Node2D
var _hp: HealthComponent
var _f := 0
var _hp_after_ground_melee := -1
var _hp_after_air_melee := -1
var _hp_after_ranged := -1


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f == 1:
		_player = _level.get_node("Player") as Player
		_drone = _level.get_node("SentinelDrone0") as Node2D
		_hp = _drone.get_node("Health") as HealthComponent
		_player.global_position = Vector2(400, 196)  # settle on the ground
		return false

	# Grounded player meleeing the flying drone -> should DEFLECT (no damage).
	if _f == 14:
		_drone.set("_phase", 1)  # HIGH
		var hb = _drone.get_node("Hurtbox")
		hb.hurt.emit({"damage": 6, "is_crit": false, "knockback": Vector2.ZERO, "source": null})
		_hp_after_ground_melee = _hp.current
		_player.global_position = Vector2(400, 110)  # lift the player into the air
		return false

	# Airborne player meleeing the flying drone -> should LAND.
	if _f == 18:
		_drone.set("_phase", 1)
		var hb = _drone.get_node("Hurtbox")
		hb.hurt.emit({"damage": 6, "is_crit": false, "knockback": Vector2.ZERO, "source": null})
		_hp_after_air_melee = _hp.current
		# Ranged anytime -> lands.
		var bolt := (ResourceLoader.load("res://Scenes/Effects/PlayerBolt.tscn") as PackedScene).instantiate()
		hb.hurt.emit({"damage": 6, "is_crit": false, "knockback": Vector2.ZERO, "source": bolt})
		_hp_after_ranged = _hp.current
		bolt.free()

		var grounded_deflected := _hp_after_ground_melee == _hp.max_health
		var air_landed := _hp_after_air_melee < _hp_after_ground_melee
		var ranged_landed := _hp_after_ranged < _hp_after_air_melee
		print("flying drone: groundMelee=%d airMelee=%d ranged=%d (max %d)" % [_hp_after_ground_melee, _hp_after_air_melee, _hp_after_ranged, _hp.max_health])
		var ok := grounded_deflected and air_landed and ranged_landed
		print("AIRBORNE MELEE TEST: %s" % ("PASS" if ok else "FAIL"))
		if not ok:
			push_error("Expected: grounded melee deflect, airborne melee + ranged land.")
		quit(0 if ok else 1)
		return true
	return false
