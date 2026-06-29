## combat_smoke_test.gd — headless check of the full hit pipeline.
## Places the player next to a dummy, triggers an attack, and asserts the
## dummy's HealthComponent registers damage via the Hitbox→Hurtbox chain.
##   godot --headless --path . --script res://tools/combat_smoke_test.gd
##
## Note: under a custom SceneTree main loop, child _ready() runs deferred, so all
## node wiring happens on the first physics frame, not in _initialize().
extends SceneTree

var _level: Node
var _player: Player
var _dummy_health: HealthComponent
var _start_hp: int = 0
var _hit := false
var _frames := 0


func _initialize() -> void:
	var scene: PackedScene = ResourceLoader.load("res://Scenes/Levels/TestArena.tscn")
	_level = scene.instantiate()
	get_root().add_child(_level)


func _physics_process(_delta: float) -> bool:
	_frames += 1

	if _frames == 1:
		# _ready has now run for the whole tree — safe to wire up the test.
		# We validate the Hitbox->Hurtbox->Health pipeline directly by activating
		# the hitbox, rather than relying on sprite-frame timing (AnimatedSprite2D
		# does not advance frames under a headless custom main loop). The combo
		# animation timing itself is exercised by normal play.
		_player = _level.get_node("Player") as Player
		var dummy := _level.get_node("TrainingDummy0")
		_player.global_position = dummy.global_position + Vector2(-16, 0)
		_player.set_facing(1)
		_dummy_health = dummy.get_node("Health") as HealthComponent
		_start_hp = _dummy_health.current
		_dummy_health.damaged.connect(_on_dummy_damaged)
		_player.hitbox.damage = 7
		_player.hitbox.crit_chance = 0.0
		_player.set_hitbox_active(true)
		return false

	if _hit:
		print("COMBAT SMOKE TEST: PASS")
		quit(0)
		return true
	if _frames > 60:
		push_error("Attack never connected with the dummy.")
		print("COMBAT SMOKE TEST: FAIL")
		quit(1)
		return true
	return false


func _on_dummy_damaged(amount: int, is_crit: bool) -> void:
	_hit = true
	print("HIT landed: %d damage (crit=%s)  hp %d -> %d" % [amount, is_crit, _start_hp, _dummy_health.current])
