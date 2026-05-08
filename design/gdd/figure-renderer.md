# Figure Renderer

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Notebook Duel Aesthetic / Read the Body

## Overview

The Figure Renderer draws each player's stick figure onto the notebook canvas using Figure Geometry for zone positions and Status Effects for visual state. It renders four layers per figure: the base stick figure (head circle, torso line, arm lines, leg lines) in the player's ink colour; a crossed-out overlay on the arms if Disarmed; a crossed-out overlay on the legs if Immobilized; and a flash effect on the most recently hit zone. P2's figure is horizontally mirrored. The renderer is purely visual — it reads game state but writes nothing back. It updates every frame.

## Player Fantasy

The stick figure on the page tells the whole story. Blue ink on the left, red ink on the right, both drawn as if a steady hand just put them there. When your arm gets crossed out in the opponent's colour, it is not a status icon — it is a mark on your body. The notebook is filling up with evidence of what just happened. Both players can read it.

## Detailed Rules

**Base Figure**
Drawn from Figure Geometry offsets relative to the player's current anchor position:
- Head: circle at `anchor + (0, −162)`, radius 18 px
- Torso: line from `anchor + (0, −144)` (neck base) to `anchor + (0, −72)` (hip)
- Arms: two lines from `anchor + (0, −126)` (shoulder) to `anchor + (±40, −108)` (hands)
- Legs: two lines from `anchor + (0, −72)` (hip) to `anchor + (±18, 0)` (feet)

All drawn in the player's ink colour (P1: blue `#1A4FBF`, P2: red `#CC2200`), line width `FIGURE_LINE_W`.

**P2 Mirror**
P2's figure is horizontally mirrored about its anchor X. Arm and leg X offsets are negated — the figure faces left instead of right. Hit zone boundaries are unchanged (see Figure Geometry EC4).

**Status Overlays**
- **Disarmed**: draw a bold X through the arms zone in the *opponent's* ink colour, centred on the arms rect
- **Immobilized**: draw a bold X through the legs zone in the *opponent's* ink colour, centred on the legs rect
- Overlays are shown while `can_fire == false` or `can_move == false` respectively

**Hit Flash**
On a zone hit, the struck zone flashes for `HIT_FLASH_MS`: the zone is filled/highlighted in the attacker's ink colour before returning to normal. Head hit triggers the flash but the match ends — the flash is shown on the result screen freeze frame.

**Stroke Style**
All lines are drawn with slight hand-drawn imperfection (jitter of ±`JITTER_PX` px per vertex, applied once at figure creation, not per frame) to match the notebook aesthetic. Jitter is deterministic per figure instance.

## Formulas

**F1 — Status Overlay X stroke**
```
# Draw two diagonal lines through zone rect
x_line_1: from (rect.x,          rect.y)          to (rect.x + rect.w, rect.y + rect.h)
x_line_2: from (rect.x + rect.w, rect.y)          to (rect.x,          rect.y + rect.h)
colour    = opponent_ink_colour
line_width = OVERLAY_LINE_W
```

**F2 — Hit Flash Alpha**
```
flash_alpha = 1.0 − clamp(hit_age / HIT_FLASH_MS, 0.0, 1.0)
```
- `hit_age`: ms since the hit was registered
- `flash_alpha` modulates a filled overlay on the struck zone: 1.0 → fully filled, 0.0 → invisible

**F3 — Jitter Application (once at figure spawn)**
```
for each vertex v in figure_geometry:
    v.x += random_uniform(−JITTER_PX, JITTER_PX)
    v.y += random_uniform(−JITTER_PX, JITTER_PX)
# JITTER_PX = 1.5 (tuning knob)
# Seed: hash(player_id + match_id) for determinism
```

## Edge Cases

**EC1 — Both status overlays active simultaneously**
Both X overlays are drawn — one on the arms rect, one on the legs rect. No conflict; they are on different zones.

**EC2 — Hit flash and status overlay on the same zone**
A hit flash on the arms zone may coincide with an existing Disarmed X overlay. Both are rendered: flash fades over `HIT_FLASH_MS`; overlay persists until the effect expires. Draw order: base figure → status overlay → hit flash (so flash appears on top).

**EC3 — Figure anchor changes mid-turn (after a MOVE action)**
The renderer reads the current anchor every frame. When the anchor updates, all drawn positions update automatically on the next frame. No special handling needed.

**EC4 — Match ends mid-flash (headshot)**
The flash is drawn on the final frame before the Game State Machine freezes input and shows the result screen. The result screen displays the frozen frame — flash is visible in the final image.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Figure Geometry | Reads zone positions and figure dimensions for all draw operations |
| Depends on | Status Effects | Reads `can_fire`, `can_move` per player to show/hide overlays |
| Depends on | Screen Layout | Reads player anchors as figure origin |
| Reads from | Body-Zone Hit Detection | Receives hit zone result to trigger flash effect |

This system writes only to the renderer. It modifies no game state.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `FIGURE_LINE_W` | 2.5 px | 1.5–4.0 px | Base figure stroke weight. Thinner = delicate sketch; thicker = bold pen. |
| `OVERLAY_LINE_W` | 4.0 px | 2.5–6.0 px | X overlay stroke weight. Should be visibly heavier than base figure. |
| `HIT_FLASH_MS` | 300 ms | 150–600 ms | Duration of zone hit flash. Too short = unnoticeable; too long = distracting. |
| `JITTER_PX` | 1.5 px | 0–3.0 px | Hand-drawn imperfection magnitude. 0 = perfectly clean lines; 3 = noticeably wobbly. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | P1 figure drawn in blue ink, P2 in red ink | Manual: start match → assert P1 figure is `#1A4FBF`, P2 is `#CC2200` |
| AC2 | Disarmed overlay (X on arms) appears when `can_fire == false` | Manual: disarm P1 → assert bold X visible over P1 arms zone |
| AC3 | Immobilized overlay (X on legs) appears when `can_move == false` | Manual: immobilize P1 → assert bold X visible over P1 legs zone |
| AC4 | Overlays disappear when status expires | Manual: wait one turn after disarm → assert X overlay removed |
| AC5 | Disarmed overlay uses opponent's ink colour | Manual: P2 disarms P1 → assert overlay on P1 is red (P2's colour) |
| AC6 | Hit flash appears on struck zone and fades over HIT_FLASH_MS | Manual: land an arm hit → assert flash visible, fades within 300 ms |
| AC7 | P2 figure is horizontally mirrored | Manual: compare P1 and P2 figures → assert P2 arms extend to opposite side |
| AC8 | Both overlays visible simultaneously when both restricted | Manual: land arm + leg hit on same player → assert both X overlays present |
| AC9 | Figure redraws at new position after MOVE action | Manual: AI or player moves → assert figure drawn at new anchor position next frame |
