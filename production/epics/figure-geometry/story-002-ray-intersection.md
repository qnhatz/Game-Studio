# Story 002: Ray Intersection Tests

> **Epic**: Figure Geometry
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/figure-geometry.md`
**Requirement**: `TR-FIG-001`, `TR-FIG-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (Physics Policy)
**ADR Decision Summary**: All hit detection uses analytic ray math in pure GDScript — no PhysicsServer, no Area2D, no CollisionShape2D. Ray vs circle for HEAD (F2), ray vs AABB slab method for ARMS/LEGS (F3). Division by zero handled with INF substitution.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `INF` constant is available in GDScript (global constant). `dot()` is a `Vector2` instance method. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: Analytic math only — no physics nodes
- Required: INF substitution for axis-aligned rays (D.x=0 or D.y=0) — no crash on degenerate input
- Required: Priority order for overlapping zones: HEAD > ARMS > LEGS (checked in this order)

---

## Acceptance Criteria

*From GDD `design/gdd/figure-geometry.md`, scoped to this story:*

- [ ] **Head hit**: A ray aimed directly at the head centre returns `&"HEAD"`.
- [ ] **Neck miss**: A ray aimed at `anchor + Vector2(0, -135)` (neck gap) returns `&"MISS"`.
- [ ] **Arms hit**: A ray aimed at the arms rect centre returns `&"ARMS"`.
- [ ] **Mid-torso miss**: A ray aimed at `anchor + Vector2(0, -81)` returns `&"MISS"`.
- [ ] **Legs hit**: A ray aimed at the legs rect centre returns `&"LEGS"`.
- [ ] **Axis-aligned ray (D.y=0)**: Calling `detect_zone` with a horizontal ray does not crash; returns correct result.
- [ ] **Axis-aligned ray (D.x=0)**: Calling `detect_zone` with a vertical ray does not crash; returns correct result.

---

## Implementation Notes

*Derived from ADR-0005 and GDD formulas F2 and F3:*

Implement `detect_zone(origin: Vector2, direction: Vector2, player_id: int) -> StringName` as a method on `FigureGeometry`.

```gdscript
const CANVAS_DIAGONAL: float = 922.0  # sqrt(800^2 + 450^2)

func detect_zone(origin: Vector2, direction: Vector2, player_id: int) -> StringName:
    # Check HEAD first (highest priority)
    var head: Dictionary = get_zone_circle(player_id)
    if _ray_hits_circle(origin, direction, head.centre, head.radius):
        return &"HEAD"
    # Check ARMS
    if _ray_hits_rect(origin, direction, get_zone_rect(player_id, &"ARMS")):
        return &"ARMS"
    # Check LEGS
    if _ray_hits_rect(origin, direction, get_zone_rect(player_id, &"LEGS")):
        return &"LEGS"
    return &"MISS"

func _ray_hits_circle(origin: Vector2, direction: Vector2, centre: Vector2, radius: float) -> bool:
    var oc: Vector2 = centre - origin
    var t: float = oc.dot(direction)
    var d_sq: float = oc.dot(oc) - t * t
    return d_sq <= radius * radius

func _ray_hits_rect(origin: Vector2, direction: Vector2, rect: Rect2) -> bool:
    var dx: float = direction.x if direction.x != 0.0 else 1e-10
    var dy: float = direction.y if direction.y != 0.0 else 1e-10
    var t_min: float = maxf((rect.position.x - origin.x) / dx, (rect.position.y - origin.y) / dy)
    var t_max: float = minf((rect.end.x - origin.x) / dx, (rect.end.y - origin.y) / dy)
    return t_min <= t_max and t_max >= 0.0 and t_min <= CANVAS_DIAGONAL
```

For the degenerate axis case, using `1e-10` (near-zero) as a guard avoids `INF` propagation issues while still giving correct slab results. Alternatively use `INF` with explicit direction component checks — either approach is valid as long as the test passes.

---

## Out of Scope

*Handled by Story 001 — do not implement here:*

- Zone accessor methods and anchor management (Story 001)

---

## QA Test Cases

- **AC-1 to AC-5**: Zone detection correctness
  - Given: P1 at default anchor (200, 338); ray origin at (0, 338) (left edge, same Y as anchor)
  - When: Ray aimed at head_centre / neck / arms_centre / mid-torso / legs_centre
  - Then: Returns HEAD / MISS / ARMS / MISS / LEGS

- **AC-6 to AC-7**: Degenerate rays
  - Given: Horizontal ray `direction = Vector2(1, 0)`; vertical ray `direction = Vector2(0, 1)`
  - When: `detect_zone` called
  - Then: No crash; returns correct zone or MISS based on geometry

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/figure_geometry/figure_geometry_ray_intersection_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be DONE (zone accessors are called by ray intersection methods)
- Unlocks: BodyZoneHitDetection epic (which calls `detect_zone`)
