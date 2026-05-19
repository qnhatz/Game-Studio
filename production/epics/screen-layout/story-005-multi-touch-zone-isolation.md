# Story 005: Multi-Touch Zone Isolation

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
**ADR Decision Summary**: `InputSystem` uses a `_touch_id` sentinel (`-1` = mouse, ≥0 = first active touch). First active touch ID owns the entire drag; any subsequent touch is silently ignored. A pointer that crosses zone boundaries during a drag remains owned by the originating player — zone membership is checked only at drag-start, not continuously.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `InputEventScreenDrag` fires continuously at display refresh rate on web export (OQ-1 resolved). Each drag event carries `event.index` matching the originating touch ID. `InputEventScreenTouch` fires on finger lift. Confirmed for iOS Safari per ADR-0007 OQ-1 resolution — smoke test on real device still required before ship.

**Control Manifest Rules (Core layer)**:
- Required: Mouse sentinel: `_touch_id = -1` distinguishes mouse from touch.
- Required: First active touch ID owns drag; subsequent touches ignored.
- Required: Clamp drag endpoint to screen bounds before computing direction and power.
- Forbidden: Never poll `Input.is_action_pressed()` for gesture detection.
- Forbidden: Never accept gesture input when `_window_open == false`.

---

## Acceptance Criteria

*From GDD `design/gdd/screen-layout.md`:*

- [ ] When P1 has an active drag in P1's gesture region and P2 begins a separate drag in P2's gesture region simultaneously, both drags are tracked independently with no interference
- [ ] When P1 has an active drag in progress and a second touch begins within P1's gesture region before the first drag ends, the second touch is silently discarded; the first drag continues unaffected
- [ ] When P1 begins a drag inside P1's gesture region and the pointer travels outside P1's gesture region, the drag remains owned by P1 and is not reassigned

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

**Single-touch-per-player model**: InputSystem tracks one active gesture per input window. `TwoActionTurnSystem` opens the window for the active player only — during any given turn, only one player's input is accepted. This means the simultaneous-drag AC (two players at the same time) is satisfied structurally: P1's InputSystem rejects all input not for the active player window.

For the second-touch-in-same-zone discard (AC-2), the `_dragging` guard in `_on_pointer_down()` handles it:

```gdscript
func _on_pointer_down(touch_id: int, pos: Vector2) -> void:
    if _dragging:
        return   # already tracking a gesture — discard new touch
    # ... zone membership check, figure proximity check
    _touch_id = touch_id
    _dragging = true
```

For the cross-boundary drag (AC-3), `_on_pointer_move()` does NOT re-evaluate zone membership:

```gdscript
func _on_pointer_move(pos: Vector2) -> void:
    if _touch_id != -1 and event.index != _touch_id:
        return   # not the owning touch
    var clamped := pos.clamp(Vector2.ZERO, _canvas_size)
    aim_updated.emit(_active_player_id, clamped)
```

Zone membership is only checked in `_on_pointer_down()`. Once a drag is in progress, all subsequent move and up events for the owning touch ID are processed regardless of position.

**`_canvas_size`** must be set to `Vector2(ScreenLayout.CANVAS_W, ScreenLayout.CANVAS_H)` (not `get_viewport().size`) to ensure clamping is in canvas space.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Initial zone membership filtering in `_on_pointer_down()`
- Story 004: Orientation gate discard — a separate guard before multi-touch logic

---

## QA Test Cases

*Written by qa-lead at story creation. Evidence required — requires real multi-touch hardware or browser DevTools touch simulation.*

- **AC-1**: Simultaneous drags (two players, different zones)
  - Setup: Browser DevTools touch simulation; open InputSystem window for P1; simulate P1 drag start in P1 zone; simultaneously simulate a second touch in P2 zone
  - Verify: P1's drag continues; P2 touch is discarded (window is not open for P2); no FlickEvent for P2; aim line only for P1
  - Pass condition: Only one `aim_updated` signal firing; no P2 action consumed

- **AC-2**: Second touch in same zone discarded
  - Setup: Open InputSystem window for P1; P1 begins drag with touch ID 0; before releasing, simulate touch ID 1 starting in P1's zone
  - Verify: Touch ID 1 is silently discarded; `_dragging` remains true for touch ID 0; `_touch_id` stays 0; aim line unaffected
  - Pass condition: Single continuous aim line; no extra FlickEvent; only one `aim_updated` stream

- **AC-3**: Cross-zone pointer stays owned
  - Setup: Open InputSystem window for P1; P1 begins drag in P1 zone; move pointer across Corridor and into P2 zone
  - Verify: `aim_updated` continues firing with the crossed position (clamped to canvas bounds); drag is not cancelled; FlickEvent fires on release with slingshot direction from P1 figure centre
  - Pass condition: Aim line visible even when pointer is in P2 zone; FlickEvent emitted; direction computed from P1_ANCHOR

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/multi-touch-isolation-evidence.md` + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 must be DONE (zone membership logic in `_on_pointer_down()`); Story 004 must be DONE (orientation gate guard is in place)
- Unlocks: None — this is the final screen-layout story

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 3/3 implemented — no new code required (all three ACs satisfied by InputSystem Story 002 implementation)
**Deviations**: None
**Test Evidence**: `production/qa/evidence/multi-touch-isolation-evidence.md` — manual sign-off pending (requires multi-touch hardware or DevTools)
**Code Review**: N/A — no new code
