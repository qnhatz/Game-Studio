# Game State Machine

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Instant to Learn / Local First

## Overview

The Game State Machine is the top-level lifecycle controller for Flick Duel. It owns four states — `MENU`, `MATCH`, `MATCH_END`, and `REMATCH_CONFIRM` — and transitions between them in response to signals from the Main Menu, Game Mode Manager, and player input. It is the single system that activates and deactivates other systems: it starts the Turn System when entering `MATCH`, freezes all game input when entering `MATCH_END`, and calls `Status Effects.reset_all()` on every new match. Nothing runs without the Game State Machine's say-so.

## Player Fantasy

The game feels seamless — menu to match is one tap, match end to rematch is one tap. There are no loading screens, no transition delays beyond the match-result display. The notebook is always there; you are just deciding what is written in it next.

## Detailed Rules

**States**

| State | Description | Active systems |
|-------|-------------|----------------|
| `MENU` | Main Menu is visible; no match in progress | Main Menu only |
| `MATCH` | Match in progress; Turn System running | All gameplay systems |
| `MATCH_END` | Match result displayed; all input frozen except rematch/menu | Match Result Screen |
| `REMATCH_CONFIRM` | Brief transition state while resetting match data | None (transitional) |

**Transitions**

| From | Event | To | Actions |
|------|-------|----|---------|
| `MENU` | `match_ready(config)` from Game Mode Manager | `MATCH` | `Status_Effects.reset_all()`, start Turn System, hide menu |
| `MATCH` | `match_ended(winner_id, config)` from Game Mode Manager | `MATCH_END` | Freeze input, show Match Result Screen with winner |
| `MATCH_END` | Player taps "Rematch" | `REMATCH_CONFIRM` | Hide result screen |
| `MATCH_END` | Player taps "Menu" | `MENU` | Hide result screen, show Main Menu |
| `REMATCH_CONFIRM` | (immediate) | `MATCH` | `Status_Effects.reset_all()`, reset figure positions, restart Turn System |

**Input Freeze**
On entering `MATCH_END`, the Game State Machine closes the Input System's input window and disables all gesture input. Only the result screen's buttons (Rematch, Menu) accept input.

**Figure Reset on Rematch**
On `REMATCH_CONFIRM → MATCH`, figure anchors reset to their Screen Layout defaults (`P1_ANCHOR`, `P2_ANCHOR`). Any positional changes from MOVE actions during the previous match are discarded.

## Formulas

No math. Complete state transition logic:

```
# State enum
MENU | MATCH | MATCH_END | REMATCH_CONFIRM

on_match_ready(config):
    assert current_state == MENU
    Status_Effects.reset_all()
    reset_figure_positions()
    Turn_System.start(config)
    current_state = MATCH

on_match_ended(winner_id, config):
    assert current_state == MATCH
    Turn_System.halt()
    Input_System.close_window()
    Match_Result_Screen.show(winner_id)
    current_state = MATCH_END

on_rematch_pressed():
    assert current_state == MATCH_END
    Match_Result_Screen.hide()
    current_state = REMATCH_CONFIRM
    # immediate transition:
    Status_Effects.reset_all()
    reset_figure_positions()
    Turn_System.start(current_config)
    current_state = MATCH

on_menu_pressed():
    assert current_state == MATCH_END
    Match_Result_Screen.hide()
    Main_Menu.show()
    current_state = MENU
```

## Edge Cases

**EC1 — Browser back button pressed during MATCH**
Treat as "Menu" navigation. Transition to `MATCH_END` is skipped — go directly to `MENU`, halting the Turn System and resetting all state. No result is shown.

**EC2 — Page is refreshed mid-match**
Browser reload resets all in-memory state. The game restarts from `MENU`. There is no save/resume in MVP.

**EC3 — `match_ended` received while already in `MATCH_END`**
Reject — this is a duplicate signal. Log a warning and ignore. The result screen is already showing.

**EC4 — Rematch pressed before result screen is fully visible**
Input on the result screen buttons is only enabled after the screen's enter animation completes. Button presses before that are discarded by the UI layer, not by this system.

**EC5 — `on_match_ready` called while in `MATCH` state (mid-match mode re-selection)**
Assert fails — rejected by Game Mode Manager before reaching this system (EC1 in Game Mode Manager GDD). Defensive assert here as belt-and-suspenders.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Game Mode Manager | Receives `match_ready` and `match_ended` signals |
| Depends on | Win Condition | Indirectly — Win Condition signals Game Mode Manager, which forwards to this system |
| Controls | Two-Action Turn System | Calls `start(config)` and `halt()` |
| Controls | Input System | Calls `close_window()` on match end |
| Controls | Status Effects | Calls `reset_all()` on match start and rematch |
| Controls | Main Menu | Shows/hides menu node |
| Controls | Match Result Screen | Shows/hides result screen with winner info |

## Tuning Knobs

No numerical tuning knobs. All transitions are event-driven with no timers or delays at the state machine level. Result screen display duration is owned by the Match Result Screen system.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | `match_ready` from MENU → state becomes MATCH, Turn System started | Unit test: assert state==MATCH and Turn_System.start called after `on_match_ready` |
| AC2 | `Status_Effects.reset_all()` called on every match start | Unit test: assert reset_all called in `on_match_ready` and in rematch path |
| AC3 | `match_ended` from MATCH → state becomes MATCH_END, input frozen | Unit test: assert state==MATCH_END and Input_System.close_window called |
| AC4 | Match Result Screen shown with correct winner on MATCH_END | Unit test: assert `Match_Result_Screen.show(winner_id)` called with correct ID |
| AC5 | Rematch → MATCH_END → MATCH, same config, state resets | Unit test: assert state==MATCH after rematch, reset_all called, Turn_System restarted |
| AC6 | Menu press → MATCH_END → MENU, Main Menu shown | Unit test: assert state==MENU and Main_Menu.show called after `on_menu_pressed` |
| AC7 | `match_ended` received in MATCH_END state is silently ignored | Unit test: call `on_match_ended` while state==MATCH_END → assert no state change, warning logged |
| AC8 | `on_match_ready` while state==MATCH raises an assertion error | Unit test: assert error raised when called mid-match |
