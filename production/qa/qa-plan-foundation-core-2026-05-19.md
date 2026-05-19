# QA Plan: Foundation + Core Systems Sprint

**Date**: 2026-05-19
**Sprint**: Foundation + Core Systems (all epics)
**Stage**: Pre-Production
**Stories in scope**: 20
**QA Lead**: qa-lead agent
**Smoke Check**: PASS WITH WARNINGS (see `production/qa/smoke-2026-05-19.md`)

---

## Story Classification

| # | Story | Epic | Type | Automated | Manual | Status |
|---|-------|------|------|-----------|--------|--------|
| 1 | Story 001: ActionValidation Logic | action-validation | Logic | YES | NO | Test file present |
| 2 | Story 001: Zone Accessors and Anchor Management | figure-geometry | Logic | YES | NO | Test file present |
| 3 | Story 002: Ray Intersection Tests | figure-geometry | Logic | YES | NO | Test file present |
| 4 | Story 001: FlickEvent Value Object | input-system | Logic | YES | NO | Test file present |
| 5 | Story 002: InputSystem Pointer State Machine | input-system | Logic | YES | NO | Test file present |
| 6 | Story 003: InputSystem Window Protocol | input-system | Integration | YES | NO | Test file present |
| 7 | Story 001: Anchor Clamping Logic | movement | Logic | YES | NO | Test file present |
| 8 | Story 002: Tap-vs-Drag Disambiguation | movement | Integration | YES | NO | Test file present |
| 9 | Story 001: ScreenLayout Constants | screen-layout | Logic | YES | NO | Test file present |
| 10 | Story 002: GESTURE_RECT Scaling | screen-layout | Logic | YES | NO | Test file present |
| 11 | Story 003: Gesture Dead-Zone Filtering | screen-layout | Integration | YES | NO | Test file present |
| 12 | Story 004: Orientation Gate | screen-layout | Integration | NO | YES | Evidence doc — sign-off pending |
| 13 | Story 005: Multi-Touch Zone Isolation | screen-layout | Integration | NO | YES | Evidence doc — sign-off pending |
| 14 | Story 001: RngService Autoload | shot-spread-calculation | Logic | YES | NO | Test file present |
| 15 | Story 002: ShotSpreadCalculation.apply_spread() | shot-spread-calculation | Logic | YES | NO | Test file present |
| 16 | Story 001: StatusEffects Write API | status-effects | Logic | YES | NO | Test file present |
| 17 | Story 002: StatusEffects Tick and Reset | status-effects | Logic | YES | NO | Test file present |
| 18 | Story 001: Aim Line Logic | trajectory-visualization | Logic | YES | NO | Test file present |
| 19 | Story 002: Shot Line Logic | trajectory-visualization | Logic | YES | NO | Test file present |
| 20 | Story 003: Visual Rendering and Lifecycle | trajectory-visualization | Visual/Feel | NO | YES | Evidence doc — sign-off pending |

---

## Automated Test Requirements

All 17 Logic and Integration stories with automated tests must pass the GdUnit4 runner before sprint Done.

**Runner command:**
```
godot --headless --script tests/gdunit4_runner.gd
```

**Expected test files:**
```
tests/unit/action_validation/action_validation_test.gd          (12 tests)
tests/unit/figure_geometry/figure_geometry_zone_accessors_test.gd (26 tests)
tests/unit/figure_geometry/figure_geometry_ray_intersection_test.gd (12 tests)
tests/unit/input_system/flick_event_test.gd                     (9 tests)
tests/unit/input_system/input_system_pointer_test.gd
tests/integration/input_system/input_window_protocol_test.gd
tests/unit/movement/movement_anchor_clamping_test.gd            (10 tests)
tests/integration/movement/tap_disambiguation_test.gd           (6 tests)
tests/unit/screen_layout/screen_layout_constants_test.gd
tests/unit/screen_layout/gesture_rect_scaling_test.gd
tests/integration/screen_layout/gesture_filtering_test.gd
tests/unit/shot_spread/rng_service_test.gd
tests/unit/shot_spread/shot_spread_calculation_test.gd          (9 tests)
tests/unit/status_effects/status_effects_write_api_test.gd
tests/unit/status_effects/status_effects_tick_reset_test.gd
tests/unit/trajectory_visualization/aim_line_test.gd            (13 tests)
tests/unit/trajectory_visualization/shot_line_test.gd           (16 tests)
```

**Stray file to investigate:** `tests/unit/rng_service_test.gd` — confirm delete or intentional before runner is executed.

---

## Manual QA Scope

Three stories require browser/device manual sessions:

### Session A: Visual Rendering (trajectory-visualization/story-003)
- **Environment**: Godot editor or browser export, landscape orientation
- **Evidence file**: `production/qa/evidence/trajectory-visualization-evidence.md`
- **Duration estimate**: 20 minutes
- **ACs**: P1 blue / P2 red ink colours, aim line opacity ≈ 0.45, shot line fade timing (2s display + 0.6s fade), freeze/reset lifecycle

### Session B: Orientation Gate + Multi-Touch Isolation (screen-layout/story-004 + story-005)
- **Environment**: Browser (Chrome/Firefox desktop for resize; iOS Safari or Android Chrome for real-device; DevTools touch simulation for multi-touch AC-2)
- **Evidence files**: `production/qa/evidence/orientation-gate-evidence.md`, `production/qa/evidence/multi-touch-isolation-evidence.md`
- **Duration estimate**: 45 + 30 = 75 minutes (can run in one browser sitting)
- **ACs**: Portrait blocks input, mid-drag portrait cancel, landscape resume; second touch ignored, cross-zone drag isolation

### Additional device test (advisory, not blocking sign-off):
- Short tap (< 12px) on iOS Safari confirms MOVE routing (real-device verification of `TAP_MOVE_RADIUS_PX = 12`)
- Can be folded into Session B on real device

---

## Out of Scope

The following are **not** tested in this QA cycle:

- Game loop wiring (TwoActionTurnSystem, GameStateMachine) — not yet implemented
- Main menu, MatchResultScreen, HUD turn indicator — Presentation layer, next sprint
- AI opponent behaviour — Feature layer, future sprint
- Save/load system — not yet designed
- Full 10-turn match performance profile — deferred to production build
- Web export / WASM build — deferred to production build readiness

---

## Entry Criteria

- [x] All 20 stories marked Status: Complete in story files
- [x] Smoke check PASS WITH WARNINGS (`production/qa/smoke-2026-05-19.md`)
- [x] All 17 automated test files present on disk
- [ ] Automated test runner confirmed green (editor or CI) — **PENDING**
- [ ] Stray `tests/unit/rng_service_test.gd` investigated — **PENDING**

---

## Exit Criteria

- [ ] All 17 automated stories: runner confirms all tests pass
- [ ] story-003 (visual rendering): evidence doc signed off
- [ ] story-004 (orientation gate): evidence doc signed off
- [ ] story-005 (multi-touch isolation): evidence doc signed off
- [ ] QA sign-off report written and verdict is APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1 or S2 bugs open

---

## Open Warnings (from smoke check)

1. Automated test suite not run via CLI — must be confirmed green before sprint Done
2. Orientation gate not tested in prototype — requires production browser build
3. Performance not profiled — schedule before ship
4. Input System story-002 lean-mode skipped code review — advisable before ship
5. Shot line fade timing (2s + 0.6s) — verify visually in Session A
6. `TAP_MOVE_RADIUS_PX = 12` real-device tap test — add to Session B scope
