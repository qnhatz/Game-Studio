# Shot Spread Calculation

> **Status**: In Design
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Skill Earns the Win / Risk vs Reward

## Overview

The Shot Spread Calculation system takes the `direction` and `power` values from a `FlickEvent` and produces a final resolved shot direction by applying angular variance. Higher power produces a wider spread cone; lower power produces a tighter cone. The system is stateless pure math — it takes two numbers in and returns a unit Vector2 out. It is called exactly once per shot, at the moment of release, before the shot line is rendered or hit detection runs. It has no side effects and no internal state.

## Player Fantasy

Power is a double-edged sword. A full-force flick feels explosive — but the shot could go anywhere within a wide arc. A restrained half-pull feels deliberate and surgical. The spread mechanic is the game's core risk knob: go for the head with a hard flick and you might graze a shoulder instead. The player who learns to read distance and adjust their pull strength is the player who wins duels.

## Detailed Rules

[To be designed]

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Acceptance Criteria

[To be designed]
