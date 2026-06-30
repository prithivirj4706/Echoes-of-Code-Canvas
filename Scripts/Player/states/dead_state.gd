## DeadState — the player's death sequence.
##
## Plays the death animation, disables input and combat, and lets the body settle.
## It does NOT auto-respawn — LevelFlow shows the Game Over screen, and Retry
## reloads the level. (A shipping build would route this to a checkpoint.)
extends PlayerState


func enter(_previous: String, _data: Dictionary = {}) -> void:
	player.velocity.x = 0.0
	player.set_hitbox_active(false)
	player.hurtbox.set_deferred("monitoring", false)  # no more hits while dead
	player.sprite.play("die")
	player.sprite.frame = 0


func physics_update(delta: float) -> String:
	# Let the corpse fall and slide to a stop, then stay dead.
	if not player.is_on_floor():
		player.apply_gravity(delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
	player.move_and_slide()
	return ""
