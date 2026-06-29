## build_drone_spriteframes.gd
## Builds the Sentinel Drone's SpriteFrames from the warped-city drone + explosion
## frames.  godot --headless --path . --script res://tools/build_drone_spriteframes.gd
extends SceneTree

const OUT_PATH := "res://Resources/Enemies/drone_frames.tres"
const SHOT_PATH := "res://Resources/Enemies/shot_frames.tres"
const DRONE_DIR := "res://Sprites/World/Digital/Enemies/Drone/"
const BOOM_DIR := "res://Sprites/World/Digital/Effects/Explosion/"
const SHOT_DIR := "res://Sprites/World/Digital/Effects/Shot/"


func _initialize() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_anim(frames, "fly", DRONE_DIR, "drone", 4, 10.0, true)
	_add_anim(frames, "explode", BOOM_DIR, "enemy-explosion", 6, 16.0, false)
	_save(frames, OUT_PATH)

	var shot := SpriteFrames.new()
	if shot.has_animation("default"):
		shot.remove_animation("default")
	_add_anim(shot, "fly", SHOT_DIR, "shot", 3, 14.0, true)
	_save(shot, SHOT_PATH)
	quit(0)


func _save(res: SpriteFrames, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("save failed (%d): %s" % [err, path])
	else:
		print("Saved %s (%s)" % [path, str(res.get_animation_names())])


func _add_anim(frames: SpriteFrames, anim: String, dir: String, prefix: String, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in range(1, count + 1):
		var path := "%s%s-%d.png" % [dir, prefix, i]
		var tex: Texture2D = ResourceLoader.load(path)
		if tex == null:
			push_error("missing %s" % path)
			continue
		frames.add_frame(anim, tex)
	print("  %s -> %d frames" % [anim, frames.get_frame_count(anim)])
