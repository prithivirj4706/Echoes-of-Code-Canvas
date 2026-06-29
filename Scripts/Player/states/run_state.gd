## RunState — grounded with horizontal input.
extends PlayerState


func enter(_previous: String, _data: Dictionary = {}) -> void:
	player.sprite.play("run")


func physics_update(delta: float) -> String:
	if not player.is_on_floor():
		return "fall"

	if player.wants_attack():
		return "attack"

	if Input.is_action_just_pressed("dash") and player.can_dash():
		return "dash"

	if player.has_buffered_jump():
		player.ground_jump()
		return "jump"

	if absf(player.input_x) <= 0.01:
		return "idle"

	player.velocity.y = 0.0
	player.apply_horizontal(delta, player.config.ground_acceleration, player.config.ground_deceleration)
	player.move_and_slide()
	return ""
