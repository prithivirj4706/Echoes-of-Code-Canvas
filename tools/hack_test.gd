## hack_test.gd — confirm the player can hack a terminal in range and it opens
## the linked door.
##   godot --headless --path . --script res://tools/hack_test.gd
extends SceneTree

var _level: Node
var _player: Player
var _terminal: Node
var _door: Node
var _frames := 0
var _sensed := false


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_player = _level.get_node("Player") as Player
		_terminal = _level.get_node("HackTerminal")
		_door = _level.get_node("HackDoor")
		# Stand on the terminal so the interact sensor overlaps it.
		_player.global_position = _terminal.global_position + Vector2(0, -4)
		return false

	if _frames == 8:
		_sensed = _terminal in _player._interactables
		_player._try_interact()
		return false

	if _frames == 12:
		var opened: bool = _door.get("_opened")
		print("Terminal sensed in range: %s" % _sensed)
		print("Door opened after hack   : %s" % opened)
		var ok := _sensed and opened
		print("HACK TEST: %s" % ("PASS" if ok else "FAIL"))
		if not ok:
			push_error("Hack chain failed (sensed=%s opened=%s)" % [_sensed, opened])
		quit(0 if ok else 1)
		return true
	return false
