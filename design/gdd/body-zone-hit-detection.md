# Body-Zone Hit Detection

> **Status**: Designed
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Skill Earns the Win / Clear Consequences

## Overview

Body-Zone Hit Detection takes a resolved shot ray (origin + direction from Shot Spread Calculation) and tests it against the target player's three hit zones (from Figure Geometry) to determine the outcome: `HEAD`, `ARMS`, `LEGS`, or `MISS`. It runs exactly once per FIRE action, after Shot Spread Calculation produces the resolved direction and before the Turn System checks the Win Condition. On a zone hit, it calls the appropriate Status Effects writer (`set_disarmed` or `set_immobilized`) or signals the Win Condition system (`HEAD`). On a miss it does nothing. This system is pure logic — it reads geometry, runs ray tests, and writes effects; it has no visual output and no state of its own.

## Player Fantasy

The shot leaves your hand and the notebook decides. A clean line through the head — instant win. A line through the arms — their drawing hand is crossed out, next turn they can't fire. A line through the legs — they're pinned, next turn they can only fire from where they stand. A line through empty space — the tension held one more turn. The detection is invisible but the result is written in ink. Every player on both sides of the screen reads the outcome at the same moment.

## Detailed Rules

**Shot Ray**
The ray originates from the firing player's figure anchor (`figure_anchor`) and travels in the `resolved_direction` (unit Vector2 from Shot Spread Calculation). The ray has no maximum length — it extends to the canvas edge.

**Test Order**
Zones are tested in priority order: `HEAD` first, then `ARMS`, then `LEGS`. The first zone hit is the result. Testing stops on the first hit — no multi-zone resolution needed given non-overlapping geometry.

**Outcome Table**

| Result | Condition | Effect |
|--------|-----------|--------|
| `HEAD` | Ray intersects head circle | Signal Win Condition: target player loses |
| `ARMS` | Ray intersects arms rectangle | Call `set_disarmed(target_player_id)` on Status Effects |
| `LEGS` | Ray intersects legs rectangle | Call `set_immobilized(target_player_id)` on Status Effects |
| `MISS` | Ray intersects none of the above | No effect |

**Target**
The target is always the opponent of the firing player. This system does not test the firing player's own zones.

**Invocation**
Called by the Turn System after a FIRE action's FlickEvent is resolved, before Win Condition is checked.

## Formulas

All ray intersection formulas are inherited directly from Figure Geometry. Reproduced here for completeness.

**F1 — Ray vs Head Circle (from Figure Geometry F2)**
```
OC = head_centre − ray_origin
t  = dot(OC, ray_direction)
d² = dot(OC, OC) − t²
head_hit = (d² ≤ HEAD_RADIUS²)
```

**F2 — Ray vs Rectangle (from Figure Geometry F3, used for Arms and Legs)**
```
t_min_x = (rect.x          − O.x) / D.x
t_max_x = (rect.x + rect.w − O.x) / D.x
t_min_y = (rect.y          − O.y) / D.y
t_max_y = (rect.y + rect.h − O.y) / D.y
t_min = max(min(t_min_x, t_max_x), min(t_min_y, t_max_y))
t_max = min(max(t_min_x, t_max_x), max(t_min_y, t_max_y))
rect_hit = (t_min ≤ t_max) AND (t_max ≥ 0)
```
- Substitute ±INF for zero-component D terms

**F3 — Resolution**
```
detect(ray_origin, ray_direction, target_player_id):
    anchor = get_anchor(target_player_id)
    if ray_vs_circle(ray_origin, ray_direction, anchor + (0,−162), 18):
        return HEAD
    if ray_vs_rect(ray_origin, ray_direction, arms_rect(anchor)):
        return ARMS
    if ray_vs_rect(ray_origin, ray_direction, legs_rect(anchor)):
        return LEGS
    return MISS
```

## Edge Cases

**EC1 — Ray passes through both ARMS and LEGS zones**
Geometrically impossible — zones are non-overlapping and the ray is a straight line. Priority order (HEAD > ARMS > LEGS) handles any future geometry change defensively.

**EC2 — Target player is already Disarmed; shot hits ARMS again**
`set_disarmed` is called again. Status Effects resets the disarm counter to 2 (restarts duration). Handled entirely by Status Effects — this system does not check current status before writing.

**EC3 — Target player is already Immobilized; shot hits LEGS again**
Same as EC2 — `set_immobilized` resets the counter. No special handling here.

**EC4 — Shot originates from the same side as the target (figures have crossed positions)**
Ray origin and target anchor are wherever the game state says they are. Hit detection is purely geometric — it does not validate player positions or ownership. The Turn System ensures the correct target player ID is passed.

**EC5 — HEAD hit when target is already Disarmed or Immobilized**
HEAD result is returned immediately. Win Condition fires. Status effects on the target are irrelevant — headshot always wins regardless of current status.

## Dependencies

| Direction | System | Nature |
|-----------|--------|--------|
| Depends on | Figure Geometry | Reads zone boundaries (head circle, arms rect, legs rect) per target player anchor |
| Depends on | Shot Spread Calculation | Receives resolved ray direction as input |
| Depends on | Screen Layout | Reads firing player's anchor as ray origin |
| Writes to | Status Effects | Calls `set_disarmed` or `set_immobilized` on zone hit |
| Signals | Win Condition | Returns `HEAD` result; Win Condition system acts on it |
| Called by | Two-Action Turn System | Invoked after each FIRE action resolves |

## Tuning Knobs

This system has no tuning knobs of its own. All zone dimensions are owned by Figure Geometry (`HEAD_RADIUS`, `ARMS_WIDTH`, `ARMS_HEIGHT`, `LEGS_WIDTH`, `LEGS_HEIGHT`). Tuning hit difficulty means tuning Figure Geometry constants, not this system.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| AC1 | Ray aimed at head centre returns `HEAD` | Unit test: ray toward anchor+(0,−162) → assert result == HEAD |
| AC2 | Ray aimed at arms centre returns `ARMS` | Unit test: ray toward arms rect centre → assert result == ARMS |
| AC3 | Ray aimed at legs centre returns `LEGS` | Unit test: ray toward legs rect centre → assert result == LEGS |
| AC4 | Ray aimed at neck gap (anchor+(0,−135)) returns `MISS` | Unit test: assert result == MISS |
| AC5 | Ray aimed at mid-torso gap (anchor+(0,−81)) returns `MISS` | Unit test: assert result == MISS |
| AC6 | Ray aimed past figure entirely returns `MISS` | Unit test: ray pointing away from target → assert result == MISS |
| AC7 | `HEAD` result does not call Status Effects | Unit test: assert `set_disarmed` and `set_immobilized` not called on HEAD hit |
| AC8 | `ARMS` result calls `set_disarmed(target_id)` exactly once | Unit test: assert `set_disarmed` called once with correct player ID |
| AC9 | `LEGS` result calls `set_immobilized(target_id)` exactly once | Unit test: assert `set_immobilized` called once with correct player ID |
| AC10 | `MISS` result calls neither Status Effects writer | Unit test: assert no Status Effects calls on MISS |
| AC11 | Horizontal ray (D.y=0) does not crash | Unit test: fire horizontal ray → no exception, returns valid result |
