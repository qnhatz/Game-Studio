# ADR-0010: HUD and Control Focus Architecture

## Status
Proposed

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI (CanvasLayer, Control, dual-focus system) |
| **Knowledge Risk** | MEDIUM — Godot 4.6 dual-focus system (mouse/touch vs keyboard/gamepad) is post-cutoff (4.6) |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md` (4.5→4.6 dual-focus), `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | `get_viewport().gui_release_focus()` — dual-focus system API (4.6) |
| **Verification Required** | Confirm `gui_release_focus()` prevents hidden-node keyboard focus on both Chrome and Safari iOS; test tab-stop behaviour |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology — CanvasLayer placement defined there), ADR-0002 (Compatibility renderer) |
| **Enables** | HUDTurnIndicator implementation, MainMenu implementation, orientation gate implementation |
| **Blocks** | Any story that renders UI or handles input routing between match and menu |
| **Ordering Note** | Must be Accepted before any UI node is implemented |

## Context

### Problem Statement

Flick Duel has two concurrent UI concerns during a match: the game canvas (gesture input for FIRE
and MOVE) and the HUD (action counters, status icons, turn indicator). The game also has three
full-screen states (MainMenu, in-match, MatchResultScreen) that must not interfere with each other's
input. We need to define the CanvasLayer structure, input routing, and how the Godot 4.6 dual-focus
system is managed to prevent hidden-node focus bugs.

### Constraints

- Godot 4.6 dual-focus: mouse/touch focus and keyboard/gamepad focus are tracked independently;
  hiding a Control does not release keyboard focus
- `MOUSE_FILTER_IGNORE` set on a parent Control does NOT propagate to child nodes in Godot 4.5+;
  each Control node in a display-only subtree must have `MOUSE_FILTER_IGNORE` set individually
- No hover states: mobile browser compatibility (touch-only); all interactions are tap/click
- HUD is display-only during a match: no tappable buttons while a turn is in progress
- Gesture regions are defined by `ScreenLayout` (ADR-0001); input ownership is by drag origin,
  not drag endpoint

### Requirements

- HUD renders above the game canvas at all times; never clips or blocks gesture input in the
  gesture regions
- MainMenu buttons have ≥48×48 px tap targets
- Hiding any Control subtree releases keyboard focus first (`gui_release_focus()` per ADR-0001)
- Orientation gate overlay appears above all other UI; suspends all game input

## Decision

**CanvasLayer hierarchy by layer order. HUD on layer 1 (per-node MOUSE_FILTER_IGNORE). Menus on
layer 10. Orientation gate on layer 20. Gesture input via `_input()`. `gui_release_focus()` called
before every `hide()` on any Control subtree.**

### CanvasLayer Structure

```
Main (Node2D)
├── [game canvas nodes — no CanvasLayer; rendered at layer 0]
│
├── HUDTurnIndicator   (CanvasLayer, layer = 1)
│   ├── P1_ActionCounter   (Label, mouse_filter = MOUSE_FILTER_IGNORE)
│   ├── P2_ActionCounter   (Label, mouse_filter = MOUSE_FILTER_IGNORE)
│   ├── P1_StatusIcons     (HBoxContainer, mouse_filter = MOUSE_FILTER_IGNORE)
│   ├── P2_StatusIcons     (HBoxContainer, mouse_filter = MOUSE_FILTER_IGNORE)
│   └── TurnArrow          (Label, mouse_filter = MOUSE_FILTER_IGNORE)
│
├── MainMenu           (CanvasLayer, layer = 10)
│   ├── TitleLabel         (Label)
│   ├── TwoPlayersButton   (Button, min size 220×60)
│   ├── VsComputerButton   (Button, min size 220×60)
│   └── DifficultySelector (HBoxContainer, 3 × Button 80×48)
│
├── MatchResultScreen  (CanvasLayer, layer = 10)
│   ├── ResultLabel        (Label)
│   ├── RematchButton      (Button)
│   └── MenuButton         (Button)
│
└── OrientationGate    (CanvasLayer, layer = 20)
    └── RotatePromptLabel  (Label, mouse_filter = MOUSE_FILTER_IGNORE)
```

