extends GdUnitTestSuite

# P1 default anchor: Vector2(200, 338)
# MAX_DRAG_PX = 150.0, AIM_LINE_MAX_LENGTH = 200.0
#
# Note: Tests access _tv._aim_line directly (GDScript has no true access modifiers).
# This is an intentional coupling for Story 001 scope. Story 003 will establish
# the full scene structure; these unit tests validate logic only.

var _fg: FigureGeometry
var _tv: TrajectoryVisualization


func before_each() -> void:
	_fg = FigureGeometry.new()
	add_child(_fg)
	_tv = TrajectoryVisualization.new()
	_tv._figure_geometry = _fg
	add_child(_tv)  # triggers _ready, creating _aim_line


func after_each() -> void:
	_tv.queue_free()
	_fg.queue_free()


# AC-1: Aim line length at full power (dist=150 = MAX_DRAG_PX → power=1.0 → length=200)
func test_trajectory_visualization_full_power_aim_length_is_200px() -> void:
	_tv._on_aim_updated(0, Vector2(350.0, 338.0))
	var anchor: Vector2 = _fg.get_anchor(0)
	var length: float = anchor.distance_to(_tv._aim_line.points[1])
	assert_float(length).is_equal_approx(200.0, 0.5)


# AC-1 edge: half power (dist=75 → power=0.5 → length=100)
func test_trajectory_visualization_half_power_aim_length_is_100px() -> void:
	_tv._on_aim_updated(0, Vector2(275.0, 338.0))
	var anchor: Vector2 = _fg.get_anchor(0)
	var length: float = anchor.distance_to(_tv._aim_line.points[1])
	assert_float(length).is_equal_approx(100.0, 0.5)


# AC-1/2: Start point of aim line is the figure anchor
func test_trajectory_visualization_aim_line_start_is_anchor() -> void:
	_tv._on_aim_updated(0, Vector2(350.0, 338.0))
	var anchor: Vector2 = _fg.get_anchor(0)
	assert_vector2(_tv._aim_line.points[0]).is_equal_approx(anchor, Vector2(0.001, 0.001))


# AC-2: Slingshot — dragging right makes aim direction point left (negative X)
func test_trajectory_visualization_drag_right_aim_direction_points_left() -> void:
	_tv._on_aim_updated(0, Vector2(350.0, 338.0))
	var aim_dir: Vector2 = (_tv._aim_line.points[1] - _tv._aim_line.points[0]).normalized()
	assert_float(aim_dir.x).is_less(0.0)


# AC-2: Dragging down makes aim direction point up (negative Y)
func test_trajectory_visualization_drag_down_aim_direction_points_up() -> void:
	_tv._on_aim_updated(0, Vector2(200.0, 488.0))
	var aim_dir: Vector2 = (_tv._aim_line.points[1] - _tv._aim_line.points[0]).normalized()
	assert_float(aim_dir.y).is_less(0.0)


# AC-3: Endpoint clamped to canvas — x never below 0
func test_trajectory_visualization_endpoint_clamped_x_not_below_zero() -> void:
	_tv._on_aim_updated(0, Vector2(600.0, 338.0))  # large drag right → aim far left
	var endpoint: Vector2 = _tv._aim_line.points[1]
	assert_float(endpoint.x).is_greater_equal(0.0)


# AC-3: x never exceeds 800
func test_trajectory_visualization_endpoint_clamped_x_not_above_800() -> void:
	_tv._on_aim_updated(0, Vector2(50.0, 338.0))  # drag left → aim right
	var endpoint: Vector2 = _tv._aim_line.points[1]
	assert_float(endpoint.x).is_less_equal(800.0)


# AC-3: y never exceeds 450
func test_trajectory_visualization_endpoint_clamped_y_not_above_450() -> void:
	_tv._on_aim_updated(0, Vector2(200.0, 0.0))  # drag up → aim down
	var endpoint: Vector2 = _tv._aim_line.points[1]
	assert_float(endpoint.y).is_less_equal(450.0)


# AC-3: y never below 0
func test_trajectory_visualization_endpoint_clamped_y_not_below_zero() -> void:
	_tv._on_aim_updated(0, Vector2(200.0, 600.0))  # large drag down → aim far up
	var endpoint: Vector2 = _tv._aim_line.points[1]
	assert_float(endpoint.y).is_greater_equal(0.0)


# AC-4: Cancelled drag hides the aim line
func test_trajectory_visualization_aim_cancelled_hides_line() -> void:
	_tv._on_aim_updated(0, Vector2(350.0, 338.0))
	_tv._on_aim_cancelled()
	assert_bool(_tv._aim_line.visible).is_false()


# AC-5: Flick event emitted hides the aim line
func test_trajectory_visualization_flick_event_emitted_hides_aim_line() -> void:
	_tv._on_aim_updated(0, Vector2(350.0, 338.0))
	var event := FlickEvent.new(Vector2(1.0, 0.0), 0.5, 0)
	_tv._on_flick_event_emitted(0, event)
	assert_bool(_tv._aim_line.visible).is_false()


# Line is visible after aim_updated
func test_trajectory_visualization_aim_updated_shows_line() -> void:
	_tv._on_aim_updated(0, Vector2(350.0, 338.0))
	assert_bool(_tv._aim_line.visible).is_true()


# Sub-pixel drag (dist < 1.0) does not update points
func test_trajectory_visualization_sub_pixel_drag_does_not_update_points() -> void:
	var initial_size: int = _tv._aim_line.points.size()
	_tv._on_aim_updated(0, Vector2(200.5, 338.0))
	assert_int(_tv._aim_line.points.size()).is_equal(initial_size)
