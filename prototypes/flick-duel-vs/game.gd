# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the slingshot-drag-to-fire mechanic feel satisfying and legible?
#           Does a full tap-move + flick-fire turn loop feel tense and decisive?
# Date: 2026-05-14

extends Node2D

# --- Canvas & input constants ---
const CANVAS_W := 800.0
const CANVAS_H := 450.0
const MAX_DRAG_PX := 150.0
const MIN_POWER := 0.05
const TAP_RADIUS_PX := 12.0
const FIGURE_HIT_RADIUS := 48.0
const ZONE_MARGIN := 20.0
const ACTIONS_PER_TURN := 2

# --- Timing ---
const SHOT_FADE_SEC := 1.5
const HIT_FLASH_SEC := 0.5

# --- Colors (notebook aesthetic) ---
const C_BG     := Color(0.961, 0.941, 0.910)
const C_RULE   := Color(0.678, 0.847, 0.902, 0.35)
const C_DIV    := Color(0.70, 0.70, 0.70)
const C_P1     := Color(0.149, 0.278, 0.682)
const C_P2     := Color(0.741, 0.149, 0.149)

# --- Figure geometry (anchor = feet, y increases downward) ---
const HEAD_OFF := Vector2(0.0, -145.0)
const HEAD_R   := 18.0
const ARMS_OFF := Vector2(0.0, -108.0)
const ARMS_SZ  := Vector2(80.0, 36.0)
const LEGS_OFF := Vector2(0.0, -36.0)
const LEGS_SZ  := Vector2(36.0, 72.0)

enum Zone { HEAD, ARMS, LEGS, NONE }

# --- Game state ---
var anchors: Array[Vector2] = [Vector2(200.0, 390.0), Vector2(600.0, 390.0)]
var turn     := 0
var actions  := ACTIONS_PER_TURN
var disabled : Array = [{}, {}]
var winner   := -1

# --- Input state ---
enum GestureState { IDLE, TRACKING }
var gesture      := GestureState.IDLE
var g_start      := Vector2.ZERO
var g_pos        := Vector2.ZERO
var g_from_fig   := false
var g_touch_id   := -1

# --- Visual lists ---
var shots  : Array = []   # { start, end, color, t }
var flashes: Array = []   # { player, zone, color, t }

# ---------- Lifecycle ----------

func _ready() -> void:
	for p in 2:
		disabled[p] = { Zone.HEAD: false, Zone.ARMS: false, Zone.LEGS: false }

func _process(delta: float) -> void:
	var s2: Array = []
	for s in shots:
		s.t -= delta
		if s.t > 0.0:
			s2.append(s)
	shots = s2

	var f2: Array = []
	for f in flashes:
		f.t -= delta
		if f.t > 0.0:
			f2.append(f)
	flashes = f2

	queue_redraw()

# ---------- Drawing ----------

func _draw() -> void:
	_draw_bg()
	_draw_divider()
	_draw_shots()
	for p in 2:
		_draw_figure(p)
	_draw_aim()
	_draw_hud()
	if winner >= 0:
		_draw_win_overlay()

func _draw_bg() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(CANVAS_W, CANVAS_H)), C_BG)
	var y := 36.0
	while y < CANVAS_H:
		draw_line(Vector2(0.0, y), Vector2(CANVAS_W, y), C_RULE, 1.0)
		y += 24.0

func _draw_divider() -> void:
	draw_line(Vector2(CANVAS_W * 0.5, 0.0),
			  Vector2(CANVAS_W * 0.5, CANVAS_H), C_DIV, 1.0)

func _draw_figure(p: int) -> void:
	var a: Vector2 = anchors[p]
	var c: Color = _cp(p)

	# Legs
	var lc := a + LEGS_OFF
	_draw_zone_rect(Rect2(lc - LEGS_SZ * 0.5, LEGS_SZ), Zone.LEGS, p, c)

	# Arms
	var ac := a + ARMS_OFF
	_draw_zone_rect(Rect2(ac - ARMS_SZ * 0.5, ARMS_SZ), Zone.ARMS, p, c)

	# Torso line
	var torso_top := a + Vector2(0.0, -127.0)
	var torso_bot := a + Vector2(0.0, -72.0)
	draw_line(torso_top, torso_bot, _a(c, 0.25 if disabled[p][Zone.ARMS] else 1.0), 2.0)

	# Head
	var hc := a + HEAD_OFF
	_draw_zone_circle(hc, HEAD_R, Zone.HEAD, p, c)

	# Anchor dot
	draw_circle(a, 3.0, c)

func _draw_zone_rect(r: Rect2, zone: Zone, p: int, c: Color) -> void:
	var is_dis: bool = disabled[p][zone]
	var flash := _flash_alpha(p, zone)
	if flash > 0.0:
		draw_rect(r, _a(_cp(1 - p), flash * 0.6))
	draw_rect(r, _a(c, 0.0 if is_dis else 0.08))
	draw_rect(r, _a(c, 0.25 if is_dis else 1.0), false, 1.5)

