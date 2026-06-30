## player_shoot_test.gd — confirm the player's energy bolt damages a drone and
## spends energy.
##   godot --headless --path . --script res://tools/player_shoot_test.gd
extends SceneTree

var _level: Node
var _player: Player
var _drone_hp: HealthComponent
var _start_energy := 0.0
var _hit := false
var _frames := 0


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_player = _level.get_node("Player") as Player
		var drone := _level.get_node("SentinelDrone0") as Node2D
		_player.global_position = Vector2(400, 182)
		drone.global_position = Vector2(460, 166)  # in front, slightly up
		_player.set_facing(1)
		_drone_hp = drone.get_node("Health") as HealthComponent
		_drone_hp.damaged.connect(func(_a: int, _c: bool) -> void: _hit = true)
		_start_energy = _player.energy
		_player._try_shoot()
		return false

	if _hit:
		print("Bolt hit drone. energy %.0f -> %.0f" % [_start_energy, _player.energy])
		var ok := _player.energy < _start_energy
		print("PLAYER SHOOT TEST: %s" % ("PASS" if ok else "FAIL"))
		quit(0 if ok else 1)
		return true
	if _frames > 40:
		push_error("Bolt never hit the drone.")
		print("PLAYER SHOOT TEST: FAIL")
		quit(1)
		return true
	return false
