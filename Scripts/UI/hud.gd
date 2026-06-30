## HUD
##
## Minimal, immersive heads-up display (per the design brief): health, energy and
## an Echo Fragment counter. It binds to the player's HealthComponent / energy
## signal and to GameState, so it updates reactively and stays decoupled.
##
## Bars are driven by scaling the fill ColorRect on X (pivots at its left edge),
## which is cheap and pixel-crisp.
extends CanvasLayer

@onready var health_fill: ColorRect = $Root/HealthFill
@onready var energy_fill: ColorRect = $Root/EnergyFill
@onready var fragment_count: Label = $Root/FragCount

var _player: Node


func _ready() -> void:
	# Defer so the player (and its Health) are guaranteed ready first.
	call_deferred("_bind")


func _bind() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(_player):
		var hp: HealthComponent = _player.get_node("Health")
		hp.health_changed.connect(_on_health_changed)
		_on_health_changed(hp.current, hp.max_health)
		if _player.has_signal("energy_changed"):
			_player.energy_changed.connect(_on_energy_changed)
		_on_energy_changed(_player.energy, _player.energy_max)

	# Autoload resolved by path so the HUD still compiles in headless tests.
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.fragments_changed.connect(_on_fragments_changed)
		_on_fragments_changed(gs.fragments)


func _on_health_changed(current: int, maximum: int) -> void:
	health_fill.scale.x = float(current) / float(max(maximum, 1))


func _on_energy_changed(current: float, maximum: float) -> void:
	energy_fill.scale.x = current / maxf(maximum, 1.0)


func _on_fragments_changed(count: int) -> void:
	var gs := get_node_or_null("/root/GameState")
	var target: int = gs.target if gs != null else 3
	fragment_count.text = "%d / %d" % [count, target]
