## DashState — a fixed-duration burst in the facing/input direction.
##
## Gravity is suspended for most of the dash for that crisp, weightless
## Celeste/Hyper-Light feel, and a fraction of the speed is preserved on exit
## so dashes flow into runs and jumps (momentum preservation).
extends PlayerState

var _dir: int = 1
var _elapsed: float = 0.0


func enter(_previous: String, _data: Dictionary = {}) -> void:
	# Dash in the pressed direction, or the way we're facing if neutral.
	_dir = int(signf(player.input_x)) if absf(player.input_x) > 0.01 else player.facing
	_elapsed = 0.0
	player.set_facing(_dir)
	player.start_dash_cooldown()
	player.velocity = Vector2(float(_dir) * player.config.dash_speed, 0.0)
	player.emit_dash_burst()
	player.sprite.play("dash")
	player.sprite.frame = 0


func physics_update(delta: float) -> String:
	_elapsed += delta
	var cfg := player.config

	# Hold dash speed; only let gravity back in after the no-gravity window.
	player.velocity.x = float(_dir) * cfg.dash_speed
	if _elapsed >= cfg.dash_duration * cfg.dash_gravity_disabled:
		player.apply_gravity(delta)
	else:
		player.velocity.y = 0.0

	player.move_and_slide()

	if _elapsed >= cfg.dash_duration:
		# Preserve a slice of the burst so it chains into other movement.
		player.velocity.x *= cfg.dash_end_speed_keep
		if player.is_on_floor():
			return "run" if absf(player.input_x) > 0.01 else "idle"
		return "fall"
	return ""
