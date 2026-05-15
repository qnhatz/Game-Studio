# Epic: Screen Layout

> **Layer**: Foundation
> **GDD**: design/gdd/screen-layout.md
> **Architecture Module**: `ScreenLayout` (Autoload)
> **Status**: Ready
> **Stories**: 5 stories — see table below

## Overview

Screen Layout implements the single source of spatial truth for Flick Duel. It is an
Autoload singleton exposing named constants for the 800×450 logical canvas, P1/P2 zone
rects, figure anchor positions, HUD strip rect, and gesture region rects. It also
implements the orientation gate — suspending all input when the viewport is portrait and
showing a "Rotate your device" prompt. Every downstream system (FigureGeometry,
InputSystem, TrajectoryVisualization, HUDTurnIndicator, AITargeting) reads from this
module; nothing writes back to it. It is designed once and never mutated at runtime.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Scene Topology | Single persistent scene; all systems are nodes under Main.tscn; reset in-place | LOW |
| ADR-0002: Web Export / Canvas | 800×450 px, 16:9, Compatibility renderer (WebGL 2), Keep Aspect letterbox | LOW |
| ADR-0007: Input System | Unified pointer state machine for mouse/touch; orientation gate at `_input()`; `_window_open` guard | HIGH |
| ADR-0010: HUD / CanvasLayer | HUD strip 90 px, CanvasLayer layer=1; MOUSE_FILTER_IGNORE on HUD subtree | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-SCRN-001 | Canvas 800×450 px, 16:9 aspect ratio | ADR-0002 ✅ |
| TR-SCRN-002 | Keep Aspect letterbox scaling | ADR-0002 ✅ |
| TR-SCRN-003 | P1-left / P2-right spatial split | ADR-0001 ✅ |
| TR-SCRN-004 | HUD strip 90 px top band | ADR-0010 ✅ |
| TR-SCRN-005 | Gesture dead zone / tap vs drag discrimination | ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/screen-layout.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [ScreenLayout Constants](story-001-screen-layout-constants.md) | Logic | Ready | ADR-0001, ADR-0002 |
| 002 | [GESTURE_RECT Formula and Scaling](story-002-gesture-rect-scaling.md) | Logic | Ready | ADR-0002, ADR-0007 |
| 003 | [Gesture Region Dead-Zone Filtering](story-003-gesture-dead-zone-filtering.md) | Integration | Ready | ADR-0007 |
| 004 | [Orientation Gate — Portrait Block and Resume](story-004-orientation-gate.md) | Integration | Ready | ADR-0007, ADR-0010 |
| 005 | [Multi-Touch Zone Isolation](story-005-multi-touch-zone-isolation.md) | Integration | Ready | ADR-0007 |

## Next Step

Run `/story-readiness production/epics/screen-layout/story-001-screen-layout-constants.md` then `/dev-story` to begin implementation. Work through stories in order — each story's `Depends on:` field tells you what must be DONE first.
