## build_player_spriteframes.gd
##
## One-shot asset pipeline tool. Builds the player's SpriteFrames resource from
## the Adventurer individual-frame PNGs so we never hand-author atlas regions or
## frame lists. Re-run any time the source sprites change:
##
##   godot --headless --path . --script res://tools/build_player_spriteframes.gd
##
## Output: res://Resources/Player/aarin_frames.tres
extends SceneTree

const SRC_DIR := "res://Sprites/Characters/Player/Aarin/"
const OUT_PATH := "res://Resources/Player/aarin_frames.tres"

# anim name -> [source prefix, fps, loop]
const ANIMS := {
	"idle":        ["idle", 6.0, true],
	"idle_alt":    ["idle-2", 6.0, true],
	"run":         ["run", 12.0, true],
	"jump":        ["jump", 10.0, false],
	"fall":        ["fall", 8.0, true],
	"wall_slide":  ["crnr-grb", 8.0, true],
	"ledge_grab":  ["crnr-jmp", 8.0, false],
	"ledge_climb": ["crnr-clmb", 12.0, false],
	"dash":        ["smrslt", 14.0, false],
	"crouch":      ["crouch", 8.0, false],
	"slide":       ["slide", 10.0, false],
	"attack1":     ["attack1", 14.0, false],
	"attack2":     ["attack2", 14.0, false],
	"attack3":     ["attack3", 14.0, false],
	"hurt":        ["hurt", 10.0, false],
	"die":         ["die", 8.0, false],
	"stand":       ["stand", 8.0, false],
}


func _initialize() -> void:
	var all_files := _list_pngs(SRC_DIR)
	if all_files.is_empty():
		push_error("No PNGs found in %s" % SRC_DIR)
		quit(1)
		return

	var frames := SpriteFrames.new()
	# SpriteFrames always ships with a "default" animation; drop it for cleanliness.
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var total_frames := 0
	for anim_name in ANIMS:
		var spec: Array = ANIMS[anim_name]
		var prefix: String = spec[0]
		var fps: float = spec[1]
		var loop: bool = spec[2]

		var matched := _frames_for_prefix(all_files, prefix)
		if matched.is_empty():
			print("  (skip) %-12s — no frames for prefix '%s'" % [anim_name, prefix])
			continue

		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, loop)
		for file_name in matched:
			var tex: Texture2D = ResourceLoader.load(SRC_DIR + file_name)
			if tex == null:
				push_error("Failed to load texture: %s" % file_name)
				continue
			frames.add_frame(anim_name, tex)
		total_frames += matched.size()
		print("  %-12s -> %2d frames @ %2.0f fps  loop=%s" % [anim_name, matched.size(), fps, loop])

	var err := ResourceSaver.save(frames, OUT_PATH)
	if err != OK:
		push_error("ResourceSaver failed (%d) writing %s" % [err, OUT_PATH])
		quit(1)
		return
	print("\nSaved %s  (%d animations, %d frames)" % [OUT_PATH, frames.get_animation_names().size(), total_frames])
	quit(0)


## All PNG file names in a directory (no path), sorted.
func _list_pngs(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Cannot open dir: %s" % dir_path)
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.to_lower().ends_with(".png"):
			out.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


## File names matching exactly "adventurer-<prefix>-NN.png", in frame order.
func _frames_for_prefix(files: PackedStringArray, prefix: String) -> PackedStringArray:
	var re := RegEx.new()
	# Escape the prefix's hyphens are literal already; anchor digits + extension.
	re.compile("^adventurer-%s-\\d+\\.png$" % prefix)
	var matched := PackedStringArray()
	for f in files:
		if re.search(f) != null:
			matched.append(f)
	matched.sort()
	return matched
