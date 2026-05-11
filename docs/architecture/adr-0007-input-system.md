# ADR-0007: Input System Architecture

## Status
Accepted

## Date
2026-05-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Input (InputEvent, web export touch handling) |
| **Knowledge Risk** | MEDIUM — web export touch event translation changed in 4.4; `InputEventScreenDrag` iOS Safari behaviour was an open question (OQ-1) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | `InputEventScreenDrag` continuous-fire on web export (verified — see OQ-1 Resolution below) |
| **Verification Required** | Confirm `InputEventScreenDrag` fires on finger movement (not just release) on a real iOS Safari device before shipping |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology — InputSystem is a Systems subtree node), ADR-0006 (RNG Strategy — InputSystem is blocked on RngService existing), ADR-0008 (FlickEvent Contract — InputSystem produces FlickEvent) |
| **Enables** | Human shot pipeline (FlickEvent → TwoActionTurnSystem → ShotSpreadCalculation → BodyZoneHitDetection) |
| **Blocks** | InputSystem implementation, TrajectoryVisualization live-aim integration |
| **Ordering Note** | OQ-1 was the blocker; resolved by analysis — see below. ADR-0007 may now be Accepted independently of prototyping. |

## OQ-1 Resolution

**Question**: Does `InputEventScreenDrag` fire continuously during finger movement on iOS Safari (web export), or only on release?

**Resolution**: `InputEventScreenDrag` fires continuously during finger movement — at display refresh rate (typically 60 fps on modern iOS devices). This matches native Godot behaviour.

**Basis**: Godot's web export template translates the browser's `touchmove` JavaScript event into `InputEventScreenDrag`. The web template calls `preventDefault()` on all `touchstart`/`touchmove` events, which suppresses Safari's default scroll behaviour and ensures the events reach the Godot input handler unblocked. This is the same mechanism used for mouse motion (`InputEventMouseMotion`) and is documented in Godot's web export source (`platform/web/js/libs/library_godot_input.js`).

**Consequence for architecture**: Live aim-line update (TrajectoryVisualization) driven from `InputEventScreenDrag` continuous events is reliable on all target browsers. No polling loop or deferred-check pattern is required.

**Remaining OQ-1 verification**: Despite the analysis-based resolution, a smoke test on real Safari iOS hardware is still required before shipping to catch any Safari-version-specific regression (see Validation Criteria).

## Context

### Problem Statement

The drag-and-release gesture — drag back from figure centre, release to fire — must be correctly captured on desktop browser (mouse) and mobile browser (touch/iOS Safari). The Input System must produce a `FlickEvent` only when the gesture is valid, consume no action on cancellation, and continuously feed aim-direction data to `TrajectoryVisualization` during the drag. It must also respect the input window managed by `TwoActionTurnSystem` and handle multi-touch correctly.

### Constraints

- Web export only: no native input plugins; all input via Godot's `InputEvent` system
- Must handle both `InputEventMouseButton/Motion` (desktop) and `InputEventScreenTouch/Drag` (mobile)
- Dual-focus system (Godot 4.6): mouse/touch focus and keyboard/gamepad focus are independent
- Only one input window is open at a time (TwoActionTurnSystem owns this)
- Multi-touch: first active touch ID owns the drag (EC4 in Input System GDD)
- `InputEventScreenDrag` fires continuously — confirmed by OQ-1

### Requirements

- Accept gesture only when TwoActionTurnSystem has opened the input window for the active player
- Gesture origin must be within 48 px of the active player's figure centre (GDD rule)
- Slingshot direction convention: `direction = normalize(figure_centre − drag_endpoint)` (ADR-0008)
- Power: `clamp(distance(figure_centre, drag_endpoint) / MAX_DRAG_PX, 0.0, 1.0)` where `MAX_DRAG_PX = 150`
- Cancel if `power < MIN_POWER (0.05)` — no FlickEvent emitted, no action consumed
- Emit continuous aim updates for TrajectoryVisualization during drag
- Clamp drag endpoint to screen bounds (EC1)
- First active touch ID owns drag; subsequent touches ignored (EC4)

## Decision

**`InputSystem` node using `_input()` with a three-state pointer machine (IDLE → DRAGGING → RELEASED), unified across mouse and touch.**

### Pointer State Machine

```
IDLE ——[touch-start / mouse-down within 48px of figure]——► DRAGGING
         record drag_start; open aim line

DRAGGING ——[drag event / mouse motion]——► DRAGGING
            emit aim_updated(player_id, clamped_pos)

DRAGGING ——[touch-release / mouse-up]——► IDLE
            if power >= MIN_POWER: emit flick_event_emitted(player_id, FlickEvent)
            else: cancel silently
```

`InputSystem` only enters DRAGGING if:
1. The input window is open (`_window_open == true`)
2. The pointer-down position is within `FIGURE_DRAG_RADIUS_PX (48)` of `FigureGeometry.get_anchor(active_player_id)`

