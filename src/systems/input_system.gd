## Pointer state machine: converts mouse/touch drag gestures into FlickEvent objects.
class_name InputSystem
extends Node

signal flick_event_emitted(player_id: int, event: FlickEvent)
signal aim_updated(player_id: int, drag_end: Vector2)
signal aim_cancelled

const FIGURE_DRAG_RADIUS_PX: float = 48.0
const MAX_DRAG_PX: float = 150.0
const MIN_POWER: float = 0.05

var _window_open: bool = false
var _active_player_id: int = -1
## -1 = mouse sentinel; any other value = owning touch index
var _touch_id: int = -1
var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
## Cached canvas bounds — avoids constructing Vector2 on every drag event.
var _canvas_size: Vector2 = Vector2(ScreenLayout.CANVAS_W, ScreenLayout.CANVAS_H)

## Typed Node until FigureGeometry / TwoActionTurnSystem classes exist in the codebase.
## Duck-typed calls (get_anchor, on_action_selected) are intentional — retype to concrete
## class names once those stories are complete.
var _figure_geometry: Node = null
var _two_action_turn_system: Node = null
## CanvasLayer at Layer 20; injected via @onready in production, set directly in tests.
var _orientation_gate: Node = null


## Called by TwoActionTurnSystem when it is ready to receive a human action.
func open_window(player_id: int) -> void:
	_active_player_id = player_id
	_window_open = true
	_touch_id = -1
	_dragging = false


## Called by TwoActionTurnSystem on halt() or AI turn start.
func close_window() -> void:
	_window_open = false
	_dragging = false
	_touch_id = -1
	aim_cancelled.emit()


func _input(event: InputEvent) -> void:
	if _orientation_gate != null and _orientation_gate.visible:
		return
	if not _window_open:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_pointer_down(event.index, event.position)
		elif event.index == _touch_id:
			_on_pointer_up(event.position)
	elif event is InputEventScreenDrag:
		if event.index == _touch_id:
			_on_pointer_move(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_pointer_down(-1, event.position)
		elif _touch_id == -1:
			_on_pointer_up(event.position)
	elif event is InputEventMouseMotion:
		if _touch_id == -1 and _dragging:
			_on_pointer_move(event.position)


func _on_pointer_down(touch_id: int, pos: Vector2) -> void:
	if _dragging:
		return
	var zone: Rect2 = ScreenLayout.P1_ZONE if _active_player_id == 0 else ScreenLayout.P2_ZONE
	if not ScreenLayout.GESTURE_RECT(zone).has_point(pos):
		return
	var anchor: Vector2 = _figure_geometry.get_anchor(_active_player_id)
	if pos.distance_to(anchor) > FIGURE_DRAG_RADIUS_PX:
		return
	_touch_id = touch_id
	_drag_start = anchor
	_dragging = true


func _on_pointer_move(pos: Vector2) -> void:
	var clamped := pos.clamp(Vector2.ZERO, _canvas_size)
	aim_updated.emit(_active_player_id, clamped)


func _on_pointer_up(pos: Vector2) -> void:
	_dragging = false
	_window_open = false
	var clamped := pos.clamp(Vector2.ZERO, _canvas_size)
	var dist := (_drag_start - clamped).length()
	var power := clampf(dist / MAX_DRAG_PX, 0.0, 1.0)
	if power < MIN_POWER:
		aim_cancelled.emit()
		return
	var dir := (_drag_start - clamped).normalized()
	var event := FlickEvent.new(dir, power, Time.get_ticks_msec())
	flick_event_emitted.emit(_active_player_id, event)
	_two_action_turn_system.on_action_selected(_active_player_id, &"FIRE", event)
