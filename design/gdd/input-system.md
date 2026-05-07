# Input System

> **Status**: In Design
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

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
