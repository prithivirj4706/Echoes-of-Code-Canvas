## Hitbox
##
## The *offensive* half of the combat pair: an Area2D that deals damage to any
## Hurtbox of a different faction it overlaps. Attacks enable it only during
## their active frames (set_active), so swings have readable, intentional reach.
##
## Scene setup: child CollisionShape2D; monitorable = true, monitoring = false;
## collision_layer = the faction's hitbox layer (PlayerHitbox or EnemyHitbox);
## collision_mask = 0 (hurtboxes do the detecting).
class_name Hitbox
extends Area2D

## 0 = Player-owned, 1 = Enemy-owned. Only opposite factions connect.
@export_enum("Player", "Enemy") var faction: int = 0
@export var damage: int = 6
@export var knockback_force: float = 180.0
@export var knockback_up: float = 70.0
@export_range(0.0, 1.0) var crit_chance: float = 0.15
@export var crit_multiplier: float = 2.0


func _ready() -> void:
	set_active(false)


## Enable/disable the hitbox for the active window of an attack.
##
## We toggle the COLLISION SHAPE, not just `monitorable`: flipping monitorable on
## a stationary, already-overlapping area does NOT make the physics server
## register the overlap (no enter event fires), so a standing melee swing would
## never connect. Enabling the shape re-adds it to the broadphase, which fires
## the overlap and lets the target's Hurtbox detect it.
func set_active(active: bool) -> void:
	monitorable = active
	var shape := get_node_or_null("CollisionShape2D")
	if shape != null:
		shape.set_deferred("disabled", not active)


## Roll this swing's damage, applying a crit if it procs.
func roll_damage() -> Dictionary:
	var is_crit := randf() < crit_chance
	var dmg := damage
	if is_crit:
		dmg = int(round(damage * crit_multiplier))
	return {"damage": dmg, "is_crit": is_crit}
