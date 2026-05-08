# Movement

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Two Actions One Regret / Read Your Opponent

## Overview

The Movement system handles the MOVE action: the player repositions their figure horizontally within their own player zone. The player taps a destination point inside their gesture region; the figure's anchor X snaps to that X position (clamped to zone bounds). Y position never changes — figures always stand at anchor Y = 338. There is no animation in MVP; the figure teleports to the new position on the same frame the tap is processed. Movement is bounded by the player's zone: P1 cannot move past x=320, P2 cannot move past x=480. This system updates Figure Geometry's anchor for the active player and nothing else.

## Player Fantasy

You dragged your feet sideways on the notebook. One step left, one step right — not a run, just a shift. Enough to get out of the line the opponent just drew. Enough to make your next shot come from a harder angle. Movement is not a sprint; it is a lean. Both players watch the figure slide and start recalculating.

## Detailed Rules

**Input**
A MOVE action is triggered by a tap (mouse click or touch tap) anywhere inside the active player's gesture region (per Screen Layout). The tap must occur during the `AWAITING_FIRST_ACTION` or `AWAITING_SECOND_ACTION` phase when MOVE is in the `remaining_pool`. Drags that exceed `TAP_MOVE_RADIUS_PX` are interpreted as FIRE drag attempts — not moves. Short taps (< `TAP_MOVE_RADIUS_PX` total displacement) are moves.

**Destination Clamping**
The figure's new anchor X is the tap X coordinate, clamped to the player's zone bounds with a margin:
- P1: `new_x = clamp(tap.x, P1_ZONE.x + MOVE_MARGIN_PX, P1_ZONE.x + P1_ZONE.w − MOVE_MARGIN_PX)`
- P2: `new_x = clamp(tap.x, P2_ZONE.x + MOVE_MARGIN_PX, P2_ZONE.x + P2_ZONE.w − MOVE_MARGIN_PX)`

Anchor Y is unchanged. `MOVE_MARGIN_PX` prevents the figure from touching the zone edge, keeping the figure fully on-screen.

**Minimum Move Distance**
A tap within `MIN_MOVE_PX` of the current anchor X is still a valid MOVE action — the figure stays in place (or moves by less than one pixel). The action is consumed from the pool; there is no "no-op move" refusal. Players cannot bank a MOVE to avoid using it.

**Instant Repositioning**
No animation. The figure anchor updates on the frame the tap resolves. All downstream systems (Figure Renderer, Figure Geometry, AI Targeting) read the new anchor on the next draw call.

**Zone Ownership**
A player can only move within their own zone. The active player's zone boundaries are the hard constraint — a P1 tap that resolves at x=350 (inside the corridor) is clamped to x=320 (or `320 − MOVE_MARGIN_PX` with margin applied). The corridor and opponent's zone are never valid destinations.

**AI MOVE**
When the AI takes a MOVE action, it selects a destination X using simple heuristics (defined in AI Targeting GDD): move toward the human if distance > `AI_PREFERRED_DISTANCE`, move away if distance < `AI_MIN_DISTANCE`, otherwise stay near current position. The destination is subject to the same clamping rules.

## Formulas

**F1 — New Anchor Position**
```
on_move_tapped(tap_position, player_id):
    zone   = (player_id == P1) ? P1_ZONE : P2_ZONE
    min_x  = zone.x + MOVE_MARGIN_PX
    max_x  = zone.x + zone.w − MOVE_MARGIN_PX
    new_x  = clamp(tap_position.x, min_x, max_x)
    set_anchor(player_id, Vector2(new_x, P1_ANCHOR.y))   # Y is constant
```

**Constants:**

| Symbol | Value | Description |
|--------|-------|-------------|
| `MOVE_MARGIN_PX` | 20 px | Minimum distance from zone edge; keeps figure fully on-screen |
| `MIN_MOVE_PX` | 0 px | Minimum displacement required — any tap is valid; action is always consumed |
| `TAP_MOVE_RADIUS_PX` | 12 px | Max drag displacement to interpret tap as MOVE vs. FIRE drag |

