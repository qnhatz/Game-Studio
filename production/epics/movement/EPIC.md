# Epic: Movement

> **Layer**: Core
> **GDD**: design/gdd/movement.md
> **Architecture Module**: `Movement`
> **Status**: Ready
> **Stories**: 2 stories created

## Overview

The Movement system handles the MOVE action: the active player taps a destination inside
their gesture region and the figure's anchor X snaps to that position (clamped to zone
bounds with a 20 px margin; Y never changes). There is no animation — the figure
teleports on the same frame. Tap vs drag disambiguation uses `TAP_MOVE_RADIUS_PX = 12 px`
from the InputSystem's pointer state machine (ADR-0007): displacements below 12 px are
MOVE taps; anything above is a FIRE drag. The action is consumed from TwoActionTurnSystem's
pool regardless of whether the figure actually moves (no-op moves are valid). Movement
calls `FigureGeometry.set_anchor()` as its sole write; all downstream systems
(FigureRenderer, BodyZoneHitDetection, AITargeting) read the new anchor on the next call.
AI MOVE uses the same clamping formula with a heuristic destination from AITargeting.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: System Communication | TwoActionTurnSystem calls Movement.on_move_tapped() directly on critical path; no event queuing | LOW |
| ADR-0007: Input System | Tap vs drag disambiguation via TAP_MOVE_RADIUS_PX threshold in pointer state machine | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-MOV-001 | MOVE action repositions anchor X within player zone bounds | ADR-0004 ✅ |
| TR-MOV-002 | Tap destination routing (distinct from flick drag) | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/movement.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Anchor Clamping Logic | Logic | Ready | ADR-0004 |
| 002 | Tap-vs-Drag Disambiguation | Integration | Ready | ADR-0007 |

## Next Step

Run `/story-readiness production/epics/movement/story-001-anchor-clamping.md` then `/dev-story` to begin implementation.
