# Session State — Flick Duel

*Last updated: 2026-05-10*

## Current Task

Priority 1 ADR fixes complete (all 8 items). Next: resolve OQ-1 (iOS Safari drag prototype), write ADR-0007, then mark clean ADRs as Accepted.

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
- [x] All 11 ADRs written (ADR-0001–0006, ADR-0008–0011; ADR-0007 pending OQ-1)
- [x] `/architecture-review` complete — CONCERNS verdict
  - Review report: `docs/architecture/architecture-review-2026-05-10.md`
  - Traceability index: `docs/architecture/architecture-traceability.md`
  - TR Registry: `docs/architecture/tr-registry.yaml` (58 IDs populated)

## Open Questions (must resolve before ADR-0007)

- **OQ-1**: iOS Safari InputEventScreenDrag — does it fire continuously during drag or only on drag-end?
  Resolve by building a one-page gesture prototype (just drag event logging) and testing on Safari iOS.
  This unblocks ADR-0007 (Input System Architecture).
- **OQ-2**: Godot 4.6 Compatibility renderer actual WASM memory baseline.
  Measure with browser DevTools on a real export before marking ADR-0002 as Accepted.

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

9. [ ] Resolve OQ-1 (build iOS Safari drag event prototype)
10. [ ] Write ADR-0007 from OQ-1 findings

### Priority 3 — Accept clean ADRs

11. [ ] Mark ADR-0001, ADR-0002, ADR-0005, ADR-0006, ADR-0008, ADR-0011 → **Accepted**

### After all above complete

- [ ] Run `/create-control-manifest` (requires all ADRs Accepted)
- [ ] Run `/gate-check pre-production`

## Architecture Review Findings Summary

**Verdict**: CONCERNS (42/58 covered · 11/58 partial · 5/58 gaps)

**2 RED conflicts** requiring ADR updates:
1. ADR-0003 Immobilized visual: grey shading → must be bold X in opponent colour
2. ADR-0009 AI accuracy: spread-only → must add Gaussian pre-error + w_miss

**4 engine findings** requiring ADR updates:
- ADR-0003: `Line2D.antialiased = true` (Compatibility renderer has no hardware MSAA)
- ADR-0003: `freeze()` needs `tween.kill()` not `set_meta()`
- ADR-0010: `MOUSE_FILTER_IGNORE` does not cascade — specify per-node vs recursive
- ADR-0010: `gui_release_focus()` required before hiding Control subtrees

**1 naming issue**: StatusEffects API inconsistency between architecture.md and GDD

**5 gaps**: All trace to ADR-0007 (blocked on OQ-1)

**ADRs clear to Accept now**: ADR-0001, ADR-0002, ADR-0005, ADR-0006, ADR-0008, ADR-0011

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

## Files Modified This Session

- `docs/architecture/architecture-review-2026-05-10.md` — created (review report)
- `docs/architecture/architecture-traceability.md` — created (full traceability matrix, 58 TR IDs)
- `docs/architecture/tr-registry.yaml` — populated (58 TR IDs, all new)
- `production/session-state/active.md` — this file

<!-- STATUS -->
Epic: Technical Setup
Feature: Architecture
Task: Resolve OQ-1 (iOS Safari drag prototype) → write ADR-0007 → mark ADRs Accepted
<!-- /STATUS -->