func _draw_zone_circle(center: Vector2, radius: float, zone: Zone, p: int, c: Color) -> void:
	var is_dis: bool = disabled[p][zone]
	var flash := _flash_alpha(p, zone)
	if flash > 0.0:
		draw_circle(center, radius, _a(_cp(1 - p), flash * 0.6))
	draw_arc(center, radius, 0.0, TAU, 32, _a(c, 0.25 if is_dis else 1.0), 2.0)

func _flash_alpha(p: int, zone: Zone) -> float:
	for f in flashes:
		if f.player == p and f.zone == zone:
			return f.t / HIT_FLASH_SEC
	return 0.0

func _draw_aim() -> void:
	if gesture != GestureState.TRACKING or not g_from_fig:
		return
	var origin: Vector2 = anchors[turn]
	var c: Color = _cp(turn)
	var drag_vec := g_pos - g_start
	var dist := drag_vec.length()

	# Rubber band to cursor
	draw_line(origin, g_pos, _a(c, 0.2), 1.5)

	if dist > TAP_RADIUS_PX:
		var aim := (origin - g_pos).normalized()
		var power := clampf(dist / MAX_DRAG_PX, 0.0, 1.0)

		# Dashed aim line (200px)
		var step := 0.0
		var drawing := true
		while step < 200.0:
			var seg := 9.0 if drawing else 5.0
			if drawing:
				draw_line(origin + aim * step,
						  origin + aim * minf(step + seg, 200.0), c, 2.0)
			step += seg
			drawing = !drawing

		# Power ring
		draw_arc(origin, 14.0 + power * 12.0, 0.0, TAU, 24, _a(c, 0.5), 1.5)

func _draw_shots() -> void:
	for s in shots:
		draw_line(s.start, s.end, _a(s.color, s.t / SHOT_FADE_SEC), 2.0)

func _draw_hud() -> void:
	if winner >= 0:
		return
	var font := ThemeDB.fallback_font
	var c: Color = _cp(turn)

	# Action dots
	var dot_x := 28.0 if turn == 0 else CANVAS_W - 72.0
	for i in ACTIONS_PER_TURN:
		var pos := Vector2(dot_x + i * 24.0, 20.0)
		if i < actions:
			draw_circle(pos, 7.0, c)
		else:
			draw_arc(pos, 7.0, 0.0, TAU, 16, _a(c, 0.35), 1.5)

	# Turn label
	var label := "P1 TURN" if turn == 0 else "P2 TURN"
	var lx := 60.0 if turn == 0 else CANVAS_W - 132.0
	draw_string(font, Vector2(lx, 28.0), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, c)

	# Disabled zone status
	for p in 2:
		var parts: Array = []
		if disabled[p][Zone.ARMS]: parts.append("ARMS LOST")
		if disabled[p][Zone.LEGS]: parts.append("LEGS LOST")
		if parts.is_empty():
			continue
		var status := "  ".join(parts)
		var sx := 10.0 if p == 0 else CANVAS_W - 160.0
		draw_string(font, Vector2(sx, CANVAS_H - 8.0), status,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, _a(_cp(p), 0.75))

func _draw_win_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(CANVAS_W, CANVAS_H)), Color(0, 0, 0, 0.45))
	var font := ThemeDB.fallback_font
	var c: Color = _cp(winner)
	var name_str := "P1" if winner == 0 else "P2"
	draw_string(font, Vector2(280.0, 210.0), name_str + " WINS",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 38, c)
	draw_string(font, Vector2(304.0, 258.0), "tap to restart",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, _a(Color.WHITE, 0.7))

func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)

func _cp(p: int) -> Color:
	return C_P1 if p == 0 else C_P2

# ---------- Input ----------

