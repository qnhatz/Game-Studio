# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-05-11
> **Manifest Version**: 2026-05-11
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011
> **Status**: Active — regenerate with `/create-control-manifest` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed this date when
created. `/story-readiness` compares a story's embedded version to this field to detect stories
written against stale rules. Always matches `Last Updated`.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs, technical
preferences, and engine reference docs. For the reasoning behind each rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, state transitions, rematch lifecycle, renderer/export setup, test infrastructure, event wiring*

### Required Patterns

- **Single persistent scene (Main.tscn)** — load once at startup; never unload. All state transitions are `show()`/`hide()` on CanvasLayer nodes. — source: ADR-0001
- **`gui_release_focus()` before every `hide()`** — call `get_viewport().gui_release_focus()` before hiding any CanvasLayer or Control subtree. The Godot 4.6 dual-focus system does not auto-release keyboard focus on hide. — source: ADR-0001, ADR-0010
- **Every stateful system exposes `reset()`** with an explicit post-condition documented in its GDD. The post-condition must be verifiable by a unit test. — source: ADR-0001
- **`GameStateMachine` is the sole reset orchestrator** — it calls `reset()` on all systems in the defined sequence (see ADR-0001 reset table). No system self-resets on a signal. — source: ADR-0001
- **Call `TwoActionTurnSystem.halt()` before transitioning to RESULT state** when `WinCondition` fires mid-turn. — source: ADR-0001
- **Use `@onready` cached node paths for all system dependencies** — wire references in `_ready()` via Inspector-assigned paths, not via Autoload lookups or `get_node()` in logic methods. — source: ADR-0001, ADR-0004
- **Exactly two Autoloads**: `ScreenLayout` (spatial constants only; no runtime state; no signals) and `RngService` (seeded RNG). No others. — source: ADR-0001
- **Set renderer to Compatibility in all three contexts** in `project.godot`:
  ```
  rendering/renderer/rendering_method = "gl_compatibility"
  rendering/renderer/rendering_method.mobile = "gl_compatibility"
  rendering/renderer/rendering_method.web = "gl_compatibility"
  ```
  The `.web` override is required — without it, the web export may not honour the project setting. — source: ADR-0002
- **Web export: `threads_enabled = false`** in the web export preset. Threads require COOP/COEP HTTP headers most hosts do not serve. — source: ADR-0002
- **Web export: WASM Memory Size = 128 MB** in the web export preset. This is a hard ceiling. — source: ADR-0002
- **Web export: Release template** (not Debug). Debug templates carry ~30% extra overhead. — source: ADR-0002
- **All signal connections use typed callables**: `signal.connect(callable)`. Connected in `_ready()` of the consuming node. — source: ADR-0004
- **All inter-system wiring uses `@onready` dependency injection** — each system receives its dependencies via node references, never via Autoload lookups (other than `ScreenLayout` and `RngService`). — source: ADR-0004
- **Test files**: GUT 4.x in `addons/gut/`; runner at `tests/gdunit4_runner.gd`; tests in `tests/unit/` and `tests/integration/` mirroring `src/`. — source: ADR-0011
- **Test naming**: file = `test_[system_slug].gd`; function = `test_[scenario]_[expected_outcome]()`. — source: ADR-0011
- **Each `before_each()` creates fresh instances** — no shared state between test cases. — source: ADR-0011

### Forbidden Approaches

