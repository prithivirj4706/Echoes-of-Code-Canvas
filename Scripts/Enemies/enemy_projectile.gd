## Projectile (energy bolt)
##
## A travelling attack. It IS a Hitbox (so an opposing Hurtbox takes damage with
## no special casing), moves in a fixed direction, and despawns on contact or
## when its lifetime runs out. Faction + collision layers/mask are set per scene,
## so the SAME script powers both the enemy bolt and the player's bolt.
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
	# faction / layers come from the scene, so this works for player or enemy.
	monitorable = true
	monitoring = true
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
