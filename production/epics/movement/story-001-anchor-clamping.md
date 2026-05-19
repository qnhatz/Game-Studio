# Story 001: Anchor Clamping Logic

> **Epic**: Movement
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/movement.md`
**Requirement**: `TR-MOV-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (System Communication)
**ADR Decision Summary**: TwoActionTurnSystem calls `Movement.on_move_tapped(tap_position, player_id)` directly on the critical path. No event queuing. `Movement` writes to `FigureGeometry.set_anchor()` as its sole output.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `clamp()` and `Vector2` are stable built-ins. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: `@onready` injection for `FigureGeometry` reference (unit-testable)
- Required: `MOVE_MARGIN_PX = 20` — anchor never within 20 px of zone edge
- Required: Y position never changes — always `ANCHOR_Y = 338`

---

## Acceptance Criteria

*From GDD `design/gdd/movement.md`, scoped to this story:*

- [ ] Tapping P1's zone at `x=150` updates P1 anchor X to 150. Y remains 338.
- [ ] Anchor Y never changes after any MOVE — always 338.
- [ ] Tap at `x=5` (near left edge) is clamped to `P1_ZONE.x + MOVE_MARGIN_PX = 0 + 20 = 20`.
- [ ] P1 tap at `x=350` (in corridor) is clamped to `P1_ZONE.x + P1_ZONE.w - MOVE_MARGIN_PX = 0 + 320 - 20 = 300`.
- [ ] A tap within 1 px of current anchor still completes without error (no minimum move distance check).
- [ ] P2 tap at `x=460` (left of P2 zone) is clamped to `P2_ZONE.x + MOVE_MARGIN_PX = 480 + 20 = 500`.

---

## Implementation Notes

*Derived from ADR-0004 and GDD formula F1:*

```gdscript
class_name Movement
extends Node

const MOVE_MARGIN_PX: float = 20.0
const ANCHOR_Y: float = 338.0

var _figure_geometry: Node = null  # injected; concrete type FigureGeometry

func on_move_tapped(tap_position: Vector2, player_id: int) -> void:
    var zone: Rect2 = ScreenLayout.P1_ZONE if player_id == 0 else ScreenLayout.P2_ZONE
    var min_x: float = zone.position.x + MOVE_MARGIN_PX
    var max_x: float = zone.end.x - MOVE_MARGIN_PX
    var new_x: float = clampf(tap_position.x, min_x, max_x)
    _figure_geometry.set_anchor(player_id, Vector2(new_x, ANCHOR_Y))
```

For unit tests, inject a mock `FigureGeometry` with a `set_anchor` method that records the last call. Verify the expected `new_x` was passed.

---

## Out of Scope

*Handled by Story 002 — do not implement here:*

- Story 002: Tap-vs-drag disambiguation (InputSystem integration, `TAP_MOVE_RADIUS_PX` threshold)

---

## QA Test Cases

- **AC-1**: Valid tap in zone
  - Given: P1 at default anchor; `_figure_geometry` mock
  - When: `on_move_tapped(Vector2(150, 338), 0)` called
  - Then: Mock received `set_anchor(0, Vector2(150, 338))`

- **AC-2**: Y unchanged
  - Given: P1 tap at `Vector2(150, 200)` (different Y)
  - When: `on_move_tapped` called
  - Then: `set_anchor` called with `y = 338` (Y is forced to ANCHOR_Y)

- **AC-3**: Left edge clamping
  - Given: P1 tap at x=5
  - When: `on_move_tapped` called
  - Then: `set_anchor` called with `x = 20`

- **AC-4**: Right edge clamping (corridor tap)
  - Given: P1 tap at x=350
  - When: `on_move_tapped` called
  - Then: `set_anchor` called with `x = 300`

- **AC-5**: Near-same-position tap (no minimum move requirement)
  - Given: P1 at anchor x=150; tap at x=151
  - When: `on_move_tapped(Vector2(151, 338), 0)` called
  - Then: Completes without error; `set_anchor(0, Vector2(151, 338))` called

- **AC-6**: P2 zone clamping
  - Given: P2 tap at x=460
  - When: `on_move_tapped(Vector2(460, 338), 1)` called
  - Then: `set_anchor(1, Vector2(500, 338))` called

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/movement/movement_anchor_clamping_test.gd` — must exist and pass

**Status**: [x] `tests/unit/movement/movement_anchor_clamping_test.gd` — 10 test functions

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 6/6 passing (all ACs verified via unit tests)
**Deviations**: None — `assert` replaced with `push_error` + early return for release safety
**Test Evidence**: `tests/unit/movement/movement_anchor_clamping_test.gd` — 10 test functions
**Code Review**: CONCERNS resolved — AC-1 y-assertion added, AC-5 properly isolates within-1px scenario, AAA comments added

---

## Dependencies

- Depends on: FigureGeometry Story 001 must be DONE (`set_anchor` must exist)
- Unlocks: Story 002 (tap disambiguation integrates with this clamping logic)
