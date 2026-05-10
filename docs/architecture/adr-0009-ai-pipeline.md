# ADR-0009: AI Pipeline Architecture

## Status
Proposed

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (GDScript logic) |
| **Knowledge Risk** | LOW — pure GDScript; no engine APIs specific to AI |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0008 (FlickEvent Contract — AI synthesises this), ADR-0006 (RngService — AI uses for zone selection), ADR-0004 (System Communication — AI uses Pattern A direct calls) |
| **Enables** | AITargeting and AIDifficultyConfig implementation |
| **Blocks** | VS Computer mode is unplayable without this |
| **Ordering Note** | ADR-0008 and ADR-0006 must be Accepted before AI implementation begins |

## Context

### Problem Statement

In VS Computer mode, the AI player must take turns — selecting a FIRE or MOVE action and executing
it. The AI's shot must be as fair as a human's: it must flow through the same spread calculation,
the same hit detection, and produce the same possible outcomes. We need to define exactly where the
AI's path joins the human's path and what the AI does before that join point.

### Constraints

- AI must produce a `FlickEvent` (ADR-0008 contract) — same type as human input
- AI must not bypass `TwoActionTurnSystem.on_action_selected()` — same entry point as human
- AI must use `RngService` for randomness (ADR-0006), not its own RNG
- AI decision must complete synchronously within the turn-start handler (no coroutines, no async)
- AI must be unit-testable without a running game loop

### Requirements

- AI selects a target zone weighted by difficulty parameters (including `w_miss` for deliberate miss)
- AI applies Gaussian pre-error to the ideal direction vector before FlickEvent construction
- AI uses same spread as human via ShotSpreadCalculation.apply_spread() (two-layer accuracy model)
- AI move decision uses simple distance heuristics
- AI cannot "cheat" by reading the human's planned actions or bypassing spread

## Decision

**AI synthesises `FlickEvent` directly and joins the human pipeline at `TwoActionTurnSystem.on_action_selected()`. Two-layer accuracy model: Gaussian pre-error before FlickEvent construction + standard spread on top.**

### Two-Layer Accuracy Model

```
Layer 1 (Gaussian pre-error, in AITargeting):
  ideal_dir = normalize(target_zone_centre - ai_anchor)
  error_angle = gaussian_sample(sigma = accuracy_spread_deg) using RngService
  pre_error_dir = ideal_dir.rotated(error_angle)
  FlickEvent.new(pre_error_dir, 1.0, Time.get_ticks_msec())

Layer 2 (spread, in ShotSpreadCalculation — same as human):
  final_dir = apply_spread(flick_event, spread_deg)
  where spread_deg = AIDifficultyConfig.get_params().accuracy_spread_deg
```

Both layers stack: the Gaussian pre-error shifts the aim direction before construction;
`apply_spread()` then adds angular noise on top. Higher `accuracy_spread_deg` = less accurate AI
at both layers.

### Pipeline Comparison

```
Human:
  InputSystem (drag/release gesture)
      → FlickEvent
      → TwoActionTurnSystem.on_action_selected(&"FIRE", event)
      → ShotSpreadCalculation.apply_spread(event, HUMAN_SPREAD_DEG)
      → BodyZoneHitDetection.detect(...)
      → WinCondition.check(...)

AI:
  AITargeting.select_action(player_id)           # heuristic decision
      → Zone selection (weighted random, includes w_miss)
      → Gaussian pre-error applied to ideal direction
      → synthesised FlickEvent (pre-error direction + power=1.0)
      → TwoActionTurnSystem.on_action_selected(&"FIRE", event)  ← joins here
      → ShotSpreadCalculation.apply_spread(event, accuracy_spread_deg)   ← same code
      → BodyZoneHitDetection.detect(...)                        ← same code
      → WinCondition.check(...)                                 ← same code
```

### AITargeting Logic

