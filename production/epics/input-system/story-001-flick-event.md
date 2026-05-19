# Story 001: FlickEvent Value Object

> **Epic**: Input System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 hour
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/input-system.md`
**Requirements**: `TR-INP-001`, `TR-INP-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (FlickEvent Contract)
**ADR Decision Summary**: `class_name FlickEvent extends RefCounted` — immutable value object constructed via `FlickEvent.new(dir, power, timestamp)`. Direction is the normalised slingshot vector (`figure_anchor − drag_release_point`). Power is `clampf(dist / MAX_DRAG_PX, 0, 1)`. Timestamp is `Time.get_ticks_msec()` at release. `_init()` asserts direction is normalised and power is in [0, 1].

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `class_name`, `RefCounted`, and typed GDScript variables are stable since Godot 4.0. No post-cutoff APIs. No verification required.

**Control Manifest Rules (Foundation layer)**:
- Required: `class_name FlickEvent extends RefCounted` — typed immutable value object; construct only via `FlickEvent.new(dir, power, timestamp)`
- Required: FlickEvent direction convention — `normalize(figure_anchor − drag_release_point)` (slingshot model; dragging right fires left)
- Required: FlickEvent power — `clampf(drag_distance / MAX_DRAG_PX, 0.0, 1.0)` where `MAX_DRAG_PX = 150`
- Required: FlickEvent timestamp — `Time.get_ticks_msec()` at pointer release
- Forbidden: Never construct FlickEvent with un-normalised direction — `_init()` asserts this in debug builds
- Forbidden: Never pass shot data as `Dictionary {direction, power, timestamp}` — use `FlickEvent`
- Forbidden: Never pass shot fields as inline parameters — use `FlickEvent`

---

## Acceptance Criteria

*From GDD `design/gdd/input-system.md` and ADR-0008:*

- [ ] `FlickEvent.new(Vector2.RIGHT, 0.5, 0)` constructs successfully; `event.direction == Vector2.RIGHT`, `event.power == 0.5`, `event.timestamp == 0`
- [ ] `FlickEvent.new(Vector2.ZERO, 0.5, 0)` triggers an assert (un-normalised direction)
- [ ] `FlickEvent.new(Vector2.RIGHT, 1.5, 0)` triggers an assert (power out of range)
- [ ] Direction convention: drag from `(200, 338)` to `(250, 338)` — direction arg `normalize(Vector2(200,338) - Vector2(250,338))` — produces `FlickEvent.direction == Vector2.LEFT`
- [ ] `FlickEvent` has no setter methods — fields set only in `_init()`

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Create `res://systems/flick_event.gd`:

```gdscript
class_name FlickEvent extends RefCounted

var direction: Vector2   # Normalised unit vector: points from release point toward figure anchor
var power: float         # [0.0, 1.0] — 0 = minimal drag, 1 = full drag distance
var timestamp: int       # Time.get_ticks_msec() at pointer release

func _init(dir: Vector2, pwr: float, ts: int) -> void:
    assert(dir.is_normalized(), "FlickEvent direction must be normalised")
    assert(pwr >= 0.0 and pwr <= 1.0, "FlickEvent power must be in [0, 1]")
    direction = dir
    power = pwr
    timestamp = ts
```

**Direction convention — slingshot model**: `direction = normalize(figure_anchor − drag_release_point)`. Dragging right → release point is to the right of the anchor → `figure_anchor − release_point` points left → direction is LEFT → shot travels LEFT. The direction vector encodes where the shot goes, not where the finger moved.

**Power in MVP**: `ShotSpreadCalculation` uses only `direction` in MVP. Power is captured for forward compatibility (speed visualisation, advanced spread). It must still be computed and stored correctly.

**`_init()` asserts fire in debug builds only.** In release export, invalid construction is silent — treat as a programming error, not a user error.

The file lives in `res://systems/` alongside `screen_layout.gd`. No scene file needed — `class_name` makes it globally importable.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `InputSystem` pointer state machine — the producer that calls `FlickEvent.new()`
- Story 003: Window protocol and orientation gate guard

---

## QA Test Cases

*Written at story creation — implement against these cases.*

- **AC-1**: Valid construction
  - Given: A normalised direction `Vector2.RIGHT`, power `0.5`, timestamp `0`
  - When: `FlickEvent.new(Vector2.RIGHT, 0.5, 0)` is called
  - Then: `.direction == Vector2.RIGHT`, `.power == 0.5`, `.timestamp == 0`
  - Edge cases: `Vector2.LEFT`, `Vector2.UP`, `Vector2.DOWN` all normalised — all should succeed

- **AC-2**: Un-normalised direction assert
  - Given: A debug build (GUT runs in debug)
  - When: `FlickEvent.new(Vector2.ZERO, 0.5, 0)` is called
  - Then: assert fires with message "FlickEvent direction must be normalised"
  - Edge cases: `Vector2(2.0, 0.0)` (length > 1) also un-normalised — assert fires

- **AC-3**: Power out of range assert
  - Given: A debug build
  - When: `FlickEvent.new(Vector2.RIGHT, 1.5, 0)` is called
  - Then: assert fires with message "FlickEvent power must be in [0, 1]"
  - Edge cases: `power = -0.1` also out of range; `power = 0.0` and `power = 1.0` are valid boundaries

- **AC-4**: Slingshot direction convention
  - Given: Figure anchor at `Vector2(200, 338)`, drag releases at `Vector2(250, 338)` (dragged 50px right)
  - When: `FlickEvent.new((Vector2(200,338) - Vector2(250,338)).normalized(), 0.5, 0)` constructed
  - Then: `event.direction.x < 0` (direction is leftward — shot fires left)
  - Edge cases: drag upward → direction is downward; ensure convention is symmetric

- **AC-5**: Immutability — no external mutation
  - Given: A valid `FlickEvent` instance
  - When: `event.direction = Vector2.UP` is attempted
  - Then: GDScript does not prevent property assignment (vars are public by default), but no setter logic exists — test reads `event.direction` and confirms it was set in `_init()` only
  - Edge cases: Confirm there are no `set direction(value)` setter methods defined

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input_system/flick_event_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (must be first — all producers and consumers import this class)
- Unlocks: Story 002 (InputSystem pointer state machine requires FlickEvent to construct events)

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 5/5 passing
**Deviations**: None
**Test Evidence**: `tests/unit/input_system/flick_event_test.gd` — 11 test functions
**Code Review**: Complete (APPROVED WITH SUGGESTIONS — AC-3 precondition tests added, cardinal direction assertions strengthened)
