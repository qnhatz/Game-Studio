# Two-Action Turn System

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Two Actions One Regret / Read Your Opponent

## Overview

The Two-Action Turn System is the structural backbone of Flick Duel. It manages the alternating turn cycle between P1 and P2 and the per-turn action pool: one `FIRE` and one `MOVE` per turn, used in player-chosen order. Each turn proceeds through three phases — start (run `tick_effects`, build valid action set), action selection (player takes available actions in chosen order), and end (hand off to opponent). Status effects reduce the pool: a disarmed player has only `MOVE`; an immobilized player has only `FIRE`; both restricted triggers an auto-skip with no input. A player must use all available actions — there is no voluntary pass. The Turn System orchestrates all other real-time systems: it opens and closes the Input System's input window, signals Action Validation before each action, and notifies the Game Mode Manager when a turn ends or a win condition is triggered.

## Player Fantasy

Two actions and a decision: which one first? Fire first and you might land the shot that cripples their next turn — but you're still standing where they last saw you. Move first and you reposition, then fire from a harder angle — but they had one beat to read your intent. Both actions are always on the table unless your opponent took one away. The choice of sequence is the micro-drama of every turn. The turn system holds that tension open while you decide, then snaps shut the moment your second action commits.

## Detailed Rules

**Action Pool**
Each turn begins with a fixed pool: `{FIRE, MOVE}`. The player chooses which to take first. Both must be used unless the match ends mid-turn (win condition triggered after the first action).

**Turn Phases**

1. **TURN_START**: The Turn System calls `tick_effects(active_player)`. It then calls `get_valid_actions(active_player)`. If the valid set is empty → enter AUTO_SKIP phase. Otherwise → enter AWAITING_FIRST_ACTION.

2. **AWAITING_FIRST_ACTION**: The Input System's window is opened for the active player (if FIRE is valid) and/or the move affordance is enabled (if MOVE is valid). The player selects their first action.

3. **ACTION_EXECUTING**: The chosen action runs to completion (shot resolves, or figure moves). If the action triggers a win condition → match ends immediately; turn does not continue. Otherwise → mark action as used and enter AWAITING_SECOND_ACTION.

4. **AWAITING_SECOND_ACTION**: The remaining action from the pool (if still valid) is offered. The player takes it. If the second action triggers a win condition → match ends. Otherwise → enter TURN_END.

5. **TURN_END**: Active player switches. The new active player's turn begins at TURN_START.

6. **AUTO_SKIP**: Both valid actions were unavailable (both flags false). A visible skip indicator is shown. After a brief display delay → TURN_END.

**No Voluntary Pass**
A player cannot skip or defer an available action. If `MOVE` is the only remaining valid action, they must take it.

**Action Ordering**
The player freely chooses to take FIRE or MOVE first, subject to validity. The Turn System does not impose an ordering.

**Win Condition Check**
After every FIRE action resolves, the Turn System checks the Win Condition system. If a win is detected, the turn halts immediately — the second action is not taken.

## Formulas

No continuous math. The system is a state machine. Complete state transition logic:

```
# Turn state enum
TURN_START | AWAITING_FIRST_ACTION | ACTION_EXECUTING
AWAITING_SECOND_ACTION | TURN_END | AUTO_SKIP

begin_turn(active_player):
    tick_effects(active_player)            # Status Effects
    valid = get_valid_actions(active_player)  # Action Validation
    if valid.is_empty():
        state = AUTO_SKIP
    else:
        remaining_pool = valid             # {FIRE}, {MOVE}, or {FIRE, MOVE}
        state = AWAITING_FIRST_ACTION

on_action_selected(action_type):           # called by Input System or UI
    assert is_valid(active_player, action_type)
    assert action_type in remaining_pool
    state = ACTION_EXECUTING
    execute(action_type)                   # resolves shot or move
    remaining_pool.remove(action_type)
    if win_condition_met():
        end_match()
        return
    if remaining_pool.is_empty():
        state = TURN_END
    else:
        state = AWAITING_SECOND_ACTION

on_turn_end():
    active_player = opponent(active_player)
    begin_turn(active_player)

on_auto_skip():
    # tick_effects and get_valid_actions were already called in begin_turn()
    # before reaching this path — effects have ticked for this turn.
    show_skip_indicator(active_player)
    # after AUTO_SKIP_DISPLAY_MS delay:
    state = TURN_END
    on_turn_end()

halt():
    # Called by Game State Machine on match end.
    # Discards the current turn immediately. TURN_END does not fire.
    # The state machine enters HALTED and takes no further action.
    state = HALTED

reset():
    # Called by Game State Machine on rematch start.
    # Resets to initial state regardless of current state (including HALTED or mid-turn).
    state       = IDLE
    active_player = P1
    remaining_pool.clear()
    # Post-condition: system is in the same state as immediately after instantiation;
    # ready for begin_turn(P1) to be called.
```

