## SentinelDrone
##
## A two-phase flying Digital-World enemy:
##
##   Phase 1 — GROUNDED: dormant. It rests on the floor and patrols / drifts
##   toward the player at ground level, dealing no damage. Easy to engage and
##   hit with normal melee.
##
##   Phase 2 — AIRBORNE: once the player has damaged it past `float_trigger`, it
##   "wakes up", lifts off, hovers above the player and fires energy bolts.
##
## It reuses the shared combat components (Hurtbox + HealthComponent) so the
## player's attacks damage it with no special casing, and it flashes, knocks
## back, and explodes on death.
##
## Setup: CharacterBody2D on the "Enemy" layer, collides with World. The player
## must be in the "player" group (Player adds itself on ready).
extends CharacterBody2D

enum Phase { GROUNDED, AIRBORNE, DEAD }

const PROJECTILE := preload("res://Scenes/Effects/EnemyProjectile.tscn")
const GRAVITY := 900.0

@export_group("Phase")
## Lifts off once HP fraction drops to/below this (0.6 = after ~40% damage).
@export_range(0.0, 1.0) var float_trigger: float = 0.6

@export_group("Grounded")
@export var ground_speed: float = 48.0
@export var patrol_range: float = 70.0

@export_group("Airborne")
## Height above the player's standing position to hover while engaging.
@export var hover_height: float = 42.0
@export var approach_gain: float = 4.0
@export var max_move_speed: float = 115.0
@export var bob_amplitude: float = 6.0
@export var bob_speed: float = 3.2

@export_group("Detection")
@export var detect_radius: float = 240.0
@export var lose_radius: float = 380.0

@export_group("Attack")
@export var fire_cooldown: float = 1.4
@export var projectile_damage: int = 4

@export_group("Reaction")
@export var knockback_friction: float = 600.0
@export var stun_time: float = 0.18

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _combat: Node = get_node_or_null("/root/Combat")

var _phase: Phase = Phase.GROUNDED
var _player: Node2D
var _spawn: Vector2
var _bob_t: float = 0.0
var _patrol_dir: int = 1
var _stun_timer: float = 0.0
var _fire_timer: float = 0.0
var _player_ground_y: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	_spawn = global_position
	_bob_t = randf() * TAU
	_fire_timer = randf() * fire_cooldown
	_acquire_player()
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	sprite.play("fly")


func _physics_process(delta: float) -> void:
	if _phase == Phase.DEAD:
		return
	_bob_t += delta

	# Knockback/stun briefly overrides movement so hits feel impactful.
	if _stun_timer > 0.0:
		_stun_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		return

	match _phase:
		Phase.GROUNDED:
			_grounded(delta)
		Phase.AIRBORNE:
			_airborne(delta)
	move_and_slide()
	_face()


# --- Phase 1: dormant ground sentinel ---------------------------------------
func _grounded(delta: float) -> void:
	velocity.y += GRAVITY * delta  # settle and stay on the floor
	if _player_in_range(detect_radius) and is_instance_valid(_player):
		# Drift toward the player along the ground.
		var dir := signf(_player.global_position.x - global_position.x)
		velocity.x = dir * ground_speed
	else:
		# Patrol around the spawn point.
		velocity.x = float(_patrol_dir) * ground_speed
		if absf(global_position.x - _spawn.x) > patrol_range:
			_patrol_dir = -1 if global_position.x > _spawn.x else 1


# --- Phase 2: airborne bolt-shooter -----------------------------------------
func _airborne(delta: float) -> void:
	if is_instance_valid(_player):
		if _player.has_method("is_on_floor") and _player.is_on_floor():
			_player_ground_y = _player.global_position.y
		var target := Vector2(_player.global_position.x, _player_ground_y - hover_height)
		var desired := (target - global_position) * approach_gain
		velocity = desired.limit_length(max_move_speed)
	else:
		_acquire_player()
		velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
	velocity.y += sin(_bob_t * bob_speed) * bob_amplitude * 0.25

	# Fire on a cooldown once it has line on the player.
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _player_in_range(lose_radius):
		_fire()
		_fire_timer = fire_cooldown


func _fire() -> void:
	if not is_instance_valid(_player):
		return
	var muzzle := global_position
	var aim := (_player.global_position + Vector2(0.0, -12.0)) - muzzle
	var bolt := PROJECTILE.instantiate()
	bolt.launch(aim, projectile_damage)
	get_parent().add_child(bolt)  # parent to the level (always valid)
	bolt.global_position = muzzle


func _lift_off() -> void:
	_phase = Phase.AIRBORNE
	_player_ground_y = _player.global_position.y if is_instance_valid(_player) else _spawn.y
	_fire_timer = 0.35
	velocity.y = -130.0  # a little pop as it wakes and rises


func _player_in_range(radius: float) -> bool:
	return is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= radius


func _acquire_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(_player):
		_player_ground_y = _player.global_position.y


## Drone art faces left; face the player, else face travel direction.
func _face() -> void:
	if is_instance_valid(_player):
		sprite.flip_h = _player.global_position.x > global_position.x
	elif absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0


func _on_hurt(info: Dictionary) -> void:
	if _phase == Phase.DEAD:
		return
	health.take_damage(info["damage"], info["is_crit"])
	velocity = info["knockback"]
	_stun_timer = stun_time
	_flash()
	_squash()
	DamageNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -34), info["damage"], info["is_crit"])
	if _combat != null:
		_combat.hit_feedback(info["damage"], info["is_crit"], global_position + Vector2(0, -16))
	# Wound it enough and it takes flight.
	if _phase == Phase.GROUNDED and health.is_alive() and health.fraction() <= float_trigger:
		_lift_off()


## Quick squash-and-stretch punch on the sprite — cheap, very juicy hit read.
func _squash() -> void:
	sprite.scale = Vector2(1.3, 0.72)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _flash() -> void:
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_amount", 1.0)
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.16
	)


func _on_died() -> void:
	_phase = Phase.DEAD
	velocity = Vector2.ZERO
	hurtbox.set_deferred("monitoring", false)
	var burst := get_node_or_null("DeathParticles")
	if burst != null:
		burst.restart()
	if _combat != null:
		_combat.shake(0.6)        # satisfying punch on the kill
		_combat.hitstop(0.11)     # heavier freeze so the kill lands
	var au := get_node_or_null("/root/Audio")
	if au != null:
		au.play("explosion", -4.0)
	sprite.play("explode")
	sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
