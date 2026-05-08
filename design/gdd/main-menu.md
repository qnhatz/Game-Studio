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
1. **"2 Players"** — emits `mode_selected(TWO_PLAYER_LOCAL)` immediately on tap
2. **"vs Computer"** — opens the difficulty selector inline (see below)

No other interactive elements in MVP. No settings, no how-to-play, no credits.

**Difficulty Selector**
Tapping "vs Computer" reveals a 3-option inline selector below the button:
- **Easy** / **Medium** / **Hard** — horizontally arranged, `DIFFICULTY_BUTTON_W` each
- Default pre-selected option: **Medium** (highlighted on appear)
- Tapping a difficulty option emits `difficulty_selected(level)` followed immediately by `mode_selected(ONE_PLAYER_VS_AI)` and hides the selector
- The "vs Computer" button is disabled while the selector is visible (prevents reopening)
- Both the selector and main buttons are hidden when `mode_selected` fires

The selector appears with no animation — it renders on the frame the tap is processed.

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
        disable_input()
        emit mode_selected(TWO_PLAYER_LOCAL)
    elif button_id == VS_COMPUTER:
        show_difficulty_selector()

on_difficulty_tapped(level):          # level ∈ {EASY, MEDIUM, HARD}
    disable_input()
    emit difficulty_selected(level)
    emit mode_selected(ONE_PLAYER_VS_AI)

on_show():
    set_visible(true)
    difficulty_selector.hide()
    enable_input()

on_hide():
    set_visible(false)
    disable_input()

show_difficulty_selector():
    difficulty_selector.show()
    difficulty_selector.set_default(MEDIUM)
    vs_computer_button.disable()
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
| Signals | AI Difficulty Config | Emits `difficulty_selected(level)` before `mode_selected`; AI Difficulty Config stores the selection for the upcoming match |
| Controlled by | Game State Machine | Receives show/hide calls; only visible in MENU state |

No other dependencies. The Main Menu does not read from any gameplay system.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| Button width | 220 px | 160–280 px | Tap target size. Must remain ≥ 48 px in height after scaling. |
| Button height | 60 px | 48–80 px | Tap target height. Lower bound is accessibility minimum. |
| Button vertical gap | 24 px | 12–40 px | Spacing between the two buttons. |
| `DIFFICULTY_BUTTON_W` | 80 px | 60–100 px | Width of each difficulty option button. Three fit side-by-side below the "vs Computer" button. |

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
| AC8 | Tapping "vs Computer" shows difficulty selector with Medium pre-selected | Manual: tap "vs Computer" → assert selector visible, Medium highlighted |
| AC9 | Tapping "Easy" emits `difficulty_selected(EASY)` then `mode_selected(ONE_PLAYER_VS_AI)` | Unit test: tap Easy → assert both signals emitted in order |
| AC10 | Difficulty selector is hidden on `on_show()` (fresh menu display) | Unit test: call `on_show()` → assert selector not visible |
