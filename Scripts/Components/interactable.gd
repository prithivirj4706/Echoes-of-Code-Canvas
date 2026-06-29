## Interactable
##
## Base for anything the player can interact with (terminals, levers, NPCs...).
## It's an Area2D on the "Interactable" layer; the player's InteractSensor finds
## it and calls interact() on the "interact" press. Shows/hides an optional
## "Prompt" child (a Label like "[E] HACK") when the player is in range.
##
## Subclasses override _on_interact(); they don't manage input or range.
class_name Interactable
extends Area2D

signal interacted(by: Node)

@export var prompt_text: String = "[E]"
## If true, it can only be used once (e.g. a terminal that stays hacked).
@export var one_shot: bool = true

@onready var _prompt: Node = get_node_or_null("Prompt")

var _used: bool = false


func _ready() -> void:
	if _prompt is Label and prompt_text != "":
		_prompt.text = prompt_text
	set_prompt_visible(false)


func can_interact() -> bool:
	return not (_used and one_shot)


func set_prompt_visible(value: bool) -> void:
	if _prompt != null:
		_prompt.visible = value and can_interact()


## Called by the player. Routes to the subclass hook and fires the signal.
func interact(by: Node) -> void:
	if not can_interact():
		return
	_used = true
	set_prompt_visible(false)
	_on_interact(by)
	interacted.emit(by)


## Override in subclasses.
func _on_interact(_by: Node) -> void:
	pass
