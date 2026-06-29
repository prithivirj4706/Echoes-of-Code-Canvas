## jump_hit_test.gd — confirm a drone hovering directly OVERHEAD is reachable by a
## jump-attack (drone at ground-58, player at jump apex below it).
##   godot --headless --path . --script res://tools/jump_hit_test.gd
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
		var ground_y := 200.0
		# Drone hovers ~58 px above the player's standing height, directly overhead.
		drone.global_position = Vector2(300, ground_y - 58.0)
		# Player at jump apex (~52 px up) directly below the drone.
		player.global_position = Vector2(300, ground_y - 52.0)
		player.set_facing(1)
		_drone_hp = drone.get_node("Health") as HealthComponent
		_drone_hp.damaged.connect(func(_a: int, _c: bool) -> void: _hit = true)
		player.hitbox.damage = 6
		player.hitbox.crit_chance = 0.0
		player.set_hitbox_active(true)
		return false
	if _hit:
		print("Overhead drone hit at jump apex. JUMP HIT TEST: PASS")
		quit(0)
		return true
	if _frames > 30:
		push_error("Could not reach overhead drone with jump-attack. JUMP HIT TEST: FAIL")
		quit(1)
		return true
	return false
