# Main Menu

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Instant to Learn / Notebook Duel Aesthetic

## Overview

The Main Menu is the entry point of Flick Duel. It presents exactly two choices — **2 Players** and **vs Computer** — and emits `mode_selected(mode)` to the Game Mode Manager when the player taps one. It has no sub-screens, no settings, no credits in MVP. It is shown on first load and whenever the player returns from a match result screen. The menu is styled per the art bible: notebook paper background, hand-drawn title lettering, two ink-stroke buttons.

## Player Fantasy

You open the game and the notebook page is already there. The title is written in ballpoint pen. Two buttons: one for the person sitting next to you, one for when you are alone. One tap and the duel begins. There is no preamble.

## Detailed Rules

**Buttons**
Two buttons, vertically stacked at canvas centre:
1. **"2 Players"** — emits `mode_selected(TWO_PLAYER_LOCAL)`
2. **"vs Computer"** — emits `mode_selected(ONE_PLAYER_VS_AI)`

No other interactive elements in MVP. No settings, no how-to-play, no credits.

**Visibility**
Shown on game load and whenever the Game State Machine transitions to `MENU` state. Hidden when a match begins.

**Input**
Both mouse click and touch tap are valid. No hover states — mobile browser compatibility requires tap-only interaction per technical preferences.

**Button tap area**
Each button has a minimum tap target of 48×48 px per accessibility requirements. Actual button size should be larger (see Tuning Knobs).

**No confirmation**
Tapping a button immediately emits `mode_selected`. There is no "are you sure?" step.

## Formulas

No math. Complete interaction logic:

```
on_button_tapped(button_id):
    if button_id == TWO_PLAYERS:
        emit mode_selected(TWO_PLAYER_LOCAL)
    elif button_id == VS_COMPUTER:
        emit mode_selected(ONE_PLAYER_VS_AI)

on_show():
    set_visible(true)
    enable_input()

on_hide():
    set_visible(false)
    disable_input()
```

## Edge Cases

**EC1 — Button double-tapped before Game State Machine hides the menu**
The menu is hidden by the Game State Machine after `mode_selected` is received. A second tap before the menu hides would emit a second `mode_selected`. Game Mode Manager rejects the second call (EC1 in that GDD). The menu should disable its own input after the first tap to prevent duplicate signals.

**EC2 — Menu shown while in portrait orientation**
The orientation gate (Screen Layout) is active — gameplay input is suspended, but the menu itself is a UI overlay and is still visible. The "Rotate your device" prompt appears on top. Menu buttons are disabled until landscape orientation is restored.

**EC3 — Game loaded on a very small viewport (< 400 px wide)**
The logical canvas scales to fit. Menu buttons remain centred in logical canvas space and scale with the canvas. No special layout adjustments needed.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Signals | Game Mode Manager | Emits `mode_selected(mode)` on button tap |
| Controlled by | Game State Machine | Receives show/hide calls; only visible in MENU state |

No other dependencies. The Main Menu does not read from any gameplay system.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| Button width | 220 px | 160–280 px | Tap target size. Must remain ≥ 48 px in height after scaling. |
| Button height | 60 px | 48–80 px | Tap target height. Lower bound is accessibility minimum. |
| Button vertical gap | 24 px | 12–40 px | Spacing between the two buttons. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | Tapping "2 Players" emits `mode_selected(TWO_PLAYER_LOCAL)` | Unit test: simulate tap on button → assert signal emitted with correct mode |
| AC2 | Tapping "vs Computer" emits `mode_selected(ONE_PLAYER_VS_AI)` | Unit test: simulate tap → assert signal emitted with ONE_PLAYER_VS_AI |
| AC3 | Menu is visible on game load | Manual: load game → assert menu visible before any button press |
| AC4 | Menu is hidden after mode selection | Integration test: tap button → assert menu not visible after Game State Machine processes signal |
| AC5 | Double-tap emits only one `mode_selected` signal | Unit test: simulate two rapid taps → assert signal emitted exactly once |
| AC6 | Both buttons have tap area ≥ 48×48 px | Visual test: inspect button Rect2 in scene → assert size.x ≥ 48, size.y ≥ 48 |
| AC7 | Menu reappears when Game State Machine returns to MENU state | Integration test: complete a match and tap "Menu" → assert main menu visible |
