## DeadState — the player's death + respawn sequence.
##
## Plays the death animation, disables all input and combat interaction, lets the
## body settle on the ground, then (in this prototype) respawns at the start
## point after a short delay so combat iteration never stops. A shipping build
## would route this to a checkpoint/load instead.
extends PlayerState

const RESPAWN_DELAY := 1.4

var _settled: bool = false
var _timer: float = 0.0


func enter(_previous: String, _data: Dictionary = {}) -> void:
	_settled = false
	_timer = 0.0
	player.velocity.x = 0.0
	player.set_hitbox_active(false)
	# Stop taking further hits while dead.
	player.hurtbox.set_deferred("monitoring", false)
	player.sprite.play("die")
	player.sprite.frame = 0


func physics_update(delta: float) -> String:
	# Let the corpse fall and slide to a stop.
	if not player.is_on_floor():
		player.apply_gravity(delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
	player.move_and_slide()

	# Once the death animation has finished, count down to respawn.
	if not _settled and not player.sprite.is_playing():
		_settled = true
	if _settled:
		_timer += delta
		if _timer >= RESPAWN_DELAY:
			player.respawn()
			return "idle"
	return ""