```gdscript
# AITargeting.select_action(player_id: int) → Dictionary
func select_action(player_id: int) -> Dictionary:
    var params := ai_difficulty_config.get_params()
    var opponent_id := 1 - player_id

    # Zone selection — weighted random (includes w_miss for deliberate miss)
    var roll := RngService.randf_range(0.0, 1.0)
    var selected_zone := _pick_zone(roll, params.zone_weights)

    var direction: Vector2
    if selected_zone == &"MISS":
        # Deliberate miss: aim at a random off-figure point
        var miss_angle := RngService.randf_range(0.0, TAU)
        direction = Vector2.RIGHT.rotated(miss_angle)
    else:
        # Direction toward selected zone centre
        var target_pos := figure_geometry.get_zone_centre(opponent_id, selected_zone)
        var origin := figure_geometry.get_anchor(player_id)
        var ideal_dir := (target_pos - origin).normalized()

        # Layer 1: Gaussian pre-error
        var error_angle := _gaussian_sample(params.accuracy_spread_deg)
        direction = ideal_dir.rotated(deg_to_rad(error_angle))
        direction = direction.normalized()

    # Move decision — distance heuristic
    var human_x := figure_geometry.get_anchor(opponent_id).x
    var ai_x := figure_geometry.get_anchor(player_id).x
    var distance := abs(human_x - ai_x)

    var move_destination_x: float = ai_x
    if distance > params.preferred_distance_px:
        move_destination_x = human_x - params.preferred_distance_px * sign(human_x - ai_x)
    elif distance < params.min_distance_px:
        move_destination_x = human_x + params.min_distance_px * sign(ai_x - human_x)

    return {
        fire_event = FlickEvent.new(direction, 1.0, Time.get_ticks_msec()),
        move_destination_x = move_destination_x,
        spread_deg = params.accuracy_spread_deg
    }

func _gaussian_sample(sigma_deg: float) -> float:
    # Box-Muller transform using RngService for determinism
    var u1 := RngService.randf_range(0.0001, 1.0)   # avoid log(0)
    var u2 := RngService.randf_range(0.0, 1.0)
    return sigma_deg * sqrt(-2.0 * log(u1)) * cos(TAU * u2)

func _pick_zone(roll: float, weights: Dictionary) -> StringName:
    # weights: {HEAD: 0.2, ARMS: 0.3, LEGS: 0.3, MISS: 0.2} — must sum to 1.0
    var cumulative := 0.0
    for zone in [&"HEAD", &"ARMS", &"LEGS", &"MISS"]:
        cumulative += weights[zone]
        if roll < cumulative:
            return zone
    return &"ARMS"   # fallback
```

### AIDifficultyConfig Parameter Tables

```gdscript
const DIFFICULTY_PARAMS := {
    &"EASY": {
        accuracy_spread_deg = 15.0,
        zone_weights = {&"HEAD": 0.05, &"ARMS": 0.35, &"LEGS": 0.35, &"MISS": 0.25},
        preferred_distance_px = 200.0,
        min_distance_px = 80.0,
    },
    &"MEDIUM": {
        accuracy_spread_deg = 8.0,
        zone_weights = {&"HEAD": 0.15, &"ARMS": 0.40, &"LEGS": 0.35, &"MISS": 0.10},
        preferred_distance_px = 180.0,
        min_distance_px = 60.0,
    },
    &"HARD": {
        accuracy_spread_deg = 3.0,
        zone_weights = {&"HEAD": 0.35, &"ARMS": 0.35, &"LEGS": 0.25, &"MISS": 0.05},
        preferred_distance_px = 160.0,
        min_distance_px = 40.0,
    },
}
```

`w_miss` is `zone_weights[&"MISS"]` — the probability the AI deliberately fires wide. Higher at
easier difficulties to create exploitable windows. Zone weights including MISS must sum to 1.0.

Only MEDIUM ships in MVP (per GDD). EASY and HARD are wired for V1.0.

### How TwoActionTurnSystem Drives AI

```gdscript
# In TwoActionTurnSystem.begin_turn():
if game_mode_manager.is_ai(active_player):
    var ai_result := ai_targeting.select_action(active_player)
    # Take FIRE action
    on_action_selected(&"FIRE", ai_result.fire_event)
    # If MOVE still in pool, take it
    if &"MOVE" in remaining_pool:
        movement.execute_move(active_player,
            Vector2(ai_result.move_destination_x, ScreenLayout.P1_ANCHOR.y))
```

## Alternatives Considered

### Alternative A: Single spread layer (spread-only, no Gaussian pre-error)

- **Description**: AI accuracy = single `spread_deg` passed to `ShotSpreadCalculation.apply_spread()`
- **Pros**: Simpler implementation
- **Cons**: Uniform spread distribution; GDD requires Gaussian. Difficulty scaling model is based
  on the Gaussian layer. Without Gaussian pre-error, "Hard" AI with low spread_deg aims nearly
  perfectly every shot with only uniform noise, not the realistic Gaussian-bell accuracy curve.
