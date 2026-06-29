## MovementConfig
##
## Designer-facing tuning resource for a character's movement feel.
## All gameplay-feel constants live here so they can be tweaked in the
## Inspector (or swapped per-character: Aarin = sharp/fast, Lyra = floaty/fluid)
## without ever touching gameplay code.
##
## Jump arc values are authored as *intent* (how high, how long) and the engine
## values (gravity, launch velocity) are derived. This is the Celeste/"Maddy
## Thorson" approach: you tune what you can feel, not raw acceleration numbers.
class_name MovementConfig
extends Resource

# ---------------------------------------------------------------------------
# Horizontal movement
# ---------------------------------------------------------------------------
@export_group("Run")
## Target horizontal speed at full tilt (px/s).
@export var run_speed: float = 120.0
## How quickly we reach run_speed on the ground (px/s²).
@export var ground_acceleration: float = 1400.0
## How quickly we stop on the ground when no input (px/s²).
@export var ground_deceleration: float = 1800.0
## Acceleration while airborne (px/s²). Lower = less air control.
@export var air_acceleration: float = 900.0
## Deceleration while airborne with no input (px/s²).
@export var air_deceleration: float = 500.0
## Extra multiplier applied to acceleration when reversing direction, so
## turn-arounds feel snappy and responsive instead of mushy.
@export var turn_around_multiplier: float = 1.8

# ---------------------------------------------------------------------------
# Jump (authored as intent, gravity derived)
# ---------------------------------------------------------------------------
@export_group("Jump")
## Peak height of a full jump in pixels.
@export var jump_height: float = 54.0
## Seconds from launch to the apex of the jump.
@export var jump_time_to_peak: float = 0.40
## Seconds from apex back down to launch height (smaller = snappier fall).
@export var jump_time_to_descent: float = 0.32
## When the jump button is released early while rising, vertical velocity is
## multiplied by this (variable jump height). 1.0 = no cut, 0 = hard stop.
@export_range(0.0, 1.0) var jump_release_cut: float = 0.45
## Terminal downward speed (px/s).
@export var max_fall_speed: float = 360.0
## Extra gravity multiplier applied at the very top of the arc for a "floaty
## but weighty" apex (hang time). 1.0 disables.
@export var apex_gravity_multiplier: float = 0.80
## Velocity band (px/s) around the apex where apex_gravity_multiplier applies.
@export var apex_velocity_threshold: float = 28.0

@export_group("Air Jumps")
## Number of mid-air jumps (1 = classic double jump).
@export var max_air_jumps: int = 1
## Height of an air jump relative to a ground jump.
@export_range(0.0, 1.5) var air_jump_height_scale: float = 0.92

# ---------------------------------------------------------------------------
# Forgiveness windows
# ---------------------------------------------------------------------------
@export_group("Feel / Forgiveness")
## Grace period after leaving a ledge during which a ground jump still works.
@export var coyote_time: float = 0.10
## How early a jump press is remembered and fired on landing.
@export var jump_buffer_time: float = 0.12

# ---------------------------------------------------------------------------
# Dash
# ---------------------------------------------------------------------------
@export_group("Dash")
@export var dash_speed: float = 260.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.32
## Mid-air dashes allowed before touching ground/wall.
@export var max_air_dashes: int = 1
## Fraction of dash speed kept when the dash ends (momentum preservation).
@export_range(0.0, 1.0) var dash_end_speed_keep: float = 0.55
## Gravity is suspended for this fraction of the dash (0..1 of duration).
@export_range(0.0, 1.0) var dash_gravity_disabled: float = 1.0

# ---------------------------------------------------------------------------
# Wall interaction
# ---------------------------------------------------------------------------
@export_group("Wall")
## Max downward speed while sliding on a wall (px/s).
@export var wall_slide_speed: float = 46.0
## Initial gravity ramp into the slide for a soft "catch" (px/s²).
@export var wall_slide_acceleration: float = 520.0
## Outward + upward impulse on a wall jump.
@export var wall_jump_push: float = 135.0
## Wall jump vertical strength as a fraction of a normal jump.
@export_range(0.0, 1.5) var wall_jump_height_scale: float = 1.0
## How long horizontal input is ignored after a wall jump so the push reads
## cleanly even if the player holds toward the wall.
@export var wall_jump_input_lock: float = 0.14
## Brief window after leaving a wall where a wall jump still works (wall coyote).
@export var wall_coyote_time: float = 0.10

# ---------------------------------------------------------------------------
# Ledge grab / climb
# ---------------------------------------------------------------------------
@export_group("Ledge")
## Enable automatic ledge grab when falling past a grabbable corner.
@export var ledge_grab_enabled: bool = true
## Pixels the body is snapped up/in when latching to a ledge.
@export var ledge_snap_offset: Vector2 = Vector2(2.0, 0.0)
## Seconds the climb-up animation/movement takes.
@export var ledge_climb_duration: float = 0.28

# ---------------------------------------------------------------------------
# Derived engine values (computed from the authored intent above)
# ---------------------------------------------------------------------------

## Launch velocity for a full ground jump (negative = up).
func get_jump_velocity() -> float:
	return -(2.0 * jump_height) / jump_time_to_peak

## Launch velocity for an air jump (negative = up).
func get_air_jump_velocity() -> float:
	return get_jump_velocity() * air_jump_height_scale

## Gravity applied while moving up (px/s²).
func get_rise_gravity() -> float:
	return (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)

## Gravity applied while falling (px/s²) — typically stronger than rise.
func get_fall_gravity() -> float:
	return (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

## Vertical strength of a wall jump (negative = up).
func get_wall_jump_velocity() -> float:
	return get_jump_velocity() * wall_jump_height_scale
