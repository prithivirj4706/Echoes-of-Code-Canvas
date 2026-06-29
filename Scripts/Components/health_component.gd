## HealthComponent
##
## Reusable HP container for any entity (player, enemy, boss, breakable). Owns no
## visuals and no combat rules — it just tracks hit points and announces changes
## via signals so HUD bars, flash effects and AI can react independently.
class_name HealthComponent
extends Node

signal damaged(amount: int, is_crit: bool)
signal healed(amount: int)
signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 30
## Optional invulnerability after the entity reads this component (set by owner).
var current: int


func _ready() -> void:
	current = max_health


func take_damage(amount: int, is_crit: bool = false) -> void:
	if current <= 0 or amount <= 0:
		return
	current = maxi(current - amount, 0)
	damaged.emit(amount, is_crit)
	health_changed.emit(current, max_health)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0 or current <= 0:
		return
	current = mini(current + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current, max_health)


func reset() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func is_alive() -> bool:
	return current > 0


func fraction() -> float:
	return float(current) / float(max(max_health, 1))
