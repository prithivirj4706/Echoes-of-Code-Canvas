# Echoes of Code & Canvas — Vertical Slice Roadmap

Derived from the project audit. Priority-ordered. Each phase commits specific
audit categories to a **7–8 / 9** target. Don't advance a phase until its
acceptance criteria hold. Scale is /9.

## Target scorecard

| Category | Now | Target | Phase |
|---|---|---|---|
| Combat feel | 5 | 8 | 1 |
| Verification / process | 5 | 8 | 2 |
| Production readiness | 3 | 7 | 3 |
| UI / UX | 6 | 8 | 3 |
| Audio | 4 | 8 | 4 |
| Architecture | 6 | 8 | 5 |
| Enemy / AI | 5 | 8 | 6 |
| Identity mechanic | 6 | 8 | 7 |
| Art coherence | 4 | 7 | 7 |
| Content / one polished level | 2 | 7 | 8 |
| Movement / Visual / Version control | 8 | maintain | — |

## Phase 1 — Lock the combat loop  (Combat 5→8, Enemy →7)
Direction chosen: **ranged attack**. Aarin gets an energy-bolt (costs Energy),
keeping melee for the ground. Flying enemies become reliably hittable by design.
- Energy-cost ranged shot + regen (makes the EN bar meaningful)
- Final-tune hitstop / knockback / cancel windows
- Acceptance: hitting enemies feels satisfying & connects every time; no re-tuning.

## Phase 2 — Feel in the loop  (Process 5→8)
- A way to run + input + screenshot the live game for self-verification of *feel*
- Acceptance: combat/feel validated without the user acting as QA.

## Phase 3 — Give the slice a shape  (Production 3→7, UI 6→8)
- Title/main menu → objective → win screen → clean lose/respawn → save fragments
- HUD objective marker
- Acceptance: a stranger knows what to do; can win and lose.

## Phase 4 — Audio bed  (Audio 4→8)
- Digital World music loop + rain/city ambience + audio bus mix.

## Phase 5 — Architecture refactor  (Architecture 6→8)
- Split player.gd into components (Input / Combat / Interact); magic numbers → config
- Acceptance: no file > ~250 lines; combat/input reusable for Lyra.

## Phase 6 — Enemy depth + mini-boss  (Enemy 5→8, Content →4)
- 2nd enemy archetype (grounded chaser) + a mini-boss (scaled Hollow Machine).

## Phase 7 — Identity depth + art coherence  (Identity 6→8, Art 4→7)
- More hack uses (lift / laser-gate / bridge); Aarin sprite recolour/skin to match the world.

## Phase 8 — The one polished level  (Content 2→7)
- Complete authored Digital World level: intro → traversal → hack puzzle →
  encounters → mini-boss → Nexus teaser. ~10 min of paced play.
