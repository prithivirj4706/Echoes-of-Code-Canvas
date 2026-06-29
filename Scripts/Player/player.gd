## Player
##
## The protagonist body (Aarin in the Digital World). This is intentionally a
## thin coordinator: it owns the physics body, the per-frame input snapshot, the
## forgiveness timers (coyote / jump-buffer / dash-cooldown) and the low-level
## movement helpers. ALL behavioural decisions live in the state machine — this
## script never decides "what the player is doing", only "how to move/sense".
##
## Required project setup:
##   * Input actions: move_left, move_right, move_up, move_down, jump, dash,
##     attack, interact (defined in project.godot).
##   * Physics: this body is on layer "Player"; it collides with "World" and
##     "OneWay". Gravity is driven entirely in code (project default_gravity=0).
class_name Player
extends CharacterBody2D

signal facing_changed(facing: int)

@export var config: MovementConfig

# --- Scene references --------------------------------------------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var wall_ray_right: RayCast2D = $Sensors/WallRayRight
@onready var wall_ray_left: RayCast2D = $Sensors/WallRayLeft
@onready var ledge_ray_high: RayCast2D = $Sensors/LedgeRayHigh
@onready var ledge_ray_low: RayCast2D = $Sensors/LedgeRayLow
## Points straight down, masked to the OneWay layer only, so we can tell when
## the player is standing specifically on a drop-through platform.
@onready var floor_probe: RayCast2D = $Sensors/FloorProbe
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $Health
## Resolved by path (not the global identifier) so the player stays compilable
## and runnable in headless/test contexts where autoloads aren't registered.
@onready var _combat: Node = get_node_or_null("/root/Combat")

## 1-based index of the "OneWay" physics layer (see project.godot layer_names).
const ONE_WAY_LAYER := 9
## Invulnerability granted after taking a hit (seconds).
const HIT_INVULN := 0.6

# --- Live movement state (read/written by states) ----------------------------
## Direction the character is visually facing: -1 left, +1 right.
var facing: int = 1
var air_jumps_left: int = 0
var air_dashes_left: int = 0

# --- Per-frame input snapshot ------------------------------------------------
var input_x: float = 0.0
var input_y: float = 0.0
var jump_held: bool = false
var jump_released: bool = false

# --- Forgiveness timers (seconds, counted down) ------------------------------
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _wall_coyote_timer: float = 0.0
var _wall_coyote_dir: int = 0
var _dash_cooldown_timer: float = 0.0
var _drop_through_timer: float = 0.0
var _invuln_timer: float = 0.0
var _hitbox_reach: float = 14.0
var _spawn_point: Vector2
var _was_on_floor: bool = false


func _ready() -> void:
	if config == null:
		# Fail loud but stay runnable so the scene never silently breaks.
		config = MovementConfig.new()
		push_warning("Player has no MovementConfig assigned; using defaults.")
	add_to_group("player")  # enemies locate the player via this group
	up_direction = Vector2.UP
	air_jumps_left = config.max_air_jumps
	air_dashes_left = config.max_air_dashes
	_hitbox_reach = absf(hitbox.position.x)
	_spawn_point = global_position
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	state_machine.setup(self)


func _physics_process(delta: float) -> void:
	# Runs before the StateMachine child each frame, so states always read a
	# fresh input snapshot and up-to-date timers.
	_sample_input()
	_update_timers(delta)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _sample_input() -> void:
	input_x = Input.get_axis("move_left", "move_right")
	input_y = Input.get_axis("move_up", "move_down")
	jump_held = Input.is_action_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	if Input.is_action_just_pressed("jump"):
		# Down + jump while stood on a one-way platform = drop through it,
		# and the press is consumed instead of buffering a jump.
		if is_on_floor() and Input.is_action_pressed("move_down") \
				and floor_probe != null and floor_probe.is_colliding():
			_start_drop_through()
		else:
			_jump_buffer_timer = config.jump_buffer_time


func _start_drop_through() -> void:
	set_collision_mask_value(ONE_WAY_LAYER, false)
	_drop_through_timer = 0.18
	velocity.y = maxf(velocity.y, 16.0)


func _update_timers(delta: float) -> void:
	var on_floor := is_on_floor()

	# Coyote time: full grace while grounded, drains once we leave the ground.
	if on_floor:
		_coyote_timer = config.coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	# Reset air budgets the instant we land.
	if on_floor and not _was_on_floor:
		air_jumps_left = config.max_air_jumps
		air_dashes_left = config.max_air_dashes
	_was_on_floor = on_floor

	# Wall coyote: remember the last wall we touched for a short grace window.
	var wall_dir := get_wall_dir()
	if wall_dir != 0 and not on_floor:
		_wall_coyote_timer = config.wall_coyote_time
		_wall_coyote_dir = wall_dir
	else:
		_wall_coyote_timer = maxf(_wall_coyote_timer - delta, 0.0)

	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)

	# Restore one-way collision once the drop-through grace expires.
	if _drop_through_timer > 0.0:
		_drop_through_timer = maxf(_drop_through_timer - delta, 0.0)
		if _drop_through_timer == 0.0:
			set_collision_mask_value(ONE_WAY_LAYER, true)

	_invuln_timer = maxf(_invuln_timer - delta, 0.0)


# ---------------------------------------------------------------------------
# Movement helpers (called by states)
# ---------------------------------------------------------------------------

## Accelerate/decelerate horizontal velocity toward the input target with a
## snappy turn-around boost. `accel`/`decel` let air states soften control.
func apply_horizontal(delta: float, accel: float, decel: float) -> void:
	if absf(input_x) > 0.01:
		var target := input_x * config.run_speed
		var rate := accel
		# Reversing direction? Boost the rate so turns feel responsive.
		if signf(input_x) != signf(velocity.x) and absf(velocity.x) > 1.0:
			rate *= config.turn_around_multiplier
		velocity.x = move_toward(velocity.x, target, rate * delta)
		set_facing(int(signf(input_x)))
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


