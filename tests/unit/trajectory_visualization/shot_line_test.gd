extends GdUnitTestSuite

# Note: AC-3 (fade opacity timing) requires a live Tween timeline and cannot be
# unit-tested without time control. The tween sequence is verified structurally
# (tween added to _shot_tweens) and the formula is encoded in the constants
# SHOT_LINE_DISPLAY_MS=2000 and SHOT_LINE_FADE_MS=600. Integration test required
# for full timing verification.

var _fg: FigureGeometry
var _tv: TrajectoryVisualization


func before_each() -> void:
	_fg = FigureGeometry.new()
	add_child(_fg)
	_tv = TrajectoryVisualization.new()
	_tv._figure_geometry = _fg
	add_child(_tv)


func after_each() -> void:
	_tv.queue_free()
	_fg.queue_free()


# AC-1: Canvas exit — horizontal right: origin=(200,338), dir=(1,0) → endpoint=(800,338)
func test_trajectory_visualization_canvas_exit_horizontal_right_hits_right_edge() -> void:
	var exit: Vector2 = _tv._compute_canvas_exit(Vector2(200.0, 338.0), Vector2(1.0, 0.0))
	assert_vector2(exit).is_equal_approx(Vector2(800.0, 338.0), Vector2(0.5, 0.5))


# AC-1: Vertical up: origin=(200,338), dir=(0,-1) → endpoint=(200,0)
func test_trajectory_visualization_canvas_exit_vertical_up_hits_top_edge() -> void:
	var exit: Vector2 = _tv._compute_canvas_exit(Vector2(200.0, 338.0), Vector2(0.0, -1.0))
	assert_vector2(exit).is_equal_approx(Vector2(200.0, 0.0), Vector2(0.5, 0.5))


# AC-1: Vertical down: origin=(200,338), dir=(0,1) → endpoint=(200,450)
func test_trajectory_visualization_canvas_exit_vertical_down_hits_bottom_edge() -> void:
	var exit: Vector2 = _tv._compute_canvas_exit(Vector2(200.0, 338.0), Vector2(0.0, 1.0))
	assert_vector2(exit).is_equal_approx(Vector2(200.0, 450.0), Vector2(0.5, 0.5))


# AC-1: Horizontal left: origin=(200,338), dir=(-1,0) → endpoint=(0,338)
func test_trajectory_visualization_canvas_exit_horizontal_left_hits_left_edge() -> void:
	var exit: Vector2 = _tv._compute_canvas_exit(Vector2(200.0, 338.0), Vector2(-1.0, 0.0))
	assert_vector2(exit).is_equal_approx(Vector2(0.0, 338.0), Vector2(0.5, 0.5))


# AC-1: Exit point is always on the canvas boundary
func test_trajectory_visualization_canvas_exit_diagonal_lands_on_canvas_boundary() -> void:
	var dir: Vector2 = Vector2(1.0, -1.0).normalized()
	var exit: Vector2 = _tv._compute_canvas_exit(Vector2(200.0, 338.0), dir)
	var on_boundary: bool = (
		absf(exit.x) < 0.5 or absf(exit.x - 800.0) < 0.5 or
		absf(exit.y) < 0.5 or absf(exit.y - 450.0) < 0.5
	)
	assert_bool(on_boundary).is_true()


# AC-2: Shot line uses resolved_direction from FlickEvent (not raw drag)
func test_trajectory_visualization_shot_line_endpoint_uses_flick_event_direction() -> void:
	var event := FlickEvent.new(Vector2(1.0, 0.0), 0.8, 0)
	_tv._on_flick_event_emitted(0, event)
	var line: Line2D = _tv._shot_lines[0]
	# Endpoint should be on right canvas edge for rightward shot
	assert_float(line.points[1].x).is_equal_approx(800.0, 1.0)


