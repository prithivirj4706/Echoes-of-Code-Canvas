## EnemyProjectile (energy bolt)
##
## A travelling enemy attack. It IS a Hitbox (so the player's Hurtbox damages the
## player on contact, with no special casing), moves in a fixed direction, and
## despawns when it hits the player, hits the world, or its lifetime runs out.
##
## Setup: Area2D on the "EnemyHitbox" layer (so the player Hurtbox detects it);
## its mask includes World + Player so it knows when to despawn.
extends Hitbox

@export var speed: float = 150.0
@export var lifetime: float = 3.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _dir: Vector2 = Vector2.RIGHT
var _life: float = 0.0


## Call right after instancing, before/just after adding to the tree.
func launch(direction: Vector2, projectile_damage: int) -> void:
	_dir = direction.normalized()
	damage = projectile_damage


func _ready() -> void:
	# Override Hitbox._ready (which disables it) — a bolt is always "live".
	monitorable = true
	monitoring = true
	faction = 1  # enemy-owned
	_life = lifetime
	rotation = _dir.angle()
	body_entered.connect(_on_body_entered)
	if sprite != null:
		sprite.play("fly")


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(_body: Node) -> void:
	# Hit the player or a wall — the player's Hurtbox already applied damage if
	# this was the player; either way the bolt is spent.
	queue_free()
