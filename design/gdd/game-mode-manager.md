# Game Mode Manager

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Local First / Instant to Learn

## Overview

The Game Mode Manager configures and owns the match session. It accepts a mode selection from the Main Menu — `TWO_PLAYER_LOCAL` or `ONE_PLAYER_VS_AI` — and produces a `MatchConfig`: a value object specifying the controller type (HUMAN or AI) for each player slot. In `TWO_PLAYER_LOCAL`, both slots are HUMAN. In `ONE_PLAYER_VS_AI`, P1 is HUMAN and P2 is AI. The Game State Machine reads `MatchConfig` to set up the match, and the Turn System uses it to determine whether to open the human input window or trigger AI Targeting on each FIRE action. The Game Mode Manager also receives the `match_won` signal from Win Condition and decides what happens next: in MVP, it simply forwards to the Game State Machine to display the match result.

## Player Fantasy

Two friends, one screen — pick 2P and the duel begins immediately. Solo, pick 1P and you face the AI. The mode choice is a single tap on the main menu; there is no lobby, no network setup, no configuration screen. The notebook is already open. The only question is who is holding the other pen.

## Detailed Rules

**Mode Selection**
Exactly two modes exist in MVP:
- `TWO_PLAYER_LOCAL` — both players are human, sharing the same device
- `ONE_PLAYER_VS_AI` — P1 is human, P2 is the AI opponent

**MatchConfig**
On mode selection, Game Mode Manager produces a `MatchConfig` value object:

| Field | TWO_PLAYER_LOCAL | ONE_PLAYER_VS_AI |
|-------|-----------------|-----------------|
| `p1_controller` | HUMAN | HUMAN |
| `p2_controller` | HUMAN | AI |
| `mode` | TWO_PLAYER_LOCAL | ONE_PLAYER_VS_AI |

**Match Lifecycle**
1. Main Menu emits `mode_selected(mode)` → Game Mode Manager creates `MatchConfig` and emits `match_ready(config)` to Game State Machine
2. Match runs under Turn System control
3. Win Condition emits `match_won(winner_id)` → Game Mode Manager receives it and emits `match_ended(winner_id, config)` to Game State Machine
4. Game State Machine displays result; on rematch or menu return, Game Mode Manager is reset

**AI Side**
In `ONE_PLAYER_VS_AI`, P2 is always the AI. The human is always P1 (left side). There is no "pick your side" option in MVP.

**No Mid-Match Mode Switch**
The mode cannot change once a match begins. A mode change requires returning to the Main Menu.

## Formulas

No math. Complete logic:

```
on_mode_selected(mode):
    if mode == TWO_PLAYER_LOCAL:
        config = MatchConfig(p1=HUMAN, p2=HUMAN, mode=TWO_PLAYER_LOCAL)
    elif mode == ONE_PLAYER_VS_AI:
        config = MatchConfig(p1=HUMAN, p2=AI, mode=ONE_PLAYER_VS_AI)
    emit match_ready(config)

on_match_won(winner_id):
    emit match_ended(winner_id, current_config)

is_ai(player_id) → bool:
    return current_config[player_id] == AI
```

**Variable domains:**

| Symbol | Type | Values |
|--------|------|--------|
| `mode` | enum | `{TWO_PLAYER_LOCAL, ONE_PLAYER_VS_AI}` |
| `controller` | enum | `{HUMAN, AI}` |
| `player_id` | enum | `{P1, P2}` |

## Edge Cases

**EC1 — `mode_selected` called while a match is already in progress**
Reject silently — no new `MatchConfig` is produced. A mode change requires the Game State Machine to first return to menu state.

**EC2 — `match_won` received before a mode has been selected**
Should not occur — Win Condition can only fire during an active match, which requires a prior `mode_selected`. Log an error and ignore if somehow reached.

**EC3 — Player requests rematch from result screen**
Game State Machine signals rematch intent. Game Mode Manager re-emits `match_ready(current_config)` with the same config — same mode, same controller assignments. No new mode selection is required.

**EC4 — AI opponent wins in ONE_PLAYER_VS_AI**
`match_won(P2)` is received normally. `match_ended` is emitted with winner=P2. The result screen handles the "you lost" display. Game Mode Manager has no special loss handling.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Two-Action Turn System | Turn System queries `is_ai(player_id)` to determine whether to open human input or trigger AI |
| Receives from | Main Menu | Receives `mode_selected(mode)` to create MatchConfig |
| Receives from | Win Condition | Receives `match_won(winner_id)` to forward match-end signal |
| Signals | Game State Machine | Emits `match_ready(config)` on match start and `match_ended(winner_id, config)` on match end |
| Consumed by | AI Targeting | Reads `is_ai(P2)` to confirm it should act on P2's FIRE turns |

## Tuning Knobs

No tuning knobs. Mode routing is a binary configuration with no numerical parameters. AI difficulty is owned by AI Difficulty Config, not this system.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | `TWO_PLAYER_LOCAL` produces MatchConfig with both controllers = HUMAN | Unit test: call `on_mode_selected(TWO_PLAYER_LOCAL)` → assert p1=HUMAN, p2=HUMAN |
| AC2 | `ONE_PLAYER_VS_AI` produces MatchConfig with p1=HUMAN, p2=AI | Unit test: call `on_mode_selected(ONE_PLAYER_VS_AI)` → assert p1=HUMAN, p2=AI |
| AC3 | `match_ready(config)` is emitted on mode selection | Unit test: assert signal emitted with correct config after `on_mode_selected` |
| AC4 | `match_won(winner_id)` triggers `match_ended(winner_id, config)` | Unit test: call `on_match_won(P1)` → assert `match_ended` emitted with winner=P1 |
| AC5 | `is_ai(P2)` returns true in ONE_PLAYER_VS_AI mode | Unit test: set mode to ONE_PLAYER_VS_AI → assert `is_ai(P2) == true` |
| AC6 | `is_ai(P1)` returns false in both modes | Unit test: both modes → assert `is_ai(P1) == false` |
| AC7 | Rematch re-emits `match_ready` with same config, no mode re-selection | Unit test: trigger rematch → assert `match_ready` emitted with identical config |
| AC8 | `mode_selected` during active match is rejected | Unit test: call `on_mode_selected` mid-match → assert no new `match_ready` emitted |
