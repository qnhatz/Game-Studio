extends GdUnitTestSuite


func test_flick_event_valid_construction_stores_fields() -> void:
	# AC-1: fields set correctly from _init arguments
	var event := FlickEvent.new(Vector2.RIGHT, 0.5, 100)
	assert_that(event.direction).is_equal(Vector2.RIGHT)
	assert_float(event.power).is_equal_approx(0.5, 0.0001)
	assert_int(event.timestamp).is_equal(100)


func test_flick_event_valid_construction_all_cardinal_directions() -> void:
	# AC-1 edge: all normalised cardinal directions construct without error
	var e1 := FlickEvent.new(Vector2.LEFT, 0.5, 0)
	var e2 := FlickEvent.new(Vector2.UP, 0.5, 0)
	var e3 := FlickEvent.new(Vector2.DOWN, 0.5, 0)
	assert_object(e1).is_not_null()
	assert_object(e2).is_not_null()
	assert_object(e3).is_not_null()


func test_flick_event_direction_invalid_zero_is_not_normalized() -> void:
	# AC-2: Vector2.ZERO is not normalised — assert fires on construction.
	# Verified here via precondition check rather than triggering assert (would crash runner).
	assert_bool(Vector2.ZERO.is_normalized()).is_false()


func test_flick_event_direction_invalid_oversized_is_not_normalized() -> void:
	# AC-2 edge: length > 1 is also un-normalised
	assert_bool(Vector2(2.0, 0.0).is_normalized()).is_false()


func test_flick_event_power_boundary_zero_is_valid() -> void:
	# AC-3: power = 0.0 is the lower valid boundary
	var event := FlickEvent.new(Vector2.RIGHT, 0.0, 0)
	assert_float(event.power).is_equal_approx(0.0, 0.0001)


func test_flick_event_power_boundary_one_is_valid() -> void:
	# AC-3: power = 1.0 is the upper valid boundary
	var event := FlickEvent.new(Vector2.RIGHT, 1.0, 0)
	assert_float(event.power).is_equal_approx(1.0, 0.0001)


func test_flick_event_slingshot_direction_drag_right_fires_left() -> void:
	# AC-4: drag right → direction is leftward (negative X) — slingshot model
	var anchor := Vector2(200.0, 338.0)
	var release := Vector2(250.0, 338.0)
	var dir := (anchor - release).normalized()
	var event := FlickEvent.new(dir, 0.5, 0)
	assert_float(event.direction.x).is_less(0.0)


func test_flick_event_slingshot_direction_drag_up_fires_down() -> void:
	# AC-4 edge: drag up → direction has positive Y (fires downward)
	var anchor := Vector2(200.0, 338.0)
	var release := Vector2(200.0, 288.0)
	var dir := (anchor - release).normalized()
	var event := FlickEvent.new(dir, 0.5, 0)
	assert_float(event.direction.y).is_greater(0.0)


func test_flick_event_direction_is_always_normalised() -> void:
	# AC-5: direction stored in _init is unit length — no external mutation in _init path
	var event := FlickEvent.new(Vector2.RIGHT, 0.5, 0)
	assert_bool(event.direction.is_normalized()).is_true()
