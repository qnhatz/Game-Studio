# Story 002: StatusEffects Tick and Reset

> **Epic**: Status Effects
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/status-effects.md`
**Requirement**: `TR-STE-003`, `TR-STE-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (System Communication Architecture), ADR-0001 (Scene Topology — reset_all is step 1 of the match reset sequence)
**ADR Decision Summary**: `tick_effects(player_id)` called by TwoActionTurnSystem at TURN_START before action validation; `reset_all()` called by GameStateMachine in the defined reset sequence. Both are direct calls (Pattern A — synchronous critical path).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript — no engine API dependencies. No post-cutoff APIs used.

**Control Manifest Rules (Foundation layer)**:
- Required: Canonical method names exactly as in ADR-0004 — `tick_effects(player_id)`, `reset_all()`
- Required: `tick_effects` must be callable safely on a Healthy player (no-op, no side effects)
- Forbidden: `tick_effects` must not be called more than once per player per turn start — the Turn System owns this guarantee; `StatusEffects` does not enforce it

---

## Acceptance Criteria

*From GDD `design/gdd/status-effects.md`, scoped to this story:*

- [ ] **Tick 2→1 stays restricted**: Given `can_fire = false` and `turns_remaining_fire = 2`, when `tick_effects(player_id)` is called once, then `turns_remaining_fire = 1` and `can_fire` is still `false`.
- [ ] **Tick 1→0 restores flag**: Given `can_fire = false` and `turns_remaining_fire = 1`, when `tick_effects(player_id)` is called, then `turns_remaining_fire = 0` and `can_fire = true`.
- [ ] **No-op on Healthy player**: Given both counters are `0` and both flags are `true`, when `tick_effects(player_id)` is called, then all flags remain `true` and all counters remain `0` (no side effects).
- [ ] **Staggered counters tick independently**: Given `turns_remaining_fire = 1` and `turns_remaining_move = 2`, when `tick_effects(player_id)` is called, then `can_fire = true` (fire counter hit 0) and `can_move = false` (move counter is now 1).
- [ ] **Both Restricted tick**: Given both counters are `2` (Both Restricted state), when `tick_effects(player_id)` is called, then both counters become `1` and both flags remain `false` (restriction still active this turn).
- [ ] **reset_all clears all effects**: Given both players have active effects with non-zero counters, when `reset_all()` is called, then both players have `can_fire = true`, `can_move = true`, `turns_remaining_fire = 0`, `turns_remaining_move = 0`.
- [ ] **reset_all is idempotent**: Given all players are already Healthy, when `reset_all()` is called, then state remains clean with no errors.

---

## Implementation Notes

*Derived from ADR-0004 and GDD `design/gdd/status-effects.md`:*

```gdscript
func tick_effects(player_id: int) -> void:
    if _turns_remaining_fire[player_id] > 0:
        _turns_remaining_fire[player_id] -= 1
        if _turns_remaining_fire[player_id] == 0:
            _can_fire[player_id] = true
    if _turns_remaining_move[player_id] > 0:
        _turns_remaining_move[player_id] -= 1
        if _turns_remaining_move[player_id] == 0:
            _can_move[player_id] = true

func reset_all() -> void:
    for pid in range(2):
        _can_fire[pid] = true
        _can_move[pid] = true
        _turns_remaining_fire[pid] = 0
        _turns_remaining_move[pid] = 0
```

The two counter branches in `tick_effects` are fully independent — both fire/move counters are decremented in the same call. The `> 0` guard ensures the function is a no-op when no effects are active.

**Ordering constraint (from ADR-0004 and GDD)**: `tick_effects` must be called at TURN_START before ActionValidation queries `can_fire`/`can_move`. The Turn System owns this ordering guarantee; `StatusEffects` does not enforce or verify it.

**Counter semantics** (for test clarity):
- Counter = 2 → flag is false, restriction applies this turn (tick reduces to 1, flag stays false)
- Counter = 1 → flag is false, restriction still applies (tick reduces to 0, flag restores to true)
- Counter = 0 → flag is true, player is unrestricted

---

## Out of Scope

*Handled by Story 001 — do not implement here:*

- `set_disarmed()`, `set_immobilized()`, initial state, and the read API (`can_fire()`, `can_move()`, `get_status()`) — all in Story 001

---

## QA Test Cases

*Written by qa-lead at story creation.*

- **AC-1**: Tick 2→1 stays restricted
  - Given: `set_disarmed(0)` has been called (counter = 2, can_fire = false)
  - When: `tick_effects(0)` is called once
  - Then: `_turns_remaining_fire[0] == 1`, `can_fire(0) == false`

- **AC-2**: Tick 1→0 restores flag
  - Given: `_turns_remaining_fire[0] = 1`, `can_fire(0) == false` (set manually or via tick from 2)
  - When: `tick_effects(0)` is called
  - Then: `_turns_remaining_fire[0] == 0`, `can_fire(0) == true`

- **AC-3**: No-op on Healthy player
  - Given: New `StatusEffects` instance (all flags true, all counters 0)
  - When: `tick_effects(0)` is called
  - Then: `can_fire(0) == true`, `can_move(0) == true`, both counters still `0`
  - Edge case: also call `tick_effects(1)` — must also be a no-op

- **AC-4**: Staggered counters
  - Given: `set_disarmed(0)` called then `tick_effects(0)` called (fire counter: 2→1); then `set_immobilized(0)` called (move counter = 2)
  - When: `tick_effects(0)` called again (fire: 1→0, move: 2→1)
  - Then: `can_fire(0) == true` (restored), `can_move(0) == false` (still restricted), `_turns_remaining_fire[0] == 0`, `_turns_remaining_move[0] == 1`

- **AC-5**: Both Restricted tick
  - Given: `set_disarmed(0)` and `set_immobilized(0)` both called (both counters = 2)
  - When: `tick_effects(0)` is called once
  - Then: `_turns_remaining_fire[0] == 1`, `_turns_remaining_move[0] == 1`, `can_fire(0) == false`, `can_move(0) == false`

- **AC-6**: reset_all clears active effects
  - Given: Player 0 has `set_disarmed(0)` applied; Player 1 has `set_immobilized(1)` applied
  - When: `reset_all()` is called
  - Then: `can_fire(0) == true`, `can_move(0) == true`, `_turns_remaining_fire[0] == 0`, `_turns_remaining_move[0] == 0`; same for P1

- **AC-7**: reset_all is idempotent
  - Given: New `StatusEffects` instance (all clean)
  - When: `reset_all()` is called
  - Then: No error; all flags still `true`, all counters still `0`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/status_effects/status_effects_tick_reset_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be DONE (write API and state variables must exist)
- Unlocks: All downstream consumers (ActionValidation, FigureRenderer, HUDTurnIndicator, GameStateMachine) can now reference the complete StatusEffects API

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 7/7 passing (all ACs verified via unit tests)
**Deviations**: None
**Test Evidence**: `tests/unit/status_effects/status_effects_tick_reset_test.gd` — 13 test functions
**Code Review**: APPROVE — GDScript specialist, no issues
