class_name Movement
extends Node

const MOVE_MARGIN_PX: float = 20.0
const ANCHOR_Y: float = 338.0

## Injected FigureGeometry reference. Must be set before calling on_move_tapped.
var _figure_geometry: Node = null


## Moves the player's anchor to the tap position, clamped within their zone by MOVE_MARGIN_PX.
## Y coordinate is always forced to ANCHOR_Y regardless of tap position.
func on_move_tapped(tap_position: Vector2, player_id: int) -> void:
	if _figure_geometry == null:
		push_error("Movement: _figure_geometry not injected")
		return
	var zone: Rect2 = ScreenLayout.P1_ZONE if player_id == 0 else ScreenLayout.P2_ZONE
	var min_x: float = zone.position.x + MOVE_MARGIN_PX
	var max_x: float = zone.end.x - MOVE_MARGIN_PX
	var new_x: float = clampf(tap_position.x, min_x, max_x)
	_figure_geometry.set_anchor(player_id, Vector2(new_x, ANCHOR_Y))
