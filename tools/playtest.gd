## playtest.gd — automated PLAYTEST harness.
##
## Drives the REAL player through scenarios using synthesized Input (the actual
## input -> state-machine -> physics path) and measures outcomes, so movement
## feel and combat can be self-verified without a human at the controls.
##
##   godot --headless --path . --script res://tools/playtest.gd
##
## Reports each scenario's metric + PASS/FAIL and exits non-zero on any failure.
extends SceneTree

const ACTIONS := [
	"move_left", "move_right", "move_up", "move_down",
	"jump", "dash", "attack", "attack_heavy", "interact",
]

var _level: Node
var _player: Player
var _drone: Node2D
var _scn := 0
var _t := -1
var _peak_y := 0.0
var _peak_vx := 0.0
var _x0 := 0.0
var _drone_hp0 := 0
var _jt := 0
var _ok := true


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


var _frame := 0


func _physics_process(_d: float) -> bool:
	_frame += 1
	if _frame > 900:
		print("  [SAFETY QUIT at scenario %d, t=%d]" % [_scn, _t])
		quit(1)
		return true
	if _player == null:
		_player = _level.get_node("Player") as Player
		_drone = _level.get_node("SentinelDrone0") as Node2D
		_reset()
		return false
	_t += 1
	match _scn:
		0: _jump()
		1: _run()
		2: _dash()
		3: _melee()
		4: _ranged()
		_:
			print("\nPLAYTEST: %s" % ("ALL PASS" if _ok else "FAILURES ABOVE"))
			quit(0 if _ok else 1)
			return true
	return false


# --- Scenarios --------------------------------------------------------------
func _jump() -> void:
	# Wait until grounded before starting (player is placed mid-air on reset).
	if _jt == 0 and not _player.is_on_floor():
		return
	_jt += 1
	if _jt == 1:
		_x0 = _player.global_position.y
		_peak_y = _x0
		Input.action_press("jump")
	_peak_y = minf(_peak_y, _player.global_position.y)
	# Hold jump the whole time (no early release = full, uncut jump) and read the
	# peak well after the apex.
	if _jt == 48:
		var h := _x0 - _peak_y
		Input.action_release("jump")
		_report("Jump height (full hold)", "%.0f px" % h, h > 40.0)


func _run() -> void:
	if _t == 0:
		Input.action_press("move_right")
	_peak_vx = maxf(_peak_vx, absf(_player.velocity.x))
	if _t == 40:
		_report("Run speed", "%.0f px/s" % _peak_vx, _peak_vx > 110.0)


func _dash() -> void:
	if _t == 0:
		_x0 = _player.global_position.x
		Input.action_press("dash")
	if _t == 1:
		Input.action_release("dash")
	if _t == 24:
		var dist := absf(_player.global_position.x - _x0)
		_report("Dash distance", "%.0f px" % dist, dist > 28.0)


func _melee() -> void:
	if _t == 0:
		_begin_combat("SentinelDrone0", 0, Vector2(18, -16))  # grounded
	_drive_combat("attack", 14, Vector2(18, -16))
	_judge_combat("Melee connects (grounded)", 80)


func _ranged() -> void:
	if _t == 0:
		_begin_combat("SentinelDrone1", 1, Vector2(70, -20))  # flying
	_drive_combat("attack_heavy", 18, Vector2(70, -20))
	_judge_combat("Ranged connects (flying)", 130)


func _begin_combat(node_name: String, phase: int, offset: Vector2) -> void:
	_player.set_facing(1)
	_drone = _level.get_node_or_null(node_name) as Node2D
	if is_instance_valid(_drone):
		_drone.set("_phase", phase)
		_drone.global_position = _player.global_position + offset
		_drone_hp0 = (_drone.get_node("Health") as HealthComponent).current


func _drive_combat(action: String, period: int, offset: Vector2) -> void:
	if is_instance_valid(_drone):
		_drone.global_position = _player.global_position + offset  # pin in reach
	if _t % period == 0:
		Input.action_press(action)
	elif _t % period == 1:
		Input.action_release(action)


## Ends the scenario the instant damage/death is detected (so it never over-kills
## and pokes a freed node).
func _judge_combat(label: String, timeout: int) -> void:
	var killed := not is_instance_valid(_drone)
	var damaged := (not killed) and (_drone.get_node("Health") as HealthComponent).current < _drone_hp0
	if killed or damaged:
		_report(label, "killed" if killed else "damaged", true)
	elif _t >= timeout:
		_report(label, "no damage", false)


# --- Framework --------------------------------------------------------------
func _report(name: String, metric: String, passed: bool) -> void:
	print("  %-28s %-14s %s" % [name, metric, "PASS" if passed else "FAIL"])
	if not passed:
		_ok = false
	_scn += 1
	_t = -1
	_reset()


func _reset() -> void:
	for a in ACTIONS:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	_peak_vx = 0.0
	if _player != null:
		# Open stretch: clear overhead (no platform to bonk) and ~100px of
		# horizontal room between the mid platform and the wall-jump shaft.
		_player.global_position = Vector2(540, 188)
		_player.velocity = Vector2.ZERO
		if _player.state_machine.has_state("idle"):
			_player.state_machine.transition_to("fall")
