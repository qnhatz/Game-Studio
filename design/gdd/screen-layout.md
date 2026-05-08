# Screen Layout

> **Status**: Designed (pending review)
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-06
> **Implements Pillar**: Local First / Read the Body

## Overview

Screen Layout is the spatial foundation of Flick Duel. It defines a fixed logical canvas, the two player zones (P1 left, P2 right), figure anchor positions, gesture input regions, and the neutral center corridor through which shots travel. Every system that places an element on screen — figures, trajectory lines, hit effects, HUD indicators — derives its coordinates from this single source of truth. The system itself is a set of named constants; there is no runtime logic. It is designed once, stabilised before any other system is built, and never modified without auditing all downstream dependents.

## Player Fantasy

Before the first turn, the shared screen has already told both players everything they need to know. Two figures face each other across a ruled page — one left, one right, a corridor of blank space between them. It reads as a confrontation without a word of instruction.

The layout creates territorial ownership. P1's side feels like *your* side: your figure, your half of the page, the direction your shots naturally travel. Firing a shot means projecting force across the border into hostile space. That crossing is legible — you can see it happen.

The mirror symmetry is also a silent promise: equal real estate, identical anchors, no home-side advantage. This is the infrastructure of fairness. When a player loses, they lost to their opponent's aim and positioning — not to an asymmetric starting condition. The page settles that before anyone flicks.

## Detailed Design

### Core Rules

1. The logical game canvas is **800 × 450 px** (16:9 landscape). All spatial values in all systems are expressed in these logical pixels. The renderer scales this canvas to fit the actual browser viewport using Keep Aspect (letterbox) mode — black bars may appear but coordinates never remap.

2. The canvas is divided into three fixed horizontal zones:

   | Zone | X range | Width | Description |
   |------|---------|-------|-------------|
   | P1 Player Zone | 0–320 px | 320 px (40%) | P1's territory: figure, gesture input, HUD |
   | Neutral Corridor | 320–480 px | 160 px (20%) | Airspace for shots in flight; no gameplay input valid here |
   | P2 Player Zone | 480–800 px | 320 px (40%) | P2's territory: figure, gesture input, HUD |

3. Each figure has a single **anchor point** (the foot/root position) from which all figure geometry is drawn upward:

   | Figure | Anchor X | Anchor Y | Notes |
   |--------|----------|----------|-------|
   | P1 | 200 px | 338 px | Centre of P1 zone, lower quarter of canvas |
   | P2 | 600 px | 338 px | Centre of P2 zone, lower quarter of canvas |

4. The **HUD strip** occupies the top 20% of the canvas (y: 0–90 px). It is divided:
   - P1 HUD cell: x 0–320, y 0–90 (action counter, status icons)
   - Turn indicator: x 280–520, y 0–90 (centre, slightly overlapping both HUD cells)
   - P2 HUD cell: x 480–800, y 0–90 (action counter, status icons)
   - Status effect icons (disarmed / immobilized) sit above each figure anchor at y ≈ figure_anchor.y − figure_height − 12 px, tied to the figure, not the HUD strip.

5. The **gesture input region** for each player is that player's zone excluding the HUD strip:
   - P1 gesture region: x 0–320, y 90–450
   - P2 gesture region: x 480–800, y 90–450
   - Gesture ownership is determined by the **drag origin**, not the endpoint. A drag that begins inside P1's gesture region is always a P1 input, regardless of where the finger or cursor travels.

6. The canvas is landscape-only. If the browser viewport aspect ratio falls below 1.0 (portrait), display an orientation prompt ("Rotate your device") and suspend all game input until the ratio is ≥ 1.0 again. No layout adjustment is made for portrait — the prompt is the entire response.

7. **One active drag per player zone at a time.** If a second touch begins in a player's gesture region while a drag is already in progress for that player, the second touch is silently discarded until the first drag ends.

### States and Transitions

Screen Layout has no runtime states. The constants defined here are fixed for the lifetime of a session. There are no transitions.

The only conditional behaviour is the **orientation gate**: active when `viewport.size.x < viewport.size.y`; suspended when `viewport.size.x ≥ viewport.size.y`.

### Interactions with Other Systems

| Downstream System | What It Reads From Screen Layout | Interface |
|-------------------|----------------------------------|-----------|
| Figure Geometry | P1/P2 anchor positions | `ScreenLayout.P1_ANCHOR`, `ScreenLayout.P2_ANCHOR` |
| Trajectory Visualization | Player zone boundaries, corridor bounds | `ScreenLayout.P1_ZONE`, `ScreenLayout.P2_ZONE`, `ScreenLayout.CORRIDOR` |
| Input System | Gesture region rectangles per player | `ScreenLayout.P1_GESTURE_RECT`, `ScreenLayout.P2_GESTURE_RECT` |
| HUD / Turn Indicator | HUD strip rects per player + turn indicator rect | `ScreenLayout.P1_HUD_RECT`, `ScreenLayout.P2_HUD_RECT`, `ScreenLayout.TURN_INDICATOR_RECT` |
| AI Targeting | Both anchor positions, corridor bounds | Same constants as Trajectory Visualization |

