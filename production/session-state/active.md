# Session State — Flick Duel

*Last updated: 2026-05-07*

## Current Task

Status Effects GDD complete. Ready to begin GDD #3 — Input System.

## Status

- [x] Game concept authored — `design/gdd/game-concept.md`
- [x] Engine configured — Godot 4.6, docs populated
- [x] Art bible authored — `design/art/art-bible.md` (all 9 sections)
- [x] Systems index created — `design/gdd/systems-index.md` (18 systems, 17 MVP)
- [x] Screen Layout GDD — `design/gdd/screen-layout.md` (all sections, Designed)
- [x] Status Effects GDD — `design/gdd/status-effects.md` (all sections, Designed)
- [ ] Individual GDDs — 2 / 18 authored

## Active File

`design/gdd/status-effects.md` (complete — next: `design/gdd/input-system.md`)

## Next Action

Run `/design-system input-system` — #3 in design order (Foundation, no dependencies, medium effort).

## Key Decisions

- Canvas: 800×450 px, 16:9, Keep Aspect letterbox
- Zone split: 40% P1 / 20% corridor / 40% P2
- P1 anchor: Vector2(200, 338) | P2 anchor: Vector2(600, 338)
- HUD strip: y 0–90 px
- Gesture regions exclude HUD strip; ownership by drag origin
- Portrait blocked (strict V_w < V_h)
- 5 layout constants + EFFECT_DURATION_TURNS registered in entities.yaml

### Status Effects key decisions
- Tick model: counter=2, tick at turn START before action validation
- counter=2 for 1 restricted turn (counter_initial = duration_turns × 2)
- Both flags false + counter=2 both → auto-skip turn on tick (2→1, both still false)
- Staggered counters → no auto-skip; restrictions expire independently
- `set_disarmed` on already-disarmed player resets counter to 2 (idempotent)
- Only writer: Body-Zone Hit Detection; only ticker: Turn System
- Open questions: system architecture location (ADR); auto-skip indicator owner

<!-- STATUS -->
Epic: Pre-Production
Feature: Systems Design
Task: Design individual GDDs (2/18)
<!-- /STATUS -->
