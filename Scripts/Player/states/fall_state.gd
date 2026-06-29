## FallState — airborne and descending (or knocked off a ledge).
extends PlayerState


func enter(previous: String, _data: Dictionary = {}) -> void:
	# Only swap to the fall pose if we didn't arrive mid-jump-animation.
	if previous != "jump":
		player.sprite.play("fall")


func physics_update(delta: float) -> String:
	if player.wants_attack():
		return "attack"

	if Input.is_action_just_pressed("dash") and player.can_dash():
		return "dash"

	# Coyote jump — still grounded "enough" to count as a normal jump.
	if player.has_buffered_jump() and player.can_coyote_jump():
		player.ground_jump()
		return "jump"

	if player.try_wall_jump():
		return "jump"

	if player.has_buffered_jump() and player.can_air_jump():
		player.air_jump()
		return "jump"

	# Latch onto a ledge if one lines up on the facing side.
	if player.velocity.y >= 0.0 and player.detect_ledge():
		return "ledge_grab"

	# Begin a wall slide when pressed into a wall while falling.
	var wall_dir := player.get_wall_dir()
	if wall_dir != 0 and player.velocity.y > 0.0 and signf(player.input_x) == float(wall_dir):
		return "wall_slide"

	player.apply_horizontal(delta, player.config.air_acceleration, player.config.air_deceleration)
	player.apply_gravity(delta)
	player.move_and_slide()

	if player.is_on_floor():
		return "run" if absf(player.input_x) > 0.01 else "idle"
	return ""
