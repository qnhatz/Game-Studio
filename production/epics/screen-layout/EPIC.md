# Epic: Screen Layout

> **Layer**: Foundation
> **GDD**: design/gdd/screen-layout.md
> **Architecture Module**: `ScreenLayout` (Autoload)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories screen-layout`

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

## Next Step

Run `/create-stories screen-layout` to break this epic into implementable stories.
