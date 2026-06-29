## HackTerminal
##
## Aarin's signature "Code" interaction: hack a terminal to affect the world
## (open a barrier, etc.). On hack it recolors its screen from locked-red to
## hacked-green, plays the hack jingle, and calls hack_open() on its target.
extends Interactable

## Node to act on when hacked (e.g. a HackDoor). Must have a hack_open() method.
@export var target_path: NodePath

@onready var _screen: ColorRect = get_node_or_null("Screen")
@onready var _audio: Node = get_node_or_null("/root/Audio")


func _on_interact(_by: Node) -> void:
	if _screen != null:
		_screen.color = Color(0.32, 0.95, 0.5)  # hacked = green
	if _audio != null:
		_audio.play("hack", -5.0)
	if target_path != NodePath(""):
		var target := get_node_or_null(target_path)
		if target != null and target.has_method("hack_open"):
			target.hack_open()
