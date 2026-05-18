extends GdUnitTestSuite


func test_screen_layout_canvas_dimensions_match_spec() -> void:
	# AC-1: CANVAS_W=800, CANVAS_H=450, HUD_H=90
	assert_int(ScreenLayout.CANVAS_W).is_equal(800)
	assert_int(ScreenLayout.CANVAS_H).is_equal(450)
	assert_int(ScreenLayout.HUD_H).is_equal(90)


func test_screen_layout_zone_rects_match_spec() -> void:
	# AC-2a: exact zone rect values
	assert_that(ScreenLayout.P1_ZONE).is_equal(Rect2(0, 0, 320, 450))
	assert_that(ScreenLayout.CORRIDOR).is_equal(Rect2(320, 0, 160, 450))
	assert_that(ScreenLayout.P2_ZONE).is_equal(Rect2(480, 0, 320, 450))


func test_screen_layout_zones_are_contiguous() -> void:
	# AC-2b: zones share boundaries with no gaps or overlaps; total = CANVAS_W
	assert_float(ScreenLayout.P1_ZONE.end.x).is_equal(ScreenLayout.CORRIDOR.position.x)
	assert_float(ScreenLayout.CORRIDOR.end.x).is_equal(ScreenLayout.P2_ZONE.position.x)
	var total_w: float = ScreenLayout.P1_ZONE.size.x + ScreenLayout.CORRIDOR.size.x + ScreenLayout.P2_ZONE.size.x
	assert_float(total_w).is_equal(float(ScreenLayout.CANVAS_W))


func test_screen_layout_anchor_positions_match_spec() -> void:
	# AC-3: P1_ANCHOR and P2_ANCHOR exact values
	assert_that(ScreenLayout.P1_ANCHOR).is_equal(Vector2(200, 338))
	assert_that(ScreenLayout.P2_ANCHOR).is_equal(Vector2(600, 338))


func test_screen_layout_p1_anchor_is_within_zone_and_below_hud() -> void:
	# AC-4: P1 anchor x within P1_ZONE x-range; y below HUD strip
	assert_float(ScreenLayout.P1_ANCHOR.x).is_greater_equal(ScreenLayout.P1_ZONE.position.x)
	assert_float(ScreenLayout.P1_ANCHOR.x).is_less(ScreenLayout.P1_ZONE.end.x)
	assert_float(ScreenLayout.P1_ANCHOR.y).is_greater(float(ScreenLayout.HUD_H))


func test_screen_layout_p2_anchor_is_within_zone_and_below_hud() -> void:
	# AC-4: P2 anchor x within P2_ZONE x-range; y below HUD strip
	assert_float(ScreenLayout.P2_ANCHOR.x).is_greater_equal(ScreenLayout.P2_ZONE.position.x)
	assert_float(ScreenLayout.P2_ANCHOR.x).is_less(ScreenLayout.P2_ZONE.end.x)
	assert_float(ScreenLayout.P2_ANCHOR.y).is_greater(float(ScreenLayout.HUD_H))


func test_screen_layout_zones_fill_canvas_exactly() -> void:
	# Zones flush with left/right canvas edges; all zone heights equal CANVAS_H
	assert_float(ScreenLayout.P1_ZONE.position.x).is_equal(0.0)
	assert_float(ScreenLayout.P2_ZONE.end.x).is_equal(float(ScreenLayout.CANVAS_W))
	assert_float(ScreenLayout.P1_ZONE.size.y).is_equal(float(ScreenLayout.CANVAS_H))
	assert_float(ScreenLayout.CORRIDOR.size.y).is_equal(float(ScreenLayout.CANVAS_H))
	assert_float(ScreenLayout.P2_ZONE.size.y).is_equal(float(ScreenLayout.CANVAS_H))
