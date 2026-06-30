## enemy_smoke_test.gd — headless check that Sentinel Drones move and take damage.
##   godot --headless --path . --script res://tools/enemy_smoke_test.gd
extends SceneTree

var _level: Node
var _drone: Node2D
var _health: HealthComponent
var _start_pos: Vector2
var _frames := 0
var _died := false


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_drone = _level.get_node("SentinelDrone0") as Node2D
		_health = _drone.get_node("Health") as HealthComponent
		_health.died.connect(func() -> void: _died = true)
		_start_pos = _drone.global_position
		return false

	if _frames == 40:
		var moved := _start_pos.distance_to(_drone.global_position)
		print("Drone moved %.1f px while patrolling" % moved)
		# Damage it through the hurt pipeline twice -> should die. Use a ranged
		# source (has launch()) so it lands even after the drone takes flight.
		var hb := _drone.get_node("Hurtbox")
		var bolt := (ResourceLoader.load("res://Scenes/Effects/PlayerBolt.tscn") as PackedScene).instantiate()
		var hp0 := _health.current
		hb.hurt.emit({"damage": 10, "is_crit": false, "knockback": Vector2(60, -20), "source": bolt})
		print("After 10 dmg: hp %d -> %d" % [hp0, _health.current])
		hb.hurt.emit({"damage": 30, "is_crit": true, "knockback": Vector2(60, -20), "source": bolt})
		bolt.free()
		var ok := moved > 3.0 and _health.current == 0 and _died
		print("ENEMY SMOKE TEST: %s" % ("PASS" if ok else "FAIL"))
		if not ok:
			push_error("Drone test failed (moved=%.1f hp=%d died=%s)" % [moved, _health.current, _died])
		quit(0 if ok else 1)
		return true
	return false
