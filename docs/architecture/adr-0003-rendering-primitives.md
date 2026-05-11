# ADR-0003: Rendering Primitive Strategy

## Status
Accepted

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Rendering (2D CanvasItem) |
| **Knowledge Risk** | LOW — `Line2D`, `CanvasItem.modulate`, and `Tween` APIs are stable since Godot 4.0; no Line2D-specific changes in 4.4–4.6 |
| **References Consulted** | `docs/engine-reference/godot/modules/rendering.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm `Line2D.antialiased` visual quality is acceptable on Safari iOS before enabling; test Tween + `queue_free` callback with force-clear path |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology), ADR-0002 (Compatibility renderer confirmed) |
| **Enables** | FigureRenderer implementation, TrajectoryVisualization implementation |
| **Blocks** | Any story that renders a figure or trajectory line |
| **Ordering Note** | Renderer choice (ADR-0002) must be Accepted first — this ADR relies on Compatibility/WebGL 2 being confirmed |

## Context

### Problem Statement

Flick Duel's “Notebook Duel” aesthetic requires stick figures and trajectory lines that look
hand-drawn — clean but imperfect, as if sketched in ballpoint pen. We need to decide which Godot
primitives implement this look, and how to manage their lifecycle (figure updates on anchor change,
aim line during drag, persistent shot lines after release).

### Constraints

- Compatibility/WebGL 2 renderer (ADR-0002): no Forward+-exclusive effects
- ≤50 draw calls (performance budget from `technical-preferences.md`)
- No textures or sprites in MVP: the aesthetic is purely geometric
- No AnimationPlayer (no animation in MVP; AnimationPlayer `StringName` API changed in 4.6)
- Hand-jitter must be consistent per figure (not re-randomised each frame)
- Player colours: P1 = blue ink, P2 = red ink (art bible)
- Shot lines must persist briefly after firing, then fade

### Requirements

- Figures must update position instantly when anchor changes (MOVE action)
- Aim line must appear during drag and disappear on release
- Shot lines must persist after firing, fade out over a configurable duration, and be cleared on `reset()`
- Visual state must reflect status effects (crossed arm = Disarmed, crossed legs = Immobilized)

## Decision

**`Line2D` nodes for all figures and trajectory lines. Hand-jitter baked into `points` arrays at
`_ready()`. `Tween` for shot-line fade-out. `default_color` for player ink colours.**

### Figure Rendering

Each stick figure segment is a `Line2D` node. The figure is a small tree of Line2D nodes under
a parent `Node2D` (`FigureRenderer_P1` / `FigureRenderer_P2`):

```
FigureRenderer_P1 (Node2D)
├── Line2D_head       # circle approximation: 8-point polygon
├── Line2D_torso      # single segment
├── Line2D_arm_left   # single segment
├── Line2D_arm_right  # single segment
├── Line2D_leg_left   # single segment
└── Line2D_leg_right  # single segment
```

**Hand-jitter**: small random per-point offsets (±2 px) baked into each Line2D's `points` array
at `_ready()` using a seeded `RandomNumberGenerator` (seeded by player ID for consistency between
sessions). The `points` array is set once and never modified during gameplay (movement is handled
by repositioning the parent `FigureRenderer_P1` node, not by rebuilding point arrays).

**Player colour**: assigned once via `Line2D.default_color`:
```gdscript
const P1_COLOR := Color(0.1, 0.2, 0.8)   # blue ink
const P2_COLOR := Color(0.8, 0.1, 0.1)   # red ink
```
`modulate` is reserved for the alpha-fade of shot lines and must not be used for colour assignment.

**Status effect visuals**:
- Disarmed: a bold X overlay drawn through the arms rect in the opponent's ink colour
- Immobilized: a bold X overlay drawn through the legs rect in the opponent's ink colour

Both status overlays are additional `Line2D` nodes (two diagonal lines forming an X), shown/hidden
by `FigureRenderer` when `StatusEffects` state changes. The X colour is the opponent's ink colour
(P1 immobilized → red X; P2 immobilized → blue X).

**Position update**: When `FigureGeometry.set_anchor()` is called, `FigureRenderer` moves the
parent `FigureRenderer_P1` Node2D's `position` to the new anchor. No point arrays are rebuilt.

**`reset()`**: Restores `FigureRenderer_P1.position` to `ScreenLayout.P1_ANCHOR`, hides all
status-effect overlays, restores `modulate = Color.WHITE` on all Line2D children.

### Trajectory Visualization

**Aim line** — single persistent `Line2D` shown during drag, hidden on release:
```gdscript
# During drag:
aim_line.show()
aim_line.points = PackedVector2Array([origin, current_endpoint])

