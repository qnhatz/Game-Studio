## Spatial constants for the 800×450 game canvas. Read-only — no runtime state.
class_name ScreenLayout
extends Node

const CANVAS_W: int = 800
const CANVAS_H: int = 450
const HUD_H: int = 90

const P1_ZONE: Rect2 = Rect2(0, 0, 320, 450)
const CORRIDOR: Rect2 = Rect2(320, 0, 160, 450)
const P2_ZONE: Rect2 = Rect2(480, 0, 320, 450)

const P1_ANCHOR: Vector2 = Vector2(200, 338)
const P2_ANCHOR: Vector2 = Vector2(600, 338)


## Returns the valid gesture region for a zone by stripping the HUD top band.
static func GESTURE_RECT(zone: Rect2) -> Rect2:
	return Rect2(zone.position.x, HUD_H, zone.size.x, CANVAS_H - HUD_H)


## Returns the Keep Aspect letterbox scale factor for a given viewport size.
static func compute_scale(viewport_w: float, viewport_h: float) -> float:
	return minf(viewport_w / CANVAS_W, viewport_h / CANVAS_H)
