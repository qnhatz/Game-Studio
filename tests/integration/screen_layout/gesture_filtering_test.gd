extends GdUnitTestSuite

## Stub returning a configurable anchor position.
class FigureGeometryStub extends Node:
	var anchor: Vector2 = Vector2(200.0, 200.0)
	func get_anchor(_player_id: int) -> Vector2:
		return anchor


## Stub that records on_action_selected() calls.
class TurnSystemStub extends Node:
	var call_count: int = 0
	func on_action_selected(_player_id: int, _action: StringName, _event: FlickEvent) -> void:
		call_count += 1


## Stub with configurable visible property for the orientation gate.
class OrientationGateStub extends Node:
	## Node has no native .visible — this member is safe to declare here.
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


func _open_p1() -> void:
	_system.open_window(0)
	# Anchor inside P1 gesture rect so figure proximity check passes
	_geometry_stub.anchor = Vector2(160.0, 200.0)


func _open_p2() -> void:
	_system.open_window(1)
	# Anchor inside P2 gesture rect so figure proximity check passes
	_geometry_stub.anchor = Vector2(640.0, 200.0)


# ---------------------------------------------------------------------------
# AC-1: Boundary pixel x=320 (P1 zone right edge) is discarded
# P1 GESTURE_RECT = Rect2(0, 90, 320, 360) → end.x = 320, excluded by has_point
# ---------------------------------------------------------------------------

func test_gesture_filtering_p1_right_boundary_x320_discards_drag() -> void:
	_open_p1()
	_system._on_pointer_down(-1, Vector2(320.0, 200.0))
	assert_bool(_system._dragging).is_false()


func test_gesture_filtering_p1_right_boundary_x320_calls_no_action_selected() -> void:
	_open_p1()
	_system._on_pointer_down(-1, Vector2(320.0, 200.0))
	_system._on_pointer_up(Vector2(320.0, 200.0))
	assert_int(_turn_stub.call_count).is_equal(0)


func test_gesture_filtering_p1_inside_x319_accepts_drag() -> void:
	_open_p1()
	_geometry_stub.anchor = Vector2(319.0, 200.0)
	_system._on_pointer_down(-1, Vector2(319.0, 200.0))
	assert_bool(_system._dragging).is_true()


# ---------------------------------------------------------------------------
# AC-2: Boundary pixel x=480 (P2 zone left edge, start) — x=479 is Corridor
# P2 GESTURE_RECT = Rect2(480, 90, 320, 360) → position.x = 480, included
# x=479 is in Corridor — outside both gesture rects → discarded
# ---------------------------------------------------------------------------

func test_gesture_filtering_corridor_x479_discards_for_p2() -> void:
	_open_p2()
	_system._on_pointer_down(-1, Vector2(479.0, 200.0))
	assert_bool(_system._dragging).is_false()


func test_gesture_filtering_p2_start_boundary_x480_accepts_drag() -> void:
	_open_p2()
	_geometry_stub.anchor = Vector2(480.0, 200.0)
	_system._on_pointer_down(-1, Vector2(480.0, 200.0))
	assert_bool(_system._dragging).is_true()


func test_gesture_filtering_p2_inside_x481_accepts_drag() -> void:
	_open_p2()
	_geometry_stub.anchor = Vector2(481.0, 200.0)
	_system._on_pointer_down(-1, Vector2(481.0, 200.0))
	assert_bool(_system._dragging).is_true()


# ---------------------------------------------------------------------------
# AC-3: HUD strip y ∈ [0, 89] discarded — y=90 is the first valid row
# GESTURE_RECT position.y = 90 → included; y=89 → excluded
# ---------------------------------------------------------------------------

func test_gesture_filtering_hud_strip_y89_discards_drag() -> void:
	_open_p1()
	_system._on_pointer_down(-1, Vector2(200.0, 89.0))
	assert_bool(_system._dragging).is_false()


func test_gesture_filtering_hud_strip_y0_discards_drag() -> void:
	_open_p1()
	_system._on_pointer_down(-1, Vector2(200.0, 0.0))
	assert_bool(_system._dragging).is_false()


func test_gesture_filtering_first_valid_row_y90_accepts_drag() -> void:
	_open_p1()
	_geometry_stub.anchor = Vector2(160.0, 90.0)
	_system._on_pointer_down(-1, Vector2(160.0, 90.0))
	assert_bool(_system._dragging).is_true()


# ---------------------------------------------------------------------------
# AC-4: Corridor centre discarded — no player assigned ownership
# Corridor = x ∈ [320, 479] — neither P1 nor P2 GESTURE_RECT contains it
# ---------------------------------------------------------------------------

func test_gesture_filtering_corridor_centre_x400_discards_drag() -> void:
	_open_p1()
	_system._on_pointer_down(-1, Vector2(400.0, 200.0))
	assert_bool(_system._dragging).is_false()


func test_gesture_filtering_corridor_centre_emits_no_flick_event() -> void:
	_open_p1()
	var emitted: Array[FlickEvent] = []
	_system.flick_event_emitted.connect(func(_pid, ev): emitted.append(ev))
	_system._on_pointer_down(-1, Vector2(400.0, 200.0))
	_system._on_pointer_up(Vector2(450.0, 200.0))
	assert_int(emitted.size()).is_equal(0)


func test_gesture_filtering_corridor_centre_calls_no_action_selected() -> void:
	_open_p1()
	_system._on_pointer_down(-1, Vector2(400.0, 200.0))
	_system._on_pointer_up(Vector2(450.0, 200.0))
	assert_int(_turn_stub.call_count).is_equal(0)


func test_gesture_filtering_corridor_for_p2_discards_drag() -> void:
	_open_p2()
	_system._on_pointer_down(-1, Vector2(400.0, 200.0))
	assert_bool(_system._dragging).is_false()


# ---------------------------------------------------------------------------
# Canvas bottom edge — GESTURE_RECT end.y = 450, excluded by has_point
# ---------------------------------------------------------------------------

func test_gesture_filtering_last_valid_row_y449_accepts_drag() -> void:
	_open_p1()
	_geometry_stub.anchor = Vector2(160.0, 449.0)
	_system._on_pointer_down(-1, Vector2(160.0, 449.0))
	assert_bool(_system._dragging).is_true()


func test_gesture_filtering_canvas_bottom_y450_discards_drag() -> void:
	_open_p1()
	_system._on_pointer_down(-1, Vector2(160.0, 450.0))
	assert_bool(_system._dragging).is_false()
