## ResultScreen
##
## Reusable end-of-run overlay (Win or Game Over). Runs while the tree is paused.
## setup() sets the title/colour; Retry reloads the level, Menu returns to title.
extends CanvasLayer

@onready var _title: Label = $Dim/Center/VBox/Title
@onready var _subtitle: Label = $Dim/Center/VBox/Subtitle


func _ready() -> void:
	$Dim/Center/VBox/Retry.pressed.connect(_on_retry)
	$Dim/Center/VBox/Menu.pressed.connect(_on_menu)
	visible = false


func show_result(title: String, subtitle: String, color: Color) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_subtitle.text = subtitle
	visible = true
	get_tree().paused = true


func _on_retry() -> void:
	get_tree().paused = false
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.reset_run()
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
