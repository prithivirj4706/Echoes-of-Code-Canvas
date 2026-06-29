## enemy_hit_test.gd — confirm the player's melee hitbox actually reaches and
## damages a flying drone positioned at engagement height.
##   godot --headless --path . --script res://tools/enemy_hit_test.gd
extends SceneTree

var _level: Node
var _drone_hp: HealthComponent
var _hit := false
var _frames := 0


func _initialize() -> void:
	_level = (ResourceLoader.load("res://Scenes/Levels/TestArena.tscn") as PackedScene).instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		var player := _level.get_node("Player") as Player
		var drone := _level.get_node("SentinelDrone0") as Node2D
		player.set_facing(1)
		# Park the drone right in front of the player at torso height.
		drone.global_position = player.global_position + Vector2(18, -14)
		_drone_hp = drone.get_node("Health") as HealthComponent
		_drone_hp.damaged.connect(func(_a: int, _c: bool) -> void: _hit = true)
		# Simulate the active frame of a swing.
		player.hitbox.damage = 6
		player.hitbox.crit_chance = 0.0
		player.set_hitbox_active(true)
		return false
	if _hit:
		print("Drone took a melee hit. ENEMY HIT TEST: PASS")
		quit(0)
		return true
	if _frames > 30:
		push_error("Melee hitbox never reached the drone. ENEMY HIT TEST: FAIL")
		quit(1)
		return true
	return false