**F2 — Input Disambiguation**
```
on_touch_begin(position, player_id):
    drag_start = position

on_touch_end(position, player_id):
    displacement = distance(drag_start, position)
    if displacement < TAP_MOVE_RADIUS_PX:
        # It's a tap — treat as MOVE if MOVE is in remaining_pool
        if MOVE in remaining_pool:
            on_move_tapped(position, player_id)
    else:
        # It's a drag — handle as FIRE FlickEvent
        pass  # Input System handles drag-to-shot
```

## Edge Cases

**EC1 — MOVE tapped outside player zone (e.g. in corridor)**
Tap X is clamped to zone bounds. The figure still moves — to the nearest valid position. The MOVE action is consumed. No error is raised.

**EC2 — MOVE tapped in the HUD strip (y < 90)**
The gesture region excludes the HUD strip (Screen Layout rule). Taps at y < 90 are discarded by the Input System before reaching Movement. This system never receives a tap originating in the HUD strip.

**EC3 — MOVE taken as first action; figure moves; figure is now inside a shot line from a previous turn**
Figures and shot lines are purely visual — figures never collide with shot lines. The move is valid. The visual of the figure overlapping an old shot line is acceptable; the notebook aesthetic treats the page as layered.

**EC4 — Both players move to identical X positions**
Valid. Both figures share the same X but retain their separate zones and anchors. Hit zone boundaries are computed from each anchor independently — there is no figure-to-figure collision.

**EC5 — MOVE taken while Immobilized (can_move = false)**
Cannot occur — Action Validation prevents MOVE from appearing in `remaining_pool` when `can_move = false`. The input system does not interpret taps as MOVE actions when MOVE is not in the pool.

**EC6 — Player taps very close to zone boundary; clamped X would place figure partially outside zone**
`MOVE_MARGIN_PX = 20` ensures the anchor never goes closer than 20 px to the zone edge. At default figure geometry, this keeps the widest hit zone (arms, ±40 px) fully inside the player zone with a small margin.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Screen Layout | Reads player zone boundaries for clamping; reads `ANCHOR_Y` for the constant Y position |
| Depends on | Input System | Receives tap position after input disambiguation (tap vs. drag) |
| Depends on | Action Validation | MOVE action only offered when `can_move = true` (enforced by Turn System) |
| Writes to | Figure Geometry | Updates `anchor(player_id)` to the new position |
| Called by | Two-Action Turn System | Turn System calls `on_move_tapped` when MOVE is selected; receives no return value |

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `MOVE_MARGIN_PX` | 20 px | 10–40 px | How close the figure can get to the zone edge. Too low: figure clips zone boundary; Too high: effective movement range shrinks noticeably. |
| `TAP_MOVE_RADIUS_PX` | 12 px | 6–24 px | Threshold for tap-vs-drag disambiguation. Too low: fast drags misread as moves; Too high: intentional short drags misread as taps. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | Tapping P1's zone during MOVE action updates P1 anchor X to tap X | Unit test: inject tap at x=150 → assert P1 anchor.x == 150 |
| AC2 | Anchor Y never changes after a MOVE | Unit test: move P1 → assert anchor.y == 338 |
| AC3 | Tap at x=5 (near left edge) is clamped to `P1_ZONE.x + MOVE_MARGIN_PX = 20` | Unit test: tap at x=5 → assert anchor.x == 20 |
| AC4 | Tap in corridor (x=350) is clamped to P1 zone right boundary | Unit test: P1 tap at x=350 → assert anchor.x == 300 (320 − 20) |
| AC5 | MOVE action is consumed after a valid tap | Unit test: MOVE in pool; tap → assert MOVE no longer in remaining_pool |
| AC6 | A tap within MIN_MOVE_PX of current position still consumes MOVE | Unit test: tap 1 px from current anchor → assert action consumed, no error |
| AC7 | Drag exceeding TAP_MOVE_RADIUS_PX is not treated as a MOVE | Unit test: release at 20 px displacement with MOVE in pool → assert MOVE not consumed |
| AC8 | Figure Geometry reads new anchor on same frame as move | Integration test: MOVE action → assert figure drawn at new position in same frame |
| AC9 | P2 move is clamped to P2 zone (x ≥ 480 + margin) | Unit test: P2 tap at x=460 → assert anchor.x == 500 (480 + 20) |