**MOUSE_FILTER_IGNORE policy:**
- `MOUSE_FILTER_IGNORE` does NOT cascade to children automatically in Godot 4.5+.
- Every non-interactive Control node in the HUD subtree (Label, TextureRect, HBoxContainer
  used as display containers) must have `mouse_filter = MOUSE_FILTER_IGNORE` set explicitly
  in the Inspector or via `set_default_cursor_shape()` in `_ready()`.
- Interactive nodes (Button in menus) use the default `MOUSE_FILTER_STOP` — they need input.
- Adding a new HUD display node requires explicitly setting `MOUSE_FILTER_IGNORE` on that node.
  This is documented in the Control Manifest as a required step.

**Layer ordering rationale:**
- Layer 0 (game canvas): game geometry — Line2D figures, trajectories
- Layer 1 (HUD): always visible over game canvas; display-only, no input during match
- Layer 10 (menus): full-screen overlays; mutually exclusive with each other
- Layer 20 (orientation gate): always on top; blocks everything

### Gesture Input Routing

Gesture input (drag for FIRE, tap for MOVE) is handled via `InputSystem._input(event)`, **not**
via Control node input. This means:

1. `InputSystem` is a Node (not a Control) — it receives `_input()` events directly
2. The HUD CanvasLayer is display-only; all Control nodes have `mouse_filter = MOUSE_FILTER_IGNORE`
3. Gesture ownership is determined by `ScreenLayout.P1_GESTURE_RECT.has_point(event.position)` —
   a spatial check, not a focus check

```gdscript
# InputSystem._input(event):
func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        _handle_touch_begin(event.position, event.pressed)
    elif event is InputEventScreenDrag or event is InputEventMouseMotion:
        if event.button_mask & MOUSE_BUTTON_MASK_LEFT or event is InputEventScreenDrag:
            _handle_drag(event.position)
```

The HUD never intercepts these events because all its Control nodes use `MOUSE_FILTER_IGNORE`.

### Focus Management and Show/Hide Lifecycle

Per ADR-0001 and the Godot 4.6 dual-focus requirement, the following contract applies to **every**
show/hide operation on a Control or CanvasLayer containing Controls:

```gdscript
# GameStateMachine — before any hide():
func _transition_to(new_state: StringName) -> void:
    get_viewport().gui_release_focus()    # ALWAYS first, before any hide()
    # ... then show/hide CanvasLayers
```

This contract applies to:
- `GameStateMachine._transition_to()` — all state transitions
- Any code that calls `hide()` or sets `visible = false` on a CanvasLayer or Control subtree
- Orientation gate show/hide — also calls `gui_release_focus()` before hiding

Additionally, when the MainMenu or MatchResultScreen becomes visible, the first focusable button
receives programmatic focus via `button.grab_focus()` to support keyboard navigation:

```gdscript
# MainMenu._on_show():
func _on_show() -> void:
    difficulty_selector.hide()
    two_players_button.grab_focus()
```

### Button Tap Targets

All buttons meet the ≥48×48 px accessibility minimum:
- "2 Players" button: 220×60 px (custom_minimum_size)
- "vs Computer" button: 220×60 px
- Difficulty buttons (Easy/Medium/Hard): 80×48 px each
- Rematch / Menu buttons: 160×60 px

### Orientation Gate

`OrientationGate` (CanvasLayer 20) is shown when `viewport.size.x < viewport.size.y`. It:
1. Shows a "Rotate your device" label (centred)
2. Does NOT change GameStateMachine state — the game is paused in-place
3. When landscape is restored, the gate hides and input resumes automatically

Input during portrait orientation: `InputSystem` checks for the orientation gate before processing
any gesture. If active, all gesture input is discarded.

```gdscript
# InputSystem:
@onready var orientation_gate: CanvasLayer = $"../OrientationGate"

func _input(event: InputEvent) -> void:
    if orientation_gate.visible:
        return   # discard all input during portrait mode
    # ... normal processing
```

## Alternatives Considered

### Alternative A: MOUSE_FILTER_IGNORE on parent only (not per-node)

- **Description**: Set `MOUSE_FILTER_IGNORE` only on the HUDTurnIndicator CanvasLayer root and
  assume it cascades to children
- **Pros**: One setting instead of N settings
- **Cons**: `MOUSE_FILTER_IGNORE` does NOT cascade in Godot 4.5+. Child Controls would still
  intercept input events, blocking gestures.
