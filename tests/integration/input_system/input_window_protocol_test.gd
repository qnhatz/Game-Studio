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


## Minimal node exposing a .visible property for the orientation gate.
## Node has no native .visible (not a CanvasItem) — this member is safe to declare here.
class OrientationGateStub extends Node:
	var visible: bool = false


var _system: InputSystem
var _geometry_stub: FigureGeometryStub
var _turn_stub: TurnSystemStub
var _gate_stub: OrientationGateStub


func before_each() -> void:
	_geometry_stub = FigureGeometryStub.new()
	_turn_stub = TurnSystemStub.new()
	_gate_stub = OrientationGateStub.new()
	_system = InputSystem.new()
	_system._figure_geometry = _geometry_stub
	_system._two_action_turn_system = _turn_stub
	_system._orientation_gate = _gate_stub
	_system._canvas_size = Vector2(800.0, 450.0)
	add_child(_system)
	add_child(_geometry_stub)
	add_child(_turn_stub)
	add_child(_gate_stub)


func after_each() -> void:
	_system.free()
	_geometry_stub.free()
	_turn_stub.free()
	_gate_stub.free()


# ---------------------------------------------------------------------------
# AC-1: Window closed → gesture discarded
# ---------------------------------------------------------------------------

func test_input_system_window_closed_by_default_discards_pointer_down() -> void:
	# _window_open is false; open_window() was never called
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	assert_bool(_system._dragging).is_false()


func test_input_system_window_closed_emits_no_flick_event_via_input_events() -> void:
	# Routes through _input() to exercise the _window_open gate, not _on_pointer_up directly
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(200.0, 338.0)
	_system._input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(250.0, 338.0)
	_system._input(release)
	assert_int(emitted.size()).is_equal(0)


func test_input_system_window_closed_by_close_window_discards_subsequent_gesture() -> void:
	_system.open_window(0)
	_system.close_window()
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	assert_bool(_system._dragging).is_false()


func test_input_system_window_closed_emits_no_aim_cancelled_on_discarded_up() -> void:
	# close_window already fired aim_cancelled; a subsequent no-op up emits nothing extra
	var cancelled_count := 0
	_system.aim_cancelled.connect(func(): cancelled_count += 1)
	_system.open_window(0)
	_system.close_window()  # emits once here
	cancelled_count = 0  # reset counter after close_window
	_system._on_pointer_up(Vector2(250.0, 338.0))
	assert_int(cancelled_count).is_equal(0)


# ---------------------------------------------------------------------------
# AC-2: open_window() arms the system
# ---------------------------------------------------------------------------

func test_input_system_open_window_sets_active_player_id() -> void:
	_system.open_window(1)
	assert_int(_system._active_player_id).is_equal(1)


func test_input_system_open_window_sets_window_open_true() -> void:
	_system.open_window(0)
	assert_bool(_system._window_open).is_true()


func test_input_system_open_window_resets_touch_id_to_sentinel() -> void:
	_system._touch_id = 3  # simulate prior touch state
	_system.open_window(0)
	assert_int(_system._touch_id).is_equal(-1)


func test_input_system_open_window_clears_dragging_flag() -> void:
	_system._dragging = true  # simulate mid-drag state
	_system.open_window(0)
	assert_bool(_system._dragging).is_false()


func test_input_system_open_window_replaces_previous_player_id() -> void:
	_system.open_window(1)
	_system.open_window(0)
	assert_int(_system._active_player_id).is_equal(0)


# ---------------------------------------------------------------------------
# AC-3: close_window() disarms and emits aim_cancelled
# ---------------------------------------------------------------------------

func test_input_system_close_window_sets_window_open_false() -> void:
	_system.open_window(0)
	_system.close_window()
	assert_bool(_system._window_open).is_false()


func test_input_system_close_window_resets_touch_id() -> void:
	_system.open_window(0)
	_system._touch_id = 2
	_system.close_window()
	assert_int(_system._touch_id).is_equal(-1)


func test_input_system_close_window_clears_dragging() -> void:
	_system.open_window(0)
	_system._dragging = true
	_system.close_window()
	assert_bool(_system._dragging).is_false()


func test_input_system_close_window_emits_aim_cancelled() -> void:
	var cancelled := false
	_system.aim_cancelled.connect(func(): cancelled = true)
	_system.open_window(0)
	_system.close_window()
	assert_bool(cancelled).is_true()


func test_input_system_close_window_mid_drag_clears_drag_state() -> void:
	_system.open_window(0)
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	assert_bool(_system._dragging).is_true()
	_system.close_window()
	assert_bool(_system._dragging).is_false()


# ---------------------------------------------------------------------------
# AC-4: Orientation gate visible → all input discarded
# ---------------------------------------------------------------------------

func test_input_system_orientation_gate_visible_discards_pointer_down() -> void:
	_system.open_window(0)
	_gate_stub.visible = true
	var touch := InputEventMouseButton.new()
	touch.button_index = MOUSE_BUTTON_LEFT
	touch.pressed = true
	touch.position = Vector2(200.0, 338.0)
	_system._input(touch)
	assert_bool(_system._dragging).is_false()


func test_input_system_orientation_gate_visible_emits_no_aim_updated() -> void:
	_system.open_window(0)
	_gate_stub.visible = true
	var emitted: Array[Vector2] = []
	_system.aim_updated.connect(func(_pid, pos): emitted.append(pos))
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(210.0, 338.0)
	_system._touch_id = -1
	_system._dragging = true  # force dragging state to test aim_updated suppression
	_system._input(motion)
	assert_int(emitted.size()).is_equal(0)


func test_input_system_orientation_gate_visible_emits_no_flick_event() -> void:
	_system.open_window(0)
	_gate_stub.visible = true
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(250.0, 338.0)
	_system._input(release)
	assert_int(emitted.size()).is_equal(0)


func test_input_system_orientation_gate_hidden_allows_gesture() -> void:
	_system.open_window(0)
	_gate_stub.visible = false  # gate hidden
	_system._on_pointer_down(-1, Vector2(200.0, 338.0))
	assert_bool(_system._dragging).is_true()