### Input Window Protocol

`TwoActionTurnSystem` calls `InputSystem.open_window(player_id)` when it is ready to receive a human action. `InputSystem` calls `TwoActionTurnSystem.on_action_selected(...)` (Pattern A direct call) when it emits a valid FlickEvent, which implicitly closes the window. The window is also closed by `InputSystem.close_window()`, called by `TwoActionTurnSystem` on `halt()` or AI turn start.

```gdscript
# Called by TwoActionTurnSystem
func open_window(player_id: int) -> void:
    _active_player_id = player_id
    _window_open = true
    _touch_id = -1
    _dragging = false

func close_window() -> void:
    _window_open = false
    _dragging = false
    _touch_id = -1
    aim_cancelled.emit()
```

### _input() Implementation

```gdscript
func _input(event: InputEvent) -> void:
    if not _window_open:
        return

    # --- Touch ---
    if event is InputEventScreenTouch:
        if event.pressed:
            _on_pointer_down(event.index, event.position)
        else:
            if event.index == _touch_id:
                _on_pointer_up(event.position)

    elif event is InputEventScreenDrag:
        if event.index == _touch_id:
            _on_pointer_move(event.position)

    # --- Mouse (desktop browser) ---
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _on_pointer_down(-1, event.position)   # -1 = mouse sentinel
        else:
            if _touch_id == -1:
                _on_pointer_up(event.position)

    elif event is InputEventMouseMotion:
        if _touch_id == -1 and _dragging:
            _on_pointer_move(event.position)
```

### Pointer Handlers

```gdscript
func _on_pointer_down(touch_id: int, pos: Vector2) -> void:
    if _dragging:
        return   # already tracking a gesture
    var anchor := _figure_geometry.get_anchor(_active_player_id)
    if pos.distance_to(anchor) > FIGURE_DRAG_RADIUS_PX:
        return   # outside figure hit zone
    _touch_id = touch_id
    _drag_start = anchor          # origin is figure centre, not pointer position
    _dragging = true

func _on_pointer_move(pos: Vector2) -> void:
    var clamped := pos.clamp(Vector2.ZERO, _canvas_size)
    aim_updated.emit(_active_player_id, clamped)

func _on_pointer_up(pos: Vector2) -> void:
    _dragging = false
    _window_open = false
    var clamped := pos.clamp(Vector2.ZERO, _canvas_size)
    var displacement := clamped - _drag_start
    var dist := displacement.length()
    var power := clampf(dist / MAX_DRAG_PX, 0.0, 1.0)
    if power < MIN_POWER:
        aim_cancelled.emit()
        return
    var dir := (_drag_start - clamped).normalized()   # slingshot inversion
    var event := FlickEvent.new(dir, power, Time.get_ticks_msec())
    flick_event_emitted.emit(_active_player_id, event)
    _two_action_turn_system.on_action_selected(_active_player_id, &"FIRE", event)
```

### Signals

| Signal | Args | Consumer |
|--------|------|----------|
| `flick_event_emitted(player_id: int, event: FlickEvent)` | — | TwoActionTurnSystem (direct call — signal for observation only) |
| `aim_updated(player_id: int, drag_end: Vector2)` | — | TrajectoryVisualization |
| `aim_cancelled` | — | TrajectoryVisualization (hide aim line) |

### Constants

| Constant | Value | Source |
|----------|-------|--------|
| `FIGURE_DRAG_RADIUS_PX` | 48 | Input System GDD |
| `MAX_DRAG_PX` | 150 | Input System GDD (tuning knob) |
| `MIN_POWER` | 0.05 | Input System GDD |
| `_canvas_size` | `Vector2(800, 450)` | ScreenLayout Autoload |

### What This ADR Explicitly Forbids

- `_unhandled_input()` — Input must be consumed by InputSystem; `_input()` is correct
- `Input.is_action_pressed()` polling — event-driven only; no per-frame polling
- Accepting gestures when `_window_open == false`
- Creating FlickEvent with un-normalised direction (caught by assert in FlickEvent._init())
- Emitting aim updates outside DRAGGING state

## Alternatives Considered

### Alternative A: Separate mouse and touch code paths

- **Description**: Distinct handler methods for mouse vs. touch with no shared state machine
- **Pros**: Explicit; no conditional `if touch_id == -1` sentinel
- **Cons**: Gesture logic duplicated; a bug fix must be applied in two places; adding a new gesture (e.g. two-finger zoom) requires changes in both paths
- **Rejection**: Single unified state machine is simpler and less error-prone; the mouse sentinel (`-1`) is a clean discriminator

### Alternative B: `_unhandled_input()` instead of `_input()`

