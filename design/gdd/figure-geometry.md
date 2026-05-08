# Figure Geometry

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Skill Earns the Win / Read Your Opponent

## Overview

Figure Geometry defines the stick figure as a spatial object: its proportions, the positions of all drawn elements relative to the figure anchor, and the boundaries of its three hit zones. It is the single source of truth for where the figure occupies screen space. Hit Detection, the Figure Renderer, and AI Targeting all derive their spatial understanding of each figure from this system — none define their own geometry. Each figure has three non-overlapping hit zones: a **head** (circle), **arms** (wide rectangle), and **legs** (narrow rectangle). Regions between zones — the neck and mid-torso — are valid miss areas. Figure Geometry is pure data; it holds no state beyond the constants that describe the figure's shape.

## Player Fantasy

The stick figure is a target, and reading it is the skill. The head is small and high — a kill shot, but a demanding one. The arms are the widest zone, the safe reliable pick. The legs sit low. Every turn the active player scans the opponent's figure and decides: play it safe, or go for the head? The geometry makes the trade-off legible without any UI annotation — the zones are visible in the figure's proportions.

## Detailed Rules

**Figure Anchor**
All figure geometry is expressed relative to the figure's anchor point (foot/root position). In screen space: P1 anchor = Vector2(200, 338), P2 anchor = Vector2(600, 338), sourced from Screen Layout. Y increases downward.

**Figure Proportions**
Total figure height: 180 px. All dimensions below are anchor-relative (offset from anchor).

**Hit Zones**

| Zone | Shape | Anchor-relative centre | Dimensions | Effect on hit |
|------|-------|----------------------|------------|---------------|
| Head | Circle | (0, −162) | radius 18 px | Instant win |
| Arms | Rectangle | (0, −108) | 80 × 36 px | Disarmed |
| Legs | Rectangle | (0, −36) | 36 × 72 px | Immobilized |

**Miss Areas**
Shots that strike outside all three zones are misses — no status effect is applied and no win condition is triggered. Two explicit miss corridors exist within the figure silhouette:
- Neck: y offset −144 to −126 (18 px)
- Mid-torso: y offset −90 to −72 (18 px)

**Zone Non-Overlap**
Hit zones do not overlap. If a shot line intersects multiple zones (geometrically impossible with non-overlapping layout, but guarded against), the highest-priority zone wins: Head > Arms > Legs.

**Orientation**
Both figures use identical geometry. P2's figure is a horizontal mirror of P1's for visual rendering only — the hit zone boundaries are symmetric and use the same anchor-relative offsets.

## Formulas

**F1 — Zone Boundaries in Screen Space**
```
head_centre   = anchor + Vector2(0, −162)
head_radius   = 18

arms_rect     = Rect2(anchor.x − 40, anchor.y − 126, 80, 36)
legs_rect     = Rect2(anchor.x − 18, anchor.y − 72,  36, 72)
```

**Zone Accessor Methods**

These are the canonical accessors. All callers (Body-Zone Hit Detection, AI Targeting, Figure Renderer) must use these instead of computing geometry inline.

```
get_zone_circle(player_id) → {centre: Vector2, radius: float}:
    anchor = get_anchor(player_id)
    return {centre: anchor + Vector2(0, −162), radius: HEAD_RADIUS}

get_zone_rect(player_id, zone) → Rect2:
    anchor = get_anchor(player_id)
    if zone == ARMS:
        return Rect2(anchor.x − 40, anchor.y − 126, ARMS_WIDTH, ARMS_HEIGHT)
    if zone == LEGS:
        return Rect2(anchor.x − 18, anchor.y − 72,  LEGS_WIDTH, LEGS_HEIGHT)

get_zone_centre(player_id, zone) → Vector2:
    if zone == HEAD:
        return get_zone_circle(player_id).centre
    return get_zone_rect(player_id, zone).get_center()
```

**F2 — Ray vs Circle (Head)**
```
# Ray: origin point O, unit direction D
# Circle: centre C, radius r
OC = C − O
t  = dot(OC, D)
d² = dot(OC, OC) − t²
hit = (d² ≤ r²)
```
- `t` = projection of OC onto ray; `d²` = squared perpendicular distance
- Returns true if the closest point on the ray to C is within radius

**F3 — Ray vs Rectangle (Arms / Legs)**
```
# Ray: origin O, unit direction D, max_length L (canvas diagonal ≈ 922 px)
# Rect: position (rx, ry), size (rw, rh)
t_min = max((rx      − O.x) / D.x,  (ry      − O.y) / D.y)
t_max = min((rx + rw − O.x) / D.x,  (ry + rh − O.y) / D.y)
hit = (t_min ≤ t_max) AND (t_max ≥ 0) AND (t_min ≤ L)
```
- Standard slab method for AABB ray intersection
- Handle D.x = 0 or D.y = 0 by substituting ±∞ for the corresponding t terms

## Edge Cases

