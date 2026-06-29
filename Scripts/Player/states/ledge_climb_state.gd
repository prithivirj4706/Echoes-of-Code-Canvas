## LedgeClimbState — scripted climb-up from a ledge hang.
##
## Input is locked while the climb animation plays; the body is smoothly moved
## from the hang position up and onto the platform, then control returns.
extends PlayerState

var _elapsed: float = 0.0
var _start: Vector2
var _target: Vector2


func enter(_previous: String, _data: Dictionary = {}) -> void:
	_elapsed = 0.0
	player.velocity = Vector2.ZERO
	_start = player.global_position
	# Rise by roughly the body height and step inward onto the ledge.
	var up := player.config.jump_height * 0.55
	_target = _start + Vector2(float(player.facing) * 12.0, -up)
	player.sprite.play("ledge_climb")
	player.sprite.frame = 0


func physics_update(delta: float) -> String:
	_elapsed += delta
	var t := clampf(_elapsed / player.config.ledge_climb_duration, 0.0, 1.0)
	# Ease-out for a planted, deliberate climb.
	var eased := 1.0 - pow(1.0 - t, 3.0)
	player.global_position = _start.lerp(_target, eased)

	if t >= 1.0:
		player.velocity = Vector2.ZERO
		return "idle"
	return ""
