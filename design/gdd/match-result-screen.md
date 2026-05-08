# Match Result Screen

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Instant to Learn / Notebook Duel Aesthetic

## Overview

The Match Result Screen is displayed by the Game State Machine when a match ends. It shows the winner identity, a result label ("P1 WINS" / "P2 WINS"), and two action buttons: "Rematch" and "Menu". It is an overlay drawn on top of the frozen match canvas — the final game state (figures, shot lines, status overlays) remains visible beneath it. The screen accepts input only after its enter animation completes. It emits `rematch_pressed` or `menu_pressed` to the Game State Machine, then hides itself.

## Player Fantasy

The notebook page freezes mid-shot. A result is written across it in large bold ink — the kind of annotation a teacher writes over a student's work. Both players see it at the same moment on the shared screen. The two buttons are small and unobtrusive: the page is the main event, not the UI chrome.

## Detailed Rules

**Content**
- Result label: "P1 WINS" (blue ink) or "P2 WINS" (red ink), large text, canvas centre
- Rematch button: bottom-centre of overlay
- Menu button: below Rematch button
- No score, no stats, no animation beyond the enter transition in MVP

**Enter Animation**
The result label fades in over `RESULT_ENTER_MS`. Buttons are disabled during this animation and enabled immediately after it completes.

**Overlay**
The screen is a semi-transparent panel over the frozen match canvas. Background fill: white at `RESULT_OVERLAY_ALPHA` opacity. The frozen game state remains legible beneath.

**Button Behaviour**
- "Rematch": emits `rematch_pressed`, screen hides
- "Menu": emits `menu_pressed`, screen hides
- Both buttons: minimum tap area 48×48 px; valid on mouse click and touch tap; no hover state

**Auto-hide**
The screen does not auto-dismiss. It persists until a button is tapped.

## Formulas

**F1 — Label Fade-In Alpha**
```
label_alpha = clamp(age / RESULT_ENTER_MS, 0.0, 1.0)
```
- `age`: ms since screen was shown
- Buttons enabled when `label_alpha == 1.0`

No other computation. Logic:

```
show(winner_id):
    result_label.text = winner_id == P1 ? "P1 WINS" : "P2 WINS"
    result_label.colour = winner_id == P1 ? BLUE_INK : RED_INK
    buttons.disable()
    start_enter_animation()

on_enter_animation_complete():
    buttons.enable()

on_rematch_button_pressed():
    emit rematch_pressed
    hide()

on_menu_button_pressed():
    emit menu_pressed
    hide()
```

## Edge Cases

**EC1 — Button tapped during enter animation**
Buttons are disabled until animation completes. The tap is discarded. No signal emitted.

**EC2 — Screen shown immediately after Game State Machine freezes input**
The Input System's gesture window is already closed by the Game State Machine before `show()` is called. No race condition — game input is frozen before the result screen appears.

**EC3 — Both buttons tapped rapidly in sequence**
The first tap emits a signal and hides the screen. The second tap is discarded — the screen is no longer visible and its buttons are inactive.

**EC4 — Rematch pressed, next match starts, then `show()` called again**
`show()` resets all internal state (label text, alpha, button state) before displaying. Each call is a clean display cycle.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Controlled by | Game State Machine | Receives `show(winner_id)` and `hide()` calls |
| Signals | Game State Machine | Emits `rematch_pressed` or `menu_pressed` on button tap |

No gameplay system dependencies. This screen only receives a winner ID and emits button events.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `RESULT_ENTER_MS` | 400 ms | 150–800 ms | Label fade-in duration. Shorter = abrupt; longer = too slow before buttons enable. |
| `RESULT_OVERLAY_ALPHA` | 0.55 | 0.3–0.75 | Overlay panel opacity. Lower = final game state too readable, result hard to see; higher = game state obscured. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | "P1 WINS" displayed in blue ink when P1 wins | Manual: P1 lands headshot → assert label text and colour |
| AC2 | "P2 WINS" displayed in red ink when P2 wins | Manual: P2 lands headshot → assert label text and colour |
| AC3 | Buttons disabled during enter animation | Manual: tap Rematch before 400ms → assert no signal emitted |
| AC4 | Buttons enabled after enter animation completes | Manual: wait 400ms → assert buttons respond to tap |
| AC5 | Rematch button emits `rematch_pressed` and hides screen | Integration test: tap Rematch → assert signal emitted and screen not visible |
| AC6 | Menu button emits `menu_pressed` and hides screen | Integration test: tap Menu → assert signal emitted and screen not visible |
| AC7 | Frozen game canvas visible beneath overlay | Manual: result screen shown → assert figure and shot lines visible under panel |
| AC8 | Double-tap on Rematch emits signal exactly once | Manual: rapid double-tap → assert `rematch_pressed` emitted once |
