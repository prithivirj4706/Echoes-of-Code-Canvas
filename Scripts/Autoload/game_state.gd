## GameState (autoload singleton)
##
## Holds run-scoped player progression that must outlive any single room — for
## now just collected Echo Fragments, surfaced to the HUD via a signal. This is
## the natural home for future save/load and checkpoint data.
extends Node

signal fragments_changed(count: int)

var fragments: int = 0


func add_fragment(amount: int = 1) -> void:
	fragments += amount
	fragments_changed.emit(fragments)


func reset() -> void:
	fragments = 0
	fragments_changed.emit(fragments)
