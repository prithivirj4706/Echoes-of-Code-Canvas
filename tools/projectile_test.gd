## projectile_test.gd — confirm a wounded drone lifts off, hovers, fires, and its
## bolt damages the player.
##   godot --headless --path . --script res://tools/projectile_test.gd
extends SceneTree

var _level: Node
var _player_hp: HealthComponent
var _start_hp := 0
var _frames := 0


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		var player := _level.get_node("Player") as Player
		var drone := _level.get_node("SentinelDrone0") as Node2D
		# Open start plaza (clear line of fire — no platforms between them).
		player.global_position = Vector2(90, 182)
		drone.global_position = Vector2(90, 146)
		_player_hp = player.get_node("Health") as HealthComponent
		_start_hp = _player_hp.current
		# Wound the drone so it takes flight, then it should start shooting.
		var hb := drone.get_node("Hurtbox")
		hb.hurt.emit({"damage": 14, "is_crit": false, "knockback": Vector2.ZERO, "source": null})
		return false

	if _player_hp != null and _player_hp.current < _start_hp:
		print("Wounded drone lifted off and shot player: hp %d -> %d" % [_start_hp, _player_hp.current])
		print("PROJECTILE TEST: PASS")
		quit(0)
		return true
	if _frames > 250:
		push_error("Drone never landed a bolt after lifting off.")
		print("PROJECTILE TEST: FAIL")
		quit(1)
		return true
	return false
