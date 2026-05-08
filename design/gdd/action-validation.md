# Action Validation

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Skill Earns the Win / Clear Consequences

## Overview

Action Validation is the gatekeeper between a player's current Status Effects state and the actions they may take on their turn. At the start of each turn, after `tick_effects` has run, it constructs a **valid action set** for the active player — a subset of `{FIRE, MOVE}` based on the player's `can_fire` and `can_move` flags. The Two-Action Turn System consults this set before presenting or accepting any action. If the valid action set is empty (both flags false), the turn is automatically skipped. Action Validation is stateless — it reads Status Effects flags and returns a result; it holds nothing between calls.

## Player Fantasy

The player never sees Action Validation — they see its output. Reaching for the fire button and finding it greyed out is a moment of clarity: *your drawing arm is crossed out, you can't*. The constraint lands with narrative weight because it was earned by your opponent's aim. The validation system makes that consequence legible and immediate, with no explanation needed.

## Detailed Rules

**Action Types**
There are exactly two action types: `FIRE` and `MOVE`. No other action types exist in MVP.

**Valid Action Set**
At any point during a player's turn, their valid action set is computed on demand by reading the current Status Effects flags:
- `FIRE` is valid if and only if `can_fire[player_id] == true`
- `MOVE` is valid if and only if `can_move[player_id] == true`

**Query Model**
Action Validation exposes two functions:
- `get_valid_actions(player_id)` → returns the full valid action set for display/UI
- `is_valid(player_id, action_type)` → returns true/false for a single action query

The Turn System calls `is_valid` before accepting each action attempt. The valid set does not change mid-turn — `tick_effects` only runs at turn start.

**Auto-Skip**
If `get_valid_actions` returns an empty set (both flags false), `is_turn_skipped(player_id)` returns true. The Turn System auto-skips that turn without prompting the player for input.

**Ordering Guarantee**
`tick_effects(player_id)` must be called by the Turn System before any call to `get_valid_actions` or `is_valid` for that turn. Action Validation does not enforce this ordering — the Turn System owns it.

## Formulas

This system contains no continuous math — all logic is boolean. The complete specification is expressed as pseudocode.

```
get_valid_actions(player_id) → Set<ActionType>:
    actions = {}
    if can_fire[player_id]:  actions.add(FIRE)
    if can_move[player_id]:  actions.add(MOVE)
    return actions

is_valid(player_id, action_type) → bool:
    if action_type == FIRE:  return can_fire[player_id]
    if action_type == MOVE:  return can_move[player_id]
    return false   # unknown action type → never valid

is_turn_skipped(player_id) → bool:
    return get_valid_actions(player_id).is_empty()
```

**Variable domains:**

| Symbol | Type | Valid values |
|--------|------|-------------|
| `action_type` | enum | `{FIRE, MOVE}` |
| `can_fire`, `can_move` | bool | `{true, false}` — sourced from Status Effects |
| return of `get_valid_actions` | Set | subset of `{FIRE, MOVE}` |
| return of `is_valid` | bool | `{true, false}` |
| return of `is_turn_skipped` | bool | `{true, false}` |

## Edge Cases

**EC1 — Unknown action type passed to `is_valid`**
Return `false`. No action type outside `{FIRE, MOVE}` is ever valid. Do not throw an error — treat as a silently invalid query.

**EC2 — `is_valid` called before `tick_effects` for this turn**
Action Validation reads the live flags from Status Effects — it will return whatever the flags currently say. If called before `tick_effects`, it may return stale (pre-tick) values. This is a Turn System ordering violation, not an Action Validation bug. The Turn System must guarantee `tick_effects` precedes any validation query.

**EC3 — Both flags false: `get_valid_actions` returns empty set**
`is_turn_skipped` returns true. The Turn System auto-skips the turn. Action Validation makes no UI call — the Turn System handles the skip indicator. This is an expected, non-error state.

**EC4 — Player attempts to repeat the same action twice in one turn**
Action Validation does not track action history or enforce the 2-action pool. Repeat-action prevention is the Turn System's responsibility. `is_valid` will return the same answer for the same action on the same turn regardless of how many times it was already taken.

**EC5 — `get_valid_actions` called for the inactive player**
Returns their flags faithfully. Action Validation does not know whose turn it is — it answers any query for any player. The Turn System is responsible for only querying the active player.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Status Effects | Reads `can_fire[player_id]` and `can_move[player_id]` — sole data source |
| Consumed by | Two-Action Turn System | Calls `is_valid`, `get_valid_actions`, and `is_turn_skipped` before each action and at turn start |

This system has no other dependencies. It reads two boolean flags and returns derived booleans or sets. It does not write to any system.

## Tuning Knobs

This system has no numerical tuning knobs — it is pure boolean logic derived entirely from Status Effects flags.

**Extensibility note**: If a new action type is added in a future version (e.g. `RELOAD`, `DEFEND`), Action Validation must be extended with a corresponding flag and `is_valid` branch. Any such addition requires a Status Effects update and an Action Validation update in lockstep.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | `can_fire=true, can_move=true` → valid set = `{FIRE, MOVE}` | Unit test: set both flags true → assert `get_valid_actions` returns `{FIRE, MOVE}` |
| AC2 | `can_fire=false, can_move=true` → valid set = `{MOVE}` | Unit test: set can_fire=false → assert `get_valid_actions` returns `{MOVE}` only |
| AC3 | `can_fire=true, can_move=false` → valid set = `{FIRE}` | Unit test: set can_move=false → assert `get_valid_actions` returns `{FIRE}` only |
| AC4 | `can_fire=false, can_move=false` → valid set = `{}`, `is_turn_skipped` = true | Unit test: set both false → assert empty set and `is_turn_skipped == true` |
| AC5 | `is_valid(player, FIRE)` with `can_fire=false` returns false | Unit test: assert `is_valid(P1, FIRE) == false` when `can_fire[P1] = false` |
| AC6 | `is_valid(player, MOVE)` with `can_move=true` returns true | Unit test: assert `is_valid(P1, MOVE) == true` when `can_move[P1] = true` |
| AC7 | Unknown action type returns false without error | Unit test: call `is_valid(P1, UNKNOWN)` → assert `false`, no exception thrown |
| AC8 | `is_turn_skipped` returns false when at least one action is valid | Unit test: set can_fire=true, can_move=false → assert `is_turn_skipped == false` |
