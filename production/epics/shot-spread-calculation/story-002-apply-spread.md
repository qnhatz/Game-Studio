# Story 002: ShotSpreadCalculation.apply_spread()

> **Epic**: Shot Spread Calculation
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/shot-spread-calculation.md`
**Requirement**: `TR-SSC-001`, `TR-SSC-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (System Communication), ADR-0006 (RNG Strategy), ADR-0009 (AI Pipeline)
**ADR Decision Summary**: `apply_spread(event: FlickEvent, spread_deg: float) -> Vector2` is a direct synchronous call on the shot critical path. Called by TwoActionTurnSystem before hit detection. AI uses the same function with a seeded RNG for determinism.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `cos()`, `sin()`, `deg_to_rad()` are stable GDScript built-ins. No post-cutoff APIs used.

**Control Manifest Rules (Foundation layer)**:
- Required: Stateless pure function — no instance state, no side effects
- Required: Uses `RngService.randf_range()` — never calls `randf()` directly
- Required: Returns a unit Vector2

---

## Acceptance Criteria

*From GDD `design/gdd/shot-spread-calculation.md`, scoped to this story:*

- [ ] **F1 — power=0.0** produces `half_angle = 2.0°`.
- [ ] **F1 — power=1.0** produces `half_angle = 30.0°`.
- [ ] **F1 — power=0.5** produces `half_angle = 16.0°`.
- [ ] **F2+F3 — cone bounds**: With a fixed seed, run `apply_spread` 1000 times at `power=1.0` — all resulting angles are within ±30° of the input direction.
- [ ] **F3 — unit vector**: `apply_spread` result has `length()` ≈ 1.0 (within float epsilon) for any valid input.
- [ ] **EC3 — zero vector fallback**: `apply_spread` called with `direction=Vector2(0,0)` returns `Vector2(1, 0)` (no crash, no NaN).
- [ ] **EC4 — seeded determinism**: Two calls with the same seed and same inputs return the same result.

---

## Implementation Notes

*Derived from GDD formulas:*

```gdscript
class_name ShotSpreadCalculation

const MIN_SPREAD_DEG: float = 2.0
const MAX_SPREAD_DEG: float = 30.0

static func apply_spread(event: FlickEvent, spread_deg: float) -> Vector2:
    var direction: Vector2 = event.direction
    if direction.is_zero_approx():
        push_error("ShotSpreadCalculation: zero direction vector — returning (1,0)")
        return Vector2(1.0, 0.0)
    var half_angle: float = MIN_SPREAD_DEG + event.power * (MAX_SPREAD_DEG - MIN_SPREAD_DEG)
    var u1: float = RngService.randf_range(0.0, 1.0)
    var u2: float = RngService.randf_range(0.0, 1.0)
    var offset_deg: float = (u1 - u2) * half_angle
    var offset_rad: float = deg_to_rad(offset_deg)
    var cos_a: float = cos(offset_rad)
    var sin_a: float = sin(offset_rad)
    return Vector2(
        direction.x * cos_a - direction.y * sin_a,
        direction.x * sin_a + direction.y * cos_a
    ).normalized()
```

Note: `spread_deg` parameter is accepted for future difficulty-level overrides (TR-SSC-003 / ADR-0009) but the half-angle formula uses `event.power` as the primary input. The `spread_deg` parameter scales the max spread for AI difficulty modes.

For tests that require determinism, call `RngService.seed_rng(FIXED_SEED)` before `apply_spread`.

---

## Out of Scope

*Handled by other epics — do not implement here:*

- RngService Autoload (Story 001)
- FlickEvent data class (input-system epic, already complete)
- Difficulty configuration (AI Pipeline epic)

---

## QA Test Cases

- **AC-1 to AC-3**: Half-angle formula
  - Given: power = 0.0 / 0.5 / 1.0
  - When: F1 is computed
  - Then: half_angle = 2.0 / 16.0 / 30.0 respectively

- **AC-4**: Cone bounds (1000-sample fuzz)
  - Given: `RngService.seed_rng(0)`, `power=1.0`, `direction=Vector2(1,0)`
  - When: `apply_spread` is called 1000 times (re-seeding each time for independent samples)
  - Then: Each result's angle from `Vector2(1,0)` is ≤ 30°

- **AC-5**: Unit vector
  - Given: 100 random valid directions
  - When: `apply_spread` is called for each
  - Then: `result.length()` is within 0.0001 of 1.0

- **AC-6**: Zero vector fallback
  - Given: `direction = Vector2.ZERO`
  - When: `apply_spread` is called
  - Then: Returns `Vector2(1, 0)` without crashing

- **AC-7**: Seeded determinism
  - Given: `RngService.seed_rng(99)`, then `apply_spread(event, spread_deg)` called, result stored
  - When: `RngService.seed_rng(99)` again, then same call
  - Then: Both results are equal

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/shot_spread/shot_spread_calculation_test.gd` — must exist and pass

**Status**: [x] `tests/unit/shot_spread/shot_spread_calculation_test.gd` — 9 test functions

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 7/7 passing (all ACs verified via unit tests)
**Deviations**: None — implemented with `spread_deg` param for AI difficulty scaling per ADR-0009; `power` clamped to [0,1]; assert guards spread_deg >= MIN_SPREAD_DEG
**Test Evidence**: `tests/unit/shot_spread/shot_spread_calculation_test.gd` — 9 test functions
**Code Review**: Self-reviewed (lean mode) — CONCERNS resolved before commit

---

## Dependencies

- Depends on: Story 001 must be DONE (RngService Autoload must be registered)
- Unlocks: BodyZoneHitDetection and TrajectoryVisualization epics