- **Never call `change_scene_to_file()`** during a session. WebGL shader recompilation causes visible hitches. — source: ADR-0001
- **Never call `PackedScene.instantiate()`** for scene-switching. Same reason — use visibility changes. — source: ADR-0001
- **Never add Autoloads beyond `ScreenLayout` and `RngService`**. The cap is fixed. — source: ADR-0001
- **Never let `ScreenLayout` hold runtime state** — it is constants only (e.g., `P1_ANCHOR`, `CANVAS_SIZE`). — source: ADR-0001
- **No physics nodes**: `RigidBody2D`, `CharacterBody2D`, `StaticBody2D`, `CollisionShape2D` are forbidden anywhere in the scene tree. — source: ADR-0002
- **Never call `PhysicsServer2D` methods** — the physics server is idle and must stay idle. — source: ADR-0002
- **No GDExtensions** — unsupported in Godot web exports. — source: ADR-0002
- **Never use Forward+ or Mobile renderer** — Compatibility (WebGL 2) only. — source: ADR-0002
- **Never use string-based `connect()`**: `connect("signal_name", object, "method_name")` is deprecated since Godot 4.0. — source: ADR-0004
- **No event bus / message bus Autoload** — violates the two-Autoload policy and creates hidden coupling. — source: ADR-0004
- **Never skip failing tests to make CI pass** — fix the underlying issue. — source: ADR-0011

### Performance Guardrails

- **Memory ceiling**: total ≤ 128 MB WASM. Any new system adding significant memory (textures, audio, large data structures) requires an explicit budget review. Projected game peak is ~48 MB. — source: ADR-0002
- **Reset sequence completes in ≤1 frame** — no loading screens between RESULT and IN_MATCH. — source: ADR-0001

---

## Core Layer Rules

*Applies to: shot pipeline, hit detection, turn system, input system, FlickEvent, StatusEffects*

### Required Patterns

- **Pattern A (synchronous direct calls) for the shot resolution chain** — the call to `on_action_selected()` must resolve the entire FIRE or MOVE action before it returns. No `await`, no deferred signals in this path. — source: ADR-0004
- **Pattern A callee list** — these must be direct calls (never signals) in the critical path:
  - `ShotSpreadCalculation.apply_spread(event, spread_deg)`
  - `BodyZoneHitDetection.detect(origin, direction, target_id)`
  - `StatusEffects.set_disarmed(player_id)` / `StatusEffects.set_immobilized(player_id)`
  - `StatusEffects.tick_effects(player_id)` — at TURN_START
  - `WinCondition.check(zone, player_id)`
  - `Movement.execute_move(player_id, position)`
  - `ActionValidation.get_valid_actions(player_id)` — at turn start
  - All `reset()` and `halt()` calls from GameStateMachine
  — source: ADR-0004
- **Pattern B (typed signals) for cross-layer notifications** — producer does not know consumers; connections made in `_ready()` of consumer. Signal routing map:
  - `WinCondition.match_won(winner_id)` → `GameModeManager` (sole listener)
  - `GameModeManager.match_ready(config)` → `GameStateMachine`
  - `GameModeManager.match_ended(winner_id, config)` → `GameStateMachine`
  - `TwoActionTurnSystem.turn_started(player_id)` → `HUDTurnIndicator`, `AITargeting`
  - `TwoActionTurnSystem.turn_ended(player_id)` → `HUDTurnIndicator`
  - `GameStateMachine.state_changed(new_state)` → `MainMenu`, `MatchResultScreen`
  — source: ADR-0004
- **Default (immediate) signal mode** — never use `CONNECT_DEFERRED` without an explicit inline comment explaining why. — source: ADR-0004
- **StatusEffects canonical method names**:
  - `set_disarmed(player_id: int)` — ARMS hit
  - `set_immobilized(player_id: int)` — LEGS hit
  - `tick_effects(player_id: int)` — called at TURN_START
  - `reset_all()` — rematch
  Never use `apply()`, `tick()`, or `reset()` on StatusEffects. — source: ADR-0004
