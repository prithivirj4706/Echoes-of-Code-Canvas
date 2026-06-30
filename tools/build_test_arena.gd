## build_test_arena.gd
##
## Builds the Digital World vertical-slice level (TestArena.tscn) in code so it's
## reproducible and reviewable: geometry, enemies, the hack gate, Echo Fragments,
## dense cyberpunk decoration (props + vehicles + animated signs/holograms), the
## parallax skyline, atmosphere (rain, motes, CRT), HUD and pause menu.
##
##   godot --headless --path . --script res://tools/build_test_arena.gd
extends SceneTree

const OUT_PATH := "res://Scenes/Levels/TestArena.tscn"
const PLAYER_SCENE := "res://Scenes/Characters/Player/Player.tscn"
const DRONE_SCENE := "res://Scenes/Characters/Enemies/SentinelDrone.tscn"
const DUMMY_SCENE := "res://Scenes/Characters/Enemies/TrainingDummy.tscn"
const BG_DIR := "res://Sprites/World/Digital/Backgrounds/"
const PROP_DIR := "res://Sprites/World/Digital/Props/"
const VEH_DIR := "res://Sprites/World/Digital/Vehicles/"

const WORLD_LAYER := 1
const ONE_WAY_BIT := 256
const GROUND_Y := 200.0   # top of the ground floor

const PANEL := Color(0.082, 0.094, 0.180)
const NEON := Color(0.28, 0.85, 1.0)
const NEON_ONEWAY := Color(0.62, 0.45, 1.0)

var _root: Node2D
var _geo: Node2D


func _initialize() -> void:
	_root = Node2D.new()
	_root.name = "TestArena"

	_build_parallax()
	_decorate()
	_ambient_motes()

	_geo = Node2D.new()
	_geo.name = "Geometry"
	_root.add_child(_geo)
	_owned(_geo)
	_build_geometry()

	_spawn_entities()
	_build_hack_gate()
	_build_hud()
	_build_atmosphere()

	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err != OK:
		push_error("pack() failed: %d" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, OUT_PATH)
	if err != OK:
		push_error("save() failed: %d" % err)
		quit(1)
		return
	print("Saved %s" % OUT_PATH)
	quit(0)


# ---------------------------------------------------------------------------
# Geometry — a wider level: start plaza, parkour, wall-jump shaft, reward zone
# ---------------------------------------------------------------------------
func _build_geometry() -> void:
	_solid(Vector2(530, 224), Vector2(1180, 48))   # continuous ground
	_solid(Vector2(-56, 110), Vector2(32, 300))    # left wall
	_solid(Vector2(1116, 110), Vector2(32, 300))   # right wall

	_solid(Vector2(180, 176), Vector2(70, 16))     # low step
	_solid(Vector2(310, 140), Vector2(80, 14))     # platform
	_one_way(Vector2(250, 116), Vector2(80, 12))   # drop-through
	_solid(Vector2(440, 150), Vector2(96, 16))     # mid platform

	_solid(Vector2(600, 120), Vector2(24, 180))    # wall-jump shaft (left)
	_solid(Vector2(688, 120), Vector2(24, 180))    # wall-jump shaft (right)
	_solid(Vector2(644, 40), Vector2(96, 14))      # high reward platform

	_solid(Vector2(800, 162), Vector2(86, 16))     # ascent
	_solid(Vector2(910, 126), Vector2(80, 14))


# ---------------------------------------------------------------------------
# Entities
# ---------------------------------------------------------------------------
func _spawn_entities() -> void:
	var ps: PackedScene = ResourceLoader.load(PLAYER_SCENE)
	if ps == null:
		push_error("no player scene"); quit(1); return
	var player := ps.instantiate()
	player.name = "Player"
	player.position = Vector2(60, 182)
	_root.add_child(player)
	_owned(player)

	var drone_scene: PackedScene = ResourceLoader.load(DRONE_SCENE)
	if drone_scene != null:
		var dspots := [Vector2(360, 150), Vector2(740, 130), Vector2(1050, 150)]
		for i in dspots.size():
			var d := drone_scene.instantiate()
			d.name = "SentinelDrone%d" % i
			d.position = dspots[i]
			_root.add_child(d)
			_owned(d)

	var dummy_scene: PackedScene = ResourceLoader.load(DUMMY_SCENE)
	if dummy_scene != null:
		var mspots := [Vector2(470, 199), Vector2(644, 24)]
		for i in mspots.size():
			var m := dummy_scene.instantiate()
			m.name = "TrainingDummy%d" % i
			m.position = mspots[i]
			_root.add_child(m)
			_owned(m)

	# Free-standing Echo Fragments (the gated one is created in _build_hack_gate).
	_fragment(Vector2(250, 100))
	_fragment(Vector2(644, 26))


