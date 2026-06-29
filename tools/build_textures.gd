## build_textures.gd — generates small procedural textures (rain streak, glow)
## so atmosphere effects need no external art.
##   godot --headless --path . --script res://tools/build_textures.gd
extends SceneTree

const DIR := "res://Sprites/World/Digital/Effects/"


func _initialize() -> void:
	_rain_streak()
	_soft_glow()
	quit()


func _rain_streak() -> void:
	var w := 2
	var h := 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / float(h - 1)
		var a := clampf(t * 1.15, 0.0, 1.0) * 0.85  # fades in toward the bottom
		for x in w:
			img.set_pixel(x, y, Color(0.72, 0.86, 1.0, a))
	img.save_png(DIR + "rain_streak.png")
	print("saved rain_streak.png")


func _soft_glow() -> void:
	var s := 16
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s, s) * 0.5
	for y in s:
		for x in s:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c) / (s * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a  # soft falloff
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	img.save_png(DIR + "soft_glow.png")
	print("saved soft_glow.png")