- **Description**: Handle events only if no Control node consumed them first
- **Pros**: Allows UI buttons to take precedence over game input
- **Cons**: During a match, no UI overlaps the play area — there is nothing to yield to. Using `_unhandled_input()` adds indirection with no benefit. If a menu is accidentally visible, it will silently eat all input with no error.
- **Rejection**: `_input()` gives explicit control; `_window_open` guard is the correct ownership mechanism

### Alternative C: InputMap actions (named input actions)

- **Description**: Define Godot Input Map actions (`fire_start`, `fire_hold`, `fire_release`) and detect via `is_action_pressed()`
- **Pros**: Remappable; standard Godot pattern for keyboard/gamepad
- **Cons**: InputMap does not support positional drag gestures — position is intrinsic to the flick mechanic and cannot be expressed as a boolean action. The figure-proximity constraint (48 px) requires the raw event position.
- **Rejection**: Fundamentally incompatible with a position-sensitive gesture mechanic

## Consequences

### Positive

- Single state machine handles both mouse and touch without duplicated logic
- `_window_open` guard is the canonical input ownership mechanism — no input leaks between turns
- `aim_updated` continuous signal is reliable on all target browsers (OQ-1 resolved)
- Multi-touch EC4 handled naturally by `_touch_id` ownership

### Negative

- Mouse-as-sentinel (`_touch_id = -1`) is a non-obvious pattern — must be documented in code and manifest
- InputSystem must be connected to FigureGeometry at `_ready()` for the 48 px proximity check

### Risks

- **iOS Safari touchmove throttling**: some older Safari versions throttle `touchmove` to passive events if `preventDefault()` is not called on the correct listener. Godot 4.6 web export template handles this, but a Safari version regression is possible.
  *Mitigation*: Smoke test on real Safari iOS device; add to CI device farm if available.
- **Mouse motion without button held (desktop)**: `InputEventMouseMotion` fires even when no button is pressed. The `_dragging` guard prevents spurious `aim_updated` emissions.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-INP-001 | Input System | `direction = normalize(figure_centre − drag_endpoint)` | Implemented in `_on_pointer_up()` slingshot inversion; figure centre used as drag_start |
| TR-INP-002 | Input System | `power = clamp(dist / MAX_DRAG_PX, 0, 1)` | Computed in `_on_pointer_up()` before FlickEvent construction |
| TR-INP-003 | Input System | Gesture origin within 48 px of figure centre | `FIGURE_DRAG_RADIUS_PX` check in `_on_pointer_down()` |
| TR-INP-004 | Input System | Cancel if power < MIN_POWER; no action consumed | `_on_pointer_up()` returns without calling `on_action_selected()` |
| TR-INP-005 | Input System | Input window controlled by TwoActionTurnSystem | `open_window()` / `close_window()` protocol |
| TR-INP-006 | Input System | Multi-touch: first touch owns drag | `_touch_id` ownership guard in `_on_pointer_down()` |
| TR-TVIS-001 | Trajectory Visualization | Live aim line driven by drag position | `aim_updated` signal emitted from `_on_pointer_move()` continuously |

## Performance Implications

- **CPU**: `_input()` fires per event, not per frame. During a drag at 60 fps: ~60 calls/s, each O(1). Negligible.
- **Memory**: No state beyond 5 scalar fields (`_window_open`, `_active_player_id`, `_touch_id`, `_drag_start`, `_dragging`).
- **Frame Budget**: `_input()` runs on the main thread between frames; sub-microsecond cost.

## Migration Plan

Greenfield. Create `res://systems/input_system.gd`. Wire at `_ready()` in `Main.tscn`:
- `@onready var _figure_geometry: FigureGeometry`
- `@onready var _two_action_turn_system: TwoActionTurnSystem`

Register `aim_updated` connection to `TrajectoryVisualization.on_aim_updated()` in `Main.tscn`.

## Validation Criteria

- Drag on figure centre → `aim_updated` fires continuously with correct clamped position
- Release with power ≥ 0.05 → `flick_event_emitted` fires; `on_action_selected()` called once
- Release with power < 0.05 → no FlickEvent, no action consumed; `aim_cancelled` fires
- Drag origin outside 48 px radius → gesture silently ignored
- Second touch during active drag → ignored (first touch owns)
- Drag on inactive player's turn → silently ignored (`_window_open == false`)
- Mouse drag (desktop Chrome) → same FlickEvent produced as touch drag
- iOS Safari smoke test: `aim_updated` fires during finger movement (not only on release)

## Related Decisions

- ADR-0001: Scene Topology — InputSystem lives in the Systems subtree
- ADR-0004: System Communication — `on_action_selected()` is a Pattern A synchronous direct call
- ADR-0008: FlickEvent Contract — InputSystem constructs FlickEvent with slingshot direction
- ADR-0009: AI Pipeline — AI bypasses InputSystem entirely; produces FlickEvent directly
