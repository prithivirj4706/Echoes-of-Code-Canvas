## SentinelDrone
##
## A two-phase flying Digital-World enemy. It hovers via script (no gravity, no
## terrain collision) so it never gets stuck on platforms or props.
##
##   Phase 1 — LOW: a dormant sentinel hovering just above the player's head,
##   tracking horizontally. Deals no damage. Reachable by a standing/short
##   attack so it's easy to start the fight.
##
##   Phase 2 — HIGH: once damaged past `float_trigger` it rises and starts firing
##   energy bolts. Reachable with a jump-attack.
##
## Reuses Hurtbox + HealthComponent; flashes, squashes, knocks back, explodes.
extends CharacterBody2D

enum Phase { LOW, HIGH, DEAD }

const PROJECTILE := preload("res://Scenes/Effects/EnemyProjectile.tscn")
## Body height (above the player's feet) the drone hovers at in the low phase —
## roughly chest height so a horizontal slash connects.
const LOW_HEIGHT := 22.0

@export_group("Phase")
@export_range(0.0, 1.0) var float_trigger: float = 0.6

@export_group("Movement")
@export var patrol_speed: float = 40.0
@export var patrol_range: float = 70.0
@export var bob_amplitude: float = 6.0
@export var bob_speed: float = 3.2
## Hover height above the player's standing position once airborne.
@export var hover_height: float = 56.0
@export var approach_gain: float = 5.0
## Capped below the player's run speed so it can't endlessly outrun a chase.
@export var max_move_speed: float = 100.0

@export_group("Detection")
@export var detect_radius: float = 250.0
@export var lose_radius: float = 400.0

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

var _phase: Phase = Phase.LOW
var _player: Node2D
var _spawn: Vector2
var _bob_t: float = 0.0
var _patrol_dir: int = 1
var _stun_timer: float = 0.0
var _fire_timer: float = 0.0
var _player_ground_y: float = 0.0
## Per-drone standoffs: small in the low phase (melee range — you CAN hit it),
## larger in the airborne phase (ranged duel). Height jitter spreads them out.
var _melee_standoff: float = 18.0
var _range_standoff: float = 44.0
var _extra_height: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	_spawn = global_position
	_player_ground_y = global_position.y
	_bob_t = randf() * TAU
	_fire_timer = randf() * fire_cooldown
	_melee_standoff = 14.0 + randf() * 8.0    # within slash reach (low phase)
	_range_standoff = 36.0 + randf() * 22.0   # ranged duel distance (airborne)
	_extra_height = randf() * 16.0            # spread altitudes
	_acquire_player()
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	sprite.play("fly")


func _physics_process(delta: float) -> void:
	if _phase == Phase.DEAD:
		return
	_bob_t += delta

	if _stun_timer > 0.0:
		_stun_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		return

	if is_instance_valid(_player) and _player.has_method("is_on_floor") and _player.is_on_floor():
		_player_ground_y = _player.global_position.y

	match _phase:
		Phase.LOW:
			_phase_low()
		Phase.HIGH:
			_phase_high(delta)
	velocity += _separation()  # spread drones apart so they never stack
	move_and_slide()
	_face()


## Push away from nearby drones so multiple enemies don't pile on one point.
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other):
			continue
		var to: Vector2 = global_position - (other as Node2D).global_position
		var dist := to.length()
		if dist > 0.01 and dist < 36.0:
			push += to.normalized() * (36.0 - dist) * 3.0
	return push


func _phase_low() -> void:
	# Always follow the player, hovering BESIDE them at body height so a slash
	# connects — never overhead/inside them.
	if is_instance_valid(_player):
		_hover_to(_beside(LOW_HEIGHT, _melee_standoff))  # within melee reach
	else:
		_acquire_player()
		_patrol()


func _phase_high(delta: float) -> void:
	if not is_instance_valid(_player):
		_acquire_player()
		_patrol()
		return
	_hover_to(_beside(hover_height + _extra_height, _range_standoff))  # keep ranged distance
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_cooldown


## A hover point BESIDE the player: it holds a per-drone standoff on whichever
## side it's currently on, at body height. This keeps it out of the player's
## body (no overlap) and out of other drones (varied standoff), while sitting in
## the path of a horizontal slash when the player turns to face it.
func _beside(height: float, standoff: float) -> Vector2:
	var side := signf(global_position.x - _player.global_position.x)
	if side == 0.0:
		side = 1.0
	var tx := _player.global_position.x + side * standoff
	return Vector2(tx, _player_ground_y - height)


## Ease toward a hover point (slows as it arrives) + a faint bob.
func _hover_to(target: Vector2) -> void:
	var desired := (target - global_position) * approach_gain
	velocity = desired.limit_length(max_move_speed)
	velocity.y += sin(_bob_t * bob_speed) * bob_amplitude * 0.25


func _patrol() -> void:
	velocity.x = float(_patrol_dir) * patrol_speed
	if absf(global_position.x - _spawn.x) > patrol_range:
		_patrol_dir = -1 if global_position.x > _spawn.x else 1
	velocity.y = (_spawn.y - global_position.y) * 4.0 + sin(_bob_t * bob_speed) * bob_amplitude


func _fire() -> void:
	if not is_instance_valid(_player):
		return
	var muzzle := global_position
	var aim := (_player.global_position + Vector2(0.0, -12.0)) - muzzle
	var bolt := PROJECTILE.instantiate()
	bolt.launch(aim, projectile_damage)
	get_parent().add_child(bolt)
	bolt.global_position = muzzle


func _lift_off() -> void:
	_phase = Phase.HIGH
	_fire_timer = 0.35


func _player_in_range(radius: float) -> bool:
	return is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= radius


func _acquire_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(_player):
		_player_ground_y = _player.global_position.y


func _face() -> void:
	if is_instance_valid(_player):
		sprite.flip_h = _player.global_position.x > global_position.x
	elif absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0


func _on_hurt(info: Dictionary) -> void:
	if _phase == Phase.DEAD:
		return
	# Once airborne it can ONLY be hurt by ranged bolts — melee whiffs, forcing
	# the player to switch to shooting. (Bolts carry a launch() method; melee
	# hitboxes don't.) Grounded, it takes both.
	var source: Object = info.get("source")
	var is_ranged := source != null and source.has_method("launch")
	if _phase == Phase.HIGH and not is_ranged:
		# Melee bounces off a flying drone — show a deflect so it reads clearly.
		HitSpark.spawn(get_tree().current_scene, global_position + Vector2(0, -8), false)
		var au := get_node_or_null("/root/Audio")
		if au != null:
			au.play("hack", -14.0)  # soft "tink"
		return

	health.take_damage(info["damage"], info["is_crit"])
	velocity = info["knockback"]
	_stun_timer = stun_time
	_flash()
	_squash()
	DamageNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -34), info["damage"], info["is_crit"])
	if _combat != null:
		_combat.hit_feedback(info["damage"], info["is_crit"], global_position + Vector2(0, -16))
	if _phase == Phase.LOW and health.is_alive() and health.fraction() <= float_trigger:
		_lift_off()


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
		_combat.shake(0.6)
		_combat.hitstop(0.11)
	var au := get_node_or_null("/root/Audio")
	if au != null:
		au.play("explosion", -4.0)
	sprite.play("explode")
	sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
