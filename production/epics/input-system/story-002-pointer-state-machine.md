# Story 002: InputSystem Pointer State Machine

> **Epic**: Input System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 3 hours
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/input-system.md`
**Requirements**: `TR-INP-001`, `TR-INP-002`, `TR-INP-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (Input System Architecture)
**ADR Decision Summary**: `InputSystem` is a Node in the Systems subtree using `_input()` with a three-state pointer machine (IDLE → DRAGGING → IDLE), unified across mouse and touch via a `_touch_id = -1` mouse sentinel. `_window_open` guards all gesture acceptance. `FIGURE_DRAG_RADIUS_PX = 48`, `MAX_DRAG_PX = 150`, `MIN_POWER = 0.05`. Drag endpoint is clamped to screen bounds before computing direction/power. Multi-touch: first active touch ID owns the drag; subsequent touches are ignored.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `InputEventScreenDrag` fires continuously during finger movement on web export (verified by OQ-1 analysis — confirmed via `touchmove` → `preventDefault()` in Godot web template). `InputEventScreenTouch` / `InputEventScreenDrag` are the mobile event types. `InputEventMouseButton` / `InputEventMouseMotion` are the desktop types. All stable since Godot 4.0 for desktop; web touch translation confirmed for 4.6. iOS Safari physical device smoke test still required before ship.

**Control Manifest Rules (Foundation layer)**:
- Required: `InputSystem` uses `_input()` — not `_unhandled_input()`; event-driven only, no `Input.is_action_pressed()` polling
- Required: `_window_open` guard — accept gesture-start only when `open_window(player_id)` has been called
- Required: Mouse sentinel `_touch_id = -1` — first active touch ID owns drag; subsequent touches ignored
- Required: Gesture origin within 48px of figure anchor — `FIGURE_DRAG_RADIUS_PX` check in `_on_pointer_down()`
- Required: Clamp drag endpoint to screen bounds before computing direction and power
- Required: Cancel silently if `power < MIN_POWER (0.05)` — no FlickEvent emitted, no action consumed
- Required: Wire `_figure_geometry` and `_two_action_turn_system` via `@onready` in `_ready()`, not Autoload lookups
- Forbidden: Never use `_unhandled_input()` in InputSystem
- Forbidden: Never poll `Input.is_action_pressed()` for gesture detection

---

## Acceptance Criteria

*From GDD `design/gdd/input-system.md`, scoped to this story:*

- [ ] AC1: A drag starting outside 48px of figure centre → no `FlickEvent` emitted (origin check)
- [ ] AC2: A drag of exactly 75px with `MAX_DRAG_PX = 150` → `FlickEvent.power == 0.5`
- [ ] AC3: A drag shorter than 7.5px (power < MIN_POWER 0.05) → no `FlickEvent` emitted, no action consumed
- [ ] AC4: Drag right → `FlickEvent.direction` has negative X (slingshot — shot fires left)
- [ ] AC5: A second touch during an active drag is ignored — power/direction remain from first touch
- [ ] AC6: Drag endpoint beyond screen rect → `FlickEvent` still emitted with clamped power (EC1)

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Create `res://systems/input_system.gd`. The class receives two injected dependencies:

```gdscript
class_name InputSystem
extends Node

signal flick_event_emitted(player_id: int, event: FlickEvent)
signal aim_updated(player_id: int, drag_end: Vector2)
signal aim_cancelled

const FIGURE_DRAG_RADIUS_PX: float = 48.0
const MAX_DRAG_PX: float = 150.0
const MIN_POWER: float = 0.05

var _window_open: bool = false
var _active_player_id: int = -1
var _touch_id: int = -1         # -1 = mouse sentinel; any other = active touch index
var _dragging: bool = false
var _drag_start: Vector2        # figure anchor, not pointer position

@onready var _figure_geometry: FigureGeometry = ...
@onready var _two_action_turn_system: TwoActionTurnSystem = ...
```

**`_on_pointer_down(touch_id, pos)`** — entry gate:
1. If `_dragging`: return (already tracking a gesture)
2. Get anchor: `var anchor = _figure_geometry.get_anchor(_active_player_id)`
3. If `pos.distance_to(anchor) > FIGURE_DRAG_RADIUS_PX`: return (outside hit zone)
4. Set `_touch_id = touch_id`, `_drag_start = anchor`, `_dragging = true`

Note: `_drag_start` is the figure anchor, not the pointer position. This ensures the slingshot origin is always the figure centre regardless of where within the 48px radius the player tapped.

**`_on_pointer_move(pos)`** — continuous aim update:
```gdscript
var clamped := pos.clamp(Vector2.ZERO, Vector2(ScreenLayout.CANVAS_W, ScreenLayout.CANVAS_H))
aim_updated.emit(_active_player_id, clamped)
```

**`_on_pointer_up(pos)`** — shot or cancel:
```gdscript
_dragging = false
_window_open = false
var clamped := pos.clamp(Vector2.ZERO, Vector2(ScreenLayout.CANVAS_W, ScreenLayout.CANVAS_H))
var dist := (_drag_start - clamped).length()   # distance from anchor to release
var power := clampf(dist / MAX_DRAG_PX, 0.0, 1.0)
if power < MIN_POWER:
    aim_cancelled.emit()
    return
var dir := (_drag_start - clamped).normalized()  # slingshot: figure_anchor - release_point
var event := FlickEvent.new(dir, power, Time.get_ticks_msec())
flick_event_emitted.emit(_active_player_id, event)
_two_action_turn_system.on_action_selected(_active_player_id, &"FIRE", event)
```

