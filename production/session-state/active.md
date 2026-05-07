# Session State — Flick Duel

*Last updated: 2026-05-06*

## Current Task

Screen Layout GDD complete. Ready for next system.

## Status

- [x] Game concept authored — `design/gdd/game-concept.md`
- [x] Engine configured — Godot 4.6, docs populated
- [x] Art bible authored — `design/art/art-bible.md` (all 9 sections)
- [x] Systems index created — `design/gdd/systems-index.md` (18 systems, 17 MVP)
- [x] Screen Layout GDD — `design/gdd/screen-layout.md` (all sections, Designed)
- [ ] Individual GDDs — 1 / 18 authored

## Active File

`design/gdd/systems-index.md`

## Next Action

Run `/design-system status-effects` — next in design order (#2, Foundation, no dependencies, small effort).

## Key Decisions

- Canvas: 800×450 px, 16:9, Keep Aspect letterbox
- Zone split: 40% P1 / 20% corridor / 40% P2
- P1 anchor: Vector2(200, 338) | P2 anchor: Vector2(600, 338)
- HUD strip: y 0–90 px
- Gesture regions exclude HUD strip; ownership by drag origin
- Portrait blocked (strict V_w < V_h)
- 5 constants registered in entities.yaml

<!-- STATUS -->
Epic: Pre-Production
Feature: Systems Design
Task: Design individual GDDs (1/18)
<!-- /STATUS -->

Or run `/map-systems next` to auto-select the next undesigned system.

## Key Decisions Made

- 18 systems total (17 MVP, 1 V1.0)
- Design order follows dependency layers (Foundation → Core → Feature → Feature+ → Presentation)
- High-risk: Figure Geometry (zone sizing), Input System (gesture feel on glass), AI Targeting (believability)
- No circular dependencies

<!-- STATUS -->
Epic: Pre-Production
Feature: Systems Design
Task: Design individual GDDs
<!-- /STATUS -->
