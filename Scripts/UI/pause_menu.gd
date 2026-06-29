## PauseMenu
##
## Toggled with the "pause" action (Esc / P). Freezes the game via the SceneTree
## and shows Resume / Restart / Quit. The whole layer runs in PROCESS_MODE_ALWAYS
## (set in the scene) so its buttons still respond while the tree is paused.
extends CanvasLayer

func _ready() -> void:
	visible = false
	$Menu/Center/VBox/Resume.pressed.connect(_on_resume_pressed)
	$Menu/Center/VBox/Restart.pressed.connect(_on_restart_pressed)
	$Menu/Center/VBox/Quit.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused


func _on_resume_pressed() -> void:
	_toggle()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.reset()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
