## LevelFlow
##
## Gives the slice a shape: shows the objective on entry, watches for the win
## condition (all Echo Fragments collected) and the lose condition (player death),
## and presents the Win / Game Over screen. One node per level.
extends Node

const RESULT_SCREEN := preload("res://Scenes/UI/ResultScreen.tscn")

var _result: CanvasLayer
var _ended := false


func _ready() -> void:
	_result = RESULT_SCREEN.instantiate()
	add_child(_result)

	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.reset_run()
		gs.fragments_changed.connect(_on_fragments_changed)

	_show_objective()

	# Wire player death once the player is in the tree.
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var hp := player.get_node_or_null("Health")
		if hp != null:
			hp.died.connect(_on_player_died)


func _on_fragments_changed(_count: int) -> void:
	var gs := get_node_or_null("/root/GameState")
	if not _ended and gs != null and gs.all_collected():
		_ended = true
		_result.show_result("SLICE COMPLETE", "All Echo Fragments recovered.", Color(0.36, 0.92, 0.55))


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	await get_tree().create_timer(1.1).timeout  # let the death animation play
	_result.show_result("DELETED", "Aarin was corrupted. Try again.", Color(1.0, 0.32, 0.36))


## Brief centered objective banner that fades out.
func _show_objective() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 6
	add_child(canvas)

	var label := Label.new()
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -170.0
	label.offset_right = 170.0
	label.offset_top = 60.0
	label.offset_bottom = 96.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.46, 0.9, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	label.text = "OBJECTIVE\nRecover 3 Echo Fragments • Hack the gate"
	canvas.add_child(label)

	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(canvas.queue_free)