- **All hit detection is analytic ray math** in pure GDScript static functions. No engine physics. — source: ADR-0005
- **HEAD detection**: `ray_vs_circle(ray_origin, ray_dir, centre, radius)` — source: ADR-0005
- **ARMS/LEGS detection**: `ray_vs_aabb(ray_origin, ray_dir, rect, max_len)` — slab method. — source: ADR-0005
- **Hit priority: HEAD > ARMS > LEGS** in `detect()` — order of `if` checks. — source: ADR-0005
- **Divide-by-zero guard in AABB**: use `INF if ray_dir.x == 0.0 else 1.0 / ray_dir.x` (and same for y). — source: ADR-0005
- **`CANVAS_DIAG = sqrt(800² + 450²) ≈ 922 px`** as the `max_len` argument to `ray_vs_aabb()`. — source: ADR-0005
- **Use `class_name FlickEvent extends RefCounted`** as the typed value object for all shot data. Construct only via `FlickEvent.new(dir, power, timestamp)`. — source: ADR-0008
- **FlickEvent direction convention**: `normalize(figure_anchor − drag_release_point)` — slingshot model. Dragging right fires left. — source: ADR-0008
- **FlickEvent power**: `clampf(drag_distance / MAX_DRAG_PX, 0.0, 1.0)` where `MAX_DRAG_PX = 150`. — source: ADR-0008
- **FlickEvent timestamp**: `Time.get_ticks_msec()` at pointer release (or at AI decision time). — source: ADR-0008
- **InputSystem uses `_input()`** (not `_unhandled_input()`). Event-driven only — no `Input.is_action_pressed()` polling. — source: ADR-0007
- **`_window_open` guard** — InputSystem only accepts gesture-start when `TwoActionTurnSystem` has called `InputSystem.open_window(player_id)`. — source: ADR-0007
- **Mouse sentinel**: `_touch_id = -1` distinguishes mouse from touch. First active touch ID owns drag; subsequent touches ignored. — source: ADR-0007
- **Gesture origin within 48 px of figure anchor** — check `pos.distance_to(anchor) ≤ FIGURE_DRAG_RADIUS_PX` in `_on_pointer_down()`. — source: ADR-0007
- **Clamp drag endpoint to screen bounds** before computing direction and power. — source: ADR-0007
- **Cancel silently if `power < MIN_POWER (0.05)`** — no FlickEvent, no `on_action_selected()` call. — source: ADR-0007

### Forbidden Approaches

- **Never use a signal where Pattern A (direct call) is required** — splitting shot resolution across frames is a correctness bug. — source: ADR-0004
- **Never use `PhysicsServer2D.space_get_direct_state()`** for hit detection. — source: ADR-0005
- **Never use `RayCast2D`** for hit detection. — source: ADR-0005
- **Never use `Area2D` + `CollisionShape2D`** for hit zones. — source: ADR-0005
- **Never pass shot data as `Dictionary`** `{direction, power, timestamp}` — use `FlickEvent`. — source: ADR-0008
- **Never pass shot fields as inline parameters** — use `FlickEvent`. — source: ADR-0008
- **Never construct `FlickEvent` with un-normalised direction** — `_init()` asserts this in debug builds. — source: ADR-0008
- **Never use `_unhandled_input()`** in InputSystem — use `_input()`. — source: ADR-0007
- **Never poll `Input.is_action_pressed()`** for gesture detection. — source: ADR-0007
- **Never accept gesture input when `_window_open == false`**. — source: ADR-0007

---

## Feature Layer Rules

*Applies to: RNG, AI pipeline, AIDifficultyConfig*

### Required Patterns

- **All random calls go through `RngService`** — the only permitted source of randomness in the game. — source: ADR-0006
- **Seed `RngService` at match start**: `RngService.seed_rng(Time.get_ticks_msec())` in `GameStateMachine`, before `TwoActionTurnSystem.begin_turn()`. — source: ADR-0006
- **Tests seed with fixed constant**: call `RngService.seed_rng(12345)` (or any constant) at the start of any test involving randomness. — source: ADR-0006, ADR-0011
- **AI two-layer accuracy model**:
  - Layer 1 (Gaussian pre-error, in `AITargeting`): apply `_gaussian_sample(sigma_deg)` via Box-Muller using `RngService` to rotate `ideal_dir` before `FlickEvent` construction.
  - Layer 2 (spread, in `ShotSpreadCalculation`): `apply_spread(event, accuracy_spread_deg)` — same code path as human.
  — source: ADR-0009
