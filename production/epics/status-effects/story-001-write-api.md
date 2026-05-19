# Story 001: StatusEffects Write API and Initial State

> **Epic**: Status Effects
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/status-effects.md`
**Requirement**: `TR-STE-001`, `TR-STE-002`, `TR-STE-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (System Communication Architecture)
**ADR Decision Summary**: Direct method calls on critical path; canonical API names `set_disarmed`, `set_immobilized`, `tick_effects`, `reset_all` — no alternative names permitted.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript data class — no engine API dependencies. No post-cutoff APIs used.

**Control Manifest Rules (Foundation layer)**:
- Required: `@onready` injection for dependencies; systems must be unit-testable without a full scene tree
- Required: Canonical method names exactly as in ADR-0004 — `set_disarmed(player_id)`, `set_immobilized(player_id)`
- Forbidden: String-based signal connect() — N/A (this system emits no signals)
- Forbidden: Polling in `_process()` — N/A (pure state, no per-frame logic)

---

## Acceptance Criteria

*From GDD `design/gdd/status-effects.md`, scoped to this story:*

- [ ] **Initial state**: After instantiation, `can_fire` and `can_move` are `true` and both duration counters are `0` for both players (P1 and P2).
- [ ] **set_disarmed**: Given a Healthy player, when `set_disarmed(player_id)` is called, then `can_fire = false`, `turns_remaining_fire = 2`, and `can_move` is unchanged (still `true`).
- [ ] **set_immobilized**: Given a Healthy player, when `set_immobilized(player_id)` is called, then `can_move = false`, `turns_remaining_move = 2`, and `can_fire` is unchanged (still `true`).
- [ ] **Both effects simultaneously**: Given `set_disarmed` and `set_immobilized` are both called for the same player, then `can_fire = false`, `can_move = false`, `turns_remaining_fire = 2`, `turns_remaining_move = 2`.
- [ ] **Idempotent re-apply (counter reset)**: Given `can_fire = false` and `turns_remaining_fire = 2`, when `set_disarmed(player_id)` is called again, then `turns_remaining_fire` resets to `2` and `can_fire` remains `false`.
- [ ] **Re-apply extends restriction**: Given `can_fire = false` and `turns_remaining_fire = 1` (effect expiring), when `set_disarmed(player_id)` is called, then `turns_remaining_fire = 2` and `can_fire` remains `false`.
- [ ] **Player isolation**: Effects applied to P1 do not change P2's state, and vice versa.

---

## Implementation Notes

*Derived from ADR-0004 and GDD `design/gdd/status-effects.md`:*

Implement as a plain GDScript class (`class_name StatusEffects`, `extends Node`). No scene dependencies.

State variables (use arrays indexed by player_id 0 and 1):

```gdscript
var _can_fire: Array[bool] = [true, true]
var _can_move: Array[bool] = [true, true]
var _turns_remaining_fire: Array[int] = [0, 0]
var _turns_remaining_move: Array[int] = [0, 0]
```

Public read API (called by ActionValidation, FigureRenderer, HUDTurnIndicator):
```gdscript
func can_fire(player_id: int) -> bool
func can_move(player_id: int) -> bool
func get_status(player_id: int) -> Dictionary  # returns {can_fire: bool, can_move: bool}
```

Write API (called only by Body-Zone Hit Detection — but implemented here):
```gdscript
func set_disarmed(player_id: int) -> void:
    _can_fire[player_id] = false
    _turns_remaining_fire[player_id] = 2

func set_immobilized(player_id: int) -> void:
    _can_move[player_id] = false
    _turns_remaining_move[player_id] = 2
```

Counter initial value of `2` is the designed mechanism: first tick (2→1) keeps restriction active; second tick (1→0) restores the flag. This is not a tuning value in this story — it is the GDD-specified rule.

**Method names are canonical per ADR-0004**: no `apply()`, `disable()`, or generic `set_effect()`. Any deviation is a blocking ADR violation.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `tick_effects()` and `reset_all()` — counter decrement logic and match reset

---

## QA Test Cases

*Written by qa-lead at story creation.*

- **AC-1**: Initial state
  - Given: A new `StatusEffects` node is instantiated
  - When: State is read immediately (no other calls)
  - Then: `can_fire(0) == true`, `can_move(0) == true`, `can_fire(1) == true`, `can_move(1) == true`; all counters `== 0`

- **AC-2**: set_disarmed
  - Given: Player 0 is Healthy
  - When: `set_disarmed(0)` is called
  - Then: `can_fire(0) == false`, `_turns_remaining_fire[0] == 2`, `can_move(0) == true` (unchanged)

- **AC-3**: set_immobilized
  - Given: Player 0 is Healthy
  - When: `set_immobilized(0)` is called
  - Then: `can_move(0) == false`, `_turns_remaining_move[0] == 2`, `can_fire(0) == true` (unchanged)

- **AC-4**: Both effects simultaneously
  - Given: Player 0 is Healthy
  - When: `set_disarmed(0)` then `set_immobilized(0)` are called
  - Then: `can_fire(0) == false`, `can_move(0) == false`, both counters `== 2`
  - Edge case: order shouldn't matter — also test immobilized then disarmed

- **AC-5**: Idempotent re-apply
  - Given: `can_fire(0) == false` and `_turns_remaining_fire[0] == 2`
  - When: `set_disarmed(0)` is called again
  - Then: `_turns_remaining_fire[0] == 2` (reset, not incremented), `can_fire(0) == false`

- **AC-6**: Re-apply extends restriction
  - Given: `can_fire(0) == false` and `_turns_remaining_fire[0] == 1`
  - When: `set_disarmed(0)` is called
  - Then: `_turns_remaining_fire[0] == 2`, `can_fire(0) == false`

- **AC-7**: Player isolation
  - Given: Player 0 and Player 1 both Healthy
  - When: `set_disarmed(0)` is called
  - Then: `can_fire(0) == false`, `can_fire(1) == true` (P1 unaffected)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/status_effects/status_effects_write_api_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002 (tick_effects and reset_all depend on the write API being in place)

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 7/7 passing (all ACs verified via unit tests)
**Deviations**: tick_effects and reset_all implemented in same file (Story 002 boundary) — logic is correct but tested by Story 002. Advisory only.
**Test Evidence**: `tests/unit/status_effects/status_effects_write_api_test.gd` — 20 test functions
**Code Review**: APPROVE — GDScript specialist, no issues
