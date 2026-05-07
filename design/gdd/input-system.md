# Input System

> **Status**: In Design
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-07
> **Implements Pillar**: Skill Earns the Win / Instant to Learn

## Overview

The Input System is the first node in the shot pipeline. It converts a mouse drag or touch drag gesture into a structured `FlickEvent` — a value object containing aim direction (angle in radians), pull distance (normalized 0–1 power), and a timestamp. Every downstream system that needs shot data reads from this event: Trajectory Visualization reads it live during the drag to draw the aim line; Shot Spread Calculation reads direction and power at release to compute angular variance. The AI bypasses this system entirely and synthesizes its own `FlickEvent` directly. The Input System makes no gameplay decisions — it is pure input translation.

## Player Fantasy

The player should feel like a marksman lining up a shot, not a user filling in a form. The drag-back creates physical tension — the longer the pull, the more committed the shot feels. The release is the moment of truth: instantaneous, irreversible, satisfying. A well-aimed flick that clips the head should feel *earned*. A miss that grazes the shoulder should sting. The gesture maps directly to the pen-flick muscle memory players already have — anyone who played the paper version in school recognises it within one turn.

## Detailed Design

### Core Rules

[To be designed]

### States and Transitions

[To be designed]

### Interactions with Other Systems

[To be designed]

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