- **Clamp Gaussian error to ±3×sigma** before applying to prevent pathological outliers. — source: ADR-0009
- **`zone_weights` dictionary must include `&"MISS"` key** and all weights must sum to 1.0. — source: ADR-0009
- **Assert zone weights sum to 1.0 ± 0.001** in `AIDifficultyConfig.set_difficulty()`. — source: ADR-0009
- **AI joins human pipeline at `TwoActionTurnSystem.on_action_selected()`** — identical entry point as human input. — source: ADR-0009
- **AI FlickEvent power = 1.0** (full drag; accuracy controlled entirely by spread and pre-error). — source: ADR-0009

### Forbidden Approaches

- **Never create `RandomNumberGenerator.new()`** outside `rng_service.gd`. — source: ADR-0006
- **AI must not bypass `TwoActionTurnSystem.on_action_selected()`** — no direct calls to `BodyZoneHitDetection` from AI. — source: ADR-0009
- **Never use single spread layer only for AI accuracy** — Gaussian pre-error (Layer 1) is required. Uniform spread alone does not produce the specified accuracy curve. — source: ADR-0009
- **Never omit `&"MISS"` from `zone_weights`** — it is a first-class difficulty parameter, not optional. — source: ADR-0009

---

## Presentation Layer Rules

*Applies to: FigureRenderer, TrajectoryVisualization, HUD, menus, CanvasLayer structure*

### Required Patterns

- **`Line2D` nodes only** for all figures and trajectory lines. One primitive type for the entire visual layer. — source: ADR-0003
- **`Line2D.antialiased = true` on every Line2D node** — the Compatibility renderer has no hardware MSAA. Without it, lines are jagged on high-DPI and mobile. — source: ADR-0003
- **Hand-jitter baked at `_ready()`** — small per-point offsets (±2 px) set into `points` arrays once, using a seeded RNG (seed = player ID). Never rebuild or re-randomise `points` during gameplay. — source: ADR-0003
- **Player colours assigned via `Line2D.default_color`**:
  - P1: `Color(0.1, 0.2, 0.8)` (blue ink)
  - P2: `Color(0.8, 0.1, 0.1)` (red ink)
  — source: ADR-0003
- **`modulate` is reserved for alpha-fade only** — never use `modulate` for colour assignment. — source: ADR-0003
- **Disarmed visual**: bold X overlay (two `Line2D` diagonals) drawn through the arms rect in the **opponent's** ink colour. — source: ADR-0003
- **Immobilized visual**: bold X overlay drawn through the legs rect in the **opponent's** ink colour. — source: ADR-0003
- **`freeze()` kills all active Tweens**: store Tween refs in `_active_tweens`; call `tween.kill()` on each with an `is_instance_valid()` guard. — source: ADR-0003
- **`is_instance_valid()` guard in every Tween callback** before `queue_free()`. — source: ADR-0003
- **CanvasLayer ordering**:
  - Layer 0: game canvas (Line2D figures, trajectories — no CanvasLayer)
  - Layer 1: `HUDTurnIndicator`
  - Layer 10: `MainMenu`, `MatchResultScreen` (mutually exclusive)
  - Layer 20: `OrientationGate` (always on top)
  — source: ADR-0010
- **`mouse_filter = MOUSE_FILTER_IGNORE` on every non-interactive HUD node** — set explicitly per node (Label, TextureRect, HBoxContainer used as display containers). Cannot rely on parent propagation. — source: ADR-0010
- **`gui_release_focus()` before every `hide()`** on any CanvasLayer or Control subtree. — source: ADR-0010
- **`grab_focus()` on first focusable button** when showing a menu (keyboard navigation support). — source: ADR-0010
- **OrientationGate check at top of `InputSystem._input()`** — discard all input when `orientation_gate.visible == true`. — source: ADR-0010

