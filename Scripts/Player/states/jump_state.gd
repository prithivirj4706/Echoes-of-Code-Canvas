## JumpState — the rising portion of a jump.
##
## The launch impulse is applied by whoever requested the jump (ground/air/wall)
## *before* transitioning here; this state only shapes the ascent: variable
## height, air control, and mid-air actions (double jump, wall jump, dash).
extends PlayerState


func enter(_previous: String, _data: Dictionary = {}) -> void:
	player.sprite.play("jump")
	player.sprite.frame = 0


func physics_update(delta: float) -> String:
	# Variable jump height — releasing the button early cuts the arc short.
	player.try_jump_cut()

	# Air attack — lets you swing on the way UP toward flying enemies.
	if player.wants_attack():
		return "attack"

	if Input.is_action_just_pressed("dash") and player.can_dash():
		return "dash"

	# Wall jump takes priority over a double jump when next to a wall.
	if player.try_wall_jump():
		player.sprite.play("jump")
		player.sprite.frame = 0
		return ""

	if player.has_buffered_jump() and player.can_air_jump():
		player.air_jump()
		player.sprite.play("jump")
		player.sprite.frame = 0
		return ""

	player.apply_horizontal(delta, player.config.air_acceleration, player.config.air_deceleration)
	player.apply_gravity(delta)
	player.move_and_slide()

	# Apex reached → hand off to Fall.
	if player.velocity.y >= 0.0:
		return "fall"
	return ""