# On release:
aim_line.hide()
```

**Shot lines** — a `Line2D` is created per shot and added to the scene. After the shot resolves,
a `Tween` fades it out and then frees it:
```gdscript
func commit_shot_line(origin: Vector2, direction: Vector2, color: Color) -> void:
    var line := Line2D.new()
    line.default_color = color
    line.points = PackedVector2Array([origin, origin + direction * CANVAS_DIAGONAL])
    add_child(line)
    _active_shot_lines.append(line)
    _active_tweens.append(null)   # slot reserved; filled below

    var tw := create_tween()
    _active_tweens[-1] = tw
    tw.tween_property(line, "modulate:a", 0.0, SHOT_LINE_FADE_SEC)
    tw.tween_callback(func():
        if is_instance_valid(line):
            _active_shot_lines.erase(line)
            line.queue_free()
    )
```

**freeze()** — called on match end; kills all active Tweens so shot lines hold their current
alpha until `reset()`:
```gdscript
func freeze() -> void:
    for tw in _active_tweens:
        if is_instance_valid(tw):
            tw.kill()
    _active_tweens.clear()

func reset() -> void:
    for line in _active_shot_lines:
        if is_instance_valid(line):
            line.queue_free()
    _active_shot_lines.clear()
    _active_tweens.clear()
    aim_line.hide()
    aim_line.points = PackedVector2Array()
