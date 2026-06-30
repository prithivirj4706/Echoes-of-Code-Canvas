## GameState (autoload singleton)
##
## Run-scoped progression (Echo Fragments) + the slice's win condition + simple
## persistent save. Surfaced to the HUD and the level flow via signals.
extends Node

signal fragments_changed(count: int)

const SAVE_PATH := "user://eo2c_save.cfg"

## Fragments needed to complete the slice.
var target: int = 3
var fragments: int = 0
## Set once the slice has ever been completed (persisted).
var completed: bool = false


func _ready() -> void:
	load_game()


func add_fragment(amount: int = 1) -> void:
	fragments += amount
	fragments_changed.emit(fragments)
	if fragments >= target and not completed:
		completed = true
		save_game()


## Begin a fresh run (called when a level starts).
func reset_run() -> void:
	fragments = 0
	fragments_changed.emit(fragments)


func all_collected() -> bool:
	return fragments >= target


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed", completed)
	cfg.set_value("progress", "best_fragments", fragments)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		completed = cfg.get_value("progress", "completed", false)