func _build_hack_gate() -> void:
	var door_scene: PackedScene = ResourceLoader.load("res://Scenes/World/HackDoor.tscn")
	var term_scene: PackedScene = ResourceLoader.load("res://Scenes/World/HackTerminal.tscn")
	if door_scene == null or term_scene == null:
		return
	var door := door_scene.instantiate()
	door.name = "HackDoor"
	door.position = Vector2(1004, 177)
	_root.add_child(door)
	_owned(door)

	var term := term_scene.instantiate()
	term.name = "HackTerminal"
	term.position = Vector2(960, 200)
	_root.add_child(term)
	_owned(term)
	term.target_path = term.get_path_to(door)

	_fragment(Vector2(1060, 186), "EchoFragment")  # reward behind the door


func _fragment(pos: Vector2, node_name: String = "") -> void:
	var frag_scene: PackedScene = ResourceLoader.load("res://Scenes/World/EchoFragment.tscn")
	if frag_scene == null:
		return
	var f := frag_scene.instantiate()
	if node_name != "":
		f.name = node_name
	f.position = pos
	_root.add_child(f)
	_owned(f)


# ---------------------------------------------------------------------------
# Decoration — dense cyberpunk dressing using the full prop + vehicle set
# ---------------------------------------------------------------------------
func _decorate() -> void:
	var decor := Node2D.new()
	decor.name = "Decor"
	_root.add_child(decor)
	_owned(decor)

	# Parked vehicles standing on the street (bottom-anchored to the ground).
	_ground_sprite(decor, VEH_DIR + "v-truck.png", 270, -4, 0.42)
	_ground_sprite(decor, VEH_DIR + "v-police.png", 720, -4, 0.55)
	_ground_sprite(decor, VEH_DIR + "v-red.png", 150, -4, 0.6)
	_ground_sprite(decor, VEH_DIR + "v-yellow.png", 1000, -4, 0.6)

	# Antennas standing on the ground.
	for x in [30, 545, 1090]:
		_ground_sprite(decor, PROP_DIR + "antenna.png", x, -3, 1.0)

	# Animated neon signs standing on the ground (bottom-anchored).
	_ground_anim(decor, _frames("banner-neon", 4), 90, 5.0, -3)
	_ground_anim(decor, _frames("banner-neon", 4), 470, 5.0, -3)
	_ground_anim(decor, _frames("banner-scroll", 4), 1040, 5.0, -3)

	# Signs hung UNDER real platforms (anchored to geometry, not floating).
	_hang(decor, PROP_DIR + "hotel-sign.png", Vector2(644, 64))   # below high platform (y40)
	_hang(decor, PROP_DIR + "banners.png", Vector2(440, 180))     # below mid platform (y150)
	_hang(decor, PROP_DIR + "banner-open.png", Vector2(310, 162)) # below platform B (y140)
	_hang(decor, PROP_DIR + "banner-small.png", Vector2(800, 184))# below ascent (y162)

	# Floating holograms — these legitimately hover.
	var face := _frames("monitor-face", 4)
	_anim_sprite(decor, face, Vector2(360, 96), 6.0, -2, 1.4)
	_anim_sprite(decor, face, Vector2(910, 92), 6.0, -2, 1.4)


func _frames(prefix: String, count: int) -> Array:
	var out := []
	for i in range(1, count + 1):
		out.append("%s-%d.png" % [prefix, i])
	return out


func _ambient_motes() -> void:
	var motes := CPUParticles2D.new()
	motes.name = "DataMotes"
	motes.position = Vector2(540, 215)
	motes.z_index = -2
	motes.amount = 70
	motes.lifetime = 5.0
	motes.local_coords = false
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(620, 24)
	motes.direction = Vector2(0, -1)
	motes.spread = 18.0
	motes.gravity = Vector2(0, -5)
	motes.initial_velocity_min = 5.0
	motes.initial_velocity_max = 16.0
	motes.scale_amount_min = 0.6
	motes.scale_amount_max = 1.4
	motes.color = Color(0.4, 0.85, 1.0, 0.5)
	_root.add_child(motes)
	_owned(motes)


func _build_atmosphere() -> void:
	for path in ["res://Scenes/Effects/Rain.tscn", "res://Scenes/Effects/ScreenFX.tscn"]:
		var s: PackedScene = ResourceLoader.load(path)
		if s != null:
			var n := s.instantiate()
			_root.add_child(n)
			_owned(n)


func _build_parallax() -> void:
	var bg := ParallaxBackground.new()
	bg.name = "ParallaxBackground"
	_root.add_child(bg)
	_owned(bg)
	var layers := [
		["skyline-a.png", 0.12, -30.0],
		["buildings-bg.png", 0.35, 60.0],
		["near-buildings-bg.png", 0.62, 40.0],
	]
	for spec in layers:
		var tex: Texture2D = ResourceLoader.load(BG_DIR + spec[0])
		if tex == null:
			continue
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(spec[1], 1.0)
		layer.motion_mirroring = Vector2(tex.get_width(), 0)
		bg.add_child(layer)
		_owned(layer)
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.position = Vector2(0, spec[2])
		layer.add_child(spr)
		_owned(spr)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Tips"
	_root.add_child(canvas)
	_owned(canvas)
	var label := Label.new()
	label.name = "Controls"
	label.position = Vector2(8, 250)
	label.add_theme_font_size_override("font_size", 7)
	label.text = "A/D move  •  Space jump  •  Shift dash  •  J melee  •  I/RMB shoot  •  E hack  •  Esc pause"
	canvas.add_child(label)
	_owned(label)
	for path in ["res://Scenes/UI/HUD.tscn", "res://Scenes/UI/PauseMenu.tscn"]:
		var s: PackedScene = ResourceLoader.load(path)
		if s != null:
			var n := s.instantiate()
			_root.add_child(n)
			_owned(n)


