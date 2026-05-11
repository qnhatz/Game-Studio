# Epic: Figure Geometry

> **Layer**: Core
> **GDD**: design/gdd/figure-geometry.md
> **Architecture Module**: `FigureGeometry`
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories figure-geometry`

## Overview

Figure Geometry defines the stick figure as a spatial object: proportions, hit zone
boundaries, and zone accessor methods. It is the single source of truth for where each
figure occupies screen space. All three hit zones (head: circle r=18, arms: 80×36 rect,
legs: 36×72 rect) are expressed as anchor-relative offsets. Zone accessors
(`get_zone_circle`, `get_zone_rect`, `get_zone_centre`) must be used by all callers —
BodyZoneHitDetection, FigureRenderer, and AITargeting must never compute geometry inline.
Each figure's anchor is initialised from `ScreenLayout` constants and updated at runtime
by the Movement system. This module also implements the two analytic intersection tests
(ray vs circle for HEAD, ray vs AABB slab method for ARMS/LEGS) that BodyZoneHitDetection
calls to resolve shots.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Scene Topology | FigureGeometry.reset() restores anchors to ScreenLayout defaults; called as step 3 of match reset sequence | LOW |
| ADR-0005: Physics Policy | No PhysicsServer; analytic ray math only; zone accessor methods are the sole geometry source | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-FIG-001 | get_zone_circle(player_id) → {centre, radius} for HEAD zone | ADR-0005 ✅ |
| TR-FIG-002 | get_zone_rect(player_id, zone) → Rect2 for ARMS/LEGS zones | ADR-0005 ✅ |
| TR-FIG-003 | Anchor repositions on MOVE; all zones track with anchor | ADR-0001 ✅ |
| TR-FIG-004 | P2 mirror: X offsets negated; hit zone boundaries unchanged | ADR-0001 ⚠️ (implicit in scene topology — P2 visual mirror is renderer concern; zones use same offsets) |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/figure-geometry.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories figure-geometry` to break this epic into implementable stories.
