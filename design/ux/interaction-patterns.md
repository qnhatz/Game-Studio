# Interaction Pattern Library — Flick Duel

> **Last Updated**: 2026-05-11
> **Platform**: Browser (desktop + mobile touch)
> **Accessibility Tier**: Standard (`design/accessibility-requirements.md`)

This library documents every reusable interaction pattern in Flick Duel.
New screens must source patterns from here before inventing new behaviour.

---

## Pattern: Tap Button

**Used in**: MainMenu, MatchResultScreen, DifficultySelector

### Behaviour
- Tap / click anywhere within the button bounds → action fires
- No hover state (mobile browser; touch-only primary interaction)
- Visual feedback: brief opacity pulse (0.8 → 1.0, 80ms) on `_pressed`
- No double-tap required

### Accessibility
- Minimum tap target: 220×60 px for primary actions; 80×48 px for secondary
- Keyboard: Tab to focus, Enter / Space to activate (`grab_focus()` on screen show)
- Focus ring: 2px outline in button's ink colour at 100% opacity

### Implementation
```gdscript
# Button pressed signal (Pattern B — typed signal)
button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
    var tween := create_tween()
    tween.tween_property(button, "modulate:a", 0.8, 0.04)
    tween.tween_property(button, "modulate:a", 1.0, 0.04)
    # then emit mode/action signal
```

### Reference
- ADR-0010: button tap targets, focus management

---

## Pattern: Flick Gesture (Drag-and-Release)

**Used in**: In-match gesture zone

### Behaviour
1. Pointer-down within 48 px of figure anchor → enter DRAGGING state, open aim line
2. Pointer-move → aim line updates continuously (TrajectoryVisualization)
3. Pointer-up with power ≥ 0.05 → FlickEvent emitted, shot fires
4. Pointer-up with power < 0.05 → cancel silently, aim line hides

### Direction convention (slingshot)
`direction = normalize(figure_centre − drag_endpoint)`
The line is drawn from anchor outward opposite the drag; release sends the
figure "flinging" in that direction.

### Cancel
Any release with power < MIN_POWER (0.05) is a silent cancel. No action consumed.

### Multi-touch
First active touch ID owns the gesture. Subsequent touches ignored until release.

### Accessibility
Not remappable (position-intrinsic mechanic). Ensure gesture zone is large enough
for imprecise touches (radius ≥ 48 px dead-zone around anchor by definition).

### Reference
- ADR-0007: InputSystem state machine, pointer handlers
- ADR-0008: FlickEvent contract

---

## Pattern: Tap to Move

**Used in**: In-match — MOVE action during player turn

### Behaviour
- Tap anywhere in the player's gesture zone → MOVE destination
- Distinct from flick: tap is a discrete touch with no significant drag
- Discrimination: if `power < MIN_POWER` on pointer-up, treat as tap (MOVE);
  otherwise treat as flick attempt
- Input window controlled by TwoActionTurnSystem (same as flick)

### Reference
- ADR-0007: gesture discrimination; ADR-0004: Pattern A direct call to Movement.execute_move()

---

## Pattern: Show / Hide Screen

**Used in**: All state transitions (MainMenu ↔ in-match ↔ MatchResultScreen)

### Behaviour
1. `get_viewport().gui_release_focus()` — always first, before any hide()
2. Hide outgoing CanvasLayer
3. Show incoming CanvasLayer
4. `first_button.grab_focus()` on the incoming screen (keyboard accessibility)

### No transition animation (MVP)
Instant show/hide in MVP. Fade transitions may be added in Polish if desired.

### Reference
- ADR-0010: focus management contract, gui_release_focus() requirement
- ADR-0001: GameStateMachine._transition_to() owns this sequence

---

## Pattern: Orientation Gate Overlay

**Used in**: Portrait-orientation detection

### Behaviour
- Appears above all UI (CanvasLayer 20) when viewport.x < viewport.y
- Shows a single centered label: "Rotate your device"
- Blocks all gesture and button input while visible
- Hides automatically when landscape restored
- Does not change game state — game is paused in-place

### Reference
- ADR-0010: OrientationGate, layer ordering

---

## Patterns Not Used

| Pattern | Why excluded |
|---------|-------------|
| Hover states | Mobile browser has no hover; tap-only for consistency |
| Drag-to-scroll | No scrollable content in MVP |
| Long-press | No long-press actions defined in GDD |
| Pinch-to-zoom | Canvas is fixed 800×450 px; no zoom |
| Swipe navigation | No swipeable panels; screen changes via buttons only |
