## Shows a "Rotate your device" prompt when the viewport is portrait-oriented.
## Attach to a CanvasLayer node at layer 20 (always on top of all game layers).
## Connects to Viewport.size_changed — no _process() polling.
class_name OrientationGate
extends CanvasLayer


func _ready() -> void:
	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed()


func _on_size_changed() -> void:
	var vp: Vector2i = get_viewport().size
	var portrait: bool = vp.x < vp.y
	if portrait and not visible:
		get_viewport().gui_release_focus()
		show()
	elif not portrait and visible:
		get_viewport().gui_release_focus()
		hide()
