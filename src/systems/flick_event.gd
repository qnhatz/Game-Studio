## Typed value object carrying shot data from input to the shot pipeline.
class_name FlickEvent extends RefCounted

## Normalised unit vector: direction the shot travels (slingshot — opposes drag direction).
var direction: Vector2
## Drag fraction of MAX_DRAG_PX, clamped to [0.0, 1.0].
var power: float
## Time.get_ticks_msec() at pointer release.
var timestamp: int

func _init(dir: Vector2, pwr: float, ts: int) -> void:
	assert(dir.is_normalized(), "FlickEvent direction must be normalised")
	assert(pwr >= 0.0 and pwr <= 1.0, "FlickEvent power must be in [0, 1]")
	direction = dir
	power = pwr
	timestamp = ts
