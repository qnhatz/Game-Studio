class_name TrajectoryVisualization
extends Node2D

const AIM_LINE_MAX_LENGTH: float = 200.0
const CANVAS_RECT: Rect2 = Rect2(Vector2.ZERO, Vector2(800.0, 450.0))
const SHOT_LINE_DISPLAY_MS: float = 2000.0
const SHOT_LINE_FADE_MS: float = 600.0
const MAX_VISIBLE_SHOT_LINES: int = 6

## Injected FigureGeometry reference. Must be set before any signal handler fires.
var _figure_geometry: Node = null

var _aim_line: Line2D
var _shot_lines: Array[Line2D] = []
var _shot_tweens: Array[Tween] = []
var _frozen: bool = false


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


## Called when the player releases (shot committed). Hides the aim line and draws the shot line.
func _on_flick_event_emitted(player_id: int, event: FlickEvent) -> void:
	_aim_line.hide()
	var anchor: Vector2 = _figure_geometry.get_anchor(player_id)
	_draw_shot_line(anchor, event.direction, Color.WHITE)


## Draws a shot line from origin along resolved_dir to the canvas boundary, then fades it out.
func _draw_shot_line(origin: Vector2, resolved_dir: Vector2, color: Color) -> void:
	if _shot_lines.size() >= MAX_VISIBLE_SHOT_LINES:
		_shot_lines[0].queue_free()
		_shot_lines.remove_at(0)
		if is_instance_valid(_shot_tweens[0]):
			_shot_tweens[0].kill()
		_shot_tweens.remove_at(0)
	var endpoint: Vector2 = _compute_canvas_exit(origin, resolved_dir)
	var line: Line2D = Line2D.new()
	line.default_color = color
	add_child(line)
	line.add_point(origin)
	line.add_point(endpoint)
	_shot_lines.append(line)
	var tween: Tween = create_tween()
	_shot_tweens.append(tween)
	tween.tween_interval(SHOT_LINE_DISPLAY_MS / 1000.0)
	tween.tween_property(line, "modulate:a", 0.0, SHOT_LINE_FADE_MS / 1000.0)
	tween.tween_callback(line.queue_free)


## Returns the point where a ray from origin along direction exits the canvas boundary.
func _compute_canvas_exit(origin: Vector2, direction: Vector2) -> Vector2:
	var dx: float = direction.x if direction.x != 0.0 else 1e-10
	var dy: float = direction.y if direction.y != 0.0 else 1e-10
	var t_max_x: float = ((CANVAS_RECT.end.x if dx > 0.0 else CANVAS_RECT.position.x) - origin.x) / dx
	var t_max_y: float = ((CANVAS_RECT.end.y if dy > 0.0 else CANVAS_RECT.position.y) - origin.y) / dy
	var t_exit: float = minf(t_max_x, t_max_y)
	return origin + direction * t_exit


## Halts all active shot-line fades in place (used during result display).
func freeze() -> void:
	_frozen = true
	for tween in _shot_tweens:
		if is_instance_valid(tween):
			tween.kill()


## Clears all shot lines and resets state for the next match.
func reset() -> void:
	for line in _shot_lines:
		if is_instance_valid(line):
			line.queue_free()
	_shot_lines.clear()
	for tween in _shot_tweens:
		if is_instance_valid(tween):
			tween.kill()
	_shot_tweens.clear()
	_frozen = false
