# QA Evidence: Trajectory Visualization — Visual Rendering

> **Story**: `production/epics/trajectory-visualization/story-003-visual-rendering.md`
> **Story Type**: Visual/Feel
> **Evidence Required**: Manual walkthrough + sign-off

---

## Implementation Status

The following constants and wiring have been implemented in
`src/systems/trajectory_visualization.gd`:

| Constant | Value | AC |
|----------|-------|----|
| `P1_COLOR` | `Color("#1A4FBF")` — blue | AC-2 |
| `P2_COLOR` | `Color("#CC2200")` — red | AC-2 |
| `LINE_WIDTH` | `3.0` px | AC-2 |
| `AIM_LINE_ALPHA` | `0.45` | AC-3 |

`_aim_line.modulate.a = AIM_LINE_ALPHA` is set in `_ready()`.
`_aim_line.default_color` is set to the player colour in `set_active_player(player_id)`.
Shot lines use `_active_color` (full opacity) via `_draw_shot_line`.
`_input_system` signals are connected in `_ready()` if the reference is injected.

---

## Manual Verification Checklist

The following checks require a browser run (Web export, or Godot editor play in browser mode):

### AC-1: Aim line visible during drag

- [ ] Setup: Run game in browser; P1's turn; drag P1's figure anchor
- [ ] Verify: Blue aim line appears during drag
- [ ] Verify: Aim line disappears on release (flick committed)
- [ ] Verify: Aim line disappears on cancel (drag below threshold)
- [ ] Pass condition: Line visible exactly during drag, gone otherwise

### AC-2: Ink colours

- [ ] Setup: Fire a shot as P1; fire a shot as P2
- [ ] Verify: P1 shot line colour matches `#1A4FBF` (blue) — inspect via Godot debugger or visual comparison
- [ ] Verify: P2 shot line colour matches `#CC2200` (red)
- [ ] Pass condition: Both lines visually match the art bible colours

### AC-3: Opacity difference (aim line dimmer)

- [ ] Setup: During P1 drag, with a P1 shot line visible from the previous turn
- [ ] Verify: Aim line is visibly dimmer than the shot line
- [ ] Verify: In Godot inspector, `_aim_line.modulate.a ≈ 0.45`; shot line `modulate.a = 1.0`
- [ ] Pass condition: Perceptible opacity difference between aim and shot lines

### AC-4: Complete reset clears all

- [ ] Setup: Fire 3 shots; trigger match reset sequence
- [ ] Verify: All shot line nodes removed from scene tree
- [ ] Verify: Aim line hidden after reset
- [ ] Pass condition: No trajectory nodes remain visible; scene tree clean

---

## Sign-Off

**Verified by**: _pending browser run_
**Date**: _pending_
**Build**: _pending_
**Notes**: Implementation code review complete (lean mode). Visual verification requires
browser device test — schedule before sprint close-out.
