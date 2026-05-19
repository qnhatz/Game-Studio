extends GdUnitTestSuite

var _fg: FigureGeometry


func before_each() -> void:
	_fg = FigureGeometry.new()
	add_child(_fg)


func after_each() -> void:
	_fg.free()


# AC-1: Initial anchors
func test_figure_geometry_get_anchor_player0_returns_default() -> void:
	assert_vector2(_fg.get_anchor(0)).is_equal_approx(Vector2(200, 338), Vector2(0.001, 0.001))


func test_figure_geometry_get_anchor_player1_returns_default() -> void:
	assert_vector2(_fg.get_anchor(1)).is_equal_approx(Vector2(600, 338), Vector2(0.001, 0.001))


# AC-2: Head zone circle
func test_figure_geometry_zone_circle_player0_centre_equals_anchor_plus_offset() -> void:
	var circle: Dictionary = _fg.get_zone_circle(0)
	assert_vector2(circle.centre).is_equal_approx(Vector2(200, 176), Vector2(0.001, 0.001))


func test_figure_geometry_zone_circle_player0_radius_is_18() -> void:
	var circle: Dictionary = _fg.get_zone_circle(0)
	assert_float(circle.radius).is_equal_approx(18.0, 0.0001)


func test_figure_geometry_zone_circle_player1_centre_equals_anchor_plus_offset() -> void:
	var circle: Dictionary = _fg.get_zone_circle(1)
	assert_vector2(circle.centre).is_equal_approx(Vector2(600, 176), Vector2(0.001, 0.001))


func test_figure_geometry_zone_circle_player1_radius_is_18() -> void:
	var circle: Dictionary = _fg.get_zone_circle(1)
	assert_float(circle.radius).is_equal_approx(18.0, 0.0001)


# AC-3: Arms zone rect
func test_figure_geometry_zone_rect_arms_player0_correct_position_and_size() -> void:
	var rect: Rect2 = _fg.get_zone_rect(0, &"ARMS")
	assert_vector2(rect.position).is_equal_approx(Vector2(160, 212), Vector2(0.001, 0.001))
	assert_vector2(rect.size).is_equal_approx(Vector2(80, 36), Vector2(0.001, 0.001))


func test_figure_geometry_zone_rect_arms_player1_correct_position_and_size() -> void:
	var rect: Rect2 = _fg.get_zone_rect(1, &"ARMS")
	assert_vector2(rect.position).is_equal_approx(Vector2(560, 212), Vector2(0.001, 0.001))
	assert_vector2(rect.size).is_equal_approx(Vector2(80, 36), Vector2(0.001, 0.001))


# AC-4: Legs zone rect
func test_figure_geometry_zone_rect_legs_player0_correct_position_and_size() -> void:
	var rect: Rect2 = _fg.get_zone_rect(0, &"LEGS")
	assert_vector2(rect.position).is_equal_approx(Vector2(182, 266), Vector2(0.001, 0.001))
	assert_vector2(rect.size).is_equal_approx(Vector2(36, 72), Vector2(0.001, 0.001))


func test_figure_geometry_zone_rect_legs_player1_correct_position_and_size() -> void:
	var rect: Rect2 = _fg.get_zone_rect(1, &"LEGS")
	assert_vector2(rect.position).is_equal_approx(Vector2(582, 266), Vector2(0.001, 0.001))
	assert_vector2(rect.size).is_equal_approx(Vector2(36, 72), Vector2(0.001, 0.001))


# AC-5: set_anchor updates zone calculations
func test_figure_geometry_set_anchor_updates_zone_circle() -> void:
	_fg.set_anchor(0, Vector2(150, 338))
	var circle: Dictionary = _fg.get_zone_circle(0)
	assert_vector2(circle.centre).is_equal_approx(Vector2(150, 176), Vector2(0.001, 0.001))


func test_figure_geometry_set_anchor_updates_zone_rect_arms() -> void:
	_fg.set_anchor(0, Vector2(300, 338))
	var rect: Rect2 = _fg.get_zone_rect(0, &"ARMS")
	assert_vector2(rect.position).is_equal_approx(Vector2(260, 212), Vector2(0.001, 0.001))


func test_figure_geometry_set_anchor_updates_zone_rect_legs() -> void:
	_fg.set_anchor(0, Vector2(300, 338))
	var rect: Rect2 = _fg.get_zone_rect(0, &"LEGS")
	assert_vector2(rect.position).is_equal_approx(Vector2(282, 266), Vector2(0.001, 0.001))