All downstream systems read constants — they do not write back to Screen Layout. This system has no inputs from other systems.

## Formulas

### Constant Definitions

These are the authoritative source for all spatial constants. Every system that needs a position reads from here — it does not define its own.

```
# Canvas
CANVAS_W  = 800 px
CANVAS_H  = 450 px
HUD_H     =  90 px   # top strip reserved for HUD (20% of canvas height)

# Zone rectangles  (x, y, width, height)
P1_ZONE   = Rect2(  0,   0, 320, 450)
P2_ZONE   = Rect2(480,   0, 320, 450)
CORRIDOR  = Rect2(320,   0, 160, 450)

# Figure anchors (foot / root positions)
P1_ANCHOR = Vector2(200, 338)
P2_ANCHOR = Vector2(600, 338)

# HUD cell rects (x, y, width, height)
P1_HUD_RECT       = Rect2(  0,   0, 320, 90)
P2_HUD_RECT       = Rect2(480,   0, 320, 90)
TURN_INDICATOR_RECT = Rect2(280, 0, 240, 90)  # overlaps inner 40 px of each HUD cell

# Orientation gate (boolean — suspend input when true)
portrait_blocked = (V_w < V_h)
```

### Formula 1 — Gesture Region Rectangle

`GESTURE_RECT(zone) = Rect2(zone.x, HUD_H, zone.w, CANVAS_H − HUD_H)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Zone left edge | `zone.x` | float | 0 or 480 px | Left edge of the player's zone |
| Zone width | `zone.w` | float | 320 px (fixed) | Width of the player's zone |
| HUD height | `HUD_H` | float | 90 px (constant) | Height reserved for the HUD strip |
| Canvas height | `CANVAS_H` | float | 450 px (constant) | Full logical canvas height |
| **Result** | — | Rect2 | y∈[90,450], h=360 px | Input-valid gesture region for that player |

**Output Range:** Height is always 360 px (= CANVAS_H − HUD_H). Expressing it as a formula makes the HUD dependency explicit — if `HUD_H` is tuned, both gesture regions update automatically by this rule.

**Example — P1:** `zone.x=0, zone.w=320, HUD_H=90, CANVAS_H=450` → `Rect2(0, 90, 320, 360)`

### Formula 2 — Canvas Scaling Factor

`S = min(V_w / CANVAS_W, V_h / CANVAS_H)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Viewport width | `V_w` | float | > 0 px | Browser viewport width in display pixels |
| Viewport height | `V_h` | float | > 0 px | Browser viewport height in display pixels |
| Canvas width | `CANVAS_W` | float | 800 px (constant) | Logical canvas width |
| Canvas height | `CANVAS_H` | float | 450 px (constant) | Logical canvas height |
| **Scaling factor** | `S` | float | > 0, typically 0.5–4.0 | Uniform scale, logical → display pixels |

**Output Range:** Positive; Godot's Keep Aspect mode handles this automatically. This formula is provided so downstream systems can back-project touch input: `logical_pos = display_pos / S`.

**Example:** 1280×720 viewport → `min(1280/800, 720/450) = 1.6`. Portrait (390×844) → `0.49`, but this case is blocked by the orientation gate before `S` is used.

## Edge Cases

- **If a drag origin lands on x=320 or x=480 (zone boundary pixels)**: the point falls outside both `P1_GESTURE_RECT` and `P2_GESTURE_RECT`. The input system discards it silently. Same applies at y=90 (HUD/gesture boundary). No shot is initiated.

- **If a drag begins in a gesture region but the pointer exits the canvas boundary**: ownership was locked at the origin; the drag completes or cancels normally. No remapping or reassignment occurs.

- **If two touches are active simultaneously, each originating in different player zones**: both are valid, each owned by its origin player independently. This is the expected shared-tablet case; no additional rule is needed.

- **If two touches are active simultaneously within the same player's gesture region**: only the first active drag is valid. The second touch is silently discarded until the first drag ends. One active drag per player zone at a time. *(Also recorded in Core Rules as Rule 7.)*

- **If a touch begins, lifts, and a second already-resting finger in the same zone begins moving after the lift**: the second finger constitutes a new valid drag from the moment the first lifts. No lockout period between gestures.

