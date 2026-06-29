## smoke_test.gd — headless behavioural check of the movement slice.
## Loads the arena, lets the player fall and settle, then asserts the FSM
## reached a grounded resting state with all expected states wired up.
##   godot --headless --path . --script res://tools/smoke_test.gd
extends SceneTree

const EXPECTED := ["idle", "run", "jump", "fall", "wall_slide", "dash", "ledge_grab", "ledge_climb"]

var _player: Player
var _frames := 0


func _initialize() -> void:
	var scene: PackedScene = ResourceLoader.load("res://Scenes/Levels/TestArena.tscn")
	var level := scene.instantiate()
	get_root().add_child(level)
	_player = level.get_node("Player") as Player


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 120:
		return false  # keep running

	# --- Assertions ---
	var ok := true
	for s in EXPECTED:
		if not _player.state_machine.has_state(s):
			push_error("Missing state: %s" % s)
			ok = false
	print("States wired: %s" % str(_player.state_machine.has_state("wall_slide")))
	print("Final state : %s" % _player.state_machine.current_name)
	print("On floor    : %s" % str(_player.is_on_floor()))
	print("Position    : %s" % str(_player.global_position.round()))
	print("Animation   : %s" % _player.sprite.animation)
	if not _player.is_on_floor():
		push_error("Player never landed.")
		ok = false
	if _player.state_machine.current_name not in ["idle", "run"]:
		push_error("Expected to rest in idle/run, got '%s'." % _player.state_machine.current_name)
		ok = false
	print("SMOKE TEST: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
	return true
