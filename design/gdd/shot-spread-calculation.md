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

**Spread Angle**
Spread is expressed as a half-angle — the maximum angular offset from the aimed direction on either side.

- At `power = 0.0`: half-angle = `MIN_SPREAD_DEG = 2°`
- At `power = 1.0`: half-angle = `MAX_SPREAD_DEG = 30°`
- Spread scales linearly between the two (see Formulas §4)

**Distribution**
The random offset is drawn from a triangular distribution centred at 0° — most shots land near the aimed direction, with probability decreasing toward the cone edges. This avoids perfectly centred shots while keeping extreme outliers rare.

**Output**
The system returns a single unit Vector2: the resolved shot direction after the random offset is applied. Callers see one direction — the randomisation is fully encapsulated here.

**Invocation**
Called once per shot at release time, after `FlickEvent` is emitted and before the shot line is drawn or hit detection runs. The AI uses the same function when resolving its synthesized `FlickEvent`.

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
