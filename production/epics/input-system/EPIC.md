# Epic: Input System

> **Layer**: Foundation
> **GDD**: design/gdd/input-system.md
> **Architecture Module**: `InputSystem` + `FlickEvent` (value object)
> **Status**: Ready
> **Stories**: 3 stories

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | FlickEvent Value Object | Logic | Ready | ADR-0008 |
| 002 | InputSystem Pointer State Machine | Logic | Ready | ADR-0007 |
| 003 | InputSystem Window Protocol and Orientation Gate | Integration | Ready | ADR-0007 |

## Overview

The Input System is the first node in the shot pipeline. It implements a unified pointer
state machine that converts mouse drag or touch drag gestures into typed `FlickEvent`
value objects (direction: Vector2, power: float, timestamp: int). `FlickEvent` is defined
here as a `class_name FlickEvent extends RefCounted` — the Foundation-layer contract
shared by InputSystem, AITargeting, and ShotSpreadCalculation. The system handles
ownership attribution to player zones via `ScreenLayout` gesture rects, enforces the
turn system's open/close input window protocol, applies cancellation thresholds, and
deactivates on orientation change. The AI bypasses this module entirely, synthesising
`FlickEvent` directly. This epic carries the project's highest engine risk: `InputEvent-
ScreenDrag` behaviour on iOS Safari is verified by analysis but requires device smoke
test before ship.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Input System | Unified mouse/touch pointer state machine; `_input()` handler; `_touch_id = -1` sentinel; `_window_open` guard; orientation gate deactivation | HIGH |
| ADR-0008: FlickEvent Contract | `class_name FlickEvent extends RefCounted`; direction convention (slingshot); power formula; immutable after construction | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-INP-001 | Mouse drag → FlickEvent (direction, power, timestamp) | ADR-0008 ✅ |
| TR-INP-002 | Touch drag → FlickEvent (same as mouse) | ADR-0008 ✅ |
| TR-INP-003 | InputEventScreenDrag: continuous fire vs drag-end behaviour | ADR-0007 ✅ |
| TR-INP-004 | Input window deactivation on orientation change | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/input-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`
- **HIGH RISK gate**: iOS Safari device smoke test documented in `production/qa/` before ship
  (OQ-1 resolved by analysis — physical device test still required at release)

## Next Step

Run `/story-readiness production/epics/input-system/story-001-flick-event.md` then `/dev-story` to begin implementation.
