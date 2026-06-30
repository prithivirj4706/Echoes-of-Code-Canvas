## player_death_test.gd — player death enters the Dead state and stays down
## (LevelFlow handles Game Over; no auto-respawn).
##   godot --headless --path . --script res://tools/player_death_test.gd
extends SceneTree

var _level: Node
var _player: Player
var _frames := 0


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 2:
		_player = _level.get_node("Player") as Player
		(_player.get_node("Health") as HealthComponent).take_damage(999, false)
		return false
	if _frames == 20:
		var state: String = _player.state_machine.current_name
		var hp: int = (_player.get_node("Health") as HealthComponent).current
		print("After death: state=%s hp=%d" % [state, hp])
		var ok := state == "dead" and hp == 0
		print("PLAYER DEATH TEST: %s" % ("PASS" if ok else "FAIL"))
		if not ok:
			push_error("Expected dead state + 0 hp.")
		quit(0 if ok else 1)
		return true
	return false
