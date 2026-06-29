## PlayerState
##
## Base class for every node in the player's finite state machine.
## States are child nodes of the StateMachine and own one "mode" of behaviour
## (Idle, Run, Jump, ...). Keeping each mode in its own small script is what
## stops the player controller from collapsing into a 1000-line monolith and
## makes new mechanics (combat, abilities) cheap to bolt on later.
##
## A state never touches the engine directly for transitions — it returns the
## *name* of the next state from physics_update()/handle_input(), or "" to stay.
class_name PlayerState
extends Node

## Back-reference to the player body. Injected by the StateMachine on ready.
var player: Player
## The owning machine, for querying siblings or shared transition helpers.
var state_machine: PlayerStateMachine


## Called once when this state becomes active. `previous` is the state we came
## from (may be empty on the very first state).
func enter(_previous: String, _data: Dictionary = {}) -> void:
	pass


## Called once when leaving this state.
func exit() -> void:
	pass


## Per-physics-frame logic. Return the name of the state to switch to, or "" to
## remain in this state.
func physics_update(_delta: float) -> String:
	return ""


## Forwarded unhandled input. Return a state name to transition, or "".
func handle_input(_event: InputEvent) -> String:
	return ""
