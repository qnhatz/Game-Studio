extends GdUnitTestSuite


func test_screen_layout_gesture_rect_p1_zone_strips_hud() -> void:
	# AC-1: GESTURE_RECT(P1_ZONE) = Rect2(0, 90, 320, 360)
	var result: Rect2 = ScreenLayout.GESTURE_RECT(ScreenLayout.P1_ZONE)
	assert_that(result).is_equal(Rect2(0, 90, 320, 360))


func test_screen_layout_gesture_rect_p1_preserves_x_origin() -> void:
	# AC-1 edge: x=0 must not shift
	var result: Rect2 = ScreenLayout.GESTURE_RECT(ScreenLayout.P1_ZONE)
	assert_float(result.position.x).is_equal(0.0)


func test_screen_layout_gesture_rect_p2_zone_strips_hud() -> void:
	# AC-2: GESTURE_RECT(P2_ZONE) = Rect2(480, 90, 320, 360)
	var result: Rect2 = ScreenLayout.GESTURE_RECT(ScreenLayout.P2_ZONE)
	assert_that(result).is_equal(Rect2(480, 90, 320, 360))


func test_screen_layout_gesture_rect_p2_preserves_x_offset() -> void:
	# AC-2 edge: x-offset 480 must be preserved unchanged
	var result: Rect2 = ScreenLayout.GESTURE_RECT(ScreenLayout.P2_ZONE)
	assert_float(result.position.x).is_equal(480.0)
	assert_float(result.size.y).is_equal(float(ScreenLayout.CANVAS_H - ScreenLayout.HUD_H))


func test_screen_layout_compute_scale_equal_constraint() -> void:
	# AC-3: both axes produce 1.6 — neither dominates
	var result: float = ScreenLayout.compute_scale(1280.0, 720.0)
	assert_float(result).is_equal_approx(1.6, 0.0001)


func test_screen_layout_compute_scale_height_constrained() -> void:
	# AC-4: width ratio 2.0 vs height ratio 1.6 — height wins
	var result: float = ScreenLayout.compute_scale(1600.0, 720.0)
	assert_float(result).is_equal_approx(1.6, 0.0001)


func test_screen_layout_compute_scale_very_wide_viewport() -> void:
	# AC-4 edge: extreme width (3840×450) still returns height-constrained value
	var result: float = ScreenLayout.compute_scale(3840.0, 450.0)
	assert_float(result).is_equal_approx(1.0, 0.0001)
