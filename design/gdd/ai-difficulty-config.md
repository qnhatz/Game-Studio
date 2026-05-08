# AI Difficulty Config

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Approachable Challenge / Skill Earns the Win

## Overview

AI Difficulty Config is a data resource that provides the numerical parameters used by AI Targeting: zone selection weights, aiming error, and shot power. It defines three named presets — `EASY`, `MEDIUM`, and `HARD` — each a complete set of values. The active preset is selected by the player on the Main Menu (in MVP: a single difficulty selector shown when "vs Computer" is tapped). AI Targeting reads exclusively from the active config; it has no hardcoded values. This system is a pure data container with no logic.

## Player Fantasy

Easy should feel like a sparring partner — present, deliberate, but forgiving. Hard should feel like someone who has played this game before and wants to win. Medium is the fair fight. The difficulty selector is one extra tap before the match — a promise about the challenge ahead.

## Detailed Rules

**Presets**
Three presets are defined. All four zone weights must sum to 1.0 per preset.

| Parameter | EASY | MEDIUM | HARD |
|-----------|------|--------|------|
| `w_head` | 0.05 | 0.20 | 0.40 |
| `w_arms` | 0.25 | 0.35 | 0.35 |
| `w_legs` | 0.20 | 0.25 | 0.20 |
| `w_miss` | 0.50 | 0.20 | 0.05 |
| `AIM_ERROR_DEG` | 18° | 9° | 3° |
| `AI_POWER` | 0.55 | 0.70 | 0.80 |

**Interpretation**
- `w_head / w_arms / w_legs / w_miss`: probability weights for zone selection in AI Targeting F1
- `AIM_ERROR_DEG`: standard deviation of the Gaussian aim error in AI Targeting F2 — higher = less accurate
- `AI_POWER`: shot power used in the synthesized FlickEvent — affects spread (more power = wider spread per Shot Spread Calculation)

**Selection**
The player selects difficulty via a 3-option selector shown after tapping "vs Computer" on the Main Menu. Default is `MEDIUM`. The selection is passed to AI Difficulty Config before the match begins and does not change mid-match.

## Formulas

No computation. This system is a lookup table. AI Targeting reads values directly:

```
get_config(difficulty) → DifficultyConfig:
    return PRESETS[difficulty]

# PRESETS is a constant dictionary:
PRESETS = {
    EASY:   DifficultyConfig(w_head=0.05, w_arms=0.25, w_legs=0.20, w_miss=0.50, aim_error=18, power=0.55),
    MEDIUM: DifficultyConfig(w_head=0.20, w_arms=0.35, w_legs=0.25, w_miss=0.20, aim_error=9,  power=0.70),
    HARD:   DifficultyConfig(w_head=0.40, w_arms=0.35, w_legs=0.20, w_miss=0.05, aim_error=3,  power=0.80),
}
```

**Validation**: `w_head + w_arms + w_legs + w_miss == 1.0` for every preset. Assert on load.

## Edge Cases

**EC1 — Invalid difficulty key passed to `get_config`**
Assert and return `MEDIUM` as a safe fallback. Log an error. This should never happen in production — the difficulty selector only offers valid preset names.

**EC2 — Weights do not sum to 1.0 after a tuning edit**
The load-time assert catches this during development. In a shipped build, normalise automatically and log a warning.

**EC3 — Difficulty changed mid-match**
Not supported. The config is locked when the match begins. Changes take effect on the next match.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Consumed by | AI Targeting | Reads zone weights, `AIM_ERROR_DEG`, `AI_POWER` for every AI action |
| Set by | Main Menu | Receives difficulty selection before match start |

No upstream data dependencies. This system is self-contained constant data.

## Tuning Knobs

All six parameters in each preset are tuning knobs. Safe ranges and gameplay effects:

| Parameter | Safe Range | Too High | Too Low |
|-----------|------------|----------|---------|
| `w_head` | 0.0–0.60 | AI goes for kill constantly — frustrating on easy | Head is never targeted — HARD feels too passive |
| `w_arms` | 0.10–0.50 | AI always disarms — match feels formulaic | Disarm is rare — status effects feel underused |
| `w_legs` | 0.05–0.40 | AI always immobilizes | Immobilize rarely triggered |
| `w_miss` | 0.0–0.70 | Easy AI feels broken/useless | Hard AI never misses intentionally — feels robotic |
| `AIM_ERROR_DEG` | 0°–25° | EASY misses everything even when targeting a zone | HARD is pixel-perfect — inhuman accuracy |
| `AI_POWER` | 0.3–1.0 | High power = wide spread = undermines accuracy | Low power = shots feel weak; spread too narrow (fast, precise) |

**Constraint**: `w_head + w_arms + w_legs + w_miss = 1.0` must hold after any tuning edit.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | `get_config(EASY)` returns correct preset values | Unit test: assert all 6 fields match EASY preset definition |
| AC2 | `get_config(MEDIUM)` returns correct preset values | Unit test: assert all 6 fields match MEDIUM preset definition |
| AC3 | `get_config(HARD)` returns correct preset values | Unit test: assert all 6 fields match HARD preset definition |
| AC4 | All preset weights sum to 1.0 | Unit test: assert `w_head+w_arms+w_legs+w_miss == 1.0` for each preset |
| AC5 | Invalid key returns MEDIUM and logs an error | Unit test: `get_config(INVALID)` → assert returns MEDIUM config, error logged |
| AC6 | EASY `w_miss` = 0.50, HARD `w_miss` = 0.05 — difficulty meaningfully differentiates | Unit test: assert EASY.w_miss > HARD.w_miss |
| AC7 | HARD `AIM_ERROR_DEG` < EASY `AIM_ERROR_DEG` — hard is more accurate | Unit test: assert HARD.aim_error < EASY.aim_error |
