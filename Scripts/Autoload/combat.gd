## Combat (autoload singleton)
##
## Central hub for impact "juice" so every attack across the game feels
## consistent: hit-stop (a few frozen frames on contact) and screen shake,
## both scaled by how hard the hit was. Decoupled from any specific entity —
## anything that lands a hit just calls Combat.hit_feedback(...).
extends Node

## Guards against stacking hit-stops (the first one owns the freeze).
var _stopping: bool = false


## One call for a landed hit: spark + sound + hit-stop + shake, scaled by damage.
## Pass the world position of the impact to spawn a hit-spark there.
func hit_feedback(damage: int, is_crit: bool = false, position: Vector2 = Vector2.INF) -> void:
	var power := clampf(float(damage) / 20.0, 0.15, 1.0)
	var stop := 0.05 + 0.10 * power + (0.04 if is_crit else 0.0)
	var trauma := 0.25 + 0.45 * power + (0.25 if is_crit else 0.0)

	var au := get_node_or_null("/root/Audio")
	if au != null:
		au.play("crit" if is_crit else "hit", -5.0)
	if position != Vector2.INF:
		HitSpark.spawn(get_tree().current_scene, position, is_crit)

	shake(trauma)
	hitstop(stop)


## Freeze game time for `duration` real seconds (hit-stop). Uses an
## ignore-time-scale timer so it still fires while time_scale is 0.
func hitstop(duration: float) -> void:
	if _stopping or duration <= 0.0:
		return
	_stopping = true
	Engine.time_scale = 0.0
	# create_timer(time, process_always, process_in_physics, ignore_time_scale)
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


## Add trauma to the active camera if it supports shaking.
func shake(trauma: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_trauma"):
		cam.add_trauma(trauma)
