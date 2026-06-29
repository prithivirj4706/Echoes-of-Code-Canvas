## LedgeGrabState — hanging motionless from a grabbed ledge.
##
## From the hang the player can climb up (up / jump), or drop (down / away).
extends PlayerState


func enter(_previous: String, _data: Dictionary = {}) -> void:
	player.velocity = Vector2.ZERO
	# Face into the wall we're hanging on.
	player.set_facing(player.get_wall_dir() if player.get_wall_dir() != 0 else player.facing)
	player.sprite.play("ledge_grab")


func physics_update(_delta: float) -> String:
	player.velocity = Vector2.ZERO

	# Climb up.
	if player.has_buffered_jump() or player.input_y < -0.5:
		return "ledge_climb"

	# Drop off (press down, or push away from the wall).
	if player.input_y > 0.5 or signf(player.input_x) == float(-player.facing):
		return "fall"

	# Hang in place — no gravity, but resolve collisions to stay snug.
	player.move_and_slide()
	return ""