# ---------------------------------------------------------------------------
# Builders / helpers
# ---------------------------------------------------------------------------
func _owned(n: Node) -> void:
	n.owner = _root


func _solid(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = center
	_geo.add_child(body)
	_owned(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	_owned(col)
	_panel_visual(body, size, NEON)


func _one_way(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = ONE_WAY_BIT
	body.collision_mask = 0
	body.position = center
	_geo.add_child(body)
	_owned(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.one_way_collision = true
	body.add_child(col)
	_owned(col)
	_panel_visual(body, size, NEON_ONEWAY)


func _panel_visual(body: Node, size: Vector2, edge: Color) -> void:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var fill := ColorRect.new()
	fill.color = PANEL
	fill.size = size
	fill.position = -size * 0.5
	fill.z_index = -1
	body.add_child(fill)
	_owned(fill)
	var bevel := ColorRect.new()
	bevel.color = Color(PANEL.r + 0.05, PANEL.g + 0.06, PANEL.b + 0.09, 1.0)
	bevel.size = Vector2(size.x, 3.0)
	bevel.position = Vector2(-hx, -hy + 2.0)
	body.add_child(bevel)
	_owned(bevel)
	_rect(body, Vector2(-hx, -hy), Vector2(size.x, 2.0), edge)
	_rect(body, Vector2(-hx, hy - 1.0), Vector2(size.x, 1.0), Color(edge.r, edge.g, edge.b, 0.30))
	var tick := 4.0
	_rect(body, Vector2(-hx, -hy), Vector2(tick, 3.0), edge)
	_rect(body, Vector2(hx - tick, -hy), Vector2(tick, 3.0), edge)


func _rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.color = color
	r.size = size
	r.position = pos
	parent.add_child(r)
	_owned(r)


func _sprite(parent: Node, path: String, pos: Vector2, z: int = -3, scale_v: float = 1.0, modulate_v: float = 0.92) -> void:
	var tex: Texture2D = ResourceLoader.load(path)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.z_index = z
	s.scale = Vector2(scale_v, scale_v)
	s.modulate = Color(modulate_v, modulate_v, modulate_v, 1.0)
	parent.add_child(s)
	_owned(s)


## Static sprite standing on the ground (bottom edge at GROUND_Y).
func _ground_sprite(parent: Node, path: String, x: float, z: int, scale_v: float) -> void:
	var tex: Texture2D = ResourceLoader.load(path)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(scale_v, scale_v)
	s.z_index = z
	s.modulate = Color(0.92, 0.92, 0.92, 1.0)
	s.position = Vector2(x, GROUND_Y - tex.get_height() * scale_v * 0.5)
	parent.add_child(s)
	_owned(s)


## Animated sign standing on the ground (bottom edge at GROUND_Y).
func _ground_anim(parent: Node, files: Array, x: float, fps: float, z: int) -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("loop")
	sf.set_animation_speed("loop", fps)
	sf.set_animation_loop("loop", true)
	var h := 0
	for file in files:
		var tex: Texture2D = ResourceLoader.load(PROP_DIR + file)
		if tex != null:
			sf.add_frame("loop", tex)
			h = max(h, tex.get_height())
	if sf.get_frame_count("loop") == 0:
		return
	var a := AnimatedSprite2D.new()
	a.sprite_frames = sf
	a.animation = "loop"
	a.autoplay = "loop"
	a.z_index = z
	a.position = Vector2(x, GROUND_Y - h * 0.5)
	parent.add_child(a)
	_owned(a)


## A sign hung just below a platform.
func _hang(parent: Node, path: String, pos: Vector2) -> void:
	_sprite(parent, path, pos, -2, 1.0)


func _anim_sprite(parent: Node, files: Array, pos: Vector2, fps: float, z: int, alpha: float) -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("loop")
	sf.set_animation_speed("loop", fps)
	sf.set_animation_loop("loop", true)
	var any := false
	for file in files:
		var tex: Texture2D = ResourceLoader.load(PROP_DIR + file)
		if tex != null:
			sf.add_frame("loop", tex)
			any = true
	if not any:
		return
	var a := AnimatedSprite2D.new()
	a.sprite_frames = sf
	a.animation = "loop"
	a.autoplay = "loop"
	a.position = pos
	a.z_index = z
	a.modulate = Color(1, 1, 1, alpha)
	parent.add_child(a)
	_owned(a)
