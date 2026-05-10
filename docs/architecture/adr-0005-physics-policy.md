# ADR-0005: Physics Policy

## Status
Accepted

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Physics (2D) |
| **Knowledge Risk** | LOW — this ADR explicitly avoids the physics engine; Jolt-as-default (4.6) is irrelevant |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — pure GDScript math, no engine physics APIs |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology — no physics nodes in the scene tree) |
| **Enables** | BodyZoneHitDetection implementation |
| **Blocks** | BodyZoneHitDetection story |
| **Ordering Note** | Must be Accepted before any hit detection code is written |

## Context

### Problem Statement

Flick Duel's hit detection — determining whether a shot line intersects a stick figure's head,
arms, or legs — could be implemented using Godot's physics engine (ray casts, collision shapes)
or via pure analytic geometry. We need a definitive choice, as these approaches are mutually
incompatible and the physics engine choice (Jolt default in Godot 4.6) has meaningful implications.

### Constraints

- Godot 4.6 uses Jolt as the default 3D physics engine; 2D physics remains GodotPhysics2D
- No `RigidBody2D`, `StaticBody2D`, or `CollisionShape2D` nodes (ADR-0002 forbidden patterns)
- All hit zones have simple geometry: one circle (head) and two axis-aligned rectangles (arms, legs)
- Hit detection must be deterministic and unit-testable without a running physics server
- Shot is a ray (origin point + direction vector); hit zones are stationary

### Requirements

- Ray vs circle intersection for HEAD zone
- Ray vs axis-aligned rectangle (AABB) intersection for ARMS and LEGS zones
- Priority: HEAD > ARMS > LEGS (if geometrically impossible overlap occurs)
- Result returned synchronously (Pattern A, ADR-0004)
- Unit-testable with pure GDScript; no physics server required in test environment

## Decision

**All hit detection is analytic ray math in pure GDScript. No physics engine nodes or server
calls are used.**

### Ray vs Circle (HEAD detection)

```gdscript
# Returns true if ray hits the circle
# ray_origin: Vector2, ray_dir: Vector2 (normalised)
# centre: Vector2, radius: float
static func ray_vs_circle(
    ray_origin: Vector2, ray_dir: Vector2,
    centre: Vector2, radius: float
) -> bool:
    var oc := centre - ray_origin
    var t := oc.dot(ray_dir)
    var d_sq := oc.dot(oc) - t * t
    return d_sq <= radius * radius
```

### Ray vs AABB (ARMS / LEGS detection)

Slab method. Handles D.x = 0 or D.y = 0 by using `INF` constants (no division-by-zero crash).

```gdscript
# Returns true if ray hits the rect within canvas length
# max_len: float — canvas diagonal (~922 px for 800×450)
static func ray_vs_aabb(
    ray_origin: Vector2, ray_dir: Vector2,
    rect: Rect2, max_len: float
) -> bool:
    var inv_dx := INF if ray_dir.x == 0.0 else 1.0 / ray_dir.x
    var inv_dy := INF if ray_dir.y == 0.0 else 1.0 / ray_dir.y

    var tx_min := (rect.position.x - ray_origin.x) * inv_dx
    var tx_max := (rect.end.x      - ray_origin.x) * inv_dx
    var ty_min := (rect.position.y - ray_origin.y) * inv_dy
    var ty_max := (rect.end.y      - ray_origin.y) * inv_dy

    if tx_min > tx_max: var tmp := tx_min; tx_min = tx_max; tx_max = tmp
    if ty_min > ty_max: var tmp := ty_min; ty_min = ty_max; ty_max = tmp

    var t_min := maxf(tx_min, ty_min)
    var t_max := minf(tx_max, ty_max)

    return t_max >= 0.0 and t_min <= t_max and t_min <= max_len
```

### Full detect() Implementation

```gdscript
func detect(
    ray_origin: Vector2,
    ray_dir: Vector2,        # must be normalised
    target_player_id: int
) -> StringName:
    # HEAD
    var head := figure_geometry.get_zone_circle(target_player_id)
    if ray_vs_circle(ray_origin, ray_dir, head.centre, head.radius):
        return &"HEAD"
    # ARMS
    if ray_vs_aabb(ray_origin, ray_dir, figure_geometry.get_zone_rect(target_player_id, &"ARMS"), CANVAS_DIAG):
        return &"ARMS"
    # LEGS
    if ray_vs_aabb(ray_origin, ray_dir, figure_geometry.get_zone_rect(target_player_id, &"LEGS"), CANVAS_DIAG):
        return &"LEGS"
    return &"MISS"
```

