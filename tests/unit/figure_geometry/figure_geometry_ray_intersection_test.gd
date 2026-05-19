extends GdUnitTestSuite

# Ray origin: left edge at anchor Y, firing rightward toward P1 (200, 338)
const ORIGIN: Vector2 = Vector2(0.0, 338.0)

var _fg: FigureGeometry


func before_each() -> void:
	_fg = FigureGeometry.new()
	add_child(_fg)


func after_each() -> void:
	_fg.free()


func _direction_to(target: Vector2) -> Vector2:
	return (target - ORIGIN).normalized()


# AC-1: Head hit — ray aimed at head centre
func test_figure_geometry_ray_aimed_at_head_centre_returns_head() -> void:
	var head_centre: Vector2 = _fg.get_zone_circle(0).centre
	var result: StringName = _fg.detect_zone(ORIGIN, _direction_to(head_centre), 0)
	assert_str(result).is_equal("HEAD")


# AC-2: Neck miss — anchor + Vector2(0, -135) is between head and arms
func test_figure_geometry_ray_aimed_at_neck_gap_returns_miss() -> void:
	var neck: Vector2 = _fg.get_anchor(0) + Vector2(0.0, -135.0)
	var result: StringName = _fg.detect_zone(ORIGIN, _direction_to(neck), 0)
	assert_str(result).is_equal("MISS")


# AC-3: Arms hit — ray aimed at arms rect centre
func test_figure_geometry_ray_aimed_at_arms_centre_returns_arms() -> void:
	var arms_centre: Vector2 = _fg.get_zone_rect(0, &"ARMS").get_center()
	var result: StringName = _fg.detect_zone(ORIGIN, _direction_to(arms_centre), 0)
	assert_str(result).is_equal("ARMS")


# AC-4: Mid-torso miss — anchor + Vector2(0, -81) is gap between arms and legs
func test_figure_geometry_ray_aimed_at_mid_torso_gap_returns_miss() -> void:
	var torso: Vector2 = _fg.get_anchor(0) + Vector2(0.0, -81.0)
	var result: StringName = _fg.detect_zone(ORIGIN, _direction_to(torso), 0)
	assert_str(result).is_equal("MISS")


# AC-5: Legs hit — ray aimed at legs rect centre
func test_figure_geometry_ray_aimed_at_legs_centre_returns_legs() -> void:
	var legs_centre: Vector2 = _fg.get_zone_rect(0, &"LEGS").get_center()
	var result: StringName = _fg.detect_zone(ORIGIN, _direction_to(legs_centre), 0)
	assert_str(result).is_equal("LEGS")


# AC-6: Axis-aligned horizontal ray (D.y=0) — no crash
func test_figure_geometry_horizontal_ray_does_not_crash() -> void:
	var arms_rect: Rect2 = _fg.get_zone_rect(0, &"ARMS")
	var origin: Vector2 = Vector2(0.0, arms_rect.get_center().y)
	var result: StringName = _fg.detect_zone(origin, Vector2(1.0, 0.0), 0)
	# Horizontal ray through arms Y should hit ARMS
	assert_str(result).is_equal("ARMS")


# AC-7: Axis-aligned vertical ray (D.x=0) — no crash
func test_figure_geometry_vertical_ray_does_not_crash() -> void:
	var head_centre: Vector2 = _fg.get_zone_circle(0).centre
	var origin: Vector2 = Vector2(head_centre.x, 0.0)
	var result: StringName = _fg.detect_zone(origin, Vector2(0.0, 1.0), 0)
	# Vertical ray through head X should hit HEAD
	assert_str(result).is_equal("HEAD")


# Priority: HEAD takes priority over ARMS when both are hit
func test_figure_geometry_ray_through_head_returns_head_not_arms() -> void:
	var head_centre: Vector2 = _fg.get_zone_circle(0).centre
	var result: StringName = _fg.detect_zone(ORIGIN, _direction_to(head_centre), 0)
	assert_str(result).is_equal("HEAD")


# Player 1 zones are checked independently
func test_figure_geometry_ray_hits_player1_head() -> void:
	var p1_origin: Vector2 = Vector2(800.0, 338.0)
	var head_centre: Vector2 = _fg.get_zone_circle(1).centre
	var dir: Vector2 = (head_centre - p1_origin).normalized()
	var result: StringName = _fg.detect_zone(p1_origin, dir, 1)
	assert_str(result).is_equal("HEAD")


func test_figure_geometry_ray_aimed_at_player1_legs_returns_legs() -> void:
	var p1_origin: Vector2 = Vector2(800.0, 338.0)
	var legs_centre: Vector2 = _fg.get_zone_rect(1, &"LEGS").get_center()
	var dir: Vector2 = (legs_centre - p1_origin).normalized()
	var result: StringName = _fg.detect_zone(p1_origin, dir, 1)
	assert_str(result).is_equal("LEGS")


# Ray aimed well above all zones returns MISS
func test_figure_geometry_ray_aimed_above_figure_returns_miss() -> void:
	var above: Vector2 = _fg.get_anchor(0) + Vector2(0.0, -300.0)
	var result: StringName = _fg.detect_zone(ORIGIN, _direction_to(above), 0)
	assert_str(result).is_equal("MISS")