- **Rejection**: Engine behaviour is explicit: per-node setting required. This is an engine
  finding (E2) from the architecture review.

### Alternative B: All input via Control node signals

- **Description**: Gesture regions are Control nodes; FIRE and MOVE actions trigger via
  `Button.pressed` or `TouchScreenButton`
- **Pros**: Godot's built-in focus and input routing handles everything
- **Cons**: `Button` is designed for discrete taps; the drag-and-release gesture requires tracking
  continuous drag state which Control nodes don't support naturally.
- **Rejection**: The core gesture mechanic requires raw `InputEvent` access

### Alternative C: Single CanvasLayer for all UI

- **Description**: All UI elements in one CanvasLayer at a fixed layer value
- **Pros**: Simpler structure
- **Cons**: Cannot independently control z-order between HUD, menus, and orientation gate
- **Rejection**: Separate CanvasLayers per concern is the idiomatic Godot approach

## Consequences

### Positive

- HUD never intercepts gesture input (`MOUSE_FILTER_IGNORE` explicitly on every display node)
- Orientation gate is guaranteed on top by layer ordering; no z-index fighting
- Focus management is centralised in `GameStateMachine._transition_to()`
- `gui_release_focus()` contract prevents dual-focus orphans on all hide() calls

### Negative

- `MOUSE_FILTER_IGNORE` must be set explicitly on every non-interactive HUD node —
  new HUD display nodes require explicit setting; cannot be forgotten
- CanvasLayer layer numbers must be documented (this ADR) to prevent ordering bugs

### Risks

- **Dual-focus orphan** (Godot 4.6): if `gui_release_focus()` is missed on any hide(),
  hidden buttons remain in the keyboard tab order. *Mitigation*: enforced in GameStateMachine;
  `gui_release_focus()` contract is in the Control Manifest as a REQUIRED rule; integration test.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-SCRN-004 | Screen Layout | HUD strip 90 px top band | HUD CanvasLayer layer=1; all Label/icon nodes have MOUSE_FILTER_IGNORE |
| TR-HUD-001 | HUD/Turn Indicator | Turn arrow in active player ink colour | TurnArrow node styled via code; colour set from P1_COLOR/P2_COLOR constants |
| TR-HUD-002 | HUD/Turn Indicator | CanvasLayer layer=1 for HUD | HUDTurnIndicator CanvasLayer layer = 1 |
| TR-HUD-003 | HUD/Turn Indicator | MOUSE_FILTER_IGNORE on HUD subtree | Per-node MOUSE_FILTER_IGNORE on every HUD Control; explicit, not cascaded |
| TR-HUD-004 | HUD/Turn Indicator | HUD input does not interfere with gesture area | gui_release_focus() contract in show/hide lifecycle; MOUSE_FILTER_IGNORE per-node |
| TR-MNU-001 | Main Menu | show/hide Control subtree on state transitions | gui_release_focus() called before every hide(); grab_focus() on show() |
| TR-MNU-002 | Main Menu | Difficulty selector subtree visibility | DifficultySelector hidden by default; shown/hidden explicitly in MainMenu._on_show() |

## Performance Implications

- **CPU**: `_input()` is called per event, not per frame. For a turn-based game with infrequent
  input, negligible cost.
- **Memory**: CanvasLayer nodes are lightweight Control containers. ~5 nodes per layer.

## Migration Plan

Greenfield.

## Validation Criteria

- HUD visible during match; gesture input still works in gesture regions (integration test)
- Tapping the HUD strip area (y<90) does not trigger a FIRE or MOVE action
- Orientation gate appears on portrait rotation; all input is discarded while visible
- Landscape restoration hides gate and input resumes
- No keyboard focus on hidden nodes after state transitions (test with Tab key on Chrome)
- MOUSE_FILTER_IGNORE confirmed on all HUD Label/TextureRect/HBoxContainer nodes (Inspector check + grep)
- gui_release_focus() called before every hide() on Control subtrees (grep: no hide() without preceding gui_release_focus())

## Related Decisions

- ADR-0001: Scene Topology — CanvasLayer placement in Main.tscn; `gui_release_focus()` pattern
- ADR-0007: Input System — gesture handling via `_input()` (pending; defines the raw event handling)
