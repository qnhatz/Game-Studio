# Win Condition

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Skill Earns the Win / Clear Consequences

## Overview

The Win Condition system has a single responsibility: receive a `HEAD` hit result from Body-Zone Hit Detection and signal the Game State Machine that the match is over. It holds no state and performs no calculation — it is a pure pass-through that gives the win signal a named, auditable home rather than embedding the end-match logic inside Hit Detection or the Turn System. It identifies the winner as the opponent of the player who was hit in the head, and emits `match_won(winner_id)` to the Game State Machine.

## Player Fantasy

The headshot is the only way to win. Arms and legs hits chip away at your opponent's options, but they stay in the fight. The head is the one irreversible result — no recovery, no next turn. That finality is what makes every other shot feel like a setup. You disarm them, you pin them, you back them into a position where the head is the only honest target — and then you take it.

## Detailed Rules

**Win Condition**
A match ends immediately when Body-Zone Hit Detection returns `HEAD` for a FIRE action. There is no other win condition in MVP.

**Winner Identification**
The winner is the firing player (the one whose shot resolved as HEAD). The loser is the target player.

**Signal**
On a HEAD hit, Win Condition emits `match_won(winner_id)` to the Game State Machine. The Turn System halts — no second action is offered, no further input is accepted.

**Draw**
There is no draw condition. Turns alternate indefinitely until a headshot lands. Stalemate is not a designed outcome.

**Match End vs Game End**
Win Condition signals one match ending. The Game Mode Manager determines whether this ends the game session (single match) or advances to the next match (if best-of-N is implemented). Win Condition does not know about session structure.

## Formulas

No math. Complete logic:

```
on_hit_resolved(hit_result, firing_player_id, target_player_id):
    if hit_result == HEAD:
        emit match_won(winner_id: firing_player_id)
        return WIN
    return NO_WIN
```

**Variable domains:**

| Symbol | Type | Values |
|--------|------|--------|
| `hit_result` | enum | `{HEAD, ARMS, LEGS, MISS}` |
| `firing_player_id` | enum | `{P1, P2}` |
| return value | enum | `{WIN, NO_WIN}` |

## Edge Cases

**EC1 — HEAD hit during the first action of a turn**
`match_won` is emitted. Turn System halts immediately. The second action is never offered. This is the expected fast-win case.

**EC2 — ARMS or LEGS result passed to Win Condition**
`on_hit_resolved` returns `NO_WIN`. No signal is emitted. Normal turn flow continues.

**EC3 — MISS result passed to Win Condition**
Same as EC2 — returns `NO_WIN`, no signal.

**EC4 — `match_won` emitted while a shot line is still animating**
The Game State Machine receives the signal and transitions to match-end state. Visual systems (shot line fade, figure renderer) are halted or frozen by the Game State Machine — Win Condition does not manage visuals.

**EC5 — Both players theoretically hit simultaneously**
Geometrically impossible — only one player fires per action, and turns are strictly alternating. There is no simultaneous fire in this game.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Body-Zone Hit Detection | Receives `hit_result` — WIN only triggers on `HEAD` |
| Signals | Game Mode Manager | Emits `match_won(winner_id)`; Game Mode Manager enriches this to `match_ended(winner_id, config)` for the Game State Machine |
| Called by | Two-Action Turn System | Turn System calls `on_hit_resolved` after each FIRE action; halts turn on WIN return |

This system has no internal state and no other dependencies.

## Tuning Knobs

No tuning knobs. The win condition is a binary rule: headshot wins. There are no thresholds, timers, or configurable parameters.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | `HEAD` result emits `match_won(firing_player_id)` | Unit test: call with HEAD, P1 firing → assert signal emitted with winner=P1 |
| AC2 | `ARMS` result returns `NO_WIN`, no signal emitted | Unit test: call with ARMS → assert return == NO_WIN, no signal |
| AC3 | `LEGS` result returns `NO_WIN`, no signal emitted | Unit test: call with LEGS → assert return == NO_WIN, no signal |
| AC4 | `MISS` result returns `NO_WIN`, no signal emitted | Unit test: call with MISS → assert return == NO_WIN, no signal |
| AC5 | Winner is the firing player, not the target | Unit test: HEAD by P2 → assert winner_id == P2 |
| AC6 | Turn System receives WIN return and halts turn (no second action) | Integration test: headshot on first action → assert AWAITING_SECOND_ACTION never entered |
