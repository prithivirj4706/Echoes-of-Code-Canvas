## build_test_arena.gd
##
## Generates the movement greybox playground (TestArena.tscn) in code so the
## scene is reproducible and reviewable. This is a deliberate *prototype* level
## for tuning movement feel — proper authored TileMap terrain arrives in the
## Level Design phase. The visuals are on-theme greybox for the Digital World:
## dark panels with cold neon edges, backed by the cyberpunk parallax skyline.
##
##   godot --headless --path . --script res://tools/build_test_arena.gd
extends SceneTree

const OUT_PATH := "res://Scenes/Levels/TestArena.tscn"
const PLAYER_SCENE := "res://Scenes/Characters/Player/Player.tscn"
const BG_DIR := "res://Sprites/World/Digital/Backgrounds/"
const PROP_DIR := "res://Sprites/World/Digital/Props/"

const WORLD_LAYER := 1            # "World"
const ONE_WAY_BIT := 256          # layer 9 -> 1 << 8

const PANEL := Color(0.082, 0.094, 0.180)       # cold dark panel
const PANEL_EDGE := Color(0.05, 0.055, 0.11)    # darker base
const NEON := Color(0.28, 0.85, 1.0)            # Aarin's signature blue
const NEON_ONEWAY := Color(0.62, 0.45, 1.0)     # purple = pass-through

var _root: Node2D


func _initialize() -> void:
	_root = Node2D.new()
	_root.name = "TestArena"

	_build_parallax()
	_decorate()
	_ambient_motes()
	var geo := Node2D.new()
	geo.name = "Geometry"
	_root.add_child(geo)
	_owned(geo)

	# ---- Layout (world units; viewport is 480x270) -----------------------
	# Long ground floor.
	_solid(geo, Vector2(300, 224), Vector2(720, 48))
	# Left boundary wall.
	_solid(geo, Vector2(-40, 120), Vector2(40, 256))
	# Right tall wall for wall-slide / wall-jump practice.
	_solid(geo, Vector2(636, 110), Vector2(40, 280))
	# A step block that creates a grabbable ledge on its left side.
	_solid(geo, Vector2(150, 150), Vector2(60, 100))
	# Mid floating platform (solid) — dash gap to reach it.
	_solid(geo, Vector2(360, 150), Vector2(90, 18))
	# Higher platform to chain a wall-jump up to.
	_solid(geo, Vector2(520, 96), Vector2(90, 18))
	# One-way drop-through platform.
	_one_way(geo, Vector2(260, 120), Vector2(80, 12))

	# ---- Player ----------------------------------------------------------
	var player_scene: PackedScene = ResourceLoader.load(PLAYER_SCENE)
	if player_scene == null:
		push_error("Could not load %s" % PLAYER_SCENE)
		quit(1)
		return
	var player := player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(300, 180)
	_root.add_child(player)
	_owned(player)

	# ---- Training dummies (static combat targets) ------------------------
	var dummy_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/Enemies/TrainingDummy.tscn")
	if dummy_scene != null:
		var spots := [Vector2(430, 199), Vector2(120, 99)]
		var i := 0
		for spot in spots:
			var dummy := dummy_scene.instantiate()
			dummy.name = "TrainingDummy%d" % i
			dummy.position = spot
			_root.add_child(dummy)
			_owned(dummy)
			i += 1

	# ---- Sentinel Drones (flying, patrol + chase AI) ---------------------
	var drone_scene: PackedScene = ResourceLoader.load("res://Scenes/Characters/Enemies/SentinelDrone.tscn")
	if drone_scene != null:
		# Spawn at ground level — they start as grounded sentinels and lift off
		# only once wounded (floor top is y=200).
		var drone_spots := [Vector2(250, 192), Vector2(530, 192), Vector2(180, 192)]
		var d := 0
		for spot in drone_spots:
			var drone := drone_scene.instantiate()
			drone.name = "SentinelDrone%d" % d
			drone.position = spot
			_root.add_child(drone)
			_owned(drone)
			d += 1

	# ---- Hackable gate: terminal -> door -> Echo Fragment reward ----------
	var door_scene: PackedScene = ResourceLoader.load("res://Scenes/World/HackDoor.tscn")
	var term_scene: PackedScene = ResourceLoader.load("res://Scenes/World/HackTerminal.tscn")
	var frag_scene: PackedScene = ResourceLoader.load("res://Scenes/World/EchoFragment.tscn")
	if door_scene != null and term_scene != null and frag_scene != null:
		var door := door_scene.instantiate()
		door.name = "HackDoor"
		door.position = Vector2(596, 177)
		_root.add_child(door)
		_owned(door)

		var term := term_scene.instantiate()
		term.name = "HackTerminal"
		term.position = Vector2(556, 200)
		_root.add_child(term)
		_owned(term)
		term.target_path = term.get_path_to(door)  # saved into the packed scene

		var frag := frag_scene.instantiate()
		frag.name = "EchoFragment"
		frag.position = Vector2(610, 186)
		_root.add_child(frag)
		_owned(frag)

	_build_hud()
	_build_atmosphere()

	# ---- Pack & save -----------------------------------------------------
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
# Builders
# ---------------------------------------------------------------------------

## Mark a node as owned by the scene root so PackedScene.pack persists it.
func _owned(n: Node) -> void:
	n.owner = _root


