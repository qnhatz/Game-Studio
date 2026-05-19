# Story 001: ActionValidation Logic

> **Epic**: Action Validation
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/action-validation.md`
**Requirement**: `TR-ACV-001`, `TR-ACV-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (System Communication)
**ADR Decision Summary**: Direct method calls on critical path. `get_valid_actions(player_id)`, `is_valid(player_id, action_type)`, and `is_turn_skipped(player_id)` are called by TwoActionTurnSystem before accepting each action. Stateless — reads StatusEffects flags, returns derived booleans.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript boolean logic. No engine APIs. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: Stateless — no instance variables beyond the StatusEffects reference; no cache
- Required: `@onready` injection for StatusEffects reference (unit-testable via mock)
- Forbidden: ActionValidation must not write to any system

---

## Acceptance Criteria

*From GDD `design/gdd/action-validation.md`:*

- [ ] `can_fire=true, can_move=true` → `get_valid_actions` returns a set containing both `FIRE` and `MOVE`.
- [ ] `can_fire=false, can_move=true` → `get_valid_actions` returns only `MOVE`.
- [ ] `can_fire=true, can_move=false` → `get_valid_actions` returns only `FIRE`.
- [ ] `can_fire=false, can_move=false` → `get_valid_actions` returns an empty set; `is_turn_skipped` returns `true`.
- [ ] `is_valid(player, &"FIRE")` with `can_fire=false` returns `false`.
- [ ] `is_valid(player, &"MOVE")` with `can_move=true` returns `true`.
- [ ] Unknown action type returns `false` without error or exception.
- [ ] `is_turn_skipped` returns `false` when at least one action is valid.

---

## Implementation Notes

*Derived from ADR-0004 and GDD pseudocode:*

```gdscript
class_name ActionValidation
extends Node

var _status_effects: Node = null  # injected; concrete type StatusEffects

func get_valid_actions(player_id: int) -> Array[StringName]:
    var actions: Array[StringName] = []
    if _status_effects.can_fire(player_id):
        actions.append(&"FIRE")
    if _status_effects.can_move(player_id):
        actions.append(&"MOVE")
    return actions

func is_valid(player_id: int, action_type: StringName) -> bool:
    if action_type == &"FIRE":
        return _status_effects.can_fire(player_id)
    if action_type == &"MOVE":
        return _status_effects.can_move(player_id)
    return false

func is_turn_skipped(player_id: int) -> bool:
    return get_valid_actions(player_id).is_empty()
```

Inject a mock `StatusEffects` in tests by setting `_status_effects` directly before the test. The mock only needs to implement `can_fire(player_id) -> bool` and `can_move(player_id) -> bool`.

Use `StringName` literals (`&"FIRE"`, `&"MOVE"`) throughout — never plain strings.

---

## Out of Scope

*N/A — this is the only story in this epic.*

---

## QA Test Cases

- **AC-1**: Both valid
  - Given: Mock StatusEffects with `can_fire(0)=true`, `can_move(0)=true`
  - When: `get_valid_actions(0)` called
  - Then: Result contains &"FIRE" and &"MOVE"

- **AC-2**: Only MOVE valid
  - Given: `can_fire(0)=false`, `can_move(0)=true`
  - When: `get_valid_actions(0)` called
  - Then: Result contains only &"MOVE"

- **AC-3**: Only FIRE valid
  - Given: `can_fire(0)=true`, `can_move(0)=false`
  - When: `get_valid_actions(0)` called
  - Then: Result contains only &"FIRE"

- **AC-4**: Both invalid → auto-skip
  - Given: `can_fire(0)=false`, `can_move(0)=false`
  - When: `get_valid_actions(0)` then `is_turn_skipped(0)` called
  - Then: Empty array; `is_turn_skipped` returns `true`

- **AC-5 to AC-8**: is_valid and edge cases
  - Given: Various flag states
  - When: `is_valid` called with FIRE/MOVE/unknown action type
  - Then: Returns correct boolean; unknown returns `false` without error

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/action_validation/action_validation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Status Effects epic (Stories 001+002) must be DONE (StatusEffects API must exist)
- Unlocks: TwoActionTurnSystem epic (calls ActionValidation at turn start)