### Forbidden Approaches

- **Never use `draw_line()` in `_draw()`** for figures or trajectories — Line2D nodes only. — source: ADR-0003
- **Never use `Sprite2D` with textures** for MVP figure parts. — source: ADR-0003
- **Never use grey shading** (`modulate = Color(grey)`) for the Immobilized visual. The GDD requires a bold X in opponent ink colour. — source: ADR-0003
- **Never call `set_meta()` to freeze a Tween** — `set_meta()` has no effect on a running Tween. Use `tween.kill()`. — source: ADR-0003
- **Never rebuild `points` arrays per frame** — hand-jitter is baked at `_ready()` and never changed. — source: ADR-0003
- **Never set `MOUSE_FILTER_IGNORE` only on a parent Control** expecting it to cascade — it does not in Godot 4.5+. Set it per node. — source: ADR-0010
- **Never use hover-only interactions** — no hover states; mobile browser has no hover. All interactions must be tap/click. — source: ADR-0010

### Performance Guardrails

- **Draw calls ≤ 50 total** — current projected peak is ~33. New visual elements must be accounted for. — source: ADR-0003
- **Button tap targets ≥ 48×48 px** (accessibility minimum). — source: ADR-0010

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|--------|
| Classes | PascalCase | `PlayerController`, `FlickEvent` |
| Variables | snake_case | `move_speed`, `active_player_id` |
| Signals / Events | snake_case past tense | `health_changed`, `shot_fired`, `match_won` |
| Files | snake_case matching class | `player_controller.gd`, `flick_event.gd` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH`, `CANVAS_DIAG` |

### Performance Budgets

| Target | Value |
|--------|-------|
| Framerate | 60 fps |
| Frame budget | 16.6 ms |
| Draw calls | ≤50 |
| Memory ceiling | ≤128 MB (browser hard limit) |

### Approved Libraries / Addons

- **GUT 4.x** — approved for unit and integration testing (`addons/gut/`)

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or behave differently in Godot 4.6:

| Forbidden | Use Instead | Notes |
|-----------|-------------|-------|
| `yield()` | `await signal` | GDScript 2.0 coroutine syntax |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | String-based connect deprecated since 4.0 |
| `PackedScene.instance()` | `PackedScene.instantiate()` | Renamed |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | Time singleton preferred |
| `duplicate()` on nested resources | `duplicate_deep()` | Explicit deep copy since 4.5 |
| `AnimationPlayer.get_queue()` as `PackedStringArray` | Treat return as `StringName[]` | Return type changed in 4.6 |
| `$NodePath` in `_process()` | `@onready var` cached reference | Path lookup every frame is expensive |
| Untyped `Array` / `Dictionary` | `Array[Type]`, typed variables | GDScript compiler optimisations |
| `TileMap` | `TileMapLayer` | Deprecated since 4.3 |
| `TwoActionTurnSystem.reset()` without preceding `halt()` | Call `halt()` first, then `reset()` | See ADR-0001 reset sequence |

*Source: `docs/engine-reference/godot/deprecated-apis.md`, ADR-0001, ADR-0004*

### Cross-Cutting Constraints

- **No polling in `_process()`** — systems do not check each other's state per frame. State changes propagate via typed signals or are queried exactly once when needed (e.g., `ActionValidation.get_valid_actions()` at TURN_START). — source: ADR-0004
- **New stateful systems must register `reset()` in the GameStateMachine reset sequence** — adding a stateful system without registering its `reset()` causes dirty state on rematch. — source: ADR-0001
- **Any new system needing randomness uses `RngService`** — never creates its own `RandomNumberGenerator`. — source: ADR-0006
- **Any new system adding significant memory must go through budget review** before implementation. Current headroom: ~80 MB. — source: ADR-0002
- **`CONNECT_DEFERRED` requires an explicit inline comment** explaining why deferred execution is intentional. — source: ADR-0004