- **If the viewport is resized to portrait mid-game** (V_w drops below V_h): the orientation gate activates, the orientation prompt appears, and any gesture in progress is dropped. This is the only condition that forcibly terminates an in-flight input. The layout constants do not change.

- **If the viewport is resized back to landscape mid-game** (V_w ≥ V_h): the orientation gate lifts, the prompt is dismissed, and input resumes. No constants are recalculated — they are all fixed from CANVAS_W and CANVAS_H.

- **If V_w = V_h exactly** (square viewport): `portrait_blocked` evaluates to `false` (condition is strict less-than). The game continues; horizontal letterboxing appears. Gesture regions remain valid.

- **If the browser window is minimized** (V_w or V_h approaches zero): this is an OS-level visibility concern outside the layout system's scope. Godot's renderer handles near-zero viewport sizes without division-by-zero. The layout system makes no explicit rule for this case.

- **If a drag origin is in the Corridor** (x 320–480, y 90–450): this is a 160 px-wide dead zone covered by no player's gesture rect. The input system must explicitly discard these events rather than fall through to a default handler.

## Dependencies

Screen Layout has no upstream dependencies — it defines the spatial foundation that all other systems build on.

**Downstream dependents** (systems that read Screen Layout constants):

| Dependent System | Nature | What It Reads |
|-----------------|--------|---------------|
| Figure Geometry | Hard | `P1_ANCHOR`, `P2_ANCHOR` — figure is drawn relative to its anchor |
| Input System | Hard | `P1_GESTURE_RECT`, `P2_GESTURE_RECT` — defines valid input regions and gesture ownership |
| Trajectory Visualization | Hard | `P1_ZONE`, `P2_ZONE`, `CORRIDOR` — shot lines are drawn across these bounds |
| HUD / Turn Indicator | Hard | `P1_HUD_RECT`, `P2_HUD_RECT`, `TURN_INDICATOR_RECT`, `HUD_H` — HUD is positioned in the top strip |
| AI Targeting | Hard | `P1_ANCHOR`, `P2_ANCHOR`, `P1_ZONE`, `P2_ZONE` — AI reasons about figure positions and movement bounds |
| Body-Zone Hit Detection | Indirect | Reads zone boundaries via Figure Geometry, not directly |
| Match Result Screen | Soft | May use canvas centre for overlay positioning |

No system writes back to Screen Layout. All relationships are read-only from this system's perspective. When a downstream system's GDD lists a Screen Layout dependency, it must cite `design/gdd/screen-layout.md` as the source of truth — it must not define its own copy of these values.

## Tuning Knobs

| Knob | Current Value | Safe Range | Too High | Too Low | Notes |
|------|--------------|-----------|----------|---------|-------|
| `HUD_H` | 90 px (20%) | 60–110 px | Crowds the gesture region; figures feel vertically cramped | HUD elements too small to read at a glance | Changing this automatically adjusts both gesture regions via Formula 1 |
| P1/P2 zone width | 320 px (40%) | 280–360 px | Figures too far apart; corridor becomes dead space | Figures too close; shots feel trivial | Both zones must remain equal; corridor width = CANVAS_W − (2 × zone_width) |
| `CORRIDOR` width | 160 px (20%) | 80–240 px | Shots have too much airtime; misses feel too safe | Figures nearly adjacent; headshots trivially easy | Derived from zone widths — do not tune independently |
| P1/P2 anchor Y | 338 px (75%) | 280–380 px | Figures too low; head approaches bottom of gesture area | Figures too high; head approaches HUD strip | Both anchors must share the same Y value for symmetry |
| Minimum viewport width | 500 px | 400–600 px | Relaxed — small phones playable but cramped | Strict — excludes more devices unnecessarily | Triggers "rotate device" prompt below this threshold |

**Interaction**: `HUD_H` and anchor Y interact — if `HUD_H` increases, anchors should move down proportionally to prevent figures appearing to overlap the HUD strip. Tune together.

## Visual/Audio Requirements

Not applicable — Screen Layout is pure spatial constants with no visual output of its own. Visual requirements belong to the systems that render into these zones (Figure Renderer, Trajectory Visualization, HUD / Turn Indicator).

The orientation prompt ("Rotate your device") requires a readable text element at canvas centre; style per art bible Section 6 (UI typography standards).

## UI Requirements

Not applicable — Screen Layout defines *where* UI elements live, not what they look like. See HUD / Turn Indicator GDD for UI requirements within the HUD strip zones defined here.

## Acceptance Criteria

- **GIVEN** the ScreenLayout module is loaded, **WHEN** I read `CANVAS_W`, `CANVAS_H`, and `HUD_H`, **THEN** `CANVAS_W = 800`, `CANVAS_H = 450`, `HUD_H = 90`.

