# Epic: Status Effects

> **Layer**: Foundation
> **GDD**: design/gdd/status-effects.md
> **Architecture Module**: `StatusEffects`
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories status-effects`

## Overview

Status Effects implements the per-player state layer that records and enforces the
consequences of body-zone hits. It tracks two boolean permission flags per player —
`can_fire` (arms hit) and `can_move` (legs hit) — plus integer duration counters.
The module is pure GDScript with no engine API dependencies: it stores state and
exposes a small write/read/reset API. Body-Zone Hit Detection writes effects;
TwoActionTurnSystem ticks and clears them at turn start; ActionValidation, FigureRenderer,
and HUDTurnIndicator read them; GameStateMachine resets all on match end. No other system
may write to this module.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Scene Topology | reset_all() is step 1 of the match reset sequence; GameStateMachine orchestrates | LOW |
| ADR-0004: System Communication | Direct method calls on critical path; canonical API names set_disarmed / tick_effects / reset_all | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-STE-001 | Disarmed state: can_fire = false for N turns | ADR-0004 ✅ |
| TR-STE-002 | Immobilized state: can_move = false for N turns | ADR-0004 ✅ |
| TR-STE-003 | tick_effects() called each turn start | ADR-0004 ✅ |
| TR-STE-004 | reset_all() restores clean state on rematch | ADR-0001 ✅ |
| TR-STE-005 | Method API: set_disarmed / tick_effects / reset_all | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/status-effects.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories status-effects` to break this epic into implementable stories.
