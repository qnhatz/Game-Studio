class_name TrajectoryVisualization
extends Node2D

const AIM_LINE_MAX_LENGTH: float = 200.0
const CANVAS_RECT: Rect2 = Rect2(Vector2.ZERO, Vector2(800.0, 450.0))

## Injected FigureGeometry reference. Must be set before any signal handler fires.
var _figure_geometry: Node = null

var _aim_line: Line2D


func _ready() -> void:
	_aim_line = Line2D.new()
	_aim_line.hide()
	add_child(_aim_line)


## Called when the player is actively dragging. Updates and shows the aim line.
func _on_aim_updated(player_id: int, drag_end: Vector2) -> void:
	var anchor: Vector2 = _figure_geometry.get_anchor(player_id)
	var raw_dir: Vector2 = anchor - drag_end
	var dist: float = raw_dir.length()
	if dist < 1.0:
		return
	var power: float = clampf(dist / InputSystem.MAX_DRAG_PX, 0.0, 1.0)
	var aim_dir: Vector2 = raw_dir.normalized()
	var length: float = power * AIM_LINE_MAX_LENGTH
	var endpoint: Vector2 = (anchor + aim_dir * length).clamp(Vector2.ZERO, CANVAS_RECT.end)
	_aim_line.points = PackedVector2Array([anchor, endpoint])
	_aim_line.show()


## Called when the drag is cancelled (power below threshold). Hides the aim line.
func _on_aim_cancelled() -> void:
	_aim_line.hide()


## Called when the player releases (shot committed). Hides the aim line.
## Shot line drawing is handled in Story 002.
func _on_flick_event_emitted(_player_id: int, _event: FlickEvent) -> void:
	_aim_line.hide()
