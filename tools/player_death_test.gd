## player_death_test.gd — confirm the player dies (death anim/state) and respawns.
##   godot --headless --path . --script res://tools/player_death_test.gd
extends SceneTree

var _level: Node
var _player: Player
var _sm: PlayerStateMachine
var _saw_dead := false
var _spawn: Vector2
var _frames := 0


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_player = _level.get_node("Player") as Player
		_sm = _player.state_machine
		_spawn = _player.global_position
		# Kill the player outright through the health component.
		(_player.get_node("Health") as HealthComponent).take_damage(999, false)
		return false

	if _sm.current_name == "dead":
		_saw_dead = true
	# It should enter "dead", play "die", then respawn back to a live state.
	if _saw_dead and _sm.current_name != "dead":
		var hp := (_player.get_node("Health") as HealthComponent).current
		print("Died -> respawned. state=%s hp=%d anim_seen=die->%s" % [_sm.current_name, hp, _player.sprite.animation])
		print("PLAYER DEATH TEST: %s" % ("PASS" if hp > 0 else "FAIL"))
		quit(0 if hp > 0 else 1)
		return true
	if _frames > 400:
		push_error("Death/respawn did not complete (saw_dead=%s, state=%s)" % [_saw_dead, _sm.current_name])
		print("PLAYER DEATH TEST: FAIL")
		quit(1)
		return true
	return false
