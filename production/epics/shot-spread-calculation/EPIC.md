# Epic: Shot Spread Calculation

> **Layer**: Foundation
> **GDD**: design/gdd/shot-spread-calculation.md
> **Architecture Module**: `ShotSpreadCalculation` (+ `RngService` Autoload — inferred Foundation module)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories shot-spread-calculation`

## Overview

Shot Spread Calculation is a stateless pure-math module that applies angular variance
to a shot direction. It takes a `FlickEvent` and a spread angle (degrees) and returns
a final resolved shot direction as a unit Vector2. Higher power yields a wider spread
cone (up to 30°); lower power yields a tighter cone (minimum 2°). The random offset
uses a triangular distribution so shots cluster near the aimed direction. This module
depends on `RngService` — a seeded Autoload (`RandomNumberGenerator`) that must be
implemented as part of this epic. `RngService` has no GDD of its own but is defined in
`docs/architecture/architecture.md` as a Foundation-layer Autoload; it provides
`seed_rng()`, `randf_range()`, and `randi_range()` to all systems that need deterministic
or reproducible randomness (AITargeting and tests both rely on it).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: System Communication | `apply_spread(event, spread_deg) → Vector2` is a direct call on the shot critical path | LOW |
| ADR-0006: RNG Strategy | `RngService` Autoload wrapping `RandomNumberGenerator`; `seed_rng(value)` at match start for test determinism | LOW |
| ADR-0009: AI Pipeline | Spread range is configurable per difficulty; AI uses the same `apply_spread` function with a seeded RNG | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-SSC-001 | apply_spread(event, spread_deg) → final direction Vector2 | ADR-0004, ADR-0009 ✅ |
| TR-SSC-002 | RngService seeded for determinism in tests | ADR-0006 ✅ |
| TR-SSC-003 | Spread range configurable per difficulty level | ADR-0009 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/shot-spread-calculation.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- `RngService` Autoload is implemented and registered in Project Settings before any story
  in this epic or the AI layer can be picked up
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories shot-spread-calculation` to break this epic into implementable stories.
