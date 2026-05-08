# HUD / Turn Indicator

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Read the Body / Instant to Learn

## Overview

The HUD/Turn Indicator occupies the top 90 px strip of the canvas (Screen Layout `HUD_H`). It displays three pieces of information: which player's turn it is (centre turn indicator), how many actions each player has used this turn (action pip counters in each player's HUD cell), and which status effects are currently active for each player (icons in each player's HUD cell). It reads from the Two-Action Turn System (active player, remaining action pool) and Status Effects (flags), and updates every frame. It is purely visual — no input is handled here.

## Player Fantasy

At a glance, both players know whose turn it is and what is left to do. The turn indicator in the centre is the shared clock — it tells the person not playing to wait, and the person playing to act. The action pips show one pip consumed after the first action, two after both. The status icons confirm what the figure already shows — a small redundant signal that makes the state unambiguous even if someone is not watching the figure closely.

## Detailed Rules

**Layout** (all positions within the 800×90 px HUD strip, per Screen Layout)

| Element | Position | Description |
|---------|----------|-------------|
| P1 HUD cell | x 0–320, y 0–90 | Action pips + status icons for P1 |
| Turn indicator | x 280–520, y 0–90 | Active player arrow or label, centred |
| P2 HUD cell | x 480–800, y 0–90 | Action pips + status icons for P2 |

**Turn Indicator**
- Displays an arrow pointing toward the active player's side (← for P1, → for P2)
- During AUTO_SKIP: displays a crossed-circle or "SKIP" text in the skipped player's colour
- Drawn in the active player's ink colour

**Action Pip Counter**
Each player's HUD cell shows two pips (small circles): filled = action available, hollow = action used.
- At turn start: both pips filled for the active player
- After first action: one pip becomes hollow
- After second action (or turn end): both pips hollow
- During opponent's turn: both pips hollow (turn is not theirs)
- If a status effect removes an action: the removed action pip is shown as an X instead of a circle

**Status Effect Icons**
Each player's HUD cell shows up to two small icons:
- **Disarmed icon**: a pen with a cross through it, shown when `can_fire == false`
- **Immobilized icon**: two crossed legs, shown when `can_move == false`
- Icons are shown in the affected player's HUD cell, in the opponent's ink colour
- Icons disappear when the effect expires

## Formulas

No math. Rendering logic:

```
draw_hud(active_player, remaining_pool, p1_status, p2_status):

    # Turn indicator
    if turn_state == AUTO_SKIP:
        draw_skip_indicator(skipped_player)
    else:
        draw_arrow(direction: active_player == P1 ? LEFT : RIGHT,
                   colour: active_player.ink_colour)

    # Action pips per player
    for player in {P1, P2}:
        fire_available = player == active_player AND FIRE in remaining_pool
        move_available = player == active_player AND MOVE in remaining_pool
        draw_pip(FIRE, filled: fire_available, x_mark: NOT status[player].can_fire)
        draw_pip(MOVE, filled: move_available, x_mark: NOT status[player].can_move)

    # Status icons per player
    for player in {P1, P2}:
        if NOT status[player].can_fire:
            draw_icon(DISARMED, cell: player, colour: opponent(player).ink_colour)
        if NOT status[player].can_move:
            draw_icon(IMMOBILIZED, cell: player, colour: opponent(player).ink_colour)
```

## Edge Cases

**EC1 — AUTO_SKIP state: both pips shown as X for skipped player**
Both `can_fire` and `can_move` are false → both pips show X marks. The turn indicator shows the SKIP state. This is consistent and legible.

**EC2 — Active player has only one action (one status effect active)**
The removed action pip shows an X. The remaining pip is filled. After the player takes their one action, the remaining pip becomes hollow.

**EC3 — HUD cells overlap at x 280–320 and x 480–520 (turn indicator zone)**
The turn indicator overlaps the inner edges of both HUD cells by 40 px each. Status icons and pips must be positioned in the outer portions of each cell (x 0–240 for P1, x 560–800 for P2) to avoid overlap.

**EC4 — Status icon displayed for inactive player**
Status icons reflect current game state for both players regardless of whose turn it is. If P1 is Disarmed during P2's turn, P1's Disarmed icon is still visible.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Two-Action Turn System | Reads active player, remaining action pool, turn state (for AUTO_SKIP) |
| Depends on | Status Effects | Reads `can_fire`, `can_move` per player for pip X marks and status icons |
| Depends on | Screen Layout | Uses HUD strip dimensions and cell rects for layout |

Read-only. No writes to game state.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| Pip size | 12 px diameter | 8–18 px | Readability of action counter. Must be legible at canvas scale on mobile. |
| Icon size | 20×20 px | 14–28 px | Readability of status effect icons. |
| Turn arrow size | 28 px | 20–40 px | Visibility of active player indicator. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | Turn arrow points left (←) on P1's turn, right (→) on P2's turn | Manual: start match → assert arrow direction matches active player |
| AC2 | Both pips filled at turn start for active player | Manual: begin P1's turn → assert both P1 pips filled |
| AC3 | One pip hollow after first action | Manual: P1 takes FIRE → assert one P1 pip hollow |
| AC4 | Both pips hollow after second action | Manual: P1 takes both actions → assert both P1 pips hollow |
| AC5 | Disarmed pip shown as X for FIRE action | Manual: disarm P1 → assert P1 FIRE pip shows X |
| AC6 | Disarmed icon appears in P1's HUD cell in P2's ink colour | Manual: P2 disarms P1 → assert DISARMED icon visible in P1 cell, red colour |
| AC7 | Status icons disappear when effect expires | Manual: wait one turn after disarm → assert icon removed |
| AC8 | SKIP indicator shown during AUTO_SKIP | Manual: double-restrict a player → assert SKIP indicator visible in turn indicator |
| AC9 | Inactive player's status icons still visible during opponent's turn | Manual: disarm P1, switch to P2's turn → assert P1 Disarmed icon still shown |
