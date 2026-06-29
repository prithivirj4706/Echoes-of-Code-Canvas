## Hurtbox
##
## The *defensive* half of the combat pair: an Area2D that listens for incoming
## Hitboxes of an opposing faction, rolls the damage, computes a knockback
## vector pointing away from the attacker, and emits a single `hurt` event with
## everything the owner needs. The owner decides what to do (take damage, flash,
## stagger) — the hurtbox stays dumb and reusable.
##
## Scene setup: child CollisionShape2D; monitoring = true; collision_mask = the
## opposing faction's hitbox layer.
class_name Hurtbox
extends Area2D

## Emitted on a valid hit. info = { damage:int, is_crit:bool, knockback:Vector2, source:Hitbox }
signal hurt(info: Dictionary)

## 0 = Player, 1 = Enemy. Hits only register from the opposite faction.
@export_enum("Player", "Enemy") var faction: int = 1


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not (area is Hitbox):
		return
	var hitbox := area as Hitbox
	if hitbox.faction == faction:
		return  # same side — friendly, ignore

	var roll := hitbox.roll_damage()
	var dir := signf(global_position.x - hitbox.global_position.x)
	if dir == 0.0:
		dir = 1.0
	var knockback := Vector2(dir * hitbox.knockback_force, -hitbox.knockback_up)

	hurt.emit({
		"damage": roll["damage"],
		"is_crit": roll["is_crit"],
		"knockback": knockback,
		"source": hitbox,
	})