func _solid(parent: Node, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = center
	parent.add_child(body)
	_owned(body)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	_owned(col)

	_panel_visual(body, size, NEON)


func _one_way(parent: Node, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = ONE_WAY_BIT
	body.collision_mask = 0
	body.position = center
	parent.add_child(body)
	_owned(body)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.one_way_collision = true
	body.add_child(col)
	_owned(col)

	_panel_visual(body, size, NEON_ONEWAY)


## Dark tech panel: body, bright neon top edge, dim underglow line, and small
## neon corner ticks. Reads as a cyberpunk platform rather than a grey box.
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

	# Slightly lighter inner band near the top for a bevel hint.
	var bevel := ColorRect.new()
	bevel.color = Color(PANEL.r + 0.05, PANEL.g + 0.06, PANEL.b + 0.09, 1.0)
	bevel.size = Vector2(size.x, 3.0)
	bevel.position = Vector2(-hx, -hy + 2.0)
	body.add_child(bevel)
	_owned(bevel)

	_rect(body, Vector2(-hx, -hy), Vector2(size.x, 2.0), edge)              # neon top
	_rect(body, Vector2(-hx, hy - 1.0), Vector2(size.x, 1.0), Color(edge.r, edge.g, edge.b, 0.30))  # underglow
	# Corner ticks.
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


func _build_parallax() -> void:
	var bg := ParallaxBackground.new()
	bg.name = "ParallaxBackground"
	_root.add_child(bg)
	_owned(bg)

	# layer file, motion_scale, y-position
	var layers := [
		["skyline-a.png", 0.15, -30.0],
		["buildings-bg.png", 0.40, 60.0],
		["near-buildings-bg.png", 0.70, 40.0],
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
	# Control tips along the bottom (out of the HUD's way).
	var canvas := CanvasLayer.new()
	canvas.name = "Tips"
	_root.add_child(canvas)
	_owned(canvas)

	var label := Label.new()
	label.name = "Controls"
	label.position = Vector2(8, 250)
	label.add_theme_font_size_override("font_size", 7)
	label.text = "A/D move  •  Space jump  •  Shift dash  •  J attack  •  Esc pause"
	canvas.add_child(label)
	_owned(label)

	# Real HUD (health / energy / fragments) + pause menu.
	var hud_scene: PackedScene = ResourceLoader.load("res://Scenes/UI/HUD.tscn")
	if hud_scene != null:
		var hud := hud_scene.instantiate()
		_root.add_child(hud)
		_owned(hud)
	var pause_scene: PackedScene = ResourceLoader.load("res://Scenes/UI/PauseMenu.tscn")
	if pause_scene != null:
		var pause := pause_scene.instantiate()
		_root.add_child(pause)
		_owned(pause)


# ---------------------------------------------------------------------------
# Phase 4 — Digital World atmosphere & decoration
# ---------------------------------------------------------------------------

## Cyberpunk props (antennas, signs, control boxes, animated holograms) placed
## behind the play geometry so they add depth without blocking gameplay.
func _decorate() -> void:
	var decor := Node2D.new()
	decor.name = "Decor"
	decor.z_index = -3
	_root.add_child(decor)
	_owned(decor)

	_sprite(decor, "antenna.png", Vector2(150, 54))
	_sprite(decor, "antenna.png", Vector2(602, 38))
	_sprite(decor, "hotel-sign.png", Vector2(450, 70))
	_sprite(decor, "banners.png", Vector2(322, 78))
	_sprite(decor, "banner-open.png", Vector2(96, 64))
	_sprite(decor, "control-box-3.png", Vector2(40, 150))
	_sprite(decor, "control-box-1.png", Vector2(636, 150))

	# Animated holograms (floating in open space).
	var face := ["monitor-face-1.png", "monitor-face-2.png", "monitor-face-3.png", "monitor-face-4.png"]
	_anim_sprite(decor, face, Vector2(250, 64), 6.0, 1.5)
	_anim_sprite(decor, face, Vector2(470, 48), 6.0, 1.5)
	var neon := ["banner-neon-1.png", "banner-neon-2.png", "banner-neon-3.png", "banner-neon-4.png"]
	_anim_sprite(decor, neon, Vector2(210, 60), 5.0, 1.0)


## Slow upward "data motes" drifting through the play space.
func _ambient_motes() -> void:
	var motes := CPUParticles2D.new()
	motes.name = "DataMotes"
	motes.position = Vector2(300, 215)
	motes.z_index = -2
	motes.amount = 42
	motes.lifetime = 5.0
	motes.local_coords = false
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(330, 24)
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


## Instance the screen-space atmosphere layers (rain + CRT overlay).
func _build_atmosphere() -> void:
	var rain: PackedScene = ResourceLoader.load("res://Scenes/Effects/Rain.tscn")
	if rain != null:
		var r := rain.instantiate()
		_root.add_child(r)
		_owned(r)
	var fx: PackedScene = ResourceLoader.load("res://Scenes/Effects/ScreenFX.tscn")
	if fx != null:
		var f := fx.instantiate()
		_root.add_child(f)
		_owned(f)


func _sprite(parent: Node, file: String, pos: Vector2, modulate_v: float = 0.92) -> void:
	var tex: Texture2D = ResourceLoader.load(PROP_DIR + file)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.modulate = Color(modulate_v, modulate_v, modulate_v, 1.0)
	parent.add_child(s)
	_owned(s)


func _anim_sprite(parent: Node, files: Array, pos: Vector2, fps: float, alpha: float) -> void:
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
	a.modulate = Color(1, 1, 1, alpha)
	parent.add_child(a)
	_owned(a)
