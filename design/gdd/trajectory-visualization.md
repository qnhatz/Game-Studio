# Trajectory Visualization

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Instant to Learn / Notebook Duel Aesthetic

## Overview

Trajectory Visualization renders two kinds of lines: the **aim line**, a live rubber-band drawn from the figure anchor to the drag endpoint (opposite direction — slingshot model) while the player is dragging, and the **shot line**, a persistent ink stroke drawn from the figure anchor in the resolved shot direction when the player releases. The aim line updates every frame during drag and disappears on release. The shot line appears on release, extends to the canvas edge or first zone boundary hit, and fades after a fixed display duration. Both lines use the active player's ink colour (P1: blue, P2: red) per the art bible. This system reads from the Input System and Screen Layout; it does not perform hit detection — it only draws.

## Player Fantasy

The aim line is your intent made visible. As you drag back, a line extends forward showing exactly where the shot will go — before spread is applied. It is an honest preview: aim well and you know where the shot is heading. The moment you release, the aim line vanishes and the shot line takes its place — a permanent ink stroke across the page that shows everyone what you did. A head shot leaves a red line through the head. A miss leaves a line in empty space. The notebook fills with evidence of the duel.

## Detailed Rules

**Aim Line**
- Drawn from `figure_anchor` to the projected shot endpoint while `power > 0` during a drag
- Direction: `normalize(figure_anchor − drag_endpoint)` (slingshot — opposite drag direction)
- Length: `power × AIM_LINE_MAX_LENGTH` px — scales with drag distance so a short drag shows a short preview
- Updated every frame during drag; removed immediately on release or cancellation
- Rendered in the active player's ink colour at `AIM_LINE_ALPHA` opacity (dimmer than the shot line — it is intent, not fact)
- The aim line shows the **pre-spread** direction. Spread is applied at release; the aim line is not adjusted retroactively.

