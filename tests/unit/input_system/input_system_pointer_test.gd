extends GdUnitTestSuite

## Stub returning a fixed anchor position.
class FigureGeometryStub extends Node:
	var anchor: Vector2 = Vector2(200.0, 338.0)
	func get_anchor(_player_id: int) -> Vector2:
		return anchor

## Stub that records on_action_selected() calls.
class TurnSystemStub extends Node:
	var call_count: int = 0
	var last_event: FlickEvent = null
	func on_action_selected(_player_id: int, _action: StringName, event: FlickEvent) -> void:
		call_count += 1
		last_event = event

var _system: InputSystem
var _geometry_stub: FigureGeometryStub
var _turn_stub: TurnSystemStub


func before_each() -> void:
	_geometry_stub = FigureGeometryStub.new()
	_turn_stub = TurnSystemStub.new()
	_system = InputSystem.new()
	_system._figure_geometry = _geometry_stub
	_system._two_action_turn_system = _turn_stub
	_system._canvas_size = Vector2(800.0, 450.0)
	_system._window_open = true
	_system._active_player_id = 0
	add_child(_system)
	add_child(_geometry_stub)
	add_child(_turn_stub)


func after_each() -> void:
	_system.free()
	_geometry_stub.free()
	_turn_stub.free()


# ---------------------------------------------------------------------------
# AC-1: Origin check — drag outside 48px radius is ignored
# ---------------------------------------------------------------------------

func test_input_system_drag_outside_radius_does_not_start_drag() -> void:
	# 50px from anchor — beyond FIGURE_DRAG_RADIUS_PX (48)
	_system._on_pointer_down(-1, Vector2(250.0, 338.0))
	assert_bool(_system._dragging).is_false()


func test_input_system_drag_outside_radius_emits_no_flick_event() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(250.0, 338.0))
	_system._on_pointer_up(Vector2(300.0, 338.0))
	assert_int(emitted.size()).is_equal(0)


func test_input_system_drag_at_exact_radius_is_accepted() -> void:
	# Exactly 48px — boundary is inclusive (≤)
	_system._on_pointer_down(-1, Vector2(248.0, 338.0))
	assert_bool(_system._dragging).is_true()


# ---------------------------------------------------------------------------
# AC-2: Power formula — 75px drag → power = 0.5
# ---------------------------------------------------------------------------

func test_input_system_power_formula_75px_drag_produces_half_power() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(275.0, 338.0))  # 75px right of anchor
	assert_int(emitted.size()).is_equal(1)
	assert_float(emitted[0].power).is_equal_approx(0.5, 0.0001)


func test_input_system_power_formula_200px_drag_clamped_to_one() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(400.0, 338.0))  # 200px — beyond MAX_DRAG_PX
	assert_int(emitted.size()).is_equal(1)
	assert_float(emitted[0].power).is_equal_approx(1.0, 0.0001)


# ---------------------------------------------------------------------------
# AC-3: Cancellation — drag shorter than 7.5px emits no FlickEvent
# ---------------------------------------------------------------------------

func test_input_system_cancel_7px_drag_emits_no_flick_event() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(207.0, 338.0))  # 7px < 7.5px threshold
	assert_int(emitted.size()).is_equal(0)


func test_input_system_cancel_7px_drag_emits_aim_cancelled() -> void:
	var cancelled := false
	_system.aim_cancelled.connect(func(): cancelled = true)
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(207.0, 338.0))
	assert_bool(cancelled).is_true()


func test_input_system_cancel_does_not_call_on_action_selected() -> void:
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(207.0, 338.0))
	assert_int(_turn_stub.call_count).is_equal(0)


func test_input_system_boundary_7_5px_drag_fires_flick_event() -> void:
	# 7.5px = 150 × 0.05 exactly — power == MIN_POWER, should fire
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(207.5, 338.0))
	assert_int(emitted.size()).is_equal(1)
	assert_float(emitted[0].power).is_equal_approx(0.05, 0.0001)


# ---------------------------------------------------------------------------
# AC-4: Slingshot direction — drag right fires left
# ---------------------------------------------------------------------------

func test_input_system_slingshot_drag_right_direction_is_leftward() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(250.0, 338.0))  # drag right
	assert_int(emitted.size()).is_equal(1)
	assert_float(emitted[0].direction.x).is_less(0.0)
	assert_bool(emitted[0].direction.is_normalized()).is_true()


func test_input_system_slingshot_drag_up_direction_is_downward() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(200.0, 288.0))  # drag up
	assert_int(emitted.size()).is_equal(1)
	assert_float(emitted[0].direction.y).is_greater(0.0)


# ---------------------------------------------------------------------------
# AC-5: Multi-touch — second touch does not override first
# ---------------------------------------------------------------------------

func test_input_system_second_touch_does_not_change_touch_id() -> void:
	_system._on_pointer_down(0, Vector2(200.0, 338.0))  # touch 0 starts drag
	assert_int(_system._touch_id).is_equal(0)
	_system._on_pointer_down(1, Vector2(100.0, 200.0))  # touch 1 arrives mid-drag
	assert_int(_system._touch_id).is_equal(0)


func test_input_system_second_touch_does_not_override_drag_start() -> void:
	_system._on_pointer_down(0, Vector2(200.0, 338.0))
	var original_drag_start := _system._drag_start
	_system._on_pointer_down(1, Vector2(100.0, 200.0))
	assert_that(_system._drag_start).is_equal(original_drag_start)


func test_input_system_second_touch_up_does_not_emit_flick_event() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(0, Vector2(200.0, 338.0))
	# Touch 1 releases — index != _touch_id, should be ignored
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 1
	touch_up.pressed = false
	touch_up.position = Vector2(100.0, 200.0)
	_system._input(touch_up)
	assert_int(emitted.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC-6: Endpoint clamp — drag beyond canvas boundary still fires
# ---------------------------------------------------------------------------

func test_input_system_endpoint_below_canvas_is_clamped_and_fires() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(200.0, 600.0))  # below canvas (max 450)
	assert_int(emitted.size()).is_equal(1)
	# Clamped release: (200, 450) — dist from anchor (200,338) = 112px → power ≈ 0.747
	assert_float(emitted[0].power).is_equal_approx(112.0 / 150.0, 0.001)


func test_input_system_endpoint_left_of_canvas_is_clamped_and_fires() -> void:
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	_system._on_pointer_up(Vector2(-50.0, 338.0))  # left of canvas (min 0)
	assert_int(emitted.size()).is_equal(1)
	# Clamped release: (0, 338) — dist = 200px → clamped to power 1.0
	assert_float(emitted[0].power).is_equal_approx(1.0, 0.0001)