`CANVAS_DIAG = sqrt(800² + 450²) ≈ 922 px` — the maximum meaningful ray length.

### What This Policy Explicitly Forbids

- `PhysicsServer2D.space_get_direct_state()` — never called for hit detection
- `RayCast2D` node — not used
- `Area2D` + `CollisionShape2D` — not used for hit zones
- Any physics body node for game-logic collision

## Alternatives Considered

### Alternative A: Area2D + CollisionShape2D (physics-engine hit zones)

- **Description**: Each hit zone is an `Area2D` with a `CollisionShape2D` (circle for head,
  rectangle for arms/legs). Shot detection via `PhysicsServer2D` raycast against these areas.
- **Pros**: Engine handles intersection math; visual debugging in editor; handles complex shapes
- **Cons**: PhysicsServer2D must be running; introduces Jolt/GodotPhysics2D non-determinism;
  unit testing requires a physics server context; `Area2D` overlap queries are not synchronous
  in the same frame for dynamic collision shapes; adds forbidden physics nodes (ADR-0002)
- **Rejection**: Overkill for three simple geometric shapes; adds untestable engine dependency;
  analytic math is faster and more deterministic for stationary axis-aligned hit zones

### Alternative B: PhysicsServer2D.space_get_direct_state() direct raycast

- **Description**: Use the physics server directly (no nodes) via `intersect_ray()` call
- **Pros**: No physics node overhead; engine math handles edge cases
- **Cons**: Requires physics server to be initialised and a Physics2DDirectSpaceState;
  not unit-testable without a running scene; introduces physics timing dependency
- **Rejection**: Analytic math is simpler, faster, and fully unit-testable without engine context

## Consequences

### Positive

- Hit detection is a pure GDScript static function: unit-testable without any engine context
- Zero dependency on physics server state or tick timing
- No non-determinism from physics simulation floating-point accumulation
- Eliminates the Jolt/GodotPhysics2D choice as a concern (both are irrelevant)

### Negative

- Developers must maintain the math functions; no editor visualisation of hit zones
  (only FigureGeometry debug rendering via `_draw()` if needed during development)
- If a new hit zone with complex shape is needed in future, analytic math must be extended

### Risks

- **D.x = 0 / D.y = 0 in AABB test**: handled by `INF` substitution; verified by AC9 in
  FigureGeometry GDD. Must have a unit test for horizontal and vertical shot directions.
- **Shot origin inside a hit zone**: geometrically impossible during normal play (shots originate
  from the firing player's side); handled by priority order HEAD > ARMS > LEGS if it somehow occurs.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-BZHD-001 | Body-Zone Hit Detection | Ray vs circle (HEAD), ray vs rect (ARMS, LEGS) — analytic math only | Defines the exact GDScript static functions implementing each intersection test |
| TR-BZHD-002 | Body-Zone Hit Detection | No PhysicsServer usage; pure geometry | Explicitly bans all physics server calls; forbids physics nodes for hit detection |
| TR-BZHD-003 | Body-Zone Hit Detection | Priority: HEAD > ARMS > LEGS | Implemented as the order of `if` checks in `detect()` |
| TR-FIG-004 | Figure Geometry | Zone accessors are the single source of geometry truth | `detect()` calls `figure_geometry.get_zone_circle()` and `get_zone_rect()` — never computes geometry inline |

## Performance Implications

- **CPU**: Two floating-point intersection tests per shot (one skipped after first hit).
  Cost: negligible — ~10 arithmetic ops per call. Called at most twice per turn.
- **Memory**: No state; pure static math.
- **Frame Budget**: Completes in <0.01 ms; irrelevant to the 16.6 ms frame budget.

## Migration Plan

Greenfield.

## Validation Criteria

- Unit tests covering: ray hits head, ray hits arms, ray hits legs, ray misses all zones,
  horizontal ray (D.y=0), vertical ray (D.x=0), ray aimed at miss area (neck, mid-torso)
- No `PhysicsServer2D`, `RayCast2D`, `Area2D`, or `CollisionShape2D` in the codebase (grep in CI)

## Related Decisions

- ADR-0001: Scene Topology — no physics nodes means the Systems subtree is pure logic nodes
- ADR-0002: Web Export — physics server cannot be disabled but sits idle; this ADR ensures it stays idle
- ADR-0004: System Communication — `detect()` is a synchronous direct call (Pattern A)
