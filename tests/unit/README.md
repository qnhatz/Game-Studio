# Unit Tests

One subdirectory per system. Each file: `[system]_[feature]_test.gd`.

## Required coverage (per ADR-0011 / coding standards)

- `turn_system/` — TwoActionTurnSystem state machine transitions
- `hit_detection/` — BodyZoneHitDetection ray_vs_circle, ray_vs_aabb
- `ai_targeting/` — AITargeting zone selection distribution, Gaussian pre-error
- `shot_spread/` — ShotSpreadCalculation.apply_spread() bounds

Write these as systems are implemented. The gate check requires at least one
example test file before advancing to Pre-Production.
