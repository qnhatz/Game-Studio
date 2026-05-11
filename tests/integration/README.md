# Integration Tests

Cross-system tests that verify multiple systems work together.

## Required coverage (per ADR-0011)

- `shot_pipeline/` — full FlickEvent → ShotSpreadCalculation → BodyZoneHitDetection → WinCondition chain
- `ai_turn/` — AITargeting → TwoActionTurnSystem → Movement full AI turn
- `state_transitions/` — GameStateMachine transitions and system reset sequence

Write these as systems are integrated. Run after each sprint's smoke check.
