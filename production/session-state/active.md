# Session State — Flick Duel

*Last updated: 2026-05-11*

## Current Task

ADR-0007 written (OQ-1 resolved by analysis). Priority 3 complete (ADR-0001/0002/0005/0006/0008/0011 Accepted). Next: run `/create-control-manifest`, then `/gate-check pre-production`.

## Status

- [x] Game concept authored — `design/gdd/game-concept.md`
- [x] Engine configured — Godot 4.6, docs populated
- [x] Art bible authored — `design/art/art-bible.md` (all 9 sections)
- [x] Systems index created — `design/gdd/systems-index.md` (19 systems, 18 MVP + 1 V1.0)
- [x] All 19 GDDs authored — complete set in `design/gdd/`
- [x] Cross-GDD review complete — `design/gdd/gdd-cross-review-2026-05-08.md`
- [x] All 6 blocking issues resolved (B1–B6)
- [x] Gate check passed (CONCERNS — proceed) — `Technical Setup` stage active
- [x] `production/stage.txt` = `Technical Setup`
- [x] Master architecture document — `docs/architecture/architecture.md` (v1.0, TD-APPROVED)
- [x] All 12 ADRs written (ADR-0001–0011, all complete)
- [x] `/architecture-review` complete — CONCERNS verdict
  - Review report: `docs/architecture/architecture-review-2026-05-10.md`
  - Traceability index: `docs/architecture/architecture-traceability.md`
  - TR Registry: `docs/architecture/tr-registry.yaml` (58 IDs populated)
- [x] ADR-0001, 0002, 0005, 0006, 0008, 0011 — **Accepted**
- [x] ADR-0003, 0004, 0009, 0010 — Priority 1 fixes applied (still Proposed — accept after control manifest)
- [x] ADR-0007 — Proposed (OQ-1 resolved; ready to Accept after control manifest)

## Open Questions

- **OQ-1**: RESOLVED — `InputEventScreenDrag` fires continuously on iOS Safari. Web export template calls `preventDefault()` on touchmove. Smoke test on real device still required before ship.
- **OQ-2**: Godot 4.6 Compatibility renderer actual WASM memory baseline. Measure with browser DevTools on a real export before shipping.

## Required Actions Before Pre-Production Gate

### Priority 1 — Fix conflicts and engine issues in ADRs (before marking Accepted)

1. [x] Update ADR-0003: Immobilized visual → bold X through legs rect in opponent colour (not grey)
2. [x] Update ADR-0003: freeze() → store Tween refs + `tween.kill()` + `is_instance_valid()` guard
3. [x] Update ADR-0003: add `Line2D.antialiased = true` specification
4. [x] Update ADR-0009: add Gaussian pre-error layer before FlickEvent construction
5. [x] Update ADR-0009: add `w_miss` parameter to `AIDifficultyConfig.get_params()` spec
6. [x] Update ADR-0010: document MOUSE_FILTER_IGNORE per-node vs recursive decision
7. [x] Update ADR-0010: add `gui_release_focus()` contract to show/hide lifecycle
8. [x] Standardise StatusEffects method names: update architecture.md + ADR-0004 pseudocode

### Priority 2 — Complete ADR set

9. [x] Resolve OQ-1 (analysis: InputEventScreenDrag fires continuously on iOS Safari)
10. [x] Write ADR-0007 — `docs/architecture/adr-0007-input-system.md`

### Priority 3 — Accept clean ADRs

11. [x] Mark ADR-0001, ADR-0002, ADR-0005, ADR-0006, ADR-0008, ADR-0011 → **Accepted**

### After all above complete

- [ ] Run `/create-control-manifest` (requires all ADRs Accepted)
- [ ] Run `/gate-check pre-production`

## Architecture Review Findings Summary

**Verdict**: CONCERNS (42/58 covered · 11/58 partial · 5/58 gaps)

**All gaps trace to ADR-0007 (now written) — 5 TR-INP/TR-TVIS IDs are covered.**

## Key Architecture Decisions (all established)

- Canvas: 800×450 px, 16:9, Keep Aspect letterbox
- Compatibility renderer: `rendering/renderer/rendering_method.web = "gl_compatibility"`
- No physics engine; analytic ray math for all hit detection
- Single persistent scene (Main.tscn); all systems reset in-place for rematch
- ScreenLayout and RngService as the only two Autoloads
- TwoActionTurnSystem synchronous orchestrator; direct calls in critical path
- `class_name FlickEvent extends RefCounted` — typed immutable value object
- AI synthesises FlickEvent; joins at TwoActionTurnSystem.on_action_selected()
- Line2D nodes for all rendering; hand-jitter baked at _ready(); `antialiased = true`
- Player ink: P1 blue `Color(0.1, 0.2, 0.8)`, P2 red `Color(0.8, 0.1, 0.1)`
- Tween fade for shot lines with is_instance_valid() guard; freeze() uses tween.kill()
- WASM Memory Size = 128 MB; threads_enabled = false
- CanvasLayer hierarchy: HUD=1, Menus=10, OrientationGate=20
- GUT 4.x test framework; headless CI runner
- Turn states: IDLE | TURN_START | AWAITING_FIRST_ACTION | ACTION_EXECUTING | AWAITING_SECOND_ACTION | TURN_END | AUTO_SKIP | HALTED
- InputSystem: unified mouse/touch pointer state machine; `_input()` + `_window_open` guard; mouse sentinel `_touch_id = -1`

## Files Modified This Session

- `docs/architecture/adr-0007-input-system.md` — created
- `production/session-state/active.md` — this file

<!-- STATUS -->
Epic: Technical Setup
Feature: Architecture
Task: Run /create-control-manifest → /gate-check pre-production
<!-- /STATUS -->
