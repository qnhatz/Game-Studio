# Story 001: ScreenLayout Constants

> **Epic**: Screen Layout
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 2 hours
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/screen-layout.md`
**Requirements**: `TR-SCRN-001`, `TR-SCRN-003`, `TR-SCRN-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Scene Topology) + ADR-0002 (Web Export and Memory)
**ADR Decision Summary**: ScreenLayout is one of exactly two Autoloads; it holds spatial constants only, with no runtime state and no signals. Canvas is fixed at 800×450 px with Keep Aspect letterbox scaling via Compatibility/WebGL 2 renderer.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Autoload, constants, and `Vector2`/`Rect2` types are stable since Godot 4.0. No post-cutoff APIs.

**Control Manifest Rules (Foundation layer)**:
- Required: Exactly two Autoloads — `ScreenLayout` (spatial constants, no state, no signals) and `RngService`. All other systems are scene-tree nodes.
- Required: All constants use `UPPER_SNAKE_CASE`.
- Forbidden: `ScreenLayout` must not hold runtime state or emit signals.
- Forbidden: Never use `$NodePath` in `_process()` — cache via `@onready`.

---

## Acceptance Criteria

*From GDD `design/gdd/screen-layout.md`:*

- [ ] `CANVAS_W = 800`, `CANVAS_H = 450`, `HUD_H = 90` are readable constants on the ScreenLayout Autoload
- [ ] `P1_ZONE = Rect2(0, 0, 320, 450)`, `CORRIDOR = Rect2(320, 0, 160, 450)`, `P2_ZONE = Rect2(480, 0, 320, 450)`
- [ ] `P1_ANCHOR = Vector2(200, 338)`, `P2_ANCHOR = Vector2(600, 338)`
- [ ] ScreenLayout is registered as an Autoload in `project.godot` — accessible from any script without a node reference

---

## Implementation Notes

*Derived from ADR-0001 and ADR-0002 Implementation Guidelines:*

Create `res://systems/screen_layout.gd` with `class_name ScreenLayout extends Node`. Register as an Autoload in Project Settings → Autoload. This node holds **only** `const` declarations — no `var`, no signals, no `_process()`, no `_ready()` logic beyond the implicit Node lifecycle.

Zone rects use the 800 px canvas width split: P1 gets the left 320 px (40%), Corridor 160 px (20%), P2 the right 320 px (40%). HUD strip occupies the top 90 px of the canvas; figure anchors sit below it at y=338.

Do not derive these values from each other at runtime — they are compile-time constants. Any other system that needs spatial data reads from this Autoload directly.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `GESTURE_RECT()` function and `compute_scale()` — those are derived computed values, not raw constants

---

## QA Test Cases

*Written by qa-lead at story creation.*

- **AC-1**: CANVAS_W, CANVAS_H, HUD_H
  - Given: ScreenLayout Autoload is loaded in a GUT test scene
  - When: I read `ScreenLayout.CANVAS_W`, `ScreenLayout.CANVAS_H`, `ScreenLayout.HUD_H`
  - Then: values equal `800`, `450`, `90` respectively
  - Edge cases: constants are typed (`int` or `float`) and not `null`

- **AC-2**: Zone rects
  - Given: ScreenLayout Autoload loaded
  - When: I read `P1_ZONE`, `CORRIDOR`, `P2_ZONE`
  - Then: `P1_ZONE == Rect2(0,0,320,450)`, `CORRIDOR == Rect2(320,0,160,450)`, `P2_ZONE == Rect2(480,0,320,450)`
  - Edge cases: zones are contiguous — `P1_ZONE.end.x == CORRIDOR.position.x`, `CORRIDOR.end.x == P2_ZONE.position.x`; total width = 800

- **AC-3**: Anchors
  - Given: ScreenLayout Autoload loaded
  - When: I read `P1_ANCHOR`, `P2_ANCHOR`
  - Then: `P1_ANCHOR == Vector2(200, 338)`, `P2_ANCHOR == Vector2(600, 338)`
  - Edge cases: anchors are within their respective zones and below the HUD strip (y > HUD_H)

- **AC-4**: Autoload accessibility
  - Given: Any GDScript file in the project (no `@onready` setup)
  - When: I reference `ScreenLayout.CANVAS_W` at parse time
  - Then: no error; value resolves to 800
  - Edge cases: Autoload must appear before any system that uses it in the Autoload order

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/screen_layout/screen_layout_constants_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (first Foundation story)
- Unlocks: Story 002 (GESTURE_RECT and scaling depend on these constants), all other epics that reference ScreenLayout

---

## Completion Notes
**Completed**: 2026-05-15
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: `tests/unit/screen_layout/screen_layout_constants_test.gd` — 7 test functions
**Code Review**: Complete (APPROVED WITH SUGGESTIONS — doc comment and canvas-boundary test added)
