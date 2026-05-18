# Story 002: GESTURE_RECT Formula and Scaling

> **Epic**: Screen Layout
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-11

## Context

**GDD**: `design/gdd/screen-layout.md`
**Requirements**: `TR-SCRN-002`, `TR-SCRN-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Web Export and Memory) + ADR-0007 (Input System Architecture)
**ADR Decision Summary**: Keep Aspect letterbox scaling is handled by the Compatibility renderer (`Window` stretch mode `canvas_items`, aspect `keep`). `GESTURE_RECT(zone)` strips the HUD top band from any zone rect to produce the valid gesture region. `compute_scale(V_w, V_h)` exposes the scaling formula as a testable static function: `min(V_w / CANVAS_W, V_h / CANVAS_H)`.

**Engine**: Godot 4.6 | **Risk**: LOW (canvas_items stretch mode stable since Godot 4.0) / MEDIUM (Compatibility renderer web override requires verification — ADR-0002)
**Engine Notes**: `rendering/renderer/rendering_method.web = "gl_compatibility"` is a 4.4+ platform override. Verify it is set in `project.godot` before export. The stretch mode `canvas_items` + `keep` aspect is confirmed stable.

**Control Manifest Rules (Foundation layer)**:
- Required: Autoload policy — `ScreenLayout` holds constants and pure functions; no runtime state.
- Forbidden: Do not hardcode gesture rect values in InputSystem — always call `ScreenLayout.GESTURE_RECT(zone)`.

---

## Acceptance Criteria

*From GDD `design/gdd/screen-layout.md`:*

- [ ] `GESTURE_RECT(P1_ZONE)` returns `Rect2(0, 90, 320, 360)`
- [ ] `GESTURE_RECT(P2_ZONE)` returns `Rect2(480, 90, 320, 360)`
- [ ] `compute_scale(1280, 720)` returns `1.6` (both axes agree — width- and height-constrained equally)
- [ ] `compute_scale(1600, 720)` returns `1.6` (height-constrained; width ratio 2.0 does not override)

---

## Implementation Notes

*Derived from ADR-0002 and ADR-0007 Implementation Guidelines:*

Add two pure static functions to `res://systems/screen_layout.gd`:

```gdscript
static func GESTURE_RECT(zone: Rect2) -> Rect2:
    return Rect2(zone.position.x, HUD_H, zone.size.x, CANVAS_H - HUD_H)

static func compute_scale(viewport_w: float, viewport_h: float) -> float:
    return minf(viewport_w / CANVAS_W, viewport_h / CANVAS_H)
```

`GESTURE_RECT` strips the HUD strip from the top of any zone rect. The formula does not modify `zone.position.x` or `zone.size.x` — only the y origin and height change.

`compute_scale` implements the Keep Aspect scale formula: the smaller ratio wins. A 1600×720 viewport produces width ratio 2.0 and height ratio 1.6; `min(2.0, 1.6) = 1.6` (height constrains). This matches Godot's Keep Aspect letterbox behaviour.

Confirm `project.godot` contains:
```
[display]
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: The raw constants (`CANVAS_W`, `P1_ZONE`, etc.) that `GESTURE_RECT` depends on
- Story 003: How InputSystem uses `GESTURE_RECT` for dead-zone filtering — that is an integration concern

---

## QA Test Cases

*Written by qa-lead at story creation.*

- **AC-1**: GESTURE_RECT for P1
  - Given: ScreenLayout Autoload loaded; `P1_ZONE = Rect2(0,0,320,450)`, `HUD_H = 90`, `CANVAS_H = 450`
  - When: `ScreenLayout.GESTURE_RECT(ScreenLayout.P1_ZONE)` is called
  - Then: result equals `Rect2(0, 90, 320, 360)`
  - Edge cases: `GESTURE_RECT` of a zone whose x starts at 0 must not shift x

- **AC-2**: GESTURE_RECT for P2
  - Given: `P2_ZONE = Rect2(480,0,320,450)`, same HUD_H/CANVAS_H
  - When: `ScreenLayout.GESTURE_RECT(ScreenLayout.P2_ZONE)` is called
  - Then: result equals `Rect2(480, 90, 320, 360)`
  - Edge cases: x-offset 480 is preserved; height = CANVAS_H - HUD_H = 360

- **AC-3**: compute_scale width/height equal constraint
  - Given: viewport_w=1280, viewport_h=720
  - When: `ScreenLayout.compute_scale(1280.0, 720.0)`
  - Then: returns `1.6` (1280/800 = 1.6; 720/450 = 1.6 — equal)
  - Edge cases: floating-point equality within 0.0001 tolerance

- **AC-4**: compute_scale height-constrained
  - Given: viewport_w=1600, viewport_h=720
  - When: `ScreenLayout.compute_scale(1600.0, 720.0)`
  - Then: returns `1.6` (not 2.0; height ratio wins)
  - Edge cases: very wide viewport (e.g. 3840×450) should still return height-constrained value

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/screen_layout/gesture_rect_scaling_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be DONE (constants required)
- Unlocks: Story 003 (dead-zone filtering depends on GESTURE_RECT)

---

## Completion Notes
**Completed**: 2026-05-15
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: `tests/unit/screen_layout/gesture_rect_scaling_test.gd` — 7 test functions
**Code Review**: Skipped (lean mode, straightforward static functions)