**Shot Line**
- Drawn from `figure_anchor` in the **resolved direction** (post-spread, from Shot Spread Calculation) on release
- Extends from `figure_anchor` to `CANVAS_EDGE` along the resolved direction — always drawn to the full canvas width regardless of hit or miss
- Rendered in the active player's ink colour at full opacity
- Persists for `SHOT_LINE_DISPLAY_MS` then fades over `SHOT_LINE_FADE_MS`
- Multiple shot lines may be visible simultaneously (previous turns' lines still fading)

**Ink Colours**
- P1: blue ink (`#1A4FBF` — per art bible)
- P2: red ink (`#CC2200` — per art bible)
- Both aim line and shot line use the firing player's colour

## Formulas

**F1 — Aim Line Endpoint**
```
aim_direction = normalize(figure_anchor − drag_endpoint)
aim_length    = power × AIM_LINE_MAX_LENGTH
aim_endpoint  = figure_anchor + aim_direction × aim_length
```
- `power` ∈ [0, 1] from FlickEvent (live, updates each frame)
- `AIM_LINE_MAX_LENGTH = 200` px (tuning knob)

**F2 — Shot Line Endpoint**
```
shot_endpoint = figure_anchor + resolved_direction × CANVAS_DIAGONAL
# clamp to canvas bounds: find t where ray exits Rect2(0,0,800,450)
# use slab method (same as Figure Geometry F3) to find exit t
shot_endpoint = figure_anchor + resolved_direction × t_exit
```
- `resolved_direction`: unit Vector2 from Shot Spread Calculation
- `CANVAS_DIAGONAL = 922` px (= sqrt(800²+450²)) — used as max_t before clamping to canvas

**F3 — Shot Line Fade**
```
alpha = 1.0 − clamp((age − SHOT_LINE_DISPLAY_MS) / SHOT_LINE_FADE_MS, 0.0, 1.0)
```
- `age`: ms since shot line was drawn
- While `age < SHOT_LINE_DISPLAY_MS`: `alpha = 1.0` (fully visible)
- During fade: alpha decreases linearly from 1.0 → 0.0
- When `alpha = 0`: line is removed from scene

## Edge Cases

**EC1 — Drag cancelled (power < MIN_POWER on release)**
Aim line is removed immediately. No shot line is drawn. Input System emits no FlickEvent; this system receives no release signal and does nothing.

**EC2 — Shot line from a previous turn is still fading when a new shot fires**
Both lines coexist. Up to `MAX_VISIBLE_SHOT_LINES` fading lines may be on screen simultaneously. Older lines continue their fade independently.

**EC3 — Shot line direction is exactly horizontal or vertical**
Standard canvas-bounds clamping (slab method) handles degenerate axis-aligned rays without division by zero, using INF substitution as in Figure Geometry F3.

**EC4 — Aim line endpoint exits the canvas during drag**
Clamp `aim_endpoint` to canvas bounds. The aim line never renders outside the logical canvas.

**EC5 — Active player switches mid-fade (opponent's shot line still visible)**
Shot lines are owned by their firing player's colour. P1's blue lines and P2's red lines may be fading simultaneously. No visual conflict — colour differentiates ownership.

**EC6 — Match ends while shot lines are still visible**
On receiving the match-end signal, all active shot line timers are frozen at their current state. No further fade or removal occurs until `reset()` is called. The winning shot line remains fully visible beneath the result screen overlay for as long as it is displayed. Shot lines do not tick during the match-end or rematch-confirm states.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Input System | Reads `FlickEvent` live during drag (direction, power) and on release (resolved direction) |
| Depends on | Screen Layout | Reads `P1_ANCHOR`, `P2_ANCHOR` as line origins; reads canvas bounds for endpoint clamping |
| Depends on | Shot Spread Calculation | Receives resolved direction at release to draw the shot line |
| No output to | Hit Detection | Does not feed hit data — purely visual; Hit Detection runs its own ray test independently |

This system writes only to the renderer. It reads data but modifies no game state.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `AIM_LINE_MAX_LENGTH` | 200 px | 120–300 px | Maximum aim line length at full power. Shorter = less telegraphing; longer = easier to read intended direction. |
| `AIM_LINE_ALPHA` | 0.45 | 0.2–0.7 | Aim line opacity. Lower = subtle intent preview; higher = too prominent, competes with shot lines. |
| `SHOT_LINE_DISPLAY_MS` | 2000 ms | 1000–4000 ms | How long shot line stays fully opaque. Shorter = less clutter; longer = more readable evidence of past shots. |
| `SHOT_LINE_FADE_MS` | 600 ms | 200–1200 ms | Fade-out duration. Shorter = abrupt disappearance; longer = smoother but more visual noise. |
| `MAX_VISIBLE_SHOT_LINES` | 6 | 2–10 | Maximum simultaneous fading shot lines. Cap prevents visual clutter in long matches. Oldest lines are removed first if cap is exceeded. |

**Reset**

```
reset():
    # Remove all active shot lines from scene
    # Unfreeze timers (no-op if not frozen)
    # Hide aim line
    # Post-condition: no shot lines or aim lines are visible; system is ready for a new match
    shot_lines.clear()
    aim_line.hide()
    frozen = false
```

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | Aim line appears during drag with power > 0, disappears on release | Manual: drag figure → assert line visible; release → assert line gone |
| AC2 | Aim line length = power × 200 at default tuning | Unit test: inject power=0.5 → assert aim line length == 100 px |
| AC3 | Aim line direction is opposite to drag direction (slingshot) | Unit test: drag right → assert aim line points left (negative X component) |
| AC4 | Shot line is drawn in resolved direction (post-spread), not drag direction | Unit test: inject resolved_direction ≠ pre-spread direction → assert shot line uses resolved_direction |
| AC5 | Shot line extends to canvas boundary | Unit test: assert shot_endpoint lies on canvas edge (Rect2 boundary) for several directions |
| AC6 | Shot line is fully opaque for SHOT_LINE_DISPLAY_MS, then fades | Unit test with mocked timer: assert alpha==1.0 at t=1999ms; assert alpha<1.0 at t=2001ms |
| AC7 | Shot line is removed after SHOT_LINE_DISPLAY_MS + SHOT_LINE_FADE_MS | Unit test: assert line node removed from scene at t=2600ms (2000+600) |
| AC8 | P1 aim/shot lines are blue, P2 are red | Manual: fire as P1 → assert blue line; fire as P2 → assert red line |
| AC9 | Cancelled drag (power < MIN_POWER) draws no shot line | Unit test: release at power=0.03 → assert no shot line created |
| AC10 | Up to MAX_VISIBLE_SHOT_LINES lines coexist; oldest removed when cap exceeded | Unit test: fire 7 shots rapidly → assert only 6 lines present, oldest removed |