- **GIVEN** the ScreenLayout module is loaded, **WHEN** I read `P1_ZONE`, `CORRIDOR`, and `P2_ZONE`, **THEN** `P1_ZONE = Rect2(0,0,320,450)`, `CORRIDOR = Rect2(320,0,160,450)`, `P2_ZONE = Rect2(480,0,320,450)`.

- **GIVEN** the ScreenLayout module is loaded, **WHEN** I read `P1_ANCHOR` and `P2_ANCHOR`, **THEN** `P1_ANCHOR = Vector2(200,338)` and `P2_ANCHOR = Vector2(600,338)`.

- **GIVEN** `zone.x=0, zone.w=320, HUD_H=90, CANVAS_H=450`, **WHEN** I evaluate `GESTURE_RECT(P1_ZONE)`, **THEN** the result is `Rect2(0,90,320,360)`.

- **GIVEN** `zone.x=480, zone.w=320, HUD_H=90, CANVAS_H=450`, **WHEN** I evaluate `GESTURE_RECT(P2_ZONE)`, **THEN** the result is `Rect2(480,90,320,360)`.

- **GIVEN** a viewport of 1280×720, **WHEN** I evaluate `S = min(V_w/CANVAS_W, V_h/CANVAS_H)`, **THEN** `S = 1.6`. *(Requires a testable `ScreenLayout.compute_scale(V_w, V_h)` function — see Open Questions.)*

- **GIVEN** a viewport of 1600×720, **WHEN** I evaluate `S`, **THEN** `S = 1.6` (height-constrained, not width-constrained).

- **GIVEN** a drag origin at exactly x=320 (or x=480, or y=90), **WHEN** the input system evaluates gesture region membership, **THEN** the origin falls outside both gesture rects and the drag is silently discarded with no shot initiated.

- **GIVEN** a drag origin at any point where x∈[321,479] and y∈[90,450] (Corridor), **WHEN** the input system evaluates gesture region membership, **THEN** the drag is silently discarded and no player is assigned ownership.

- **GIVEN** a drag origin at any point where y∈[0,89] (HUD strip), **WHEN** the input system evaluates gesture region membership, **THEN** the drag is silently discarded and no shot is initiated.

- *(Integration)* **GIVEN** the browser viewport has V_w < V_h, **WHEN** the layout system evaluates the orientation gate, **THEN** all game input is suspended and an orientation prompt is visible; no touch event produces a shot or game action.

- *(Integration)* **GIVEN** V_w = V_h exactly (square viewport), **WHEN** the orientation gate evaluates `portrait_blocked`, **THEN** `portrait_blocked` is `false` and input is not suspended.

- *(Integration)* **GIVEN** P1 has a drag in progress, **WHEN** the viewport is resized so V_w < V_h mid-drag, **THEN** the in-flight drag is cancelled, the orientation prompt appears, and no shot is registered from the dropped gesture.

- *(Integration)* **GIVEN** the orientation gate is active, **WHEN** the viewport is resized back to V_w ≥ V_h, **THEN** the prompt is dismissed, input resumes, and no layout constants have changed.

- *(Integration)* **GIVEN** P1 has an active drag in P1's gesture region, **WHEN** P2 begins a separate drag in P2's gesture region simultaneously, **THEN** both drags are tracked independently with no interference.

- *(Integration)* **GIVEN** P1 has an active drag in progress, **WHEN** a second touch begins within P1's gesture region before the first drag ends, **THEN** the second touch is silently discarded; the first drag continues unaffected.

- *(Integration)* **GIVEN** P1 begins a drag inside P1's gesture region, **WHEN** the pointer travels outside P1's gesture region, **THEN** the drag remains owned by P1 and is not reassigned.

*Note: Integration criteria (marked above) require a running Godot scene in-browser and cannot be unit-tested headlessly. Evidence files at `production/qa/evidence/`.*

## Open Questions

- **Scaling formula testability**: AC-SL-06 and AC-SL-07 assume a testable `ScreenLayout.compute_scale(V_w, V_h)` function. If Godot's Keep Aspect renderer handles scaling implicitly (no exposed function), these criteria become visual/platform smoke checks rather than unit tests. Confirm during architecture phase whether to expose this function or reclassify the criteria. *Owner: lead-programmer. Resolve before: test-setup sprint.*

- **HUD-anchor Y coupling**: If `HUD_H` is tuned above ~100 px, the figure anchors at y=338 will need to move down proportionally or the figures will visually encroach on the HUD strip. The Tuning Knobs section notes this interaction, but no formula formalises the constraint. Consider adding `MIN_ANCHOR_Y = HUD_H + figure_height + margin` as a derived constant once figure height is defined in the Figure Geometry GDD. *Resolve after: Figure Geometry GDD is authored.*
