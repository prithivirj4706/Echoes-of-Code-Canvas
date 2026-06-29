## EchoFragment
##
## A collectible Echo Fragment. On player contact it adds to GameState (updating
## the HUD counter), plays a pickup blip, and removes itself. Gently bobs so it
## reads as pickup-able.
extends Area2D

@onready var _audio: Node = get_node_or_null("/root/Audio")

var _t: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	_base_y = position.y
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 2.0


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.add_fragment(1)
	if _audio != null:
		_audio.play("pickup", -5.0)
	queue_free()
