## DamageNumber
##
## A floating combat number that drifts up and fades out. Built entirely in code
## (no scene file) and self-destructs, so any system can spawn one with a single
## static call: DamageNumber.spawn(parent, world_pos, amount, is_crit).
class_name DamageNumber
extends Node2D

const NORMAL_COLOR := Color(0.92, 0.96, 1.0)
const CRIT_COLOR := Color(1.0, 0.82, 0.25)


static func spawn(parent: Node, world_pos: Vector2, amount: int, is_crit: bool) -> void:
	if parent == null:
		return
	var node := DamageNumber.new()
	node.global_position = world_pos
	parent.add_child(node)
	node._show(amount, is_crit)


func _show(amount: int, is_crit: bool) -> void:
	var label := Label.new()
	label.text = ("%d!" % amount) if is_crit else str(amount)
	label.add_theme_font_size_override("font_size", 12 if is_crit else 8)
	label.add_theme_color_override("font_color", CRIT_COLOR if is_crit else NORMAL_COLOR)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-12, -8)
	label.size = Vector2(24, 16)
	add_child(label)

	# A little horizontal scatter so stacked hits don't overlap perfectly.
	var drift_x := randf_range(-6.0, 6.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(drift_x, -20.0), 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.55).set_delay(0.15)
	tween.chain().tween_callback(queue_free)
