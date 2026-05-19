extends GdUnitTestSuite

# ScreenLayout constants (verified in screen_layout.gd):
# P1_ZONE = Rect2(0, 0, 320, 450) → min_x=20, max_x=300
# P2_ZONE = Rect2(480, 0, 320, 450) → min_x=500, max_x=780
# ANCHOR_Y = 338.0

var _fg: FigureGeometry
var _mv: Movement


func before_each() -> void:
	_fg = FigureGeometry.new()
	add_child(_fg)
	_mv = Movement.new()
	_mv._figure_geometry = _fg
	add_child(_mv)


func after_each() -> void:
	_mv.queue_free()
	_fg.queue_free()


# AC-1: Valid tap in P1 zone — anchor X set to tap X, Y remains 338
func test_movement_valid_tap_in_p1_zone_sets_anchor() -> void:
	# Arrange: P1 at default anchor
	# Act:
	_mv.on_move_tapped(Vector2(150.0, 338.0), 0)
	# Assert:
	assert_float(_fg.get_anchor(0).x).is_equal_approx(150.0, 0.001)
	assert_float(_fg.get_anchor(0).y).is_equal_approx(338.0, 0.001)


# AC-2: Y coordinate never changes — always ANCHOR_Y=338 regardless of tap Y
func test_movement_tap_with_different_y_anchor_y_stays_338() -> void:
	# Arrange: any valid tap with Y ≠ 338
	# Act:
	_mv.on_move_tapped(Vector2(150.0, 200.0), 0)
	# Assert:
	assert_float(_fg.get_anchor(0).y).is_equal_approx(338.0, 0.001)


# AC-3: Left edge clamping — tap x=5 clamped to x=20 (P1_ZONE.x + MARGIN)
func test_movement_tap_near_left_edge_clamped_to_minimum() -> void:
	# Act:
	_mv.on_move_tapped(Vector2(5.0, 338.0), 0)
	# Assert:
	assert_float(_fg.get_anchor(0).x).is_equal_approx(20.0, 0.001)


# AC-4: Right edge clamping — tap x=350 (past P1 max) clamped to x=300
func test_movement_tap_past_right_edge_clamped_to_maximum() -> void:
	# Act:
	_mv.on_move_tapped(Vector2(350.0, 338.0), 0)
	# Assert:
	assert_float(_fg.get_anchor(0).x).is_equal_approx(300.0, 0.001)


# AC-5: Tap within 1px of current anchor — no minimum-move guard, completes normally
func test_movement_tap_within_1px_of_anchor_still_moves() -> void:
	# Arrange: position anchor at x=150 first
	_fg.set_anchor(0, Vector2(150.0, 338.0))
	# Act: tap at x=150.5 — 0.5 px from current anchor
	_mv.on_move_tapped(Vector2(150.5, 338.0), 0)
	# Assert: anchor updated to new position (no early return due to proximity)
	assert_float(_fg.get_anchor(0).x).is_equal_approx(150.5, 0.001)


# AC-6: P2 zone clamping — tap x=460 clamped to x=500 (P2_ZONE.x + MARGIN)
func test_movement_p2_tap_left_of_zone_clamped_to_p2_minimum() -> void:
	# Act:
	_mv.on_move_tapped(Vector2(460.0, 338.0), 1)
	# Assert:
	assert_float(_fg.get_anchor(1).x).is_equal_approx(500.0, 0.001)


# P2 right edge clamping — tap x=810 clamped to x=780 (P2_ZONE.end.x - MARGIN)
func test_movement_p2_tap_past_right_edge_clamped_to_p2_maximum() -> void:
	_mv.on_move_tapped(Vector2(810.0, 338.0), 1)
	assert_float(_fg.get_anchor(1).x).is_equal_approx(780.0, 0.001)


# Player isolation — P1 move does not affect P2 anchor
func test_movement_p1_move_does_not_change_p2_anchor() -> void:
	# Arrange:
	var p2_anchor_before: Vector2 = _fg.get_anchor(1)
	# Act:
	_mv.on_move_tapped(Vector2(150.0, 338.0), 0)
	# Assert:
	assert_vector2(_fg.get_anchor(1)).is_equal_approx(p2_anchor_before, Vector2(0.001, 0.001))


# Tap at exact zone minimum boundary — not clamped further
func test_movement_tap_at_exact_min_x_is_not_clamped() -> void:
	_mv.on_move_tapped(Vector2(20.0, 338.0), 0)
	assert_float(_fg.get_anchor(0).x).is_equal_approx(20.0, 0.001)


# Tap at exact zone maximum boundary — not clamped further
func test_movement_tap_at_exact_max_x_is_not_clamped() -> void:
	_mv.on_move_tapped(Vector2(300.0, 338.0), 0)
	assert_float(_fg.get_anchor(0).x).is_equal_approx(300.0, 0.001)
