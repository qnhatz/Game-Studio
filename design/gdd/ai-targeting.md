# AI Targeting

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Skill Earns the Win / Approachable Challenge

## Overview

AI Targeting is invoked by the Turn System when the active player is the AI (P2 in `ONE_PLAYER_VS_AI` mode). It synthesizes a `FlickEvent` — a target zone selection, aim direction, and power — without reading from the Input System. It uses Figure Geometry to locate the human player's hit zones, selects a target zone based on difficulty-weighted probabilities from AI Difficulty Config, computes a direction toward that zone centre with a configurable accuracy offset, and returns the synthesized `FlickEvent` to the Turn System for normal shot resolution (spread, hit detection, visualization all run unchanged). The AI uses the same shot pipeline as the human player; only the input source differs.

## Player Fantasy

The AI opponent feels like a player who knows what they're doing, not a random number generator. On easy difficulty it misses often and avoids the head. On hard difficulty it aims true and goes for the kill. The escalation feels earned — the AI is reading you back, applying pressure, choosing its shots. When it disarms you, it felt intentional. When it misses, it felt like a real mistake, not a coin flip.

## Detailed Rules

**Invocation**
The Turn System calls `ai_take_action(action_type, ai_player_id, target_player_id)` when the active player is AI. For `FIRE`: synthesize and return a `FlickEvent`. For `MOVE`: synthesize and return a move target position (see Move Synthesis below).

**FIRE: Target Zone Selection**
The AI selects a target zone (`HEAD`, `ARMS`, `LEGS`) using weighted random selection. Weights are provided by AI Difficulty Config. A fourth outcome `INTENTIONAL_MISS` is also weighted — the AI deliberately aims away from all zones.

**FIRE: Aim Direction**
Once a zone is selected, the AI aims at the zone's centre position (from Figure Geometry) with a Gaussian accuracy offset applied. The offset magnitude is `AIM_ERROR_DEG` from AI Difficulty Config. The resulting direction is passed to Shot Spread Calculation as a synthesized `FlickEvent` with `power = AI_POWER` (also from config).

**MOVE: Move Synthesis**
When the AI takes a MOVE action, it selects a target X position within its player zone using simple heuristics: move toward the human player if distance > `AI_PREFERRED_DISTANCE`, move away if distance < `AI_MIN_DISTANCE`, otherwise stay. The exact move distance is governed by the same move rules as human players (defined in a future movement GDD if movement is designed). For MVP, MOVE is treated as a placeholder — AI holds position or makes a minimal adjustment.

**Determinism**
AI targeting uses a seeded RNG when called with an explicit seed (for testing). Normal play uses the default unseeded RNG.

## Formulas

**F1 — Zone Selection (Weighted Random)**
```
zones        = [HEAD, ARMS, LEGS, INTENTIONAL_MISS]
weights      = [w_head, w_arms, w_legs, w_miss]  # from AI Difficulty Config; sum = 1.0
selected     = weighted_random_choice(zones, weights, rng)
```

**F2 — Aim Direction with Error**
```
zone_centre  = get_zone_centre(target_player_id, selected_zone)  # Figure Geometry
ideal_dir    = normalize(zone_centre − ai_anchor)
error_rad    = gaussian(mean=0, stddev=AIM_ERROR_DEG) × (π / 180)
aim_dir      = rotate(ideal_dir, error_rad)
```
- `AIM_ERROR_DEG` from AI Difficulty Config (e.g. 0° on hard, 15° on easy)
- `gaussian` clamped to [−2σ, +2σ] to prevent extreme outliers

**F3 — Synthesized FlickEvent**
```
FlickEvent(
    direction = aim_dir,
    power     = AI_POWER,   # from AI Difficulty Config; e.g. 0.7
    timestamp = now()
)
```

**F4 — Intentional Miss Direction**
```
# Aim well outside the target figure — offset ideal_dir by a large fixed angle
miss_dir = rotate(ideal_dir, MISS_OFFSET_RAD)
MISS_OFFSET_RAD = π / 4   # 45° offset guarantees a miss at normal distances
```

## Edge Cases

**EC1 — AI selects HEAD but `INTENTIONAL_MISS` triggers spread that accidentally misses**
Normal shot resolution — Shot Spread Calculation applies spread to the AI's synthesized direction just as it does for the human. The AI is not immune to spread. A HEAD aim might still miss due to spread; this is intentional and fair.

**EC2 — AI targeting called when human player is already dead (headshot in same turn)**
Cannot occur — the Turn System halts after a win condition is triggered. AI targeting is only called on active turns.

**EC3 — `get_zone_centre` returns a position outside the current canvas (e.g. after a move)**
Zone centres are derived from the figure anchor, which is always within the player zone. If the anchor is at a valid position, zone centres are always valid. No special handling needed.

**EC4 — Weights in AI Difficulty Config do not sum to 1.0**
Normalise the weights before sampling: `w_i = w_i / sum(weights)`. Never assume the config provides pre-normalised weights.

**EC5 — AI is asked to MOVE when already Immobilized**
Cannot occur — Action Validation prevents the Turn System from offering MOVE to an immobilized player. AI targeting is only called for valid actions.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Figure Geometry | Reads zone centre positions for the target player |
| Depends on | Screen Layout | Reads AI player anchor position as ray origin |
| Depends on | AI Difficulty Config | Reads zone weights, `AIM_ERROR_DEG`, `AI_POWER` |
| Depends on | Game Mode Manager | Confirms `is_ai(player_id)` before acting |
| Bypasses | Input System | Synthesizes `FlickEvent` directly — does not read from Input System |
| Feeds into | Shot Spread Calculation | Synthesized `FlickEvent` enters normal shot pipeline |
| Called by | Two-Action Turn System | Invoked instead of opening the input window when active player is AI |

## Tuning Knobs

All numerical tuning is owned by **AI Difficulty Config** (GDD #15). This system has no knobs of its own — it reads values from that config. Refer to the AI Difficulty Config GDD for zone weights, `AIM_ERROR_DEG`, `AI_POWER`, and difficulty presets.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | AI synthesizes a valid `FlickEvent` (unit direction, power ∈ [0,1]) | Unit test: call `ai_take_action(FIRE, ...)` → assert FlickEvent.direction.length ≈ 1.0 and power ∈ [0,1] |
| AC2 | With `INTENTIONAL_MISS` weight = 1.0, AI always misses all zones | Unit test: seed RNG, set w_miss=1.0 → run 100 shots → assert Hit Detection returns MISS every time |
| AC3 | With `HEAD` weight = 1.0 and `AIM_ERROR_DEG = 0`, AI always hits head | Unit test: seed RNG, set w_head=1.0, error=0 → assert Hit Detection returns HEAD every time |
| AC4 | Weights are normalised before sampling (non-summing-to-1 input handled) | Unit test: pass weights [2, 2, 2, 2] → assert valid zone selected without crash |
| AC5 | Seeded RNG produces identical zone selection and aim on repeated calls | Unit test: call twice with same seed → assert identical FlickEvent output |
| AC6 | `AIM_ERROR_DEG = 15` produces aim offsets distributed around 0° | Unit test: 1000 samples with fixed zone → assert mean offset ≈ 0°, stddev ≈ 15° |
| AC7 | AI synthesized FlickEvent passes through Shot Spread Calculation unchanged (same pipeline as human) | Integration test: verify spread is applied to AI shot exactly as it is to a human shot |
