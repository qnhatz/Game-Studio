# ADR-0011: Test Framework Integration

## Status
Proposed

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (testing infrastructure) |
| **Knowledge Risk** | LOW — GUT (Godot Unit Testing) targets GDScript; headless runner is a stable Godot CLI feature |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `technical-preferences.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm GUT addon is compatible with Godot 4.6 before first test run |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology — tests target systems as standalone nodes) |
| **Enables** | All Logic and Integration story implementation (test evidence is blocking for those story types) |
| **Blocks** | Any Logic or Integration story cannot reach Done without passing unit tests |
| **Ordering Note** | Must be Accepted and the framework initialised before the first Logic story begins |

## Context

### Problem Statement

Flick Duel's core systems (hit detection, turn state machine, spread calculation, status effects,
AI targeting) are pure logic with no external dependencies. They must have automated unit tests
to validate GDD acceptance criteria and catch regressions. We need a test framework, directory
structure, and CI runner configured before any system is implemented.

### Constraints

- GDScript only (GUT is the standard GDScript test framework)
- `technical-preferences.md` specifies: GUT (Godot Unit Testing 4.x), minimum coverage on core
  game logic, CI runner: `godot --headless --script tests/gdunit4_runner.gd`
- Browser export (Compatibility) cannot run headless tests — tests run against the desktop export
- Tests must not require a full scene tree for Logic stories (pure GDScript systems are testable
  in isolation)

### Requirements

- Unit test framework: GUT (Godot Unit Testing, compatible with Godot 4.x)
- CI runner: headless Godot invocation (no display server)
- Directory structure mirrors `src/` layout
- Tests are deterministic: no random seeds except when explicitly testing RNG behaviour
  (always seed RngService with a fixed constant at test start)
- Logic stories: `tests/unit/` — blocking gate, must pass before story reaches Done
- Integration stories: `tests/integration/` — blocking gate

## Decision

**GUT 4.x addon in `addons/gut/`, test runner at `tests/gdunit4_runner.gd`, tests in `tests/unit/`
and `tests/integration/` mirroring `src/` structure.**

### Directory Structure

```
tests/
├── gdunit4_runner.gd          # Headless CI entry point
├── unit/
│   ├── systems/
│   │   ├── test_figure_geometry.gd
│   │   ├── test_body_zone_hit_detection.gd
│   │   ├── test_shot_spread_calculation.gd
│   │   ├── test_status_effects.gd
│   │   ├── test_action_validation.gd
│   │   ├── test_movement.gd
│   │   ├── test_two_action_turn_system.gd
│   │   ├── test_win_condition.gd
│   │   ├── test_game_mode_manager.gd
│   │   ├── test_ai_targeting.gd
│   │   └── test_flick_event.gd
│   └── autoloads/
│       └── test_rng_service.gd
└── integration/
    ├── test_shot_pipeline.gd      # FlickEvent → spread → hit → status effect
    ├── test_turn_flow.gd          # full turn: FIRE + MOVE → TURN_END
    ├── test_win_flow.gd           # headshot → match_won signal
    └── test_rematch_reset.gd      # all reset() calls produce correct post-conditions
```

### Test File Convention

```gdscript
# tests/unit/systems/test_figure_geometry.gd
extends GutTest

func before_each() -> void:
    # Set up system under test
    pass

func test_head_centre_at_correct_offset() -> void:
    var fg := FigureGeometry.new()
    var result := fg.get_zone_circle(0)   # P1
    assert_eq(result.centre, Vector2(200, 338) + Vector2(0, -162))
    assert_eq(result.radius, 18.0)
```

**Naming conventions:**
- File: `test_[system_slug].gd`
- Test function: `test_[scenario]_[expected_outcome]()`
- No shared state between tests: each `before_each()` creates fresh instances

### RngService in Tests

All tests that involve randomness seed `RngService` with a fixed constant before the call:

```gdscript
func test_spread_applies_angular_offset() -> void:
    RngService.seed_rng(12345)
    var event := FlickEvent.new(Vector2.RIGHT, 1.0, 0)
    var result := ShotSpreadCalculation.apply_spread(event, 10.0)
    # With seed 12345, the specific offset is known; assert it is within ±10 degrees of RIGHT
    assert_true(result.angle_to(Vector2.RIGHT) <= deg_to_rad(10.0))
