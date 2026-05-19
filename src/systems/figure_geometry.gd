class_name FigureGeometry
extends Node

const P1_DEFAULT_ANCHOR: Vector2 = Vector2(200, 338)
const P2_DEFAULT_ANCHOR: Vector2 = Vector2(600, 338)
const HEAD_OFFSET: Vector2 = Vector2(0, -162)
const HEAD_RADIUS: float = 18.0
const ARMS_OFFSET: Vector2 = Vector2(-40, -126)
const ARMS_SIZE: Vector2 = Vector2(80, 36)
const LEGS_OFFSET: Vector2 = Vector2(-18, -72)
const LEGS_SIZE: Vector2 = Vector2(36, 72)

var _anchors: Array[Vector2] = [P1_DEFAULT_ANCHOR, P2_DEFAULT_ANCHOR]


## Returns the current anchor position for the given player (0 or 1).
func get_anchor(player_id: int) -> Vector2:
	return _anchors[player_id]


## Sets the anchor position for the given player. All zone accessors use this position.
func set_anchor(player_id: int, pos: Vector2) -> void:
	_anchors[player_id] = pos


## Returns head zone as {centre: Vector2, radius: float}.
func get_zone_circle(player_id: int) -> Dictionary:
	return {centre = _anchors[player_id] + HEAD_OFFSET, radius = HEAD_RADIUS}


## Returns ARMS or LEGS zone as Rect2.
func get_zone_rect(player_id: int, zone: StringName) -> Rect2:
	var anchor: Vector2 = _anchors[player_id]
	if zone == &"ARMS":
		return Rect2(anchor + ARMS_OFFSET, ARMS_SIZE)
	if zone == &"LEGS":
		return Rect2(anchor + LEGS_OFFSET, LEGS_SIZE)
	push_error("FigureGeometry: unknown zone " + String(zone))
	return Rect2()


## Returns the centre point of the named zone (HEAD, ARMS, or LEGS).
func get_zone_centre(player_id: int, zone: StringName) -> Vector2:
	if zone == &"HEAD":
		return get_zone_circle(player_id).centre
	return get_zone_rect(player_id, zone).get_center()


## Restores both players' anchors to their default ScreenLayout positions.
func reset() -> void:
	_anchors[0] = P1_DEFAULT_ANCHOR
	_anchors[1] = P2_DEFAULT_ANCHOR
