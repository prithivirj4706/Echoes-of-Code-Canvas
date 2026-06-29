## SlashEffect
##
## A neon arc that flashes along the sword's path on each swing, then fades and
## frees itself. Built procedurally (a Line2D crescent) so it needs no art and
## reads instantly as Aarin's "digital blade". Spawn it per swing:
##   SlashEffect.spawn(parent, world_pos, facing, big, color)
class_name SlashEffect
extends Node2D

const LIGHT_COLOR := Color(0.45, 0.92, 1.0)   # Aarin blue
const HEAVY_COLOR := Color(1.0, 0.78, 0.35)   # finisher gold


static func spawn(parent: Node, world_pos: Vector2, facing: int, big: bool = false, color: Color = LIGHT_COLOR) -> void:
	if parent == null:
		return
	var fx := SlashEffect.new()
	parent.add_child(fx)
	fx.global_position = world_pos
	fx._play(facing, big, color)


func _play(facing: int, big: bool, color: Color) -> void:
	var radius := 30.0 if big else 22.0
	var line := Line2D.new()
	line.width = 5.0 if big else 3.5
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND

	# Taper the stroke toward both tips for a blade-swipe look.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.15))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.15))
	line.width_curve = curve

	# A vertical crescent bulging forward (downward swing).
	var pts := PackedVector2Array()
	for i in range(9):
		var t := lerpf(-1.0, 1.0, i / 8.0)
		var ang := deg_to_rad(t * 75.0)
		pts.append(Vector2(cos(ang) * radius, sin(ang) * radius))
	line.points = pts
	add_child(line)

	scale.x = float(facing)  # mirror to the swing direction

	# Quick punch-out: grow slightly and fade, then clean up.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(facing * 1.25, 1.25), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "modulate:a", 0.0, 0.16).set_delay(0.04)
	tween.chain().tween_callback(queue_free)
