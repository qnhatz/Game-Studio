# Story 001: Aim Line Logic

> **Epic**: Trajectory Visualization
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/trajectory-visualization.md`
**Requirement**: `TR-TVIS-001`, `TR-TVIS-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (Rendering Primitives), ADR-0007 (Input System)
**ADR Decision Summary**: Line2D nodes only. Aim line is a single reused Line2D node updated on `aim_updated` signal from InputSystem. Direction is slingshot (opposite to drag). Length scales with power.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: ADR-0007 notes that `InputEventScreenDrag` fires continuously at display refresh rate on iOS Safari (OQ-1 resolved as confirmed behaviour). The aim line update path relies on this — smoke test on real iOS device required before ship.

**Control Manifest Rules (Core layer)**:
- Required: Aim line uses `Line2D` node — no `draw_line` calls in `_draw()`
- Required: Subscribe to `InputSystem.aim_updated` signal in `_ready()` — typed callable connect
- Forbidden: String-based `connect()` — use `signal.connect(callable)` form

---

## Acceptance Criteria

*From GDD `design/gdd/trajectory-visualization.md`, scoped to this story:*

- [ ] **Aim line length formula**: `aim_length = power × AIM_LINE_MAX_LENGTH` where `AIM_LINE_MAX_LENGTH = 200`. At `power=0.5`, aim line length = 100 px.
- [ ] **Aim line direction (slingshot)**: `aim_direction = normalize(figure_anchor − drag_endpoint)`. Dragging right → aim line points left (negative X component).
- [ ] **Aim line endpoint**: `aim_endpoint = figure_anchor + aim_direction × aim_length`, clamped to canvas bounds `Rect2(0, 0, 800, 450)`.
- [ ] **Cancelled drag**: When drag is cancelled (power < MIN_POWER), aim line is hidden and no shot line is created.
- [ ] **Aim line hidden on release**: When `flick_event_emitted` fires (player releases), aim line is hidden.

---

## Implementation Notes

*Derived from ADR-0003 and GDD formulas:*

`TrajectoryVisualization` connects to `InputSystem` signals in `_ready()`. The aim line is a single `Line2D` node, shown/hidden as needed.

```gdscript
const AIM_LINE_MAX_LENGTH: float = 200.0
const AIM_LINE_ALPHA: float = 0.45

func _on_aim_updated(player_id: int, drag_end: Vector2) -> void:
    # live power is not in aim_updated signal — derive from drag distance
    var anchor: Vector2 = _figure_geometry.get_anchor(player_id)
    var raw_dir: Vector2 = anchor - drag_end
    var dist: float = raw_dir.length()
    if dist < 1.0:
        return
    var power: float = clampf(dist / InputSystem.MAX_DRAG_PX, 0.0, 1.0)
    var aim_dir: Vector2 = raw_dir.normalized()
    var length: float = power * AIM_LINE_MAX_LENGTH
    var endpoint: Vector2 = (anchor + aim_dir * length).clamp(Vector2.ZERO, Vector2(800, 450))
    _aim_line.points = PackedVector2Array([anchor, endpoint])
    _aim_line.show()

func _on_aim_cancelled() -> void:
    _aim_line.hide()

func _on_flick_event_emitted(player_id: int, event: FlickEvent) -> void:
    _aim_line.hide()
    # shot line drawing handled in Story 002
```

The aim line direction test: if `drag_end` is to the right of `anchor` (drag_end.x > anchor.x), then `aim_dir = normalize(anchor - drag_end)` has a negative X → line points left. This is the slingshot model.

---

## Out of Scope

*Handled by Story 002 and 003 — do not implement here:*

- Story 002: Shot line drawing, fade timeline, MAX_VISIBLE_SHOT_LINES logic
- Story 003: Visual rendering (Line2D node setup, ink colors, opacity), freeze/reset lifecycle

---

## QA Test Cases

- **AC-1**: Aim line length
  - Given: `figure_anchor = Vector2(200, 338)`, `drag_end = Vector2(350, 338)` (150 px right, full power)
  - When: `_on_aim_updated(0, Vector2(350, 338))` called
  - Then: Aim line endpoint is 150 px from anchor (power=1.0 → length=200, but dist/150 = 1.0 clamped → length=200; direction is left)
  - Edge: `drag_end = Vector2(275, 338)` (75 px right) → power=0.5 → length=100

- **AC-2**: Slingshot direction
  - Given: `anchor = Vector2(200, 338)`, `drag_end = Vector2(350, 338)` (drag to right)
  - When: Aim direction computed
  - Then: `aim_direction.x < 0` (line points left)

- **AC-3**: Endpoint clamped to canvas
  - Given: Aim line endpoint would be at `Vector2(-50, 338)` before clamping
  - When: Endpoint is computed
  - Then: Endpoint is clamped to `Vector2(0, 338)`

- **AC-4**: Cancelled drag hides line
  - Given: Aim line is visible
  - When: `_on_aim_cancelled()` fires
  - Then: `_aim_line.visible == false`

- **AC-5**: Release hides aim line
  - Given: Aim line is visible
  - When: `_on_flick_event_emitted(0, event)` fires
  - Then: `_aim_line.visible == false`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/trajectory_visualization/aim_line_test.gd` — must exist and pass

**Status**: [x] `tests/unit/trajectory_visualization/aim_line_test.gd` — 13 test functions

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 5/5 passing (all ACs verified via unit tests)
**Deviations**: None — Line2D created in _ready (Story 003 adds colors/opacity)
**Test Evidence**: `tests/unit/trajectory_visualization/aim_line_test.gd` — 13 test functions
**Code Review**: CONCERNS resolved — test names corrected, y≥0 clamp test added, coupling comment added

---

## Dependencies

- Depends on: FigureGeometry Story 001 (get_anchor used), InputSystem epic (aim_updated signal exists)
- Unlocks: Story 002 (shot line uses the same node setup)
