## MainMenu — title screen. Play starts the Digital World slice; Quit exits.
extends Control

const LEVEL := "res://Scenes/Levels/TestArena.tscn"

@onready var _badge: Label = $Center/VBox/Badge


func _ready() -> void:
	$Center/VBox/Play.pressed.connect(_on_play)
	$Center/VBox/Quit.pressed.connect(_on_quit)
	$Center/VBox/Play.grab_focus()
	var gs := get_node_or_null("/root/GameState")
	_badge.visible = gs != null and gs.completed


func _on_play() -> void:
	get_tree().change_scene_to_file(LEVEL)


func _on_quit() -> void:
	get_tree().quit()