```

### Anti-aliasing

`Line2D.antialiased = true` must be set on all `Line2D` nodes. The Compatibility renderer (WebGL 2)
has no hardware MSAA; software anti-aliasing via `antialiased = true` adds geometry vertices and
is renderer-agnostic. Without it, lines appear jagged on high-DPI and mobile screens.

### Draw Call Count

| Element | Node count | Draw calls |
|---------|-----------|------------|
| P1 figure segments | 6 | 6 |
| P2 figure segments | 6 | 6 |
| P1 status overlays (max 2 × 2 lines) | 4 | 4 |
| P2 status overlays (max 2 × 2 lines) | 4 | 4 |
| Aim line | 1 | 1 |
| Shot lines (max concurrent) | ~4 (typical) | ~4 |
| HUD elements | ~8 | ~8 |
| **Total** | **~33** | **~33** |

Well within the ≤50 draw call budget.

## Alternatives Considered

### Alternative A: `draw_line()` in `_draw()` (Canvas2D custom draw)

- **Description**: Override `_draw()` on a Node2D and call `draw_line()` directly
- **Pros**: Fewer nodes; all figure drawing in one `_draw()` call
- **Cons**: Requires `queue_redraw()` every time the figure moves or changes visual state;
  more complex to manage per-segment visual state (status effects); no persistent shot lines
  (draw calls are per-frame)
- **Rejection**: Line2D nodes are simpler to manage per-segment, support independent visibility and
  modulate control, and don't require a redraw cycle

### Alternative B: `Sprite2D` with a hand-drawn texture atlas

- **Description**: Pre-draw stick figure parts as sprites; compose at runtime
- **Pros**: Maximum visual control; exact “hand-drawn” look from an artist
- **Cons**: Requires texture assets (contradicts “geometric only” MVP scope); no easy runtime
  colour-per-player without shaders; texture loading adds memory and import pipeline
- **Rejection**: Out of scope for MVP; the Notebook Duel aesthetic is achievable with geometry alone

### Alternative C: Grey shading for Immobilized (rejected)

- **Description**: Immobilized figure → `modulate = Color(0.4, 0.4, 0.4)` (grey shading)
- **Pros**: Simple one-line implementation
- **Cons**: Conflicts with Figure Renderer GDD acceptance criteria; grey shading is not the
  specified visual — the GDD requires a bold X through the legs rect in opponent ink colour,
  consistent with the Disarmed X treatment on the arms rect
- **Rejection**: GDD is authoritative; grey shading removed from this ADR

## Consequences

### Positive

- One primitive type (Line2D) for the entire visual layer — consistent API, minimal context switching
- Per-segment visibility and overlay Line2D nodes make status-effect visuals correct and consistent
- Jitter-baked at `_ready()`: zero per-frame cost for the hand-drawn look
- Tween-based fade is idiomatic 4.x GDScript; no Timer nodes needed
- `antialiased = true` ensures clean lines on mobile and high-DPI screens

### Negative

- Head rendered as a Line2D polygon (not a filled circle): slightly different look from the pen-flick
  source material. Acceptable per art direction (“lines, not fills”).
- Shot lines are dynamically created and freed: small allocation overhead per shot.
  At ≤2 shots per turn this is negligible but worth noting.

### Risks

- Tween + `queue_free` callback: if a shot line is force-cleared by `reset()` before the Tween
  completes, the callback's `is_instance_valid(line)` guard prevents a null-access crash.
  This guard is mandatory.
- `freeze()` must call `tween.kill()` on stored Tween references, not `set_meta()`. `set_meta()`
  has no effect on a running Tween — the fade timer continues and will free the Line2D node,
  violating the freeze contract.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-FRD-001 | Figure Renderer | Line2D nodes; hand-jitter baked at spawn | Defines Line2D as the sole primitive; jitter baked into `points` at `_ready()` |
| TR-FRD-002 | Figure Renderer | Disarmed overlay: bold X through arms in opponent colour | X overlay Line2D nodes shown on Disarmed state; colour = opponent ink |
| TR-FRD-003 | Figure Renderer | Immobilized overlay: bold X through legs in opponent colour | X overlay Line2D nodes shown on Immobilized state; colour = opponent ink |
| TR-TVIS-001 | Trajectory Visualization | Live aim line during drag; persistent shot line on release | Aim line: single reused Line2D; shot lines: dynamically created, Tween-faded |
| TR-TVIS-002 | Trajectory Visualization | Shot lines frozen on match end; cleared on `reset()` | `freeze()` calls `tween.kill()` on stored refs; `reset()` calls `queue_free()` |

## Performance Implications

- **CPU**: Tween updates are engine-managed; no per-frame GDScript cost for figure rendering
- **Memory**: ~33 Line2D nodes at peak; each is a lightweight CanvasItem. Total overhead <1 MB.
- **Draw Calls**: ~33 at peak, within 50-call budget
- **Load Time**: No textures to import; near-instant scene init

## Migration Plan

Greenfield. FigureRenderer and TrajectoryVisualization are authored against this spec from day one.

## Validation Criteria

- P1 and P2 figures render in correct ink colours (blue / red) from first frame
- Disarmed: bold X appears through arms rect in opponent colour; no grey shading
- Immobilized: bold X appears through legs rect in opponent colour; no grey shading
- `antialiased = true` set on all Line2D nodes (grep check)
- Aim line appears on drag start, disappears on release — verified via integration test
- Shot lines fade over `SHOT_LINE_FADE_SEC` and are freed — verified by node count check
- `reset()` leaves zero active shot lines — unit test: call `reset()` mid-fade, assert `_active_shot_lines.size() == 0`
- `freeze()` prevents shot line queue_free: call `freeze()`, wait > fade_duration, assert lines still exist
- Draw call count ≤50 measured in Godot debugger during a full match

## Related Decisions

- ADR-0001: Scene Topology — Line2D nodes placed in the `Presentation` subtree of Main.tscn
- ADR-0002: Compatibility renderer confirmed — `Line2D.antialiased = true` required (no hardware MSAA)
- ADR-0004: System Communication — FigureRenderer reacts to TwoActionTurnSystem signals for visual updates
