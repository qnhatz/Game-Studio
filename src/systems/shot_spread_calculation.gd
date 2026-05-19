class_name ShotSpreadCalculation

const MIN_SPREAD_DEG: float = 2.0
const MAX_SPREAD_DEG: float = 30.0


## Public entry point — called by TwoActionTurnSystem on the shot critical path.
## spread_deg is the maximum half-angle in degrees; defaults to MAX_SPREAD_DEG.
## AI difficulty modes pass a different value to tighten or widen the cone.
static func apply_spread(event: FlickEvent, spread_deg: float = MAX_SPREAD_DEG) -> Vector2:
	return _apply_spread_raw(event.direction, event.power, spread_deg)


## Computes the spread half-angle from power and the configured max spread.
static func _compute_half_angle(power: float, spread_deg: float = MAX_SPREAD_DEG) -> float:
	assert(spread_deg >= MIN_SPREAD_DEG, "spread_deg must be >= MIN_SPREAD_DEG (%f)" % MIN_SPREAD_DEG)
	var p: float = clampf(power, 0.0, 1.0)
	return MIN_SPREAD_DEG + p * (spread_deg - MIN_SPREAD_DEG)


## Internal — accepts raw direction so it can be tested with a zero vector (EC3 guard).
static func _apply_spread_raw(direction: Vector2, power: float, spread_deg: float = MAX_SPREAD_DEG) -> Vector2:
	if direction.is_zero_approx():
		push_error("ShotSpreadCalculation: zero direction vector — returning (1,0)")
		return Vector2(1.0, 0.0)
	var half_angle: float = _compute_half_angle(power, spread_deg)
	var u1: float = RngService.randf_range(0.0, 1.0)
	var u2: float = RngService.randf_range(0.0, 1.0)
	var offset_deg: float = (u1 - u2) * half_angle
	var offset_rad: float = deg_to_rad(offset_deg)
	var cos_a: float = cos(offset_rad)
	var sin_a: float = sin(offset_rad)
	return Vector2(
		direction.x * cos_a - direction.y * sin_a,
		direction.x * sin_a + direction.y * cos_a
	).normalized()
