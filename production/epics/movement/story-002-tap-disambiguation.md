# Story 002: Tap-vs-Drag Disambiguation

> **Epic**: Movement
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/movement.md`
**Requirement**: `TR-MOV-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (Input System Architecture)
**ADR Decision Summary**: `TAP_MOVE_RADIUS_PX = 12` px threshold in the InputSystem pointer state machine disambiguates taps (MOVE) from drags (FIRE). Displacement below threshold on pointer-up → MOVE. Displacement above → FIRE drag (FlickEvent). TwoActionTurnSystem routes the result.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: ADR-0007 notes that `InputEventScreenDrag` fires continuously at refresh rate on iOS Safari (OQ-1 resolved). The tap disambiguation path is on the same code path — real device test required before ship.

**Control Manifest Rules (Core layer)**:
- Required: `TAP_MOVE_RADIUS_PX = 12` — the threshold is in InputSystem (already implemented); Movement trusts the call routing
- Forbidden: Movement must not re-implement its own input handling — it only receives `on_move_tapped` calls from TwoActionTurnSystem

---

## Acceptance Criteria

*From GDD `design/gdd/movement.md`, scoped to this story:*

- [ ] A pointer release with displacement < 12 px routes to `Movement.on_move_tapped` (MOVE action consumed, not FIRE).
- [ ] A pointer release with displacement ≥ 12 px is treated as a FIRE drag (FlickEvent emitted, MOVE not consumed).
- [ ] After a MOVE action, `FigureGeometry.get_anchor(player_id).x` reflects the new position on the same call frame.

---

## Implementation Notes

*Derived from ADR-0007:*

The tap disambiguation logic lives in `InputSystem._on_pointer_up()` — it already measures displacement. The current implementation always emits `FlickEvent` on pointer-up if power ≥ MIN_POWER. The MOVE tap path requires the InputSystem to detect a short drag (displacement < TAP_MOVE_RADIUS_PX) and route it as a MOVE instead of FIRE.

This story extends `InputSystem._on_pointer_up()` to add the disambiguation branch:

```gdscript
# In InputSystem._on_pointer_up()
func _on_pointer_up(pos: Vector2) -> void:
    _dragging = false
    _window_open = false
    var clamped := pos.clamp(Vector2.ZERO, _canvas_size)
    var dist := (_drag_start - clamped).length()
    if dist < TAP_MOVE_RADIUS_PX:
        # Short tap → MOVE action
        _two_action_turn_system.on_move_tapped(_active_player_id, clamped)
        return
    var power := clampf(dist / MAX_DRAG_PX, 0.0, 1.0)
    if power < MIN_POWER:
        aim_cancelled.emit()
        return
    var dir := (_drag_start - clamped).normalized()
    var event := FlickEvent.new(dir, power, Time.get_ticks_msec())
    flick_event_emitted.emit(_active_player_id, event)
    _two_action_turn_system.on_action_selected(_active_player_id, &"FIRE", event)
```

Add `TAP_MOVE_RADIUS_PX: float = 12.0` constant to `InputSystem`.

The integration test mocks `TwoActionTurnSystem` to capture which method was called (`on_move_tapped` vs `on_action_selected(&"FIRE", ...)`).

---

## Out of Scope

*Handled by Story 001 — do not implement here:*

- Anchor clamping math (Story 001)

---

## QA Test Cases

- **AC-1**: Short tap → MOVE
  - Given: InputSystem with mock TurnSystem; pointer-down at `(200, 338)`, pointer-up at `(208, 338)` (8 px displacement, < 12)
  - When: `_on_pointer_up` fires
  - Then: Mock TurnSystem received `on_move_tapped` call; `on_action_selected` was NOT called

- **AC-2**: Long drag → FIRE
  - Given: InputSystem; pointer-down at `(200, 338)`, pointer-up at `(230, 338)` (30 px displacement, > 12)
  - When: `_on_pointer_up` fires
  - Then: `on_action_selected(&"FIRE", event)` called; `on_move_tapped` NOT called

- **AC-3**: Same-frame anchor update
  - Given: Full integration of Movement + FigureGeometry; short tap at `x=180`
  - When: `on_move_tapped` called
  - Then: `FigureGeometry.get_anchor(player_id).x == 180` immediately (no deferred update)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/movement/tap_disambiguation_test.gd` — must exist and pass

**Status**: [x] `tests/integration/movement/tap_disambiguation_test.gd` — 6 test functions

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 3/3 passing (AC-1 short tap routes to MOVE, AC-2 long drag routes to FIRE, AC-3 full routing chain updates anchor same-frame)
**Deviations**: None — AC-3 test drives through full InputSystem → MockTurnSystem → Movement → FigureGeometry chain
**Test Evidence**: `tests/integration/movement/tap_disambiguation_test.gd` — 6 test functions
**Code Review**: CONCERNS resolved — AC-3 test rewritten to exercise full routing chain

---

## Dependencies

- Depends on: Story 001 must be DONE; InputSystem epic must be DONE (InputSystem code is extended here)
- Unlocks: TwoActionTurnSystem epic (full input-to-action routing is now complete)
