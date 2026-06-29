## Hurtbox
##
## The *defensive* half of the combat pair: an Area2D that registers hits from
## opposing-faction Hitboxes, rolls damage, computes knockback away from the
## attacker, and emits one `hurt` event. The owner decides how to react.
##
## Detection is robust: besides reacting to `area_entered`, it also SCANS its
## overlapping areas every physics frame. This catches the common case where a
## melee hitbox is toggled active while already overlapping (where area_entered
## alone may not re-fire) — the bug behind "my hits don't register". Each hitbox
## only lands once until it leaves and returns.
class_name Hurtbox
extends Area2D

signal hurt(info: Dictionary)

## 0 = Player, 1 = Enemy. Hits only register from the opposite faction.
@export_enum("Player", "Enemy") var faction: int = 1

## Hitbox instance ids already processed while currently overlapping.
var _seen: Dictionary = {}


func _ready() -> void:
	area_entered.connect(_try_hit)
	area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		_try_hit(area)


func _on_area_exited(area: Area2D) -> void:
	if area != null:
		_seen.erase(area.get_instance_id())


func _try_hit(area: Area2D) -> void:
	if not (area is Hitbox):
		return
	var hitbox := area as Hitbox
	if not hitbox.monitorable or hitbox.faction == faction:
		return
	var id := hitbox.get_instance_id()
	if _seen.has(id):
		return
	_seen[id] = true

	var roll := hitbox.roll_damage()
	var dir := signf(global_position.x - hitbox.global_position.x)
	if dir == 0.0:
		dir = 1.0
	hurt.emit({
		"damage": roll["damage"],
		"is_crit": roll["is_crit"],
		"knockback": Vector2(dir * hitbox.knockback_force, -hitbox.knockback_up),
		"source": hitbox,
	})
