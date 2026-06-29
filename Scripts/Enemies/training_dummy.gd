## TrainingDummy
##
## A combat target for tuning attack feel. Not real AI — it stands, takes hits,
## reacts (flash, knockback, damage numbers, hit feedback), shows a health bar,
## and respawns after death so iteration never stops. It exercises the full
## Hitbox→Hurtbox→HealthComponent + Combat-juice pipeline end to end.
extends CharacterBody2D

const GRAVITY := 900.0
const FRICTION := 700.0
const RESPAWN_DELAY := 1.4

@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: Node2D = $Visual
@onready var flash: ColorRect = $Visual/Flash
@onready var bar_fill: ColorRect = $HealthBar/Fill
## Resolved by path so the dummy runs in headless/test contexts without autoloads.
@onready var _combat: Node = get_node_or_null("/root/Combat")

var _spawn_point: Vector2
var _dead: bool = false


func _ready() -> void:
	_spawn_point = global_position
	hurtbox.hurt.connect(_on_hurt)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	flash.modulate.a = 0.0
	_on_health_changed(health.current, health.max_health)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	move_and_slide()


func _on_hurt(info: Dictionary) -> void:
	if _dead:
		return
	health.take_damage(info["damage"], info["is_crit"])
	velocity = info["knockback"]
	_play_flash()
	DamageNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -38), info["damage"], info["is_crit"])
	# The attacker's impact juice (spark + sound + hit-stop + shake).
	if _combat != null:
		_combat.hit_feedback(info["damage"], info["is_crit"], global_position + Vector2(0, -16))


func _play_flash() -> void:
	flash.modulate.a = 0.9
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.14)


func _on_health_changed(current: int, maximum: int) -> void:
	bar_fill.scale.x = float(current) / float(max(maximum, 1))


func _on_died() -> void:
	_dead = true
	hurtbox.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.15, 0.2)
	await tween.finished
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	_respawn()


func _respawn() -> void:
	global_position = _spawn_point
	velocity = Vector2.ZERO
	health.reset()
	visual.modulate.a = 1.0
	flash.modulate.a = 0.0
	hurtbox.monitoring = true
	_dead = false
