# Input System

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-07
> **Implements Pillar**: Skill Earns the Win / Instant to Learn

## Overview

The Input System is the first node in the shot pipeline. It converts a mouse drag or touch drag gesture into a structured `FlickEvent` — a value object containing aim direction (angle in radians), pull distance (normalized 0–1 power), and a timestamp. Every downstream system that needs shot data reads from this event: Trajectory Visualization reads it live during the drag to draw the aim line; Shot Spread Calculation reads direction and power at release to compute angular variance. The AI bypasses this system entirely and synthesizes its own `FlickEvent` directly. The Input System makes no gameplay decisions — it is pure input translation.

## Player Fantasy

The player should feel like a marksman lining up a shot, not a user filling in a form. The drag-back creates physical tension — the longer the pull, the more committed the shot feels. The release is the moment of truth: instantaneous, irreversible, satisfying. A well-aimed flick that clips the head should feel *earned*. A miss that grazes the shoulder should sting. The gesture maps directly to the pen-flick muscle memory players already have — anyone who played the paper version in school recognises it within one turn.

## Detailed Rules

**Drag Origin**
The gesture must begin within 48px of the active player's figure centre. Taps outside this radius are ignored. This anchors the interaction to the figure — you are flicking *your* character, not drawing in empty space.

**Direction and Power**
The shot fires in the direction *opposite* to the drag — slingshot model. Drag left → shot goes right. This mirrors the physical pen-flick: you pull back to launch forward.

- `direction = normalize(figure_centre − drag_endpoint)`
- `power = clamp(distance(figure_centre, drag_endpoint) / MAX_DRAG_PX, 0.0, 1.0)`
- `MAX_DRAG_PX = 150` (tuning knob — see §7)

**Cancellation**
If the player releases with `power < 0.05` (drag shorter than 7.5px), the release is treated as a cancelled gesture — no `FlickEvent` is emitted and no action is consumed. There is no other cancellation method; once dragging past the threshold, only a release fires the shot.

**Input Window**
The Input System only accepts gesture-start events when the Turn System has opened the active player's input window. Gestures that begin outside an open window are silently discarded. The Turn System closes the window the moment a valid `FlickEvent` is emitted.

## Formulas

**F1 — Shot Direction**
```
direction = normalize(figure_centre − drag_endpoint)
```
- `figure_centre`: Vector2, active player's figure origin in screen coordinates
- `drag_endpoint`: Vector2, pointer position at release
- Result: unit Vector2 (length = 1.0)

**F2 — Power**
```
power = clamp(|drag_endpoint − figure_centre| / MAX_DRAG_PX, 0.0, 1.0)
```
- `MAX_DRAG_PX = 150` px (default)
- Range: [0.0, 1.0]
- Example: drag 75px → power = 0.5; drag 200px → power = 1.0 (clamped)

**F3 — Cancellation Threshold**
```
cancelled = (power < MIN_POWER)
MIN_POWER = 0.05
```
- Equivalent to a drag shorter than `150 × 0.05 = 7.5 px`

## Edge Cases

**EC1 — Drag starts on figure, pointer leaves play area**
Clamp `drag_endpoint` to the screen bounds before computing direction and power. The shot still fires on release; it does not cancel.

**EC2 — Player taps the figure without dragging (power = 0)**
Caught by the cancellation threshold (F3). No `FlickEvent` emitted, no action consumed.

**EC3 — Both players' figures overlap (crowded screen)**
Gesture origin is attributed to the *active* player only. The inactive player's figure hit area is ignored for input purposes during the opponent's turn.

**EC4 — Multi-touch: second finger touches screen mid-drag**
First active touch ID owns the drag. Subsequent touch events are ignored until the owning touch is released or cancelled.

**EC5 — Pointer released outside browser window (focus lost)**
Treat as a release at the last known pointer position. Emit `FlickEvent` if power ≥ MIN_POWER, cancel otherwise.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Consumed by | Trajectory Visualization | Reads `FlickEvent` continuously during drag to update the live aim line |
| Consumed by | Shot Spread Calculation | Reads `direction` and `power` from `FlickEvent` at release |
| Gated by | Two-Action Turn System | Opens and closes the input window; Input System discards gestures when window is closed |
| Bypassed by | AI Targeting | Synthesizes `FlickEvent` directly — does not interact with this system |

This system has no upstream dependencies. It reads only from hardware input (mouse/touch events).

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `MAX_DRAG_PX` | 150 px | 80–250 px | Maps physical drag distance to power 1.0. Lower = more sensitive (full power on shorter drag); higher = more deliberate effort required. |
| `MIN_POWER` | 0.05 | 0.01–0.15 | Cancellation threshold. Lower = easier to accidentally fire; higher = requires more intentional pull to commit. |
| `TAP_RADIUS_PX` | 48 px | 32–80 px | Hit area for gesture origin on the figure. Lower = more precise targeting required; higher = more forgiving on mobile. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | A drag starting outside 48px of the figure centre produces no `FlickEvent` | Unit test: simulate pointer-down at 50px from centre → assert no event emitted |
| AC2 | A drag of exactly 75px produces `power = 0.5` (with `MAX_DRAG_PX = 150`) | Unit test: inject drag vector of length 75 → assert `FlickEvent.power == 0.5` |
| AC3 | A drag shorter than 7.5px (MIN_POWER threshold) produces no `FlickEvent` | Unit test: inject drag vector of length 7 → assert no event emitted |
| AC4 | Shot direction is opposite to drag direction (slingshot model) | Unit test: drag right → assert `FlickEvent.direction` points left (negative X) |
| AC5 | A second touch during an active drag is ignored | Unit test: inject touch-down with a second touch ID mid-drag → assert power/direction unchanged |
| AC6 | A drag endpoint outside screen bounds is clamped — shot still fires | Unit test: inject drag_endpoint beyond screen rect → assert `FlickEvent` emitted with clamped power |
| AC7 | Input is silently discarded when the input window is closed | Integration test: simulate gesture-start with window closed → assert no `FlickEvent` emitted |