func _input(event: InputEvent) -> void:
	if winner >= 0:
		if event is InputEventMouseButton and event.pressed:
			_restart()
		elif event is InputEventScreenTouch and event.pressed:
			_restart()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_ptr_down(event.position)
		else:
			_ptr_up(event.position)
	elif event is InputEventMouseMotion:
		if gesture == GestureState.TRACKING:
			_ptr_move(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed and g_touch_id < 0:
			g_touch_id = event.index
			_ptr_down(event.position)
		elif not event.pressed and event.index == g_touch_id:
			g_touch_id = -1
			_ptr_up(event.position)
	elif event is InputEventScreenDrag:
		if event.index == g_touch_id:
			_ptr_move(event.position)

func _ptr_down(pos: Vector2) -> void:
	if gesture != GestureState.IDLE:
		return
	gesture = GestureState.TRACKING
	g_start = pos
	g_pos = pos
	g_from_fig = pos.distance_to(anchors[turn]) <= FIGURE_HIT_RADIUS

func _ptr_move(pos: Vector2) -> void:
	g_pos = pos.clamp(Vector2.ZERO, Vector2(CANVAS_W, CANVAS_H))

func _ptr_up(pos: Vector2) -> void:
	if gesture != GestureState.TRACKING:
		return
	gesture = GestureState.IDLE
	g_pos = pos.clamp(Vector2.ZERO, Vector2(CANVAS_W, CANVAS_H))

	var drag_dist := g_start.distance_to(g_pos)

	if drag_dist < TAP_RADIUS_PX:
		# Tap → MOVE if in own zone
		if _in_own_zone(g_start):
			_do_move(g_start)
	elif g_from_fig:
		# Drag from figure → FIRE
		var power := clampf(drag_dist / MAX_DRAG_PX, 0.0, 1.0)
		if power >= MIN_POWER:
			var dir := (anchors[turn] - g_pos).normalized()
			_do_fire(dir)

func _in_own_zone(pos: Vector2) -> bool:
	return pos.x < CANVAS_W * 0.5 if turn == 0 else pos.x >= CANVAS_W * 0.5

# ---------- Actions ----------

func _do_move(tap: Vector2) -> void:
	var lo := ZONE_MARGIN if turn == 0 else CANVAS_W * 0.5 + ZONE_MARGIN
	var hi := CANVAS_W * 0.5 - ZONE_MARGIN if turn == 0 else CANVAS_W - ZONE_MARGIN
	anchors[turn].x = clampf(tap.x, lo, hi)
	_consume()

func _do_fire(dir: Vector2) -> void:
	var origin: Vector2 = anchors[turn]
	var opp := 1 - turn
	var end := origin + dir * _ray_edge_t(origin, dir)
	var zone := _check_hit(origin, dir, opp)

	shots.append({ "start": origin, "end": end, "color": _cp(turn), "t": SHOT_FADE_SEC })

	if zone != Zone.NONE:
		_apply_hit(opp, zone)

	_consume()

func _consume() -> void:
	actions -= 1
	if actions <= 0:
		turn = 1 - turn
		actions = ACTIONS_PER_TURN

func _apply_hit(p: int, zone: Zone) -> void:
	disabled[p][zone] = true
	flashes.append({ "player": p, "zone": zone, "color": _cp(1 - p), "t": HIT_FLASH_SEC })
	if zone == Zone.HEAD or _all_disabled(p):
		winner = 1 - p

func _all_disabled(p: int) -> bool:
	return disabled[p][Zone.HEAD] and disabled[p][Zone.ARMS] and disabled[p][Zone.LEGS]

func _restart() -> void:
	anchors  = [Vector2(200.0, 390.0), Vector2(600.0, 390.0)]
	turn     = 0
	actions  = ACTIONS_PER_TURN
	winner   = -1
	shots.clear()
	flashes.clear()
	for p in 2:
		disabled[p] = { Zone.HEAD: false, Zone.ARMS: false, Zone.LEGS: false }

# ---------- Hit detection ----------

func _ray_edge_t(origin: Vector2, dir: Vector2) -> float:
	var t := 2000.0
	if dir.x > 0.0:  t = minf(t, (CANVAS_W - origin.x) / dir.x)
	elif dir.x < 0.0: t = minf(t, -origin.x / dir.x)
	if dir.y > 0.0:  t = minf(t, (CANVAS_H - origin.y) / dir.y)
	elif dir.y < 0.0: t = minf(t, -origin.y / dir.y)
	return t

func _check_hit(origin: Vector2, dir: Vector2, opp: int) -> Zone:
	var a: Vector2 = anchors[opp]

	if not disabled[opp][Zone.HEAD]:
		if _ray_circle(origin, dir, a + HEAD_OFF, HEAD_R):
			return Zone.HEAD

	if not disabled[opp][Zone.ARMS]:
		var ac := a + ARMS_OFF
		if _ray_rect(origin, dir, Rect2(ac - ARMS_SZ * 0.5, ARMS_SZ)):
			return Zone.ARMS

	if not disabled[opp][Zone.LEGS]:
		var lc := a + LEGS_OFF
		if _ray_rect(origin, dir, Rect2(lc - LEGS_SZ * 0.5, LEGS_SZ)):
			return Zone.LEGS

	return Zone.NONE

func _ray_circle(o: Vector2, d: Vector2, c: Vector2, r: float) -> bool:
	var oc := o - c
	var b  := oc.dot(d)
	var disc := b * b - oc.dot(oc) + r * r
	if disc < 0.0:
		return false
	return (-b - sqrt(disc)) > 0.0

func _ray_rect(o: Vector2, d: Vector2, r: Rect2) -> bool:
	var ix := (1.0 / d.x) if d.x != 0.0 else INF
	var iy := (1.0 / d.y) if d.y != 0.0 else INF
	var t1 := (r.position.x - o.x) * ix
	var t2 := (r.end.x     - o.x) * ix
	var t3 := (r.position.y - o.y) * iy
	var t4 := (r.end.y     - o.y) * iy
	var tmin := maxf(minf(t1, t2), minf(t3, t4))
	var tmax := minf(maxf(t1, t2), maxf(t3, t4))
	return tmax >= 0.0 and tmin <= tmax