**Constants:**

| Symbol | Value | Description |
|--------|-------|-------------|
| `AUTO_SKIP_DISPLAY_MS` | 1200 ms | Duration skip indicator is shown before turn advances (tuning knob) |

## Edge Cases

**EC1 — Win condition triggered after first action**
Match ends immediately. `remaining_pool` still contains the unused action — this is discarded. The second action is never offered. `end_match()` fires; the Turn System halts.

**EC2 — FIRE resolves but produces no hit (miss)**
Win condition check runs and returns false. Turn proceeds normally to AWAITING_SECOND_ACTION. A miss does not end the turn early.

**EC3 — Only one action in valid set (one status effect active)**
`remaining_pool` starts as `{MOVE}` or `{FIRE}`. Player takes it. `remaining_pool` becomes empty → TURN_END. The player effectively has a 1-action turn.

**EC4 — Both actions valid but player takes MOVE which causes figures to overlap**
Move resolves, win condition check runs (MOVE never triggers win condition — only FIRE can). Turn advances to AWAITING_SECOND_ACTION. Figure overlap is a Figure Geometry / collision concern, not a Turn System concern.

**EC5 — `on_action_selected` called with an action not in `remaining_pool`**
Assert fires — this is a caller error. The UI/Input System must only surface actions currently in `remaining_pool`. The Turn System does not silently ignore the duplicate; it treats it as a programming error.

**EC6 — Auto-skip display interrupted (e.g. browser tab loses focus)**
The skip indicator timer is paused when the game loses focus. It resumes on focus return. The turn does not advance during a focus loss.

**EC7 — `halt()` called mid-turn (e.g. match ends on first action)**
`halt()` immediately transitions to `HALTED`. The second action in `remaining_pool` is discarded. `TURN_END` does not fire. No further state transitions occur until `reset()` is called.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Action Validation | Calls `get_valid_actions`, `is_valid`, `is_turn_skipped` at turn start and before each action |
| Depends on | Status Effects | Calls `tick_effects(player_id)` at the start of each player's turn |
| Depends on | Win Condition | Queries win state after each FIRE action resolves |
| Consumed by | Game Mode Manager | Receives `turn_ended` signal to track match state and determine game over |
| Consumed by | Input System | Receives open/close input window signals from Turn System |
| Consumed by | HUD / Turn Indicator | Reads active player and remaining pool to display turn state |
| Consumed by | AI Targeting | Receives `awaiting_action(FIRE)` signal when it is the AI player's fire turn |

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `AUTO_SKIP_DISPLAY_MS` | 1200 ms | 600–2000 ms | Duration the auto-skip indicator is shown. Too short = players miss the feedback; too long = pacing drags when a double-restricted state occurs. |

No other numerical knobs — the action pool size (2) and action types (FIRE, MOVE) are structural constants, not tunable without redesigning the game.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | Turn starts by calling `tick_effects` before any action query | Unit test: assert `tick_effects` is called before `get_valid_actions` on `begin_turn` |
| AC2 | Healthy player: `remaining_pool` starts as `{FIRE, MOVE}` | Unit test: begin_turn with both flags true → assert pool == {FIRE, MOVE} |
| AC3 | Disarmed player: `remaining_pool` starts as `{MOVE}` | Unit test: begin_turn with can_fire=false → assert pool == {MOVE} |
| AC4 | Immobilized player: `remaining_pool` starts as `{FIRE}` | Unit test: begin_turn with can_move=false → assert pool == {FIRE} |
| AC5 | Both restricted: state enters AUTO_SKIP, no action input accepted | Unit test: begin_turn with both false → assert state == AUTO_SKIP, assert no input window opened |
| AC6 | After first action, `remaining_pool` shrinks by one | Unit test: healthy player takes FIRE → assert pool == {MOVE} |
| AC7 | After second action, state enters TURN_END and active player switches | Unit test: healthy player takes both actions → assert active_player switched |
| AC8 | Win condition triggered after FIRE halts turn — second action not offered | Integration test: simulate headshot → assert TURN_END fires without AWAITING_SECOND_ACTION |
| AC9 | A miss after FIRE does not end the turn | Unit test: FIRE resolves with no hit → assert state == AWAITING_SECOND_ACTION |
| AC10 | `on_action_selected` with action not in pool raises an error | Unit test: call with FIRE when pool == {MOVE} → assert assertion/error raised |
| AC11 | Auto-skip display lasts `AUTO_SKIP_DISPLAY_MS` before turn advances | Unit test with mocked timer: assert turn_end fires after exactly 1200 ms delay |
