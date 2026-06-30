## AttackState — the grounded/air light-attack combo (attack1 → attack2 → attack3).
##
## The hitbox is driven by a TIME window from the swing's start (not by sprite
## frames). Frame-driven activation proved unreliable — this is deterministic and
## testable, and guarantees the hitbox is live for the active portion of every
## swing regardless of animation playback.
##
##  * Small forward LUNGE on the ground so attacks feel committed.
##  * Follow-up presses are BUFFERED and chain the combo within the window.
##  * Dash cancels the combo.
extends PlayerState

# Per-step: animation, total duration, [active_start, active_end] seconds,
# lunge px/s, damage, knockback. Aarin's combo escalates.
const COMBO := [
	{"anim": "attack1", "dur": 0.34, "active": [0.04, 0.27], "lunge": 70.0, "damage": 5, "knockback": 150.0, "up": 50.0},
	{"anim": "attack2", "dur": 0.40, "active": [0.05, 0.33], "lunge": 55.0, "damage": 5, "knockback": 150.0, "up": 50.0},
	{"anim": "attack3", "dur": 0.46, "active": [0.06, 0.40], "lunge": 95.0, "damage": 9, "knockback": 240.0, "up": 110.0},
]

var _index: int = 0
var _elapsed: float = 0.0
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
	_elapsed += delta

	if Input.is_action_just_pressed("attack"):
		_buffered = true
	if Input.is_action_just_pressed("dash") and player.can_dash():
		return "dash"

	_update_hitbox_window()

	# Decelerate the lunge; hold ground or fall naturally.
	player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
	if player.is_on_floor():
		player.velocity.y = 0.0
	else:
		player.apply_gravity(delta)
	player.move_and_slide()

	# Swing finished by time.
	if _elapsed >= float(COMBO[_index]["dur"]):
		if _buffered and _index < COMBO.size() - 1:
			_index += 1
			_buffered = false
			_start_swing()
			return ""
		if not player.is_on_floor():
			return "fall"
		return "run" if absf(player.input_x) > 0.01 else "idle"
	return ""


func _start_swing() -> void:
	var step: Dictionary = COMBO[_index]
	_elapsed = 0.0
	_hit_live = false
	player.set_hitbox_active(false)
	player.sprite.play(step["anim"])
	player.sprite.frame = 0
	player.hitbox.damage = step["damage"]
	player.hitbox.knockback_force = step["knockback"]
	player.hitbox.knockback_up = step["up"]
	if player.is_on_floor():
		player.velocity.x = float(player.facing) * step["lunge"]

	player.play_sfx("swing", -9.0)
	var big := _index == COMBO.size() - 1
	var color := SlashEffect.HEAVY_COLOR if big else SlashEffect.LIGHT_COLOR
	var at := player.global_position + Vector2(float(player.facing) * 14.0, -16.0)
	SlashEffect.spawn(player.get_parent(), at, player.facing, big, color)


func _update_hitbox_window() -> void:
	var step: Dictionary = COMBO[_index]
	var want := _elapsed >= float(step["active"][0]) and _elapsed <= float(step["active"][1])
	if want and not _hit_live:
		player.set_hitbox_active(true)
		_hit_live = true
	elif not want and _hit_live:
		player.set_hitbox_active(false)
		_hit_live = false