**`_input()` event routing** — full implementation per ADR-0007:
```gdscript
func _input(event: InputEvent) -> void:
    if not _window_open:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _on_pointer_down(event.index, event.position)
        elif event.index == _touch_id:
            _on_pointer_up(event.position)
    elif event is InputEventScreenDrag:
        if event.index == _touch_id:
            _on_pointer_move(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _on_pointer_down(-1, event.position)
        elif _touch_id == -1:
            _on_pointer_up(event.position)
    elif event is InputEventMouseMotion:
        if _touch_id == -1 and _dragging:
            _on_pointer_move(event.position)
```

The `open_window()` and `close_window()` methods belong to Story 003 (window protocol). For this story, `_window_open` is a field that tests can set directly to exercise the state machine. The gate check `if not _window_open: return` at the top of `_input()` is implemented here; the callers that set it are Story 003.

**Testing approach**: `FigureGeometry` does not exist yet. For unit tests, inject a mock/stub node that implements `get_anchor(player_id) -> Vector2`. Similarly, `TwoActionTurnSystem` can be a stub that records `on_action_selected()` calls. Set `_window_open = true` directly in test setup to bypass the protocol gate.

**`_figure_geometry` and `_two_action_turn_system`**: In the unit test context, these are assigned directly (no Inspector wiring). Use `@onready` with `= $Path/To/Node` for production use; the unit test assigns the mock after instantiation.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `FlickEvent` class definition — must already exist
- Story 003: `open_window()` / `close_window()` public API; orientation gate guard (`_orientation_gate.visible` check)
- Screen-layout Story 003: How `GESTURE_RECT` constrains where valid gesture origins are — that is tested at integration with the full scene tree

---

## QA Test Cases

*Written at story creation — implement against these cases.*

- **AC-1**: Origin outside 48px radius → no FlickEvent
  - Given: `_window_open = true`, `_active_player_id = 0`, mock figure anchor at `Vector2(200, 338)`
  - When: `_on_pointer_down(-1, Vector2(250, 338))` — 50px from anchor, beyond 48px radius
  - Then: `_dragging == false`; no `FlickEvent` emitted on subsequent `_on_pointer_up()`
  - Edge cases: exactly 48.0px distance → accepted (boundary is inclusive ≤); 48.1px → rejected

- **AC-2**: Power formula at 75px drag
  - Given: `_window_open = true`, anchor at `Vector2(200, 338)`, `_on_pointer_down(-1, Vector2(200, 338))` (tap on anchor, within radius)
  - When: `_on_pointer_up(Vector2(275, 338))` — 75px to the right
  - Then: emitted `FlickEvent.power ≈ 0.5` (within 0.0001 tolerance)
  - Edge cases: 150px → power=1.0; 200px → power=1.0 (clamped); 5px → power<0.05, cancelled

- **AC-3**: Cancellation threshold at 7px drag
  - Given: `_window_open = true`, anchor at `Vector2(200, 338)`
  - When: down at anchor, up at `Vector2(207, 338)` — 7px drag
  - Then: `aim_cancelled` emitted; no `FlickEvent` emitted; no `on_action_selected()` call recorded
  - Edge cases: exactly `7.5px` (= 150 × 0.05) → power == 0.05 exactly → FlickEvent IS emitted (boundary); `7.4px` → cancelled

- **AC-4**: Slingshot direction — drag right fires left
  - Given: anchor at `Vector2(200, 338)`, drag up at anchor, release at `Vector2(250, 338)` (50px right)
  - When: `FlickEvent` emitted
  - Then: `event.direction.x < 0.0` (direction is leftward); `event.direction.is_normalized() == true`
  - Edge cases: drag upward → `direction.y > 0` (downward aim when dragging up)

- **AC-5**: Multi-touch — second touch ignored
  - Given: Touch 0 down at anchor, `_dragging == true`, `_touch_id == 0`
  - When: Touch 1 down at `Vector2(100, 200)` (mid-drag)
  - Then: `_touch_id` still == 0; `_dragging` still true; first gesture unaffected; `_drag_start` unchanged
  - Edge cases: Touch 1 up before Touch 0 up — should have no effect

- **AC-6**: Endpoint clamp — shot fires with clamped position
  - Given: Anchor at `Vector2(200, 338)`, drag down at anchor, release at `Vector2(200, 600)` (below canvas bottom 450px)
  - When: `_on_pointer_up(Vector2(200, 600))`
  - Then: `FlickEvent` IS emitted (not cancelled); `event.power` computed from clamped pos `Vector2(200, 450)` → dist = 112px → power ≈ 0.747
  - Edge cases: release at `Vector2(-50, 338)` (left of canvas) → clamped to `Vector2(0, 338)`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input_system/input_system_pointer_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (FlickEvent must be DONE — `InputSystem._on_pointer_up()` constructs `FlickEvent.new()`)
- Unlocks: Story 003 (window protocol wraps this state machine); screen-layout Story 003 (dead-zone filtering uses `InputSystem` signals)

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 6/6 passing
**Deviations**: ADVISORY — `_figure_geometry` / `_two_action_turn_system` typed as `Node` with external injection rather than `@onready`; intentional pending concrete class creation (Story 003+)
**Test Evidence**: `tests/unit/input_system/input_system_pointer_test.gd` — 16 test functions covering all 6 ACs
**Code Review**: Skipped — Lean mode