- **Rejection**: AI Targeting GDD explicitly specifies two-layer model; uniform spread alone
  does not produce the intended accuracy curve at any difficulty level

### Alternative B: Separate AI shot resolution path

- **Description**: AI bypasses TwoActionTurnSystem; directly calls BodyZoneHitDetection
- **Pros**: Could allow AI to "cheat" if desired
- **Cons**: Two code paths; impossible to verify AI fairness; GDD forbids this
- **Rejection**: GDD TR-AIR-002 and architecture principle "AI uses same pipeline" forbid this

### Alternative C: No w_miss (zone weights for HEAD/ARMS/LEGS only)

- **Description**: Zone selection only between hit zones; no deliberate miss weight
- **Pros**: Simpler weight dictionary
- **Cons**: AI at Easy difficulty always tries to hit — just poorly. A dedicated `w_miss` weight
  creates intentional "breathing room" turns where the AI visibly fires wide, which teaches the
  player the game rhythm without punishing them unfairly at low difficulty.
- **Rejection**: AI Targeting GDD specifies `w_miss` as a first-class difficulty parameter

## Consequences

### Positive

- AI fairness provable by inspection: same ShotSpreadCalculation + BodyZoneHitDetection
- Two-layer model produces realistic accuracy curve: Gaussian pre-error matches how human aim
  error actually distributes (bell curve, not uniform)
- `w_miss` creates intentional difficulty breathing room without requiring separate logic
- Fully unit-testable: seed RngService, call `select_action()`, assert FlickEvent fields

### Negative

- Box-Muller requires two RngService calls per AI shot (vs. one for spread-only)
- Zone weight dictionary now has 4 entries (HEAD/ARMS/LEGS/MISS) instead of 3; sum-to-1 assert required

### Risks

- **Zone weight sum ≠ 1.0**: `_pick_zone()` may return fallback on every call. *Mitigation*: assert
  weights sum to 1.0 ± 0.001 in `AIDifficultyConfig.set_difficulty()`.
- **Gaussian outliers**: Box-Muller can produce values many sigma from mean on rare rolls.
  *Mitigation*: clamp error_angle to ±3×sigma before applying — prevents pathological misses.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-AIR-001 | AI Targeting | AI synthesises FlickEvent directly; bypasses InputSystem | `AITargeting.select_action()` constructs `FlickEvent.new()` directly |
| TR-AIR-002 | AI Targeting | Gaussian pre-error applied before FlickEvent construction | `_gaussian_sample()` applied to ideal direction before `FlickEvent.new()` |
| TR-AIR-003 | AI Targeting | AI joins shot pipeline at on_action_selected() | AI calls `on_action_selected(&"FIRE", event)` — identical entry point to human |
| TR-AIR-004 | AI Targeting | Zone selection by weighted random (w_miss for deliberate miss) | `zone_weights` dict includes `&"MISS"` key; `w_miss = zone_weights[&"MISS"]` |
| TR-ADC-001 | AI Difficulty Config | get_params() → {accuracy_spread_deg, zone_weights, distances} | Full parameter tables with w_miss in zone_weights defined in DIFFICULTY_PARAMS |
| TR-ADC-002 | AI Difficulty Config | Difficulty levels: Easy / Medium / Hard | All three defined; MEDIUM ships in MVP |

## Performance Implications

- **CPU**: Box-Muller: 2 log/cos ops per AI shot. ~0.01 ms. Negligible.
- **Memory**: One `FlickEvent` allocation per AI turn — freed by reference counting.

## Migration Plan

Greenfield.

## Validation Criteria

- Unit test: seed RngService, call `AITargeting.select_action(P2)` in MEDIUM difficulty 1000 times;
  assert pre-error angle distribution is approximately Gaussian (mean ~0, std ~8°)
- Integration test: AI completes a full turn (FIRE + MOVE) without raising any assert
- Zone weights sum to 1.0 ± 0.001 for all three difficulty levels — assert in test suite
- w_miss produces observable misses: in EASY mode over 100 turns, >15% result in MISS zone

## Related Decisions

- ADR-0004: System Communication — AI joins human pipeline at `on_action_selected()` (Pattern A)
- ADR-0006: RNG Strategy — AI uses `RngService.randf_range()` for zone selection and Box-Muller
- ADR-0008: FlickEvent Contract — AI constructs `FlickEvent` with same invariants as human
