## flow_test.gd — slice shape: collecting all fragments triggers WIN.
##   godot --headless --path . --script res://tools/flow_test.gd
extends SceneTree

var _gs: Node
var _level: Node
var _flow: Node
var _frames := 0


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)
	_flow = _level.get_node("LevelFlow")
	_gs = get_root().get_node_or_null("GameState")  # the autoload


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _gs == null:
		print("FLOW TEST: FAIL (no GameState)")
		quit(1)
		return true
	if _frames == 10:
		_gs.add_fragment(_gs.target)  # collect everything
		return false
	if _frames == 14:
		var won: bool = _flow.get("_ended")
		print("All fragments collected -> win triggered = %s" % won)
		print("FLOW TEST: %s" % ("PASS" if won else "FAIL"))
		if not won:
			push_error("Collecting all fragments did not trigger the win.")
		quit(0 if won else 1)
		return true
	return false
