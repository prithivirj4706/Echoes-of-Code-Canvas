# Echoes of Code & Canvas

A 2D Metroidvania about **Logic and Emotion learning to coexist** — built in
**Godot 4.7** (GDScript). This repo (`eo-2c`) is the Godot project.

> Note: `~/EchoesOfCodeAndCanvas` on this machine is a separate **Unity** project.
> The Godot game lives here in `eo-2c`.

---

## Current milestone — Movement Vertical Slice ✅

Per the production workflow (Movement → Combat → Camera → …), the first system
is a **commercial-feel movement controller**. Implemented and validated headless:

| Feature | Status |
|---|---|
| Run with accel / decel + snappy turn-around | ✅ |
| Variable jump height (release to cut) | ✅ |
| Coyote time + jump buffering | ✅ |
| Apex hang-time gravity | ✅ |
| Double jump (configurable air-jump count) | ✅ |
| Dash + air dash (cooldown, momentum keep) | ✅ |
| Wall slide + wall jump + wall coyote | ✅ |
| Ledge grab → climb | ✅ |
| Drop-through one-way platforms | ✅ |
| Smooth-follow camera | ✅ |
| Cyberpunk parallax background (Digital World) | ✅ |

## Milestone 2 — Combat slice ✅

| Feature | Status |
|---|---|
| Reusable Hitbox / Hurtbox / HealthComponent | ✅ |
| 3-hit light combo (attack1→2→3) with buffer/cancel windows | ✅ |
| Frame-driven hitbox activation (readable reach) | ✅ |
| Dash-cancel out of attacks | ✅ |
| Hit-stop (damage-scaled) | ✅ |
| Screen shake (trauma model) | ✅ |
| Knockback + critical hits | ✅ |
| Floating damage numbers | ✅ |
| Player i-frames + hit flash | ✅ |
| Training dummy (flash, health bar, respawn) | ✅ |

### Controls
| Action | Keys |
|---|---|
| Move | `A`/`D` or arrows |
| Jump / Double / Wall jump | `Space` or `K` |
| Dash | `Shift` or `L` |
| Drop through platform | hold `Down` + `Space` |
| Attack (3-hit combo) | `J` or left-click |
| Heavy (reserved) | `I` / right-click |
| Interact (reserved) | `E` / `F` |

---

## Run it

Open `eo-2c` in Godot 4.7 and press Play, or from the CLI:

```bash
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$GODOT" --path . --import          # first time / after adding assets
"$GODOT" --path .                   # play (main scene = TestArena)
"$GODOT" --headless --path . --script res://tools/smoke_test.gd          # movement CI check
"$GODOT" --headless --path . --script res://tools/combat_smoke_test.gd   # combat CI check
```

---

## Architecture

**Node-based finite state machine** — the controller is split into small,
single-responsibility scripts instead of one monolith, so combat states bolt on
cheaply later.

```
Scripts/Player/
  movement_config.gd        # MovementConfig Resource — ALL tuning lives here
  player.gd                 # CharacterBody2D: physics, sensing, timers (thin)
  player_state_machine.gd   # drives states, emits state_changed signal
  states/
	player_state.gd         # base class
	idle / run / jump / fall / wall_slide / dash / ledge_grab / ledge_climb
```

- **Tuning is data, not code.** Designers edit `Resources/Movement/aarin_movement.tres`
  in the Inspector. Jump arcs are authored as *intent* (height + time-to-peak)
  and gravity/launch velocity are derived (the Maddy-Thorson method).
- **Per-character feel** is just a different `MovementConfig` — Aarin (sharp/fast)
  vs Lyra (floaty/fluid) will be two resources, one controller.
- **Decoupling via signals** — `state_changed`, `facing_changed` so audio/VFX
  can react without states knowing they exist.

### Asset pipeline (reproducible)
`tools/build_player_spriteframes.gd` slices the Adventurer frames into
`Resources/Player/aarin_frames.tres` (17 animations). Re-run it any time the
source sprites change. `tools/build_test_arena.gd` regenerates the greybox level.

---

## What's greybox / prototype (clearly labelled)
- **TestArena geometry** is on-theme greybox (neon-edged dark panels). Proper
  authored TileMap terrain comes in the **Level Design** phase — the cyberpunk
  `tileset.png` in the asset pack is decorative props, not walkable terrain, so a
  dedicated ground tileset is still needed.
- Player sprites use the **Adventurer** set (complete movement vocabulary). The
  **warped-city** cyberpunk sprites + backgrounds are reserved for Aarin's final
  look and the Digital World, swappable without code changes.

## Next up (roadmap)
1. ~~Movement~~ ✅ → ~~Combat~~ ✅
2. **Camera rig** — look-ahead, combat zoom, room limits/transitions, boss framing.
3. **Enemies** — real AI (patrol/chase/attack) reusing the Hitbox/Health components.
4. Bosses → Level Design → UI (health/energy HUD) → Audio → VFX → Polish.
