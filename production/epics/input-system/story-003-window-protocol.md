# Story 003: InputSystem Window Protocol and Orientation Gate

> **Epic**: Input System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 2 hours
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/input-system.md`
**Requirements**: `TR-INP-003`, `TR-INP-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (Input System Architecture)
**ADR Decision Summary**: `TwoActionTurnSystem` calls `open_window(player_id)` to arm the InputSystem and `close_window()` to disarm it. InputSystem calls `TwoActionTurnSystem.on_action_selected()` (Pattern A synchronous direct call) when a valid FlickEvent is emitted — which implicitly closes the window. Separately, ADR-0010 mandates that InputSystem checks `_orientation_gate.visible` at the top of `_input()` and discards all input when the orientation gate is visible.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `_input()` event routing and `CanvasLayer.visible` are stable since Godot 4.0. The orientation gate `visible` check requires `_orientation_gate` to be a node reference injected via `@onready`. No post-cutoff APIs.

**Control Manifest Rules (Foundation layer)**:
- Required: `open_window(player_id)` sets `_active_player_id`, `_window_open = true`, resets `_touch_id = -1` and `_dragging = false`
- Required: `close_window()` sets `_window_open = false`, `_dragging = false`, `_touch_id = -1`, emits `aim_cancelled`
- Required: OrientationGate check at top of `InputSystem._input()` — `if _orientation_gate.visible: return` — discards all input when orientation gate is visible
- Required: Wire `_orientation_gate` via `@onready`; it is a CanvasLayer node at Layer 20
- Required: All signal connections (`aim_updated`, `flick_event_emitted`, `aim_cancelled`) wired in `_ready()` of consumers — not in InputSystem
- Forbidden: Never accept gesture input when `_window_open == false`
- Forbidden: Never add Autoloads beyond ScreenLayout and RngService — orientation gate is a node reference, not an Autoload

---

## Acceptance Criteria

*From GDD `design/gdd/input-system.md`, scoped to this story:*

- [ ] AC7: A gesture-start event with `_window_open == false` is silently discarded — no `FlickEvent` emitted, no signal fired
- [ ] `open_window(1)` sets `_active_player_id = 1`, `_window_open = true`, clears `_touch_id` to -1 and `_dragging` to false
- [ ] `close_window()` sets `_window_open = false`, `_dragging = false`, `_touch_id = -1`, emits `aim_cancelled`
- [ ] A valid gesture while `_orientation_gate.visible == true` produces no `FlickEvent` and no `aim_updated`

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Add the window protocol API and orientation gate guard to `res://systems/input_system.gd` (created in Story 002).

**Window protocol methods** (called by `TwoActionTurnSystem`):

```gdscript
## Called by TwoActionTurnSystem when it is ready to receive a human action.
func open_window(player_id: int) -> void:
    _active_player_id = player_id
    _window_open = true
    _touch_id = -1
    _dragging = false

## Called by TwoActionTurnSystem on halt() or AI turn start.
func close_window() -> void:
    _window_open = false
    _dragging = false
    _touch_id = -1
    aim_cancelled.emit()
```

**Orientation gate guard** — add as the very first check in `_input()`, before the `_window_open` guard:

```gdscript
func _input(event: InputEvent) -> void:
    if _orientation_gate.visible:
        return
    if not _window_open:
        return
    # ... rest of state machine (from Story 002) ...
```

**New field and `@onready` dependency**:

```gdscript
@onready var _orientation_gate: CanvasLayer = $"/root/Main/OrientationGate"
```

The path `$"/root/Main/OrientationGate"` is the absolute path to the OrientationGate CanvasLayer (Layer 20). Use the Inspector-assigned `@onready` pattern — the actual path is wired in `Main.tscn` at scene setup time. For integration tests, inject a mock node with a `visible` property.

**`on_action_selected()` call closes the window implicitly**: In `_on_pointer_up()`, after `_two_action_turn_system.on_action_selected(...)` is called, `TwoActionTurnSystem` internally calls back `close_window()` as part of its action-selected handling. InputSystem also sets `_window_open = false` in `_on_pointer_up()` before calling `on_action_selected()` to prevent double-gesture during the synchronous call.

**Integration test strategy**: Create a test scene with:
1. An `InputSystem` node
2. A mock `TwoActionTurnSystem` stub that records `on_action_selected()` calls and exposes a `call_open_window(player_id)` helper
3. A mock `FigureGeometry` stub returning a fixed anchor
4. A `CanvasLayer` node acting as the orientation gate (toggle its `visible` property in tests)

The test does not use `_input()` directly — send synthetic `InputEvent` objects via `Input.parse_input_event()` or call `_on_pointer_down()` / `_on_pointer_up()` directly after setting `_window_open` via `open_window()`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Core pointer state machine (`_on_pointer_down`, `_on_pointer_move`, `_on_pointer_up`)
- Screen-layout Story 004: OrientationGate node creation — that story creates the CanvasLayer; this story only reads its `.visible` property

---

## QA Test Cases

*Written at story creation — implement against these cases.*

- **AC-1**: Window closed → gesture discarded
  - Given: `InputSystem` instantiated; `open_window()` never called; `_window_open == false`
  - When: `_on_pointer_down(-1, Vector2(200, 338))` called directly
  - Then: `_dragging == false`; subsequent `_on_pointer_up(Vector2(250, 338))` emits no `FlickEvent`, no `aim_cancelled`
  - Edge cases: window was opened then explicitly closed via `close_window()` — same result

- **AC-2**: `open_window()` arms the system
  - Given: `InputSystem` instantiated; mock figure anchor at `Vector2(200, 338)`
  - When: `open_window(1)` called
  - Then: `_active_player_id == 1`, `_window_open == true`, `_touch_id == -1`, `_dragging == false`
  - Edge cases: calling `open_window(0)` after `open_window(1)` replaces active player correctly

- **AC-3**: `close_window()` disarms and emits `aim_cancelled`
  - Given: `InputSystem` with `open_window(0)` already called; `_window_open == true`
  - When: `close_window()` called
  - Then: `_window_open == false`, `_touch_id == -1`, `_dragging == false`; `aim_cancelled` signal emitted once
  - Edge cases: `close_window()` while mid-drag (`_dragging == true`) → drag state cleared; `aim_cancelled` fires

- **AC-4**: Orientation gate visible → all input discarded
  - Given: `open_window(0)` called; mock orientation gate node with `visible = true`; anchor at `Vector2(200, 338)`
  - When: `_input(InputEventMouseButton{pressed=true, position=Vector2(200,338)})` processed
  - Then: `_dragging == false`; no `aim_updated` emitted; no `FlickEvent` emitted
  - Edge cases: gate hides (`visible = false`) mid-drag — subsequent events are processed normally once window is re-opened

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/input_system/input_window_protocol_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (pointer state machine must be DONE — window protocol wraps it)
- Unlocks: Screen-layout Story 003 (dead-zone filtering integration requires InputSystem with open window protocol complete); Screen-layout Story 004 (orientation gate integration requires this story's guard)

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 4/4 passing
**Deviations**: ADVISORY — `_orientation_gate` typed as `Node = null` with external injection; intentional pending concrete scene tree (consistent with _figure_geometry/_two_action_turn_system pattern)
**Test Evidence**: `tests/integration/input_system/input_window_protocol_test.gd` — 18 test functions covering all 4 ACs
**Code Review**: Complete (APPROVED WITH SUGGESTIONS — all SHOULD FIX items applied: _drag_start explicit init, AC-1 test routes through _input(), OrientationGateStub.visible comment)
