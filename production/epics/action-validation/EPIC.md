# Epic: Action Validation

> **Layer**: Core
> **GDD**: design/gdd/action-validation.md
> **Architecture Module**: `ActionValidation`
> **Status**: Ready
> **Stories**: 1 story created

## Overview

Action Validation is the stateless gatekeeper between a player's current Status Effects
state and the actions they may take on their turn. It reads `can_fire` and `can_move`
flags from StatusEffects and exposes three query methods: `get_valid_actions(player_id)`
returns the full valid action set `{FIRE, MOVE}`; `is_valid(player_id, action_type)`
returns a single boolean; `is_turn_skipped(player_id)` returns true when both flags are
false. TwoActionTurnSystem calls these before accepting each action. ActionValidation
holds no state — it never writes to any system and has no lifecycle methods (no reset, no
tick). The ordering guarantee that `tick_effects` precedes any validation query is
enforced by TwoActionTurnSystem, not by this module.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: System Communication | Direct method calls on critical path; canonical API names `get_valid_actions` / `is_valid`; AUTO_SKIP routing defined in signal map | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ACV-001 | get_valid_actions(player_id) respects Status Effects flags | ADR-0004 ✅ |
| TR-ACV-002 | AUTO_SKIP triggered when no actions valid | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/action-validation.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | ActionValidation Logic | Logic | Ready | ADR-0004 |

## Next Step

Run `/story-readiness production/epics/action-validation/story-001-validation-logic.md` then `/dev-story` to begin implementation.
