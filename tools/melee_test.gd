## melee_test.gd — confirm a real melee swing (AttackState, time-driven hitbox)
## damages an adjacent drone.
##   godot --headless --path . --script res://tools/melee_test.gd
extends SceneTree

var _level: Node
var _player: Player
var _hp: HealthComponent
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
		_player.set_facing(1)
		drone.global_position = Vector2(416, 166)  # adjacent, body height
		_hp = drone.get_node("Health") as HealthComponent
		_hp.damaged.connect(func(_a: int, _c: bool) -> void: _hit = true)
		return false
	if _frames == 2:
		_player.state_machine.transition_to("attack", {"combo": 0})
		return false
	if _hit:
		print("Melee swing damaged adjacent drone.")
		print("MELEE TEST: PASS")
		quit(0)
		return true
	if _frames > 30:
		push_error("Melee swing did not damage the adjacent drone.")
		print("MELEE TEST: FAIL")
		quit(1)
		return true
	return false
