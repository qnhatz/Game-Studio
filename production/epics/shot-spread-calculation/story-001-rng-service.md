# Story 001: RngService Autoload

> **Epic**: Shot Spread Calculation
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/shot-spread-calculation.md`
**Requirement**: `TR-SSC-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 (RNG Strategy)
**ADR Decision Summary**: `RngService` Autoload wrapping a seeded `RandomNumberGenerator`. All random calls go through it. Exposes `seed_rng(value)`, `randf_range(from, to)`, `randi_range(from, to)`. Registered as an Autoload in Project Settings.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RandomNumberGenerator` has been stable since Godot 4.0. `randf_range` and `randi_range` are instance methods on `RandomNumberGenerator` — verified pre-cutoff. No post-cutoff APIs used.

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload registered in Project Settings (not instantiated manually)
- Required: Exposes `seed_rng(seed: int)` for deterministic test replay
- Forbidden: Direct `randf()` or `randi()` global calls — all random calls go through `RngService`

---

## Acceptance Criteria

*From GDD `design/gdd/shot-spread-calculation.md`, scoped to this story:*

- [ ] `RngService` is an Autoload registered in Project Settings under the name `RngService`.
- [ ] `seed_rng(value: int)` sets the internal `RandomNumberGenerator` seed.
- [ ] `randf_range(from: float, to: float) -> float` returns a value in `[from, to)`.
- [ ] `randi_range(from: int, to: int) -> int` returns a value in `[from, to]`.
- [ ] After calling `seed_rng(42)` twice with identical inputs to `randf_range`, both calls produce identical output (deterministic).

---

## Implementation Notes

*Derived from ADR-0006:*

```gdscript
class_name RngService
extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func seed_rng(value: int) -> void:
    _rng.seed = value

func randf_range(from: float, to: float) -> float:
    return _rng.randf_range(from, to)

func randi_range(from: int, to: int) -> int:
    return _rng.randi_range(from, to)
```

Register in Godot Project Settings → Autoloads as `RngService` pointing to `src/systems/rng_service.gd`.

For unit tests, use `RngService.seed_rng(FIXED_SEED)` before each test that uses randomness to ensure determinism. The seed value itself does not matter — consistency between calls is what matters.

---

## Out of Scope

*Handled by Story 002 — do not implement here:*

- Story 002: `ShotSpreadCalculation.apply_spread()` which calls `RngService.randf_range`

---

## QA Test Cases

- **AC-1 to AC-4**: RngService interface
  - Given: RngService autoload is available
  - When: `seed_rng(123)` is called then `randf_range(0.0, 1.0)` is called
  - Then: Returns a float in [0.0, 1.0); calling again with same seed returns same value

- **AC-5**: Determinism
  - Given: `seed_rng(42)` is called
  - When: `randf_range(0.0, 1.0)` is called, then `seed_rng(42)` is called again, then `randf_range(0.0, 1.0)` is called again
  - Then: Both calls return the same value

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/shot_spread/rng_service_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002 (apply_spread requires RngService)

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 5/5 passing (all ACs verified via unit tests)
**Deviations**: None
**Test Evidence**: `tests/unit/shot_spread/rng_service_test.gd` — 9 test functions
**Code Review**: Self-reviewed — thin wrapper, no ADR deviations, no non-trivial logic
