# Story 003: Visual Rendering and Lifecycle

> **Epic**: Trajectory Visualization
> **Status**: Complete
> **Layer**: Core
> **Type**: Visual/Feel
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/trajectory-visualization.md`
**Requirement**: `TR-TVIS-001`, `TR-TVIS-002`, `TR-TVIS-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 (Rendering Primitives), ADR-0001 (Scene Topology)
**ADR Decision Summary**: Line2D nodes; P1 ink is `#1A4FBF` (blue), P2 ink is `#CC2200` (red). Aim line alpha = 0.45 (intent, dimmer). Shot lines full opacity.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Line2D.default_color` and `Line2D.width` are stable pre-cutoff APIs. ADR-0003 specifies `default_color` for player ink assignment.

**Control Manifest Rules (Core layer)**:
- Required: P1 colour = `Color("#1A4FBF")`, P2 colour = `Color("#CC2200")` per art bible
- Required: Aim line `modulate.a = AIM_LINE_ALPHA = 0.45`
- Required: Line2D width per art bible spec

---

## Acceptance Criteria

*From GDD `design/gdd/trajectory-visualization.md`, scoped to this story:*

- [ ] **Aim line visible during drag**: When a drag is in progress, aim line is visible; on release or cancel, aim line is hidden.
- [ ] **P1 lines are blue, P2 lines are red**: Aim and shot lines for P1 use `#1A4FBF`; for P2 use `#CC2200`.
- [ ] **Aim line is dimmer than shot line**: Aim line `modulate.a ≈ 0.45`; shot lines fully opaque (`alpha = 1.0`) while in display phase.
- [ ] **Complete reset**: After `reset()`, scene contains no shot line nodes; aim line is hidden.

---

## Implementation Notes

*Derived from ADR-0003:*

Initialization in `_ready()`:
```gdscript
const P1_COLOR: Color = Color("#1A4FBF")
const P2_COLOR: Color = Color("#CC2200")
const LINE_WIDTH: float = 3.0

func _ready() -> void:
    _aim_line = Line2D.new()
    _aim_line.width = LINE_WIDTH
    _aim_line.hide()
    add_child(_aim_line)
    # Connect InputSystem signals
    _input_system.aim_updated.connect(_on_aim_updated)
    _input_system.aim_cancelled.connect(_on_aim_cancelled)
    _input_system.flick_event_emitted.connect(_on_flick_event_emitted)
```

Player colour is set when the active player is known (e.g. when `open_window` fires):
```gdscript
func set_active_player(player_id: int) -> void:
    _active_color = P1_COLOR if player_id == 0 else P2_COLOR
    _aim_line.default_color = Color(_active_color, AIM_LINE_ALPHA)
```

---

## Out of Scope

*Handled by Stories 001 and 002 — do not implement here:*

- Aim line formula and direction logic (Story 001)
- Shot line endpoint math, Tween fade, MAX_VISIBLE logic (Story 002)

---

## QA Test Cases

*Manual verification — requires visual inspection in Godot editor or browser.*

- **AC-1**: Aim line visibility
  - Setup: Run game; P1's turn; drag P1's figure
  - Verify: Blue aim line appears during drag; disappears on release
  - Pass condition: Aim line visible exactly during drag, gone on release

- **AC-2**: Ink colours
  - Setup: Fire a shot as P1 and as P2
  - Verify: P1 shot line is blue (#1A4FBF); P2 shot line is red (#CC2200)
  - Pass condition: Both lines visually match the art bible colours

- **AC-3**: Opacity difference
  - Setup: During P1 drag
  - Verify: Aim line is noticeably dimmer than the shot line from the previous turn
  - Pass condition: Aim line alpha ≈ 0.45 (confirm in inspector); shot line alpha = 1.0

- **AC-4**: Reset clears all
  - Setup: Fire 3 shots; trigger reset
  - Verify: All shot lines are gone; aim line hidden
  - Pass condition: Scene tree contains no shot line nodes; aim line invisible

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/trajectory-visualization-evidence.md` + sign-off

**Status**: [x] `production/qa/evidence/trajectory-visualization-evidence.md` — pending browser sign-off

---

## Completion Notes
**Completed**: 2026-05-19
**Criteria**: 4/4 ACs implemented; visual verification pending browser run
**Deviations**: None — P1/P2 colors, LINE_WIDTH, AIM_LINE_ALPHA per art bible
**Test Evidence**: `production/qa/evidence/trajectory-visualization-evidence.md`
**Code Review**: Lean mode — no LP gate; constants verified against art bible spec

---

## Dependencies

- Depends on: Stories 001 and 002 must be DONE
- Unlocks: Integration of the complete trajectory system with the turn loop
