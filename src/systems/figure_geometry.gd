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
const CANVAS_DIAGONAL: float = 922.0  # sqrt(800^2 + 450^2)

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


## Returns the zone name hit by the ray, or &"MISS". Priority: HEAD > ARMS > LEGS.
## direction must be a unit vector.
func detect_zone(origin: Vector2, direction: Vector2, player_id: int) -> StringName:
	var head: Dictionary = get_zone_circle(player_id)
	if _ray_hits_circle(origin, direction, head.centre, head.radius):
		return &"HEAD"
	if _ray_hits_rect(origin, direction, get_zone_rect(player_id, &"ARMS")):
		return &"ARMS"
	if _ray_hits_rect(origin, direction, get_zone_rect(player_id, &"LEGS")):
		return &"LEGS"
	return &"MISS"


func _ray_hits_circle(origin: Vector2, direction: Vector2, centre: Vector2, radius: float) -> bool:
	assert(direction.is_normalized(), "FigureGeometry._ray_hits_circle: direction must be a unit vector")
	var oc: Vector2 = centre - origin
	var t: float = oc.dot(direction)
	# If the circle is entirely behind the ray origin, miss
	if t < 0.0 and oc.dot(oc) > radius * radius:
		return false
	var d_sq: float = oc.dot(oc) - t * t
	return d_sq <= radius * radius


# Slab method: 1e-10 guard avoids division by zero for axis-aligned rays.
func _ray_hits_rect(origin: Vector2, direction: Vector2, rect: Rect2) -> bool:
	var dx: float = direction.x if direction.x != 0.0 else 1e-10
	var dy: float = direction.y if direction.y != 0.0 else 1e-10
	var t_min: float = maxf((rect.position.x - origin.x) / dx, (rect.position.y - origin.y) / dy)
	var t_max: float = minf((rect.end.x - origin.x) / dx, (rect.end.y - origin.y) / dy)
	return t_min <= t_max and t_max >= 0.0 and t_min <= CANVAS_DIAGONAL
