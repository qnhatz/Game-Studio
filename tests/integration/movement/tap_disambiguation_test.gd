extends GdUnitTestSuite

# Integration test: InputSystem tap disambiguation → Movement → FigureGeometry
#
# TAP_MOVE_RADIUS_PX = 12.0 (InputSystem constant)
# P1 default anchor: Vector2(200, 338)
# Tests simulate pointer-down then pointer-up and check routing via MockTurnSystem.

var _fg: FigureGeometry
var _mv: Movement
var _is: InputSystem
var _mock_ts: MockTurnSystem


func before_each() -> void:
	_fg = FigureGeometry.new()
	add_child(_fg)

	_mock_ts = MockTurnSystem.new()
	add_child(_mock_ts)

	_is = InputSystem.new()
	_is._figure_geometry = _fg
	_is._two_action_turn_system = _mock_ts
	add_child(_is)

	_mv = Movement.new()
	_mv._figure_geometry = _fg
	add_child(_mv)

	# Open the action window for P1
	_is.open_window(0)


func after_each() -> void:
	_mv.queue_free()
	_is.queue_free()
	_mock_ts.queue_free()
	_fg.queue_free()


# AC-1: Short tap (displacement < TAP_MOVE_RADIUS_PX=12) routes to on_move_tapped
func test_tap_disambiguation_short_tap_routes_to_move_tapped() -> void:
	# Arrange: pointer-down at anchor, pointer-up 8px right (< 12px threshold)
	var start: Vector2 = _fg.get_anchor(0)  # (200, 338)
	var end_pos: Vector2 = start + Vector2(8.0, 0.0)

	# Act:
	_is._on_pointer_down(-1, start)
	_is._on_pointer_up(end_pos)

	# Assert: move_tapped called, fire NOT called
	assert_bool(_mock_ts.move_tapped_called).is_true()
	assert_bool(_mock_ts.action_selected_called).is_false()


# AC-1: Short tap routes with correct player_id
func test_tap_disambiguation_short_tap_passes_correct_player_id() -> void:
	var start: Vector2 = _fg.get_anchor(0)
	_is._on_pointer_down(-1, start)
	_is._on_pointer_up(start + Vector2(8.0, 0.0))
	assert_int(_mock_ts.move_tapped_player_id).is_equal(0)


# AC-2: Long drag (displacement ≥ TAP_MOVE_RADIUS_PX) routes to on_action_selected FIRE
func test_tap_disambiguation_long_drag_routes_to_fire() -> void:
	# Arrange: 30px displacement >> 12px threshold
	var start: Vector2 = _fg.get_anchor(0)
	var end_pos: Vector2 = start + Vector2(30.0, 0.0)

	# Act:
	_is._on_pointer_down(-1, start)
	_is._on_pointer_up(end_pos)

	# Assert: action_selected FIRE called, move NOT called
	assert_bool(_mock_ts.action_selected_called).is_true()
	assert_str(_mock_ts.action_selected_type).is_equal("FIRE")
	assert_bool(_mock_ts.move_tapped_called).is_false()


# AC-2: Displacement exactly at threshold (12px) routes to FIRE (>= check)
func test_tap_disambiguation_displacement_at_threshold_routes_to_fire() -> void:
	var start: Vector2 = _fg.get_anchor(0)
	_is._on_pointer_down(-1, start)
	_is._on_pointer_up(start + Vector2(12.0, 0.0))
	assert_bool(_mock_ts.action_selected_called).is_true()
	assert_bool(_mock_ts.move_tapped_called).is_false()


# AC-3: Same-frame anchor update — full routing chain InputSystem → MockTurnSystem → Movement → FigureGeometry
func test_tap_disambiguation_move_updates_anchor_same_frame() -> void:
	# Arrange: wire MockTurnSystem to forward on_move_tapped calls to Movement
	_mock_ts._movement = _mv
	var start: Vector2 = _fg.get_anchor(0)  # (200, 338)

	# Act: 8px displacement < 12px threshold → routes to MOVE path
	_is._on_pointer_down(-1, start)
	_is._on_pointer_up(start + Vector2(8.0, 0.0))

	# Assert: anchor updated synchronously through the full routing chain
	assert_float(_fg.get_anchor(0).x).is_equal_approx(208.0, 0.001)


# Displacement of 11px (just below threshold) routes to MOVE
func test_tap_disambiguation_11px_displacement_routes_to_move() -> void:
	var start: Vector2 = _fg.get_anchor(0)
	_is._on_pointer_down(-1, start)
	_is._on_pointer_up(start + Vector2(11.0, 0.0))
	assert_bool(_mock_ts.move_tapped_called).is_true()
	assert_bool(_mock_ts.action_selected_called).is_false()
