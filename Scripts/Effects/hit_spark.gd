## HitSpark
##
## A short radial burst at the exact point of impact — the "spark" that sells a
## hit landing. Procedural (Line2D rays), self-freeing. Crits are bigger/gold.
##   HitSpark.spawn(parent, world_pos, is_crit)
class_name HitSpark
extends Node2D


static func spawn(parent: Node, world_pos: Vector2, is_crit: bool = false) -> void:
	if parent == null:
		return
	var fx := HitSpark.new()
	parent.add_child(fx)
	fx.global_position = world_pos
	fx._play(is_crit)


func _play(is_crit: bool) -> void:
	var color := Color(1.0, 0.85, 0.4) if is_crit else Color(0.72, 0.96, 1.0)
	var rays := 8 if is_crit else 5
	var radius := 17.0 if is_crit else 11.0
	var base := randf() * TAU
	for i in rays:
		var ang := base + TAU * (float(i) / rays) + randf_range(-0.2, 0.2)
		var line := Line2D.new()
		line.width = 2.5
		line.default_color = color
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		var ray_len := radius * randf_range(0.7, 1.2)
		line.points = PackedVector2Array([Vector2(cos(ang), sin(ang)) * 3.0, Vector2(cos(ang), sin(ang)) * ray_len])
		add_child(line)

	scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)
