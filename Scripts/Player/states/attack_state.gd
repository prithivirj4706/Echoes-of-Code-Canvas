## AttackState — the grounded/air light-attack combo (attack1 → attack2 → attack3).
##
## Game-feel notes:
##  * Each swing has a small forward LUNGE so attacks feel committed and push
##    into the enemy.
##  * The HITBOX is only live during a per-swing active frame window, giving the
##    attack readable reach and timing.
##  * Pressing attack again is BUFFERED; if it lands during the cancel window the
##    next combo step chains seamlessly — otherwise the combo ends.
##  * Dash cancels the combo for aggressive, expressive play.
extends PlayerState

# Per-step tuning: animation, [active_start_frame, active_end_frame], lunge px/s,
# damage, knockback. Aarin's combo escalates: light, light, big finisher.
const COMBO := [
	{"anim": "attack1", "active": [0, 4], "lunge": 70.0, "damage": 5, "knockback": 150.0, "up": 50.0},
	{"anim": "attack2", "active": [0, 5], "lunge": 55.0, "damage": 5, "knockback": 150.0, "up": 50.0},
	{"anim": "attack3", "active": [0, 5], "lunge": 95.0, "damage": 9, "knockback": 240.0, "up": 110.0},
]

var _index: int = 0
var _buffered: bool = false
var _hit_live: bool = false


func enter(_previous: String, data: Dictionary = {}) -> void:
	_index = data.get("combo", 0)
	_buffered = false
	_start_swing()


func exit() -> void:
	player.set_hitbox_active(false)
	_hit_live = false


func physics_update(delta: float) -> String:
	# Buffer a follow-up press at any time during the swing.
	if Input.is_action_just_pressed("attack"):
		_buffered = true

	# Dash-cancel for expressive, aggressive movement.
	if Input.is_action_just_pressed("dash") and player.can_dash():
		return "dash"

	_update_hitbox_window()

	# Decelerate the lunge; keep grounded or fall naturally if knocked off.
	player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
	if player.is_on_floor():
		player.velocity.y = 0.0
	else:
		player.apply_gravity(delta)
	player.move_and_slide()

	# Swing finished (non-looping anim stopped playing).
	if not player.sprite.is_playing():
		if _buffered and _index < COMBO.size() - 1:
			_index += 1
			_buffered = false
			player.set_hitbox_active(false)
			_hit_live = false
			_start_swing()
			return ""
		# Combo over.
		if not player.is_on_floor():
			return "fall"
		return "run" if absf(player.input_x) > 0.01 else "idle"
	return ""


func _start_swing() -> void:
	var step: Dictionary = COMBO[_index]
	player.sprite.play(step["anim"])
	player.sprite.frame = 0
	# Configure this swing's hitbox payload.
	player.hitbox.damage = step["damage"]
	player.hitbox.knockback_force = step["knockback"]
	player.hitbox.knockback_up = step["up"]
	# Commit a forward lunge in the facing direction.
	player.velocity.x = float(player.facing) * step["lunge"]


func _update_hitbox_window() -> void:
	var step: Dictionary = COMBO[_index]
	var f := player.sprite.frame
	var want := f >= int(step["active"][0]) and f <= int(step["active"][1])
	if want and not _hit_live:
		player.set_hitbox_active(true)
		_hit_live = true
	elif not want and _hit_live:
		player.set_hitbox_active(false)
		_hit_live = false