# AC-2: Shot line start point is the player's anchor
func test_trajectory_visualization_shot_line_starts_at_anchor() -> void:
	var event := FlickEvent.new(Vector2(1.0, 0.0), 0.8, 0)
	_tv._on_flick_event_emitted(0, event)
	var anchor: Vector2 = _fg.get_anchor(0)
	assert_vector2(_tv._shot_lines[0].points[0]).is_equal_approx(anchor, Vector2(0.001, 0.001))


# AC-3 structural: A tween is created for each shot line
func test_trajectory_visualization_draw_shot_line_creates_tween_entry() -> void:
	_tv._draw_shot_line(Vector2(200.0, 338.0), Vector2(1.0, 0.0), Color.WHITE)
	assert_int(_tv._shot_tweens.size()).is_equal(1)


# AC-5: Cancelled drag does not create a shot line
func test_trajectory_visualization_aim_cancelled_does_not_add_shot_line() -> void:
	_tv._on_aim_cancelled()
	assert_int(_tv._shot_lines.size()).is_equal(0)


# AC-6: MAX_VISIBLE_SHOT_LINES cap — drawing 7 keeps size at 6
func test_trajectory_visualization_max_visible_shot_lines_capped_at_6() -> void:
	var dir: Vector2 = Vector2(1.0, 0.0)
	for i in range(7):
		_tv._draw_shot_line(Vector2(200.0, 338.0), dir, Color.WHITE)
	assert_int(_tv._shot_lines.size()).is_equal(6)
	assert_int(_tv._shot_tweens.size()).is_equal(6)


# AC-6: After cap, oldest line is removed first
func test_trajectory_visualization_oldest_shot_line_removed_when_cap_exceeded() -> void:
	for i in range(6):
		_tv._draw_shot_line(Vector2(float(i) * 10.0 + 100.0, 338.0), Vector2(1.0, 0.0), Color.WHITE)
	var expected_first_x: float = _tv._shot_lines[0].points[0].x
	# Draw 7th — first should be replaced by the second original
	_tv._draw_shot_line(Vector2(200.0, 338.0), Vector2(1.0, 0.0), Color.WHITE)
	# New oldest should have been the second line (x = 110)
	assert_float(_tv._shot_lines[0].points[0].x).is_not_equal(expected_first_x)


# AC-7: freeze() sets _frozen flag
func test_trajectory_visualization_freeze_sets_frozen_flag() -> void:
	_tv.freeze()
	assert_bool(_tv._frozen).is_true()


# AC-7: freeze() kills all active tweens (tween.is_running() returns false after kill)
func test_trajectory_visualization_freeze_kills_active_tweens() -> void:
	_tv._draw_shot_line(Vector2(200.0, 338.0), Vector2(1.0, 0.0), Color.WHITE)
	var tween: Tween = _tv._shot_tweens[0]
	_tv.freeze()
	assert_bool(tween.is_running()).is_false()


# AC-7: freeze() is idempotent — calling twice keeps _frozen true
func test_trajectory_visualization_freeze_twice_remains_frozen() -> void:
	_tv.freeze()
	_tv.freeze()
	assert_bool(_tv._frozen).is_true()


# AC-8: reset() clears shot lines array
func test_trajectory_visualization_reset_clears_shot_lines() -> void:
	_tv._draw_shot_line(Vector2(200.0, 338.0), Vector2(1.0, 0.0), Color.WHITE)
	_tv._draw_shot_line(Vector2(200.0, 338.0), Vector2(0.0, -1.0), Color.WHITE)
	_tv.reset()
	assert_int(_tv._shot_lines.size()).is_equal(0)


# AC-8: reset() clears tweens array
func test_trajectory_visualization_reset_clears_tweens() -> void:
	_tv._draw_shot_line(Vector2(200.0, 338.0), Vector2(1.0, 0.0), Color.WHITE)
	_tv.reset()
	assert_int(_tv._shot_tweens.size()).is_equal(0)


# AC-8: reset() resets _frozen flag
func test_trajectory_visualization_reset_clears_frozen_flag() -> void:
	_tv.freeze()
	_tv.reset()
	assert_bool(_tv._frozen).is_false()
