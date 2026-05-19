# Epic: Trajectory Visualization

> **Layer**: Core
> **GDD**: design/gdd/trajectory-visualization.md
> **Architecture Module**: `TrajectoryVisualization`
> **Status**: Ready
> **Stories**: 3 stories created

## Overview

Trajectory Visualization renders two kinds of ink lines. The **aim line** is a live
rubber-band drawn from the figure anchor in the shot direction while the player drags —
it updates on every `InputEventScreenDrag` event (driven by ADR-0007's `aim_updated`
signal from InputSystem) and disappears on release. The **shot line** is a persistent
Line2D node drawn on release in the resolved post-spread direction, extending to the
canvas edge; it fades out after `SHOT_LINE_DISPLAY_MS` using a Tween, guarded by
`is_instance_valid()`. Both lines use the firing player's ink colour. On match end,
`freeze()` calls `tween.kill()` to hold all lines in place; `reset()` clears them all.
This module is purely visual — it does not feed into hit detection, which runs its own
independent ray test. This epic shares the HIGH engine risk of InputSystem because the
aim line update path depends on `InputEventScreenDrag` iOS Safari behaviour.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Scene Topology | freeze() / reset() are part of the match lifecycle; reset() called as step 4 in match reset sequence | LOW |
| ADR-0003: Rendering Primitives | Line2D nodes only; aim line reused single node; shot lines dynamically instantiated and Tween-faded | LOW |
| ADR-0007: Input System | aim_updated signal emitted from InputSystem._on_pointer_move(); TrajectoryVisualization subscribes | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-TVIS-001 | Live aim line draws during drag | ADR-0003 ✅ |
| TR-TVIS-002 | Shot lines persist during HALTED state (freeze) | ADR-0003 ⚠️ (verify tween.kill() called on all stored Tween refs in freeze()) |
| TR-TVIS-003 | Live aim line updates on each drag event | ADR-0007 ✅ |
| TR-TVIS-004 | Shot lines fade via Tween; guarded by is_instance_valid() | ADR-0003 ✅ |
| TR-TVIS-005 | reset() clears all shot lines on rematch | ADR-0001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/trajectory-visualization.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- TR-TVIS-002 implementation note resolved: `freeze()` must call `tween.kill()` on every
  stored Tween reference — verify in code review before closing the freeze() story
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Aim Line Logic | Logic | Ready | ADR-0003, ADR-0007 |
| 002 | Shot Line Logic | Logic | Ready | ADR-0003, ADR-0001 |
| 003 | Visual Rendering and Lifecycle | Visual/Feel | Ready | ADR-0003, ADR-0001 |

## Next Step

Run `/story-readiness production/epics/trajectory-visualization/story-001-aim-line-logic.md` then `/dev-story` to begin implementation.