**EC1 — Ray direction is axis-aligned (D.x = 0 or D.y = 0)**
In F3, a zero component produces division by zero. Substitute +∞ when `D.x = 0` and the ray travels parallel to the rectangle's X slabs (no intersection on that axis), or −∞ / +∞ as appropriate per standard slab convention. Godot's `INF` constant handles this directly.

**EC2 — Shot origin is inside a hit zone**
Geometrically impossible during normal play — shots originate from the firing player's figure and travel toward the opponent. If it occurs (e.g. figures overlapping during a move action), treat as a hit on the innermost zone using the priority order Head > Arms > Legs.

**EC3 — Figure anchor is at the zone boundary of the canvas**
At anchor y=338, the head top sits at y=158. The HUD strip ends at y=90. Minimum clearance is 68 px — no zone clips the HUD. If `ANCHOR_Y` is tuned, verify `ANCHOR_Y − FIGURE_HEIGHT ≥ HUD_H + margin` (see Tuning Knobs).

**EC4 — P2 figure mirroring affects rendering but not hit zones**
P2's figure is visually mirrored (arm drawn on the left instead of right), but hit zone rectangles use identical anchor-relative offsets for both players. The renderer mirrors the sprite; the hit zone data does not change.

**EC5 — Immobilized figure: legs zone still exists**
A figure with the Immobilized status effect cannot move, but its legs zone remains a valid hit target. Hitting an already-immobilized figure's legs is a valid shot that produces no additional effect (already handled by Status Effects GDD).

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Screen Layout | Reads `P1_ANCHOR`, `P2_ANCHOR` — all zone positions are computed from these |
| Consumed by | Body-Zone Hit Detection | Uses F1–F3 to test shot rays against zone boundaries |
| Consumed by | Figure Renderer | Uses F1 zone positions to draw the stick figure and visual hit zone overlays |
| Consumed by | AI Targeting | Uses head/arms/legs screen-space positions to select aim targets |

This system has no other upstream dependencies. It defines constants derived from Screen Layout anchors — it does not read from any runtime game state.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `FIGURE_HEIGHT` | 180 px | 140–220 px | Overall figure scale. Lower = harder to hit all zones; higher = zones feel generous. Must keep head top ≥ 68 px below HUD strip. |
| `HEAD_RADIUS` | 18 px | 12–26 px | Head zone difficulty. Lower = kill shot is extremely demanding; higher = head is too easy a target. |
| `ARMS_WIDTH` | 80 px | 60–100 px | Arms zone width. Primary "safe" target — wider makes disarm more reliable. |
| `ARMS_HEIGHT` | 36 px | 24–48 px | Arms zone height. Affects how tight vertical aim must be for an arm hit. |
| `LEGS_WIDTH` | 36 px | 24–50 px | Legs zone width. Narrower than arms to make immobilize slightly harder than disarm. |
| `LEGS_HEIGHT` | 72 px | 50–90 px | Legs zone height. Tall zone compensates for legs sitting low — easier to graze. |

**Constraint**: `HEAD_OFFSET_Y + HEAD_RADIUS + NECK_GAP + ARMS_HEIGHT + TORSO_GAP + LEGS_HEIGHT = FIGURE_HEIGHT`. If any dimension is tuned, verify the sum still equals `FIGURE_HEIGHT` or adjust gaps proportionally.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | Head centre in screen space = anchor + (0, −162) | Unit test: call `get_head_centre(anchor)` → assert result == anchor + Vector2(0, -162) |
| AC2 | Arms rect in screen space = Rect2(anchor.x−40, anchor.y−126, 80, 36) | Unit test: call `get_arms_rect(anchor)` → assert expected Rect2 |
| AC3 | Legs rect in screen space = Rect2(anchor.x−18, anchor.y−72, 36, 72) | Unit test: call `get_legs_rect(anchor)` → assert expected Rect2 |
| AC4 | Ray aimed directly at head centre returns Head hit | Unit test: ray from (0, 338) toward head_centre → assert zone == HEAD |
| AC5 | Ray aimed at neck offset (0, −135) returns miss | Unit test: ray from (0, 338) toward anchor+(0,−135) → assert no hit |
| AC6 | Ray aimed at arms centre returns Arms hit | Unit test: ray toward arms rect centre → assert zone == ARMS |
| AC7 | Ray aimed at mid-torso offset (0, −81) returns miss | Unit test: ray toward anchor+(0,−81) → assert no hit |
| AC8 | Ray aimed at legs centre returns Legs hit | Unit test: ray toward legs rect centre → assert zone == LEGS |
| AC9 | Horizontal ray (D.y = 0) does not crash on arms/legs rect test | Unit test: call F3 with D=Vector2(1,0) → assert no division-by-zero error |
| AC10 | Head top (anchor.y − 180) is at least 68 px below HUD strip bottom (y=90) | Unit test: assert (338 − 180) = 158 ≥ (90 + 68) = 158 — passes exactly |
| AC11 | Hit zones do not overlap | Unit test: assert head circle and arms rect have zero intersection; arms rect and legs rect have zero intersection |
