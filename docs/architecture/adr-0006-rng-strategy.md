# ADR-0006: RNG Strategy

## Status
Accepted

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (RandomNumberGenerator) |
| **Knowledge Risk** | LOW — `RandomNumberGenerator` API is stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology — RngService is one of exactly two Autoloads) |
| **Enables** | ADR-0007 (Input System), ShotSpreadCalculation implementation, AITargeting implementation |
| **Blocks** | Any system that uses random numbers (ShotSpreadCalculation, AITargeting) |
| **Ordering Note** | RngService Autoload must exist before any random-number caller is implemented |

## Context

### Problem Statement

Two systems require randomness: `ShotSpreadCalculation` (angular variance on shot release) and
`AITargeting` (weighted zone selection). Without a shared, seeded RNG source, each system would
use its own internal RNG, making replay or deterministic testing impossible and creating
unpredictable interactions between spread and AI decisions in the same match.

### Constraints

- Only two Autoloads are permitted (ADR-0001): `ScreenLayout` and `RngService`; this ADR designates
  `RngService` as the second Autoload for RNG
- RNG calls must be deterministic given a fixed seed (for unit testing shot spread and AI targeting)
- Single-threaded web export (ADR-0002): no thread-safety concerns
- GDScript only: no native RNG libraries

### Requirements

- Shared seeded `RandomNumberGenerator` accessible to any system that needs it
- Re-seedable at match start (for reproducible tests)
- Provides `randf_range()` and `randi_range()` wrappers (no raw state access)
- No system creates its own `RandomNumberGenerator` instance

## Decision

**`RngService` Autoload wrapping a seeded `RandomNumberGenerator`. All random calls go through it.
Seeded at match start by `GameStateMachine`.**

### RngService Implementation

```gdscript
# res://autoloads/rng_service.gd
extends Node

var _rng := RandomNumberGenerator.new()

func seed_rng(value: int) -> void:
    _rng.seed = value

func randf_range(min_val: float, max_val: float) -> float:
    return _rng.randf_range(min_val, max_val)

func randi_range(min_val: int, max_val: int) -> int:
    return _rng.randi_range(min_val, max_val)
```

**Seed policy:**
- In production: seeded with `Time.get_ticks_msec()` at the start of each match
- In unit tests: seeded with a fixed constant (e.g., `12345`) for deterministic assertions
- `RngService.seed_rng()` is called by `GameStateMachine` as part of match initialisation,
  before `TwoActionTurnSystem.begin_turn()` is called

### Callers

| System | Method used | Purpose |
|--------|-------------|----------|
| ShotSpreadCalculation | `randf_range(-spread_deg, +spread_deg)` | Angular variance on shot release |
| AITargeting | `randf_range(0.0, 1.0)` | Weighted zone selection roll |

No other system calls `RngService`. If a new system needs randomness, it must use `RngService`
(not create its own `RandomNumberGenerator` instance).

### Why an Autoload (not a passed dependency)

`RngService` is one of exactly two Autoloads permitted (ADR-0001). The exception from the general
"no Autoloads" rule is justified because:
1. RNG state is inherently global — it must advance with every call to produce correct distributions
2. Passing `RngService` as a parameter to every callee would create artificial dependencies;
   it is a service, not a system
3. Autoload is appropriate here because `RngService` has no game-logic dependencies of its own

## Alternatives Considered

### Alternative A: Each system owns its own RandomNumberGenerator

- **Description**: `ShotSpreadCalculation` and `AITargeting` each create and manage their own
  `RandomNumberGenerator` instances
- **Pros**: Complete isolation; no shared state
- **Cons**: Two independent RNG streams cannot be seeded together for deterministic replay;
  unit testing requires re-seeding two separate objects; spread and AI decisions can't be
  correlated for test purposes
- **Rejection**: Deterministic testing requires a single seedable RNG source

### Alternative B: Pass RandomNumberGenerator as a parameter

- **Description**: `GameStateMachine` creates one `RandomNumberGenerator`, seeds it, and passes it
  to ShotSpreadCalculation and AITargeting as a constructor parameter
- **Pros**: No Autoload; explicit dependency injection; unit-testable
- **Cons**: Creates a dependency chain through systems that don't otherwise interact;
  `TwoActionTurnSystem` would need to hold and pass the RNG to both callers; adds constructor
  complexity with no benefit over an Autoload for a service this stateless
- **Rejection**: Adds indirection with no practical benefit; Autoload is appropriate for a service
  that has no game-logic state

## Consequences

### Positive

- One seed controls all randomness in a match: deterministic test scenarios are achievable
- No system creates its own RNG: the random stream is globally auditable
- `seed_rng()` is the single point for test seed injection

### Negative

- Autoload: `RngService` creates a global dependency. Systems that call it cannot be unit-tested
  without `RngService` being present.
  *Mitigation*: `RngService` is trivially mockable in tests (a single `seed_rng()` call before
  the test is sufficient); it has no game logic to mock.
- RNG call order affects outcomes: if two systems call `RngService` in different order than expected,
  the random sequence shifts. In practice, shot spread is always called before AI zone selection
  within a turn, so order is deterministic.

### Risks

- **Test seed coupling**: if the call order between ShotSpreadCalculation and AITargeting changes,
  test assertions based on specific random outputs will break. *Mitigation*: unit tests for each
  system seed RngService fresh at test start; they do not share seed state across test cases.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-SSC-002 | Shot Spread Calculation | RngService must be seeded; replay determinism required | Defines `RngService` as the sole RNG source with `seed_rng()` at match start |
| TR-AIR-003 | AI Targeting | Zone selection by weighted random per difficulty params | AITargeting uses `RngService.randf_range()` for weighted rolls |

## Performance Implications

- **CPU**: `RandomNumberGenerator.randf_range()` is a single native call; negligible cost
- **Memory**: One `RandomNumberGenerator` object (~100 bytes)
- **Frame Budget**: Called at most twice per turn; irrelevant to frame budget

## Migration Plan

Greenfield. Create `res://autoloads/rng_service.gd` and register it in Project Settings >
Autoloads before implementing ShotSpreadCalculation or AITargeting.

## Validation Criteria

- `RngService.seed_rng(12345)` followed by `randf_range(0, 1)` returns the same value every
  test run (determinism unit test)
- No `RandomNumberGenerator.new()` calls outside `rng_service.gd` (grep in CI)
- ShotSpreadCalculation unit test: seed RngService, call `apply_spread()`, assert output is in
  expected range and reproducible with same seed

## Related Decisions

- ADR-0001: Scene Topology — RngService is one of exactly two Autoloads
- ADR-0008: FlickEvent Contract — FlickEvent includes `timestamp` (not used for RNG, but from
  `Time.get_ticks_msec()` which is also used to seed the RNG at match start)
