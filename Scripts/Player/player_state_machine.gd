## PlayerStateMachine
##
## A lightweight, node-based finite state machine. Each child node is a
## PlayerState; the node's lowercased name is its key (e.g. node "Run" -> "run").
##
## The machine drives the active state every physics frame and performs the
## actual transition when a state asks for one. Transitions emit a signal so
## that animation, audio and VFX systems can react without the states needing
## to know those systems exist (decoupling via signals, per project standards).
class_name PlayerStateMachine
extends Node

signal state_changed(from_state: String, to_state: String)

## Name of the state to start in (must match a child node, case-insensitive).
@export var initial_state: String = "fall"

var current_state: PlayerState
var current_name: String = ""
var previous_name: String = ""

var _states: Dictionary = {}
var _player: Player


func setup(player: Player) -> void:
	_player = player
	# Nodes are named in PascalCase (Idle, WallSlide, LedgeGrab); keys are the
	# snake_case form (idle, wall_slide, ledge_grab) used by transition calls.
	for child in get_children():
		if child is PlayerState:
			var key := child.name.to_snake_case()
			_states[key] = child
			child.player = player
			child.state_machine = self
	var start := initial_state.to_snake_case()
	if not _states.has(start):
		push_error("PlayerStateMachine: initial_state '%s' not found." % initial_state)
		return
	current_name = start
	current_state = _states[start]
	current_state.enter("")


func _physics_process(delta: float) -> void:
	if current_state == null:
		return
	var next := current_state.physics_update(delta)
	if next != "":
		transition_to(next)


func _unhandled_input(event: InputEvent) -> void:
	if current_state == null:
		return
	var next := current_state.handle_input(event)
	if next != "":
		transition_to(next)


## Switch to another state by name. `data` is handed to the new state's enter().
func transition_to(target: String, data: Dictionary = {}) -> void:
	var key := target.to_snake_case()
	if not _states.has(key):
		push_error("PlayerStateMachine: unknown state '%s'." % target)
		return
	if key == current_name:
		return
	current_state.exit()
	previous_name = current_name
	current_name = key
	current_state = _states[key]
	current_state.enter(previous_name, data)
	state_changed.emit(previous_name, current_name)


func has_state(name_key: String) -> bool:
	return _states.has(name_key.to_snake_case())
