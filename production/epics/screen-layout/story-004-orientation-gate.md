# Story 004: Orientation Gate — Portrait Block and Resume

> **Epic**: Screen Layout
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/screen-layout.md`
**Requirement**: `TR-SCRN-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (HUD and Control Focus Architecture) + ADR-0007 (Input System Architecture)
**ADR Decision Summary**: `OrientationGate` is a CanvasLayer at layer 20 (always on top). It shows a "Rotate your device" prompt when `viewport.size.x < viewport.size.y`. InputSystem checks `orientation_gate.visible` at the top of `_input()` and discards all events while it is active. The gate does not change `GameStateMachine` state — the game pauses in-place.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `get_viewport().size` updates dynamically on window resize. `Viewport.size_changed` signal (stable since 4.0) is the correct hook for resize detection. Portrait detection should connect to this signal, not poll in `_process()`.

**Control Manifest Rules (Foundation + Presentation layer)**:
- Required: CanvasLayer layer 20 for OrientationGate — always on top of everything.
- Required: `gui_release_focus()` before any `hide()` on a CanvasLayer or Control subtree.
- Required: OrientationGate check at the top of `InputSystem._input()` — discard all input when `orientation_gate.visible == true`.
- Forbidden: No polling in `_process()` — use `Viewport.size_changed` signal.
- Forbidden: OrientationGate must not call `GameStateMachine` state transitions — game pauses in-place.
- Forbidden: Never use hover-only interactions — all interactions must be tap/click.

---

## Acceptance Criteria

*From GDD `design/gdd/screen-layout.md`:*

- [ ] When `V_w < V_h` (portrait), all game input is suspended and an orientation prompt is visible; no touch event produces a shot or game action
- [ ] When `V_w = V_h` exactly (square viewport), `portrait_blocked` is `false` and input is not suspended
- [ ] When the viewport transitions to portrait mid-drag (P1 has a drag in progress), the in-flight drag is cancelled, the orientation prompt appears, and no shot is registered from the dropped gesture
- [ ] When the viewport returns to landscape (`V_w ≥ V_h`), the prompt is dismissed, input resumes, and no layout constants have changed

---

## Implementation Notes

*Derived from ADR-0010 and ADR-0007 Implementation Guidelines:*

**OrientationGate node** (`res://ui/orientation_gate.gd`, CanvasLayer layer=20):

```gdscript
func _ready() -> void:
    get_viewport().size_changed.connect(_on_size_changed)
    _on_size_changed()   # evaluate on startup

func _on_size_changed() -> void:
    var vp := get_viewport().size
    var portrait := vp.x < vp.y
    if portrait and not visible:
        get_viewport().gui_release_focus()
        show()
    elif not portrait and visible:
        get_viewport().gui_release_focus()
        hide()
```

Square viewport (`V_w == V_h`): condition `vp.x < vp.y` is false → gate stays hidden → input not suspended.

**InputSystem integration** (top of `_input()`, before all other checks):

```gdscript
@onready var _orientation_gate: CanvasLayer = $"../OrientationGate"

func _input(event: InputEvent) -> void:
    if _orientation_gate.visible:
        return   # discard all input during portrait mode
    if not _window_open:
        return
    # ... normal processing
```

**Mid-drag portrait transition**: when `_on_size_changed()` fires during a drag, `InputSystem._window_open` is reset by `close_window()` (called from `OrientationGate` via a signal, or by polling `orientation_gate.visible` at the guard). The simpler approach: `InputSystem` connects to `orientation_gate.visibility_changed` and calls `close_window()` when it becomes visible — this cancels the in-flight drag and emits `aim_cancelled`.

```gdscript
# InputSystem._ready():
_orientation_gate.visibility_changed.connect(_on_orientation_changed)

func _on_orientation_changed() -> void:
    if _orientation_gate.visible and _dragging:
        _dragging = false
        _window_open = false
        aim_cancelled.emit()
```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Zone membership dead-zone filtering — a separate discard condition
- Story 005: Multi-touch isolation — handled by touch ID ownership

---

## QA Test Cases

*Written by qa-lead at story creation. Evidence required — cannot run headlessly.*

- **AC-1**: Portrait blocks input
  - Setup: Export to browser or run Godot with a portrait-shaped window; open InputSystem window for P1
  - Verify: Orientation prompt label is visible; tapping the gesture area produces no shot; P1 action count unchanged
  - Pass condition: Zero FlickEvents emitted while portrait prompt is visible

- **AC-2**: Square viewport does not block
  - Setup: Resize window to exactly square (e.g. 450×450)
  - Verify: Orientation prompt is hidden; gesture input works normally
  - Pass condition: Drag from P1 figure → FlickEvent emitted; prompt not visible

- **AC-3**: Mid-drag portrait transition
  - Setup: Begin a P1 drag; before releasing, resize window to portrait
  - Verify: Drag is cancelled (aim line disappears); portrait prompt appears; no shot is registered
  - Pass condition: action count unchanged; `aim_cancelled` signal observed; no FlickEvent

- **AC-4**: Landscape restore resumes input
  - Setup: Portrait gate active; resize window back to landscape
  - Verify: Prompt disappears; gestures work again; ScreenLayout constants unchanged
  - Pass condition: Drag produces FlickEvent again after restore; CANVAS_W still reads 800

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/orientation-gate-evidence.md` + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 must be DONE (orientation check layers on top of zone filtering); ADR-0010 (HUD/UI epic) CanvasLayer structure must exist
- Unlocks: Story 005 (multi-touch isolation; both require a running InputSystem)
