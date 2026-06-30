## Audio (autoload singleton)
##
## A tiny pooled SFX player. Call Audio.play("hit") from anywhere; it round-robins
## a pool of AudioStreamPlayers (so overlapping sounds don't cut each other) and
## adds slight pitch variation so repeated hits don't feel robotic.
##
## All sounds are procedurally generated 8-bit-style WAVs (see tools), fitting
## the Digital World's synth identity.
extends Node

const POOL_SIZE := 12

const SOUNDS := {
	"swing": preload("res://Audio/SFX/swing.wav"),
	"hit": preload("res://Audio/SFX/hit.wav"),
	"crit": preload("res://Audio/SFX/crit.wav"),
	"dash": preload("res://Audio/SFX/dash.wav"),
	"jump": preload("res://Audio/SFX/jump.wav"),
	"hurt": preload("res://Audio/SFX/hurt.wav"),
	"explosion": preload("res://Audio/SFX/explosion.wav"),
	"hack": preload("res://Audio/SFX/hack.wav"),
	"pickup": preload("res://Audio/SFX/pickup.wav"),
	"shoot": preload("res://Audio/SFX/shoot.wav"),
}

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String, volume_db: float = -7.0, pitch_variation: float = 0.08) -> void:
	if not SOUNDS.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = SOUNDS[sound]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()