```

### CI Runner

```
godot --headless --script tests/gdunit4_runner.gd
```

Run on every push and PR (`.github/workflows/tests.yml`). Exit code 0 = all tests pass.
Exit code non-zero = failure; CI blocks merge.

### What NOT to Automate (per coding-standards.md)

- Visual fidelity (Line2D rendering, colour correctness)
- "Feel" qualities (input responsiveness, gesture timing)
- Full gameplay sessions (covered by playtesting)

These are ADVISORY story types (Visual/Feel/UI) and use manual sign-off in `production/qa/evidence/`.

## Alternatives Considered

### Alternative A: Godot's built-in test runner (no addon)

- **Description**: Write tests as GDScript scripts executed directly with `--script`
- **Pros**: No addon dependency
- **Cons**: No test runner UI, no assert library, no parameterised tests, no failure reporting
  beyond print statements. GUT provides all of these and is the community standard for GDScript.
- **Rejection**: GUT is explicitly specified in `technical-preferences.md`

### Alternative B: C# NUnit (if switching to C#)

- **Description**: Use Godot's .NET test support with NUnit
- **Pros**: Richer test ecosystem
- **Cons**: Project is GDScript-only (CLAUDE.md). C# would require a separate runtime.
- **Rejection**: Language constraint

## Consequences

### Positive

- Every Logic and Integration story has a clear, automated pass/fail gate
- Headless runner integrates with CI: tests run on every push, no manual step
- Test structure mirrors `src/`: easy to find the test for any implementation file
- RngService seeding pattern makes all spread and AI tests deterministic

### Negative

- GUT addon must be kept updated; breaking GUT changes require test maintenance
- Tests must be written alongside implementation (not after) to satisfy the blocking gate

### Risks

- **GUT + Godot 4.6 compatibility**: GUT releases track Godot but may lag on point releases.
  *Mitigation*: pin GUT version; check release notes before Godot 4.6 upgrade.
- **Headless runner on CI**: requires Godot 4.6 desktop binary available in CI environment.
  *Mitigation*: use a GitHub Actions Godot setup action (`chickensoft-games/setup-godot`
  or equivalent) to install the correct version.

## GDD Requirements Addressed

This ADR does not correspond to a single GDD system — it satisfies the testing requirements
of all Logic and Integration GDD acceptance criteria across all 19 systems.

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-BZHD-001 | Body-Zone Hit Detection | Analytic ray math — unit testable | `test_body_zone_hit_detection.gd` covers all AC from figure-geometry and body-zone-hit-detection GDDs |
| TR-TATS-003 | Turn System | reset() post-conditions | `test_rematch_reset.gd` integration test verifies all system post-conditions |
| TR-SSC-002 | Shot Spread | RngService seeded determinism | `test_rng_service.gd` and `test_shot_spread_calculation.gd` use fixed seed |

## Performance Implications

- **CI time**: Full test suite estimated <60 seconds headless for a game of this scope
- **Development**: GUT runs in-editor; instant feedback during implementation

## Migration Plan

Greenfield. Steps:
1. Download GUT 4.x and place in `addons/gut/`
2. Enable plugin in Project Settings > Plugins
3. Create `tests/gdunit4_runner.gd` (standard GUT headless runner script)
4. Create `.github/workflows/tests.yml` with Godot headless invocation
5. Write `tests/unit/systems/test_flick_event.gd` as the first test (simplest system, pure logic)
6. Verify CI passes before beginning any other implementation story

## Validation Criteria

- `godot --headless --script tests/gdunit4_runner.gd` exits with code 0 on a clean repo
- At least one passing unit test exists before any Logic story is marked Done
- CI workflow file present at `.github/workflows/tests.yml`

## Related Decisions

- ADR-0001: Scene Topology — systems are plain GDScript nodes; unit-testable without full scene
- ADR-0006: RNG Strategy — `RngService.seed_rng()` used in all randomness tests
- ADR-0008: FlickEvent Contract — first test file recommended (`test_flick_event.gd`)
