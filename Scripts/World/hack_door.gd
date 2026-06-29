## HackDoor
##
## A barrier that blocks a path until a linked HackTerminal opens it. On
## hack_open() it disables its collision and slides out of the way.
extends StaticBody2D

@export var open_offset: Vector2 = Vector2(0, -44)
@export var open_time: float = 0.5

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _audio: Node = get_node_or_null("/root/Audio")

var _opened: bool = false


func hack_open() -> void:
	if _opened:
		return
	_opened = true
	_collision.set_deferred("disabled", true)
	if _audio != null:
		_audio.play("dash", -9.0)
	var tween := create_tween()
	tween.tween_property(self, "position", position + open_offset, open_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