## Gravity with separate rise/fall strengths and an apex "hang time" softener.
func apply_gravity(delta: float) -> void:
	var g := config.get_fall_gravity() if velocity.y > 0.0 else config.get_rise_gravity()
	if absf(velocity.y) < config.apex_velocity_threshold:
		g *= config.apex_gravity_multiplier
	velocity.y += g * delta
	velocity.y = minf(velocity.y, config.max_fall_speed)


func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing:
		return
	facing = dir
	sprite.flip_h = facing < 0
	# Keep the attack hitbox in front of the character.
	hitbox.position.x = facing * _hitbox_reach
	facing_changed.emit(facing)


# ---------------------------------------------------------------------------
# Jump API
# ---------------------------------------------------------------------------
func ground_jump() -> void:
	velocity.y = config.get_jump_velocity()
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func air_jump() -> void:
	velocity.y = config.get_air_jump_velocity()
	air_jumps_left -= 1
	_jump_buffer_timer = 0.0


func wall_jump(wall_dir: int) -> void:
	# Launch up and away from the wall.
	velocity.y = config.get_wall_jump_velocity()
	velocity.x = -wall_dir * config.wall_jump_push
	set_facing(-wall_dir)
	_wall_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


## Variable jump height: shorten the arc when the button is released early.
func try_jump_cut() -> void:
	if jump_released and velocity.y < 0.0:
		velocity.y *= config.jump_release_cut


## If a jump is buffered and a wall (or wall-coyote grace) is available, perform
## the wall jump and report success so the calling state can transition.
func try_wall_jump() -> bool:
	if not has_buffered_jump():
		return false
	var dir := get_wall_dir()
	if dir == 0 and can_wall_coyote_jump():
		dir = get_wall_coyote_dir()
	if dir == 0:
		return false
	wall_jump(dir)
	return true


# ---------------------------------------------------------------------------
# Queries used by states
# ---------------------------------------------------------------------------
func has_buffered_jump() -> bool:
	return _jump_buffer_timer > 0.0

func can_coyote_jump() -> bool:
	return _coyote_timer > 0.0

func can_air_jump() -> bool:
	return air_jumps_left > 0

func can_wall_coyote_jump() -> bool:
	return _wall_coyote_timer > 0.0

func get_wall_coyote_dir() -> int:
	return _wall_coyote_dir

func can_dash() -> bool:
	if _dash_cooldown_timer > 0.0:
		return false
	if is_on_floor():
		return true
	return air_dashes_left > 0

## Enable/disable the attack hitbox (called by AttackState during active frames).
func set_hitbox_active(active: bool) -> void:
	hitbox.set_active(active)


## True the frame the attack button was pressed — used by states to enter Attack.
func wants_attack() -> bool:
	return Input.is_action_just_pressed("attack")


## Incoming damage handler (i-frames respected). Applies knockback + feedback.
func _on_hurt(info: Dictionary) -> void:
	if _invuln_timer > 0.0 or not health.is_alive():
		return
	health.take_damage(info["damage"], info["is_crit"])
	velocity = info["knockback"]
	_invuln_timer = HIT_INVULN
	if _combat != null:
		_combat.hit_feedback(info["damage"], info["is_crit"])
	_flash_invuln()


## Health hit zero — hand control to the death state.
func _on_died() -> void:
	if state_machine.has_state("dead"):
		state_machine.transition_to("dead")


## Reset to the spawn point with full health (called by DeadState).
func respawn() -> void:
	global_position = _spawn_point
	velocity = Vector2.ZERO
	health.reset()
	hurtbox.monitoring = true
	sprite.modulate.a = 1.0
	air_jumps_left = config.max_air_jumps
	air_dashes_left = config.max_air_dashes
	_invuln_timer = HIT_INVULN  # brief grace so you don't instantly die again


## Brief blink while invulnerable for clear damage feedback.
func _flash_invuln() -> void:
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)


func start_dash_cooldown() -> void:
	_dash_cooldown_timer = config.dash_cooldown
	if not is_on_floor():
		air_dashes_left -= 1

## Direction of an adjacent wall the player is pressed against: -1, 0 or +1.
func get_wall_dir() -> int:
	if wall_ray_right != null and wall_ray_right.is_colliding():
		return 1
	if wall_ray_left != null and wall_ray_left.is_colliding():
		return -1
	return 0

## True when a grabbable ledge is detected on the facing side: the lower sensor
## hits a wall while the upper sensor sees open space above it.
func detect_ledge() -> bool:
	if not config.ledge_grab_enabled:
		return false
	_aim_ledge_sensors()
	if ledge_ray_low == null or ledge_ray_high == null:
		return false
	ledge_ray_low.force_raycast_update()
	ledge_ray_high.force_raycast_update()
	return ledge_ray_low.is_colliding() and not ledge_ray_high.is_colliding()

## World-space top of the ledge we're grabbing (for snapping the climb).
func get_ledge_point() -> Vector2:
	if ledge_ray_low != null and ledge_ray_low.is_colliding():
		return ledge_ray_low.get_collision_point()
	return global_position

func _aim_ledge_sensors() -> void:
	if ledge_ray_high == null or ledge_ray_low == null:
		return
	var reach := absf(ledge_ray_low.target_position.x)
	ledge_ray_low.target_position.x = facing * reach
	reach = absf(ledge_ray_high.target_position.x)
	ledge_ray_high.target_position.x = facing * reach
