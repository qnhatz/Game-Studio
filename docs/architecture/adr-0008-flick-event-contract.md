# ADR-0008: FlickEvent Contract

## Status
Proposed

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (GDScript class design) |
| **Knowledge Risk** | LOW — `class_name`, `RefCounted`, and typed GDScript are stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0006 (RngService — FlickEvent timestamp uses Time.get_ticks_msec(), same source as RNG seed) |
| **Enables** | ADR-0007 (Input System — produces FlickEvent), ADR-0009 (AI Pipeline — synthesises FlickEvent) |
| **Blocks** | InputSystem implementation, ShotSpreadCalculation implementation, AITargeting implementation |
| **Ordering Note** | FlickEvent must be defined before any producer or consumer is implemented |

## Context

### Problem Statement

The drag-and-release gesture produces a direction vector and a power value that must be passed
from `InputSystem` to `TwoActionTurnSystem` and from there to `ShotSpreadCalculation`. The AI also
produces a simulated version of this same data. We need a single typed contract for this value so
both human and AI shots flow through an identical pipeline.

### Constraints

- GDScript only (no C# value types / structs)
- Must be passable as a typed argument in synchronous direct calls (Pattern A, ADR-0004)
- Must be unit-testable without a running scene
- Immutable after construction: no setter methods; values are set in `_init()`

### Requirements

- Carries: shot direction (normalised Vector2), power (float 0–1), creation timestamp (int)
- Invariants must hold at construction time; invalid instances must be impossible to create
  through the normal API

## Decision

**`class_name FlickEvent extends RefCounted` — typed immutable value object.**

### Implementation

```gdscript
# res://systems/flick_event.gd
class_name FlickEvent extends RefCounted

var direction: Vector2   # Normalised unit vector: points from figure anchor toward release point
var power: float         # [0.0, 1.0] — 0 = minimal drag, 1 = full drag distance
var timestamp: int       # Time.get_ticks_msec() at pointer release

func _init(dir: Vector2, pwr: float, ts: int) -> void:
    assert(dir.is_normalized(), "FlickEvent direction must be normalised")
    assert(pwr >= 0.0 and pwr <= 1.0, "FlickEvent power must be in [0, 1]")
    direction = dir
    power = pwr
    timestamp = ts
```

### Construction (InputSystem — human)

```gdscript
# In InputSystem._on_touch_end():
var displacement := drag_end - drag_start
var dist := displacement.length()
if dist < TAP_MOVE_RADIUS_PX:
    return   # tap, not drag — handled by Movement
var event := FlickEvent.new(
    (drag_start - drag_end).normalized(),   # slingshot: direction opposes drag vector
    clampf(dist / MAX_DRAG_PX, 0.0, 1.0),
    Time.get_ticks_msec()
)
flick_event_emitted.emit(active_player_id, event)
```

### Construction (AITargeting — AI)

```gdscript
# In AITargeting.select_fire_action():
var target_pos := figure_geometry.get_zone_centre(opponent_id, selected_zone)
var origin := figure_geometry.get_anchor(ai_player_id)
var dir := (target_pos - origin).normalized()
# Gaussian pre-error applied here before FlickEvent construction (see ADR-0009)
var event := FlickEvent.new(dir, 1.0, Time.get_ticks_msec())
return {action_type = &"FIRE", flick_event = event}
```

### Direction Convention

```
direction = normalize(figure_anchor − drag_release_point)
```

The slingshot model: dragging right fires left, dragging down fires up. This matches the
physical pen-flick analogy. The vector points from the release point back toward the figure,
i.e., the shot travels in `direction`.

### Fields

| Field | Type | Range | Description |
|-------|------|-------|-------------|
| `direction` | `Vector2` | normalised | Shot travel direction (slingshot model) |
| `power` | `float` | [0.0, 1.0] | Drag fraction of `MAX_DRAG_PX`; 0 = minimal, 1 = full |
| `timestamp` | `int` | any | `Time.get_ticks_msec()` at release; not used for game logic in MVP; available for analytics/replay |

### What `power` Is Not Used For (MVP)

In MVP, `ShotSpreadCalculation` uses only `direction` (and a spread angle from difficulty config).
`power` is captured for future use (e.g., shot speed visualisation, advanced spread scaling).
It must still be set correctly at construction for forward compatibility.

## Alternatives Considered

### Alternative A: Plain Dictionary `{direction, power, timestamp}`

- **Description**: Pass a `Dictionary` instead of a typed class
- **Pros**: No boilerplate class file; GDScript dictionaries are flexible
- **Cons**: No type safety; misspelled keys are silent bugs; no `_init()` invariant enforcement;
  no autocompletion in editor; callers can mutate fields freely
- **Rejection**: Typed value objects are explicitly preferred in GDScript 4 best practices;
  `class_name` + `RefCounted` is the idiomatic equivalent of a value type

### Alternative B: Array `[direction, power, timestamp]` (positional)

- **Description**: Pass a 3-element `Array`
- **Pros**: Minimal syntax
- **Cons**: Positional access (`event[0]`) is completely unreadable; no type safety whatsoever
- **Rejection**: Obviously wrong

### Alternative C: Inline parameters (no event object)

- **Description**: `on_action_selected(action_type, direction, power, timestamp)` — pass fields directly
- **Pros**: No extra class
- **Cons**: AI and human callers must match parameter signatures exactly; adding a field requires
  changing every caller; impossible to pass the "pending event" through intermediate systems cleanly
- **Rejection**: Event object pattern is clearly superior for a value that crosses multiple system
  boundaries; the object also serves as a natural unit test fixture

## Consequences

### Positive

- Type-safe: `FlickEvent` parameters in function signatures catch type errors at edit time
- Invariants enforced at construction: no invalid FlickEvent can be created through normal API
- Single definition point: all producers (human, AI) and all consumers (TurnSystem, Spread, tests)
  import the same `class_name`
- Forward-compatible: new fields can be added to FlickEvent without changing call sites

### Negative

- One additional file (`flick_event.gd`) to maintain
- `assert()` in `_init()` fires only in debug builds; invalid construction in Release is silent
  (acceptable — invalid events are a programming error, not a user error)

### Risks

- **Direction convention confusion**: the slingshot inversion (drag right → fire left) must be
  documented prominently. *Mitigation*: comment in `InputSystem` at the construction site;
  unit test asserts the correct direction for a known drag vector.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-INP-001 | Input System | direction = normalize(figure_anchor − drag_release_point) | Direction convention documented and enforced at construction |
| TR-INP-002 | Input System | power = clamp(drag_distance / MAX_DRAG_PX, 0, 1) | Power formula documented at construction site |
| TR-AIR-001 | AI Targeting | AI synthesises FlickEvent directly; bypasses InputSystem | AI constructs `FlickEvent.new()` directly with computed direction and power=1.0 |
| TR-AIR-002 | AI Targeting | Uses same ShotSpreadCalculation pipeline as human | Both human and AI produce `FlickEvent`; ShotSpreadCalculation receives identical type |

## Performance Implications

- **CPU**: `RefCounted` object allocation per shot. At ≤2 shots per turn, negligible. Reference
  counting frees the object automatically when no longer referenced.
- **Memory**: One `FlickEvent` object per shot, freed at end of `on_action_selected()` call.
  Peak: 1 live instance.

## Migration Plan

Greenfield. Create `res://systems/flick_event.gd` before implementing InputSystem or AITargeting.

## Validation Criteria

- `FlickEvent.new(Vector2.ZERO, 0.5, 0)` raises an assert (un-normalised direction)
- `FlickEvent.new(Vector2.RIGHT, 1.5, 0)` raises an assert (power out of range)
- `FlickEvent.new(Vector2.RIGHT, 0.5, 0)` succeeds; `event.direction == Vector2.RIGHT`
- Direction convention unit test: drag from (200, 338) to (250, 338) → `direction == Vector2.LEFT`

## Related Decisions

- ADR-0004: System Communication — FlickEvent is passed in synchronous direct calls (Pattern A)
- ADR-0007: Input System — produces FlickEvent (pending; blocked on OQ-1)
- ADR-0009: AI Pipeline — synthesises FlickEvent without InputSystem
