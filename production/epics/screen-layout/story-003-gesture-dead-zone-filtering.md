# Story 003: Gesture Region Dead-Zone Filtering

> **Epic**: Screen Layout
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/screen-layout.md`
**Requirement**: `TR-SCRN-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (Input System Architecture)
**ADR Decision Summary**: InputSystem checks gesture origin against `ScreenLayout.GESTURE_RECT(zone)` before entering DRAGGING state. Drag origins at exact boundary pixels, inside the Corridor, or inside the HUD strip (y<HUD_H) fall outside both gesture rects and are silently discarded — no FlickEvent, no action consumed.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `InputEventScreenTouch` / `InputEventMouseButton` position is in viewport coordinates, not canvas coordinates. In Compatibility + Keep Aspect, canvas and viewport coordinates may differ at non-1:1 scale. Verify that `event.position` is correctly mapped to canvas space via `get_viewport().get_screen_transform().affine_inverse() * event.position` if InputSystem operates in canvas space; alternatively confirm that ScreenLayout constants are expressed in the same coordinate space as `event.position`.

**Control Manifest Rules (Foundation + Core layer)**:
- Required: `InputSystem` uses `_input()` (not `_unhandled_input()`).
- Required: `_window_open` guard — InputSystem only accepts gesture-start when `open_window()` has been called.
- Required: Gesture origin within 48 px of figure anchor AND within the active player's `GESTURE_RECT` — both checks required.
- Forbidden: Never accept gesture input when `_window_open == false`.
- Forbidden: Never use `Input.is_action_pressed()` polling.

---

## Acceptance Criteria

*From GDD `design/gdd/screen-layout.md`:*

- [ ] A drag origin at exactly `x=320` (P1_ZONE/CORRIDOR boundary), `x=480` (CORRIDOR/P2_ZONE boundary), or `y=90` (HUD strip boundary) is silently discarded — no shot initiated
- [ ] A drag origin anywhere in the Corridor (`x ∈ [321, 479]`, `y ∈ [90, 450]`) is silently discarded with no player assigned ownership
- [ ] A drag origin in the HUD strip (`y ∈ [0, 89]`) is silently discarded — no shot initiated
- [ ] In all discard cases, no `FlickEvent` is produced, `on_action_selected()` is not called, and action count is unchanged

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

In `InputSystem._on_pointer_down(touch_id, pos)`, before the figure-proximity check:

```gdscript
func _on_pointer_down(touch_id: int, pos: Vector2) -> void:
    if _dragging:
        return
    # Zone membership check — pos must be inside active player's GESTURE_RECT
    var gesture_rect: Rect2 = ScreenLayout.GESTURE_RECT(
        ScreenLayout.P1_ZONE if _active_player_id == 0 else ScreenLayout.P2_ZONE
    )
    if not gesture_rect.has_point(pos):
        return   # silently discard — boundary, corridor, HUD strip all excluded
    # … then figure proximity check
```

`Rect2.has_point()` in Godot excludes the `end` point (right/bottom edges) — a point at exactly `x=320` is excluded from `P1_ZONE` (`end.x = 320`). This matches the GDD boundary exclusion rule: exact boundary pixels belong to neither zone.

The Corridor has no `GESTURE_RECT` — it is implicitly excluded because it falls outside both `P1_GESTURE_RECT` and `P2_GESTURE_RECT`.

Do not add a separate Corridor membership check — the zone membership check already covers it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `GESTURE_RECT` formula definition — must be DONE before this story
- Story 004: Orientation gate check — a separate discard condition handled in `_input()` before zone check
- Story 005: Multi-touch second-touch discard — handled by `_touch_id` ownership, not zone membership

---

## QA Test Cases

*Written by qa-lead at story creation.*

- **AC-1**: Boundary pixel x=320 discarded
  - Given: InputSystem window open for P1; drag origin at Vector2(320, 200)
  - When: `_on_pointer_down(-1, Vector2(320, 200))` called
  - Then: `_dragging` remains false; no signal emitted; no `on_action_selected()` call
  - Edge cases: x=319 should pass zone check (inside P1_ZONE); x=321 should discard (Corridor)

- **AC-2**: Boundary pixel x=480 discarded
  - Given: InputSystem window open for P2; drag origin at Vector2(480, 200)
  - When: `_on_pointer_down(-1, Vector2(480, 200))` called
  - Then: `_dragging` remains false; no signal emitted
  - Edge cases: x=479 should discard (Corridor); x=481 should pass P2_ZONE check

- **AC-3**: HUD strip y=89 discarded
  - Given: InputSystem window open for P1; drag origin at Vector2(200, 89)
  - When: `_on_pointer_down(-1, Vector2(200, 89))` called
  - Then: `_dragging` remains false; no shot
  - Edge cases: y=90 is inside GESTURE_RECT (first valid row); y=0 discarded

- **AC-4**: Corridor discard
  - Given: InputSystem window open; drag origin at Vector2(400, 200) (dead centre of Corridor)
  - When: `_on_pointer_down(-1, Vector2(400, 200))` called
  - Then: `_dragging` remains false; neither P1 nor P2 action consumed

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/screen_layout/gesture_filtering_test.gd` — must exist and pass (or documented playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 must be DONE (`GESTURE_RECT` must exist); InputSystem epic (input-system) story providing `_on_pointer_down` must be DONE or in progress
- Unlocks: Story 004 (orientation gate is another discard condition layered on top of this)

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: `tests/integration/screen_layout/gesture_filtering_test.gd` — 15 test functions covering AC-1–AC-4 plus bottom-edge boundary pair added from code review
**Code Review**: Complete (APPROVED WITH SUGGESTIONS — y=449/450 boundary tests added)
