## ShakeCamera2D
##
## A Camera2D with a trauma-based shake (the GDC "Math for Game Programmers"
## model): callers add trauma, the felt shake is trauma², and it decays over
## time. Squaring makes small hits barely wiggle while big hits really kick,
## then settles smoothly back to centre. Pair with Combat.shake().
class_name ShakeCamera2D
extends Camera2D

## Maximum positional shake at full trauma (pixels).
@export var max_offset: Vector2 = Vector2(6.0, 4.0)
## Maximum rotational shake at full trauma (radians).
@export var max_roll: float = 0.04
## Trauma units lost per second.
@export var decay: float = 1.6
## How quickly the camera re-centres when not shaking.
@export var recenter_speed: float = 12.0

var _trauma: float = 0.0


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(_trauma - decay * delta, 0.0)
		var shake := _trauma * _trauma
		offset = Vector2(
			max_offset.x * shake * randf_range(-1.0, 1.0),
			max_offset.y * shake * randf_range(-1.0, 1.0)
		)
		rotation = max_roll * shake * randf_range(-1.0, 1.0)
	elif offset != Vector2.ZERO or rotation != 0.0:
		offset = offset.lerp(Vector2.ZERO, recenter_speed * delta)
		rotation = lerp(rotation, 0.0, recenter_speed * delta)