func test_figure_geometry_set_anchor_player0_does_not_affect_player1() -> void:
	_fg.set_anchor(0, Vector2(100, 338))
	assert_vector2(_fg.get_anchor(1)).is_equal_approx(Vector2(600, 338), Vector2(0.001, 0.001))


func test_figure_geometry_set_anchor_player1_does_not_affect_player0() -> void:
	_fg.set_anchor(1, Vector2(400, 338))
	assert_vector2(_fg.get_anchor(0)).is_equal_approx(Vector2(200, 338), Vector2(0.001, 0.001))


# AC-6: Head non-overlap with arms — derived from accessor return values
func test_figure_geometry_head_top_is_above_arms_top() -> void:
	var circle: Dictionary = _fg.get_zone_circle(0)
	var arms: Rect2 = _fg.get_zone_rect(0, &"ARMS")
	var head_top: float = circle.centre.y - circle.radius
	var arms_top: float = arms.position.y
	assert_float(head_top).is_less(arms_top)


# AC-7: Arms non-overlap with legs — derived from accessor return values
func test_figure_geometry_arms_bottom_is_above_legs_top() -> void:
	var arms: Rect2 = _fg.get_zone_rect(0, &"ARMS")
	var legs: Rect2 = _fg.get_zone_rect(0, &"LEGS")
	var arms_bottom: float = arms.position.y + arms.size.y
	var legs_top: float = legs.position.y
	assert_float(arms_bottom).is_less_equal(legs_top)


# AC-8: HUD clearance — head top must be at or below HUD bottom (y=90 per ScreenLayout)
func test_figure_geometry_head_top_clears_hud_bottom() -> void:
	var hud_bottom: float = 90.0  # ScreenLayout.HUD_BOTTOM constant
	var circle: Dictionary = _fg.get_zone_circle(0)
	var head_top: float = circle.centre.y - circle.radius
	assert_float(head_top).is_greater_equal(hud_bottom)


# AC-9: reset() restores defaults
func test_figure_geometry_reset_restores_player0_anchor() -> void:
	_fg.set_anchor(0, Vector2(100, 338))
	_fg.reset()
	assert_vector2(_fg.get_anchor(0)).is_equal_approx(Vector2(200, 338), Vector2(0.001, 0.001))


func test_figure_geometry_reset_restores_player1_anchor() -> void:
	_fg.set_anchor(1, Vector2(400, 338))
	_fg.reset()
	assert_vector2(_fg.get_anchor(1)).is_equal_approx(Vector2(600, 338), Vector2(0.001, 0.001))


func test_figure_geometry_reset_restores_both_players() -> void:
	_fg.set_anchor(0, Vector2(50, 300))
	_fg.set_anchor(1, Vector2(750, 300))
	_fg.reset()
	assert_vector2(_fg.get_anchor(0)).is_equal_approx(Vector2(200, 338), Vector2(0.001, 0.001))
	assert_vector2(_fg.get_anchor(1)).is_equal_approx(Vector2(600, 338), Vector2(0.001, 0.001))


# get_zone_centre coverage
func test_figure_geometry_zone_centre_head_matches_circle_centre() -> void:
	var circle: Dictionary = _fg.get_zone_circle(0)
	var centre: Vector2 = _fg.get_zone_centre(0, &"HEAD")
	assert_vector2(centre).is_equal_approx(circle.centre, Vector2(0.001, 0.001))


func test_figure_geometry_zone_centre_arms_matches_rect_centre() -> void:
	var rect: Rect2 = _fg.get_zone_rect(0, &"ARMS")
	var centre: Vector2 = _fg.get_zone_centre(0, &"ARMS")
	assert_vector2(centre).is_equal_approx(rect.get_center(), Vector2(0.001, 0.001))


func test_figure_geometry_zone_centre_legs_matches_rect_centre() -> void:
	var rect: Rect2 = _fg.get_zone_rect(0, &"LEGS")
	var centre: Vector2 = _fg.get_zone_centre(0, &"LEGS")
	assert_vector2(centre).is_equal_approx(rect.get_center(), Vector2(0.001, 0.001))


# Unknown zone returns empty Rect2
func test_figure_geometry_zone_rect_unknown_zone_returns_empty_rect() -> void:
	var rect: Rect2 = _fg.get_zone_rect(0, &"UNKNOWN")
	assert_vector2(rect.position).is_equal_approx(Vector2.ZERO, Vector2(0.001, 0.001))
	assert_vector2(rect.size).is_equal_approx(Vector2.ZERO, Vector2(0.001, 0.001))
