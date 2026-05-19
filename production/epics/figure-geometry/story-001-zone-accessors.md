# Story 001: Zone Accessors and Anchor Management

> **Epic**: Figure Geometry
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/figure-geometry.md`
**Requirement**: `TR-FIG-001`, `TR-FIG-002`, `TR-FIG-003`, `TR-FIG-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (Physics Policy), ADR-0001 (Scene Topology)
**ADR Decision Summary**: No PhysicsServer — analytic ray math only. Zone accessor methods (`get_zone_circle`, `get_zone_rect`, `get_anchor`) are the sole geometry source; all callers use these instead of computing geometry inline. Anchor resets to ScreenLayout defaults in the match reset sequence (step 3).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Rect2`, `Vector2` are stable built-in types. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: All zone geometry derived from `get_anchor(player_id)` — never hardcoded in callers
- Required: `reset()` restores anchors to `ScreenLayout.P1_ANCHOR` / `ScreenLayout.P2_ANCHOR`
- Forbidden: Inline geometry calculations in callers (BodyZoneHitDetection, FigureRenderer, AITargeting)

---

## Acceptance Criteria

*From GDD `design/gdd/figure-geometry.md`, scoped to this story:*

- [ ] **Initial anchors**: `get_anchor(0)` returns `Vector2(200, 338)` and `get_anchor(1)` returns `Vector2(600, 338)` after construction.
- [ ] **Head zone**: `get_zone_circle(player_id)` returns `{centre: anchor + Vector2(0, -162), radius: 18}`.
- [ ] **Arms zone**: `get_zone_rect(player_id, "ARMS")` returns `Rect2(anchor.x - 40, anchor.y - 126, 80, 36)`.
- [ ] **Legs zone**: `get_zone_rect(player_id, "LEGS")` returns `Rect2(anchor.x - 18, anchor.y - 72, 36, 72)`.
- [ ] **set_anchor**: After `set_anchor(player_id, new_pos)`, all subsequent zone accessors use the new anchor.
- [ ] **Head zone non-overlap with arms**: Head circle top edge (`anchor.y - 162 - 18 = anchor.y - 180`) is above arms rect top edge (`anchor.y - 126`); no overlap.
- [ ] **Arms and legs non-overlap**: Arms rect bottom (`anchor.y - 90`) is above legs rect top (`anchor.y - 72`); no overlap.
- [ ] **HUD clearance**: Head top at `anchor.y - 180 = 338 - 180 = 158`; HUD bottom is at `y = 90`; clearance is 68 px ≥ 0.
- [ ] **reset()**: After `set_anchor` changes a player's position, calling `reset()` restores it to the default ScreenLayout anchor.

---

## Implementation Notes

*Derived from ADR-0005 and GDD formulas:*

```gdscript
class_name FigureGeometry
extends Node

const P1_DEFAULT_ANCHOR: Vector2 = Vector2(200, 338)
const P2_DEFAULT_ANCHOR: Vector2 = Vector2(600, 338)
const HEAD_OFFSET: Vector2 = Vector2(0, -162)
const HEAD_RADIUS: float = 18.0
const ARMS_OFFSET: Vector2 = Vector2(-40, -126)
const ARMS_SIZE: Vector2 = Vector2(80, 36)
const LEGS_OFFSET: Vector2 = Vector2(-18, -72)
const LEGS_SIZE: Vector2 = Vector2(36, 72)

var _anchors: Array[Vector2] = [P1_DEFAULT_ANCHOR, P2_DEFAULT_ANCHOR]

func get_anchor(player_id: int) -> Vector2:
    return _anchors[player_id]

func set_anchor(player_id: int, pos: Vector2) -> void:
    _anchors[player_id] = pos

func get_zone_circle(player_id: int) -> Dictionary:
    return {centre = _anchors[player_id] + HEAD_OFFSET, radius = HEAD_RADIUS}

func get_zone_rect(player_id: int, zone: StringName) -> Rect2:
    var anchor: Vector2 = _anchors[player_id]
    if zone == &"ARMS":
        return Rect2(anchor + ARMS_OFFSET, ARMS_SIZE)
    if zone == &"LEGS":
        return Rect2(anchor + LEGS_OFFSET, LEGS_SIZE)
    push_error("FigureGeometry: unknown zone " + zone)
    return Rect2()

func get_zone_centre(player_id: int, zone: StringName) -> Vector2:
    if zone == &"HEAD":
        return get_zone_circle(player_id).centre
    return get_zone_rect(player_id, zone).get_center()

func reset() -> void:
    _anchors[0] = P1_DEFAULT_ANCHOR
    _anchors[1] = P2_DEFAULT_ANCHOR
```

Use `StringName` constants (prefixed with `&`) for zone names to avoid per-call string allocation.

---

## Out of Scope

*Handled by Story 002 — do not implement here:*

- Story 002: Ray intersection tests (F2 ray vs circle, F3 ray vs AABB slab method)

---

## QA Test Cases

- **AC-1**: Initial anchors
  - Given: New `FigureGeometry` instance
  - When: `get_anchor(0)` and `get_anchor(1)` are called
  - Then: Returns `Vector2(200, 338)` and `Vector2(600, 338)` respectively

- **AC-2 to AC-4**: Zone accessor correctness
  - Given: P1 at default anchor (200, 338)
  - When: `get_zone_circle(0)`, `get_zone_rect(0, "ARMS")`, `get_zone_rect(0, "LEGS")` called
  - Then: Returns exact expected values per GDD formulas

- **AC-5**: Dynamic anchor tracking
  - Given: `set_anchor(0, Vector2(150, 338))`
  - When: `get_zone_circle(0)` is called
  - Then: Centre is `Vector2(150, 338 - 162) = Vector2(150, 176)` — updated from new anchor

- **AC-6 to AC-7**: Non-overlap assertions
  - Given: Default anchors
  - When: Zone boundaries are read
  - Then: Head bottom < Arms top; Arms bottom < Legs top

- **AC-8**: reset() restores defaults
  - Given: `set_anchor(0, Vector2(100, 338))`
  - When: `reset()` is called
  - Then: `get_anchor(0)` == `Vector2(200, 338)`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/figure_geometry/figure_geometry_zone_accessors_test.gd` — must exist and pass

**Status**: [x] `tests/unit/figure_geometry/figure_geometry_zone_accessors_test.gd` — 26 test functions

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 9/9 passing (all ACs verified via unit tests)
**Deviations**: None
**Test Evidence**: `tests/unit/figure_geometry/figure_geometry_zone_accessors_test.gd` — 26 test functions
**Code Review**: CONCERNS resolved — AC-6/7/8 tests rewritten to use accessors, test names corrected, `get_zone_centre` coverage added, `queue_free` → `free`

---

## Dependencies

- Depends on: None — ScreenLayout constants are already implemented
- Unlocks: Story 002 (ray intersection tests use zone accessors)
