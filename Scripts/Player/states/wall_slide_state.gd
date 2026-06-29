## WallSlideState — clinging to and sliding down a wall.
##
## Caps fall speed, lets the player kick off with a wall jump, and feeds into
## a ledge grab if the top of the wall is reached.
extends PlayerState

var _wall_dir: int = 0


func enter(_previous: String, _data: Dictionary = {}) -> void:
	_wall_dir = player.get_wall_dir()
	if _wall_dir == 0:
		_wall_dir = player.facing
	# The cling pose faces the wall.
	player.set_facing(_wall_dir)
	player.sprite.play("wall_slide")


func physics_update(delta: float) -> String:
	_wall_dir = player.get_wall_dir()

	if player.is_on_floor():
		return "run" if absf(player.input_x) > 0.01 else "idle"

	# Wall jump — buffered press kicks off and away.
	if player.try_wall_jump():
		return "jump"

	if Input.is_action_just_pressed("dash") and player.can_dash():
		return "dash"

	if player.detect_ledge():
		return "ledge_grab"

	# Dropped off the wall, or actively pushing away from it → fall.
	if _wall_dir == 0 or signf(player.input_x) == float(-_wall_dir):
		return "fall"

	# Keep light pressure into the wall so contact (and is_on_wall) holds.
	player.velocity.x = float(_wall_dir) * 8.0
	# Eased clamp toward the slide speed for a soft "catch".
	player.velocity.y = move_toward(
		player.velocity.y, player.config.wall_slide_speed, player.config.wall_slide_acceleration * delta
	)
	player.move_and_slide()
	return ""
