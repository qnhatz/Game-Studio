# Flick Duel — Master Architecture

## Document Status

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Last Updated** | 2026-05-08 |
| **Engine** | Godot 4.6 (GDScript, Compatibility renderer) |
| **GDDs Covered** | All 19 (see `design/gdd/systems-index.md`) |
| **ADRs Referenced** | ADR-0001 through ADR-0011 (ADR-0007 pending OQ-1) |
| **Technical Director Sign-Off** | 2026-05-08 — APPROVED |
| **Lead Programmer Feasibility** | Skipped — Lean mode |

---

## Engine Knowledge Gap Summary

**Risk Level: HIGH** — Godot 4.6 was released January 2026. The LLM's training data covers
Godot approximately through 4.3 (mid-2024). Versions 4.4, 4.5, and 4.6 introduced changes
that the model does NOT reliably know.

| Domain | Risk | Implication for this project |
|--------|------|------------------------------|
| Physics (Jolt default in 4.6) | HIGH | This project disables the physics engine entirely — analytic ray math only. Jolt is irrelevant. |
| Rendering (glow rework in 4.6) | HIGH | We use Compatibility renderer (WebGL 2). No HDR glow pipeline. Rework does not affect us. |
| AnimationPlayer StringName in 4.6 | HIGH | No AnimationPlayer used in MVP (no animation). Risk is irrelevant for launch scope. |
| InputEventScreenDrag on mobile browser | HIGH | Core mechanic depends on this. **Requires iOS Safari validation spike before Input ADR is finalised.** |
| TileMapLayer physics chunking (4.5) | MEDIUM | No TileMap used. Irrelevant. |
| FileAccess return types (4.4) | MEDIUM | No file I/O in MVP. Irrelevant. |
| AccessKit accessibility (4.5) | MEDIUM | Browser target; accessibility handled at browser level. Monitor for future relevance. |
| Variadic args / @abstract (4.5) | LOW | GDScript style features. Adopt if useful; no correctness risk. |

**Systems touching HIGH-risk domains:**
- Input System → `InputEventScreenDrag` → must validate on target browsers before finalising ADR

---

## System Layer Map

```
┌─────────────────────────────────────────────────────────────────┐
│  PLATFORM LAYER                                                 │
│  Godot 4.6 Engine · Compatibility Renderer (WebGL 2) ·         │
│  Browser Input APIs (mouse / touch)                            │
└────────────────────────▬─────────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│  FOUNDATION LAYER                                               │
│  ScreenLayout (Autoload) · RngService (Autoload) · InputSystem  │
│  ShotSpreadCalculation · StatusEffects                          │
└────────────────────────▬─────────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│  CORE LAYER                                                     │
│  FigureGeometry · ActionValidation · TrajectoryVisualization    │
│  Movement                                                       │
└────────────────────────▬─────────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│  FEATURE LAYER                                                  │
│  BodyZoneHitDetection · TwoActionTurnSystem · WinCondition      │
│  GameModeManager · AITargeting · AIDifficultyConfig             │
└────────────────────────▬─────────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│  PRESENTATION LAYER                                             │
│  FigureRenderer · HUDTurnIndicator · GameStateMachine           │
│  MainMenu · MatchResultScreen                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Assignments

| GDD System | Layer | Module Name | Notes |
|------------|-------|-------------|-------|
| Screen Layout | Foundation | `ScreenLayout` | Autoload — single source of spatial truth |
| Status Effects | Foundation | `StatusEffects` | Pure state data; no engine API |
| Input System | Foundation | `InputSystem` | ⚠️ HIGH RISK: InputEventScreenDrag |
| Shot Spread Calculation | Foundation | `ShotSpreadCalculation` | Pure math; uses `RngService` |
| RNG Service *(inferred)* | Foundation | `RngService` | Autoload — seeded RNG for determinism |
| Figure Geometry | Core | `FigureGeometry` | Pure data; zone accessors |
| Action Validation | Core | `ActionValidation` | Queries StatusEffects |
| Trajectory Visualization | Core | `TrajectoryVisualization` | Line2D nodes, persistent shot lines |
| Movement | Core | `Movement` | Updates FigureGeometry anchor |
| Body-Zone Hit Detection | Feature | `BodyZoneHitDetection` | Analytic ray math against FigureGeometry |
| Two-Action Turn System | Feature | `TwoActionTurnSystem` | Synchronous orchestrator |
| Win Condition | Feature | `WinCondition` | Headshot detection; signals GameModeManager |
| Game Mode Manager | Feature | `GameModeManager` | MatchConfig; routes AI vs human |
| AI Targeting | Feature | `AITargeting` | Heuristic zone selection; synthesises FlickEvent |
| AI Difficulty Config | Feature | `AIDifficultyConfig` | Parameter tables per difficulty level |
| Figure Renderer | Presentation | `FigureRenderer` | Line2D stick figures; status visual state |
| HUD / Turn Indicator | Presentation | `HUDTurnIndicator` | Label/icon nodes; reads TurnSystem state |
| Game State Machine | Presentation | `GameStateMachine` | Top-level match lifecycle |
| Main Menu | Presentation | `MainMenu` | Two buttons + inline difficulty selector |
| Match Result Screen | Presentation | `MatchResultScreen` | Win/loss display; rematch flow |

---

## Module Ownership

### Foundation Layer

#### ScreenLayout (Autoload)
| | |
|---|---|
| **Owns** | All spatial constants: canvas size (800×450), zone rects, anchor positions, HUD strip rect, gesture regions |
| **Exposes** | `P1_ANCHOR: Vector2`, `P2_ANCHOR: Vector2`, `P1_ZONE: Rect2`, `P2_ZONE: Rect2`, `CORRIDOR: Rect2`, `P1_GESTURE_RECT: Rect2`, `P2_GESTURE_RECT: Rect2`, `P1_HUD_RECT: Rect2`, `P2_HUD_RECT: Rect2`, `TURN_INDICATOR_RECT: Rect2`, `HUD_H: float = 90`, `CANVAS_SIZE: Vector2 = (800, 450)` |
| **Consumes** | Nothing — pure constants |
| **Engine APIs** | None |

#### RngService (Autoload)
| | |
|---|---|
| **Owns** | Seeded `RandomNumberGenerator`; current RNG state |
| **Exposes** | `seed_rng(value: int)`, `randf_range(min: float, max: float) → float`, `randi_range(min: int, max: int) → int` |
| **Consumes** | Nothing |
| **Engine APIs** | `RandomNumberGenerator` (Godot core, stable since 4.0) |

#### InputSystem
| | |
|---|---|
| **Owns** | Drag state per player zone (start position, current position); active drag tracking |
| **Exposes** | Signal `flick_event_emitted(player_id: int, event: FlickEvent)` |
| **Consumes** | `ScreenLayout.P1_GESTURE_RECT`, `ScreenLayout.P2_GESTURE_RECT` |
| **Engine APIs** | ⚠️ `InputEventScreenTouch`, `InputEventScreenDrag` (HIGH RISK — validate iOS Safari), `InputEventMouseButton`, `InputEventMouseMotion` |

```
# FlickEvent — typed value object (Foundation-layer contract)
class_name FlickEvent extends RefCounted:
    var direction: Vector2   # unit vector, normalised; points from figure toward drag release
    var power: float         # [0.0, 1.0]; 0 = minimal drag, 1 = max drag distance
    var timestamp: int       # Time.get_ticks_msec() at release
```

#### ShotSpreadCalculation
| | |
|---|---|
| **Owns** | Angular variance formula; spread constants |
| **Exposes** | `apply_spread(event: FlickEvent, spread_degrees: float) → Vector2` (returns final shot direction) |
| **Consumes** | `RngService.randf_range()` |
| **Engine APIs** | None (pure math) |

#### StatusEffects
| | |
|---|---|
| **Owns** | Per-player status counters: `disarmed_counter[P1/P2]`, `immobilized_counter[P1/P2]`; derived flags: `can_fire`, `can_move` |
| **Exposes** | `set_disarmed(player_id)`, `set_immobilized(player_id)`, `tick_effects(player_id)`, `can_fire(player_id) → bool`, `can_move(player_id) → bool`, `reset_all()` |
| **Consumes** | Nothing |
| **Engine APIs** | None |

---

### Core Layer

#### FigureGeometry
| | |
|---|---|
| **Owns** | Per-player anchor positions (runtime mutable via Movement); figure shape constants |
| **Exposes** | `get_anchor(player_id) → Vector2`, `set_anchor(player_id, pos: Vector2)`, `get_zone_circle(player_id) → Dictionary`, `get_zone_rect(player_id, zone) → Rect2`, `get_zone_centre(player_id, zone) → Vector2`, `reset()` |
| **Consumes** | `ScreenLayout.P1_ANCHOR`, `ScreenLayout.P2_ANCHOR` (initial values) |
| **Engine APIs** | None (pure data) |

**Shape constants:**
```
HEAD_RADIUS   = 18 px    HEAD_OFFSET_Y  = −162 px
ARMS_WIDTH    = 80 px    ARMS_HEIGHT    = 36 px    ARMS_OFFSET_Y = −126 px
LEGS_WIDTH    = 36 px    LEGS_HEIGHT    = 72 px    LEGS_OFFSET_Y = −72 px
FIGURE_HEIGHT = 180 px
```

#### ActionValidation
| | |
|---|---|
| **Owns** | Nothing (stateless query) |
| **Exposes** | `get_valid_actions(player_id) → Array[StringName]` — returns subset of `{&"FIRE", &"MOVE"}` |
| **Consumes** | `StatusEffects.can_fire(player_id)`, `StatusEffects.can_move(player_id)` |
| **Engine APIs** | None |

#### TrajectoryVisualization
| | |
|---|---|
| **Owns** | Active aim Line2D node (live drag preview); array of persistent shot Line2D nodes with active Tween refs |
| **Exposes** | `show_aim_line(origin: Vector2, direction: Vector2)`, `hide_aim_line()`, `commit_shot_line(origin: Vector2, direction: Vector2, color: Color)`, `freeze()`, `reset()` |
| **Consumes** | `ScreenLayout` (corridor bounds, canvas size) |
| **Engine APIs** | `Line2D` (stable), `Tween` (stable) |

#### Movement
| | |
|---|---|
| **Owns** | Nothing (stateless action executor) |
| **Exposes** | `execute_move(player_id: int, tap_position: Vector2)` |
| **Consumes** | `FigureGeometry.set_anchor()`, `ScreenLayout.P1_ZONE`, `ScreenLayout.P2_ZONE` |
| **Engine APIs** | None |

**Move clamping constants:**
```
MOVE_MARGIN_PX    = 20 px
TAP_MOVE_RADIUS_PX = 12 px   # tap vs drag disambiguation threshold
```

---

### Feature Layer

#### BodyZoneHitDetection
| | |
|---|---|
| **Owns** | Ray-intersection math (stateless) |
| **Exposes** | `detect(ray_origin: Vector2, ray_direction: Vector2, target_player_id: int) → StringName` — returns `&"HEAD"`, `&"ARMS"`, `&"LEGS"`, or `&"MISS"` |
| **Consumes** | `FigureGeometry.get_zone_circle()`, `FigureGeometry.get_zone_rect()` |
| **Engine APIs** | None (analytic math only — no PhysicsServer) |

#### TwoActionTurnSystem
| | |
|---|---|
| **Owns** | Turn state machine; active player; remaining action pool |
| **Exposes** | `begin_turn(player_id: int)`, `on_action_selected(action_type: StringName, flick_event: FlickEvent)`, `halt()`, `reset()`, signal `turn_started(player_id)`, signal `turn_ended(player_id)` |
| **Consumes** | `ActionValidation.get_valid_actions()`, `StatusEffects.tick_effects()`, `WinCondition.check()`, `GameModeManager.is_ai()` |
| **Engine APIs** | None (state machine, no engine-specific deps) |

**Turn states:** `IDLE | TURN_START | AWAITING_FIRST_ACTION | ACTION_EXECUTING | AWAITING_SECOND_ACTION | TURN_END | AUTO_SKIP | HALTED`

#### WinCondition
| | |
|---|---|
| **Owns** | Nothing (stateless check) |
| **Exposes** | `check(zone_hit: StringName, firing_player_id: int) → bool`, signal `match_won(winner_id: int)` |
| **Consumes** | Nothing (receives zone result as parameter) |
| **Engine APIs** | None |

#### GameModeManager
| | |
|---|---|
| **Owns** | `current_config: MatchConfig`; match-active flag |
| **Exposes** | `on_mode_selected(mode: StringName)`, `on_match_won(winner_id: int)`, `on_rematch()`, `is_ai(player_id: int) → bool`, signal `match_ready(config: MatchConfig)`, signal `match_ended(winner_id: int, config: MatchConfig)` |
| **Consumes** | `WinCondition.match_won` signal |
| **Engine APIs** | None |

#### AITargeting
| | |
|---|---|
| **Owns** | Nothing (stateless per-turn decision) |
| **Exposes** | `select_action(player_id: int) → Dictionary` — `{fire_event: FlickEvent, move_destination_x: float, spread_deg: float}` |
| **Consumes** | `FigureGeometry.get_zone_centre()`, `FigureGeometry.get_anchor()`, `AIDifficultyConfig.get_params()`, `RngService.randf_range()` |
| **Engine APIs** | None |

#### AIDifficultyConfig
| | |
|---|---|
| **Owns** | Difficulty level selection; parameter tables |
| **Exposes** | `set_difficulty(level: StringName)`, `get_params() → Dictionary` — `{accuracy_spread_deg, zone_weights: Dictionary (includes w_miss), preferred_distance_px, min_distance_px}` |
| **Consumes** | Nothing |
| **Engine APIs** | None |

---

### Presentation Layer

#### FigureRenderer
| | |
|---|---|
| **Owns** | Line2D nodes composing each stick figure; visual state per figure (X overlays for status effects) |
| **Exposes** | `update_figure(player_id: int)`, `set_status_visual(player_id: int, effect: StringName, active: bool)`, `reset()` |
| **Consumes** | `FigureGeometry` (anchor + zone positions), `StatusEffects.can_fire()`, `StatusEffects.can_move()` |
| **Engine APIs** | `Line2D` with `antialiased = true` (stable) |

**Rendering approach:** Line2D nodes with hand-jitter baked at `_ready()`. No physics, no AnimationPlayer.
Per-player ink colour: P1 = `Color(0.1, 0.2, 0.8)` (blue ink), P2 = `Color(0.8, 0.1, 0.1)` (red ink).
Status effect visuals: bold X overlay through arms rect (Disarmed) or legs rect (Immobilized),
drawn in opponent ink colour. No grey shading.

#### HUDTurnIndicator
| | |
|---|---|
| **Owns** | Label and icon Control nodes for action counters, status icons, turn arrow |
| **Exposes** | `update_hud(active_player: int, remaining_pool: Array, p1_effects: Dictionary, p2_effects: Dictionary)` |
| **Consumes** | `TwoActionTurnSystem` (via signal `turn_started`), `StatusEffects` (direct read) |
| **Engine APIs** | `Label`, `TextureRect`, `Control` (stable); all nodes have `mouse_filter = MOUSE_FILTER_IGNORE` |

#### GameStateMachine
| | |
|---|---|
| **Owns** | Top-level game state enum; scene/node visibility routing |
| **Exposes** | `transition_to(state: StringName)`, signal `state_changed(new_state: StringName)` |
| **Consumes** | `GameModeManager.match_ready`, `GameModeManager.match_ended` signals |
| **Engine APIs** | None — no scene loading; single persistent scene, nodes shown/hidden by state |

**Game states:** `MENU | MODE_SELECT | IN_MATCH | RESULT`

**Show/hide lifecycle contract:** `get_viewport().gui_release_focus()` must always be called before
any `hide()` or `visible = false` on a Control or CanvasLayer subtree.

#### MainMenu
| | |
|---|---|
| **Owns** | Button Control nodes; difficulty selector Control subtree |
| **Exposes** | `show()`, `hide()`, signal `mode_selected(mode: StringName)`, signal `difficulty_selected(level: StringName)` |
| **Consumes** | `GameStateMachine.state_changed` (listens for MENU state) |
| **Engine APIs** | `Button`, `Control`, `HBoxContainer` (stable) |

#### MatchResultScreen
| | |
|---|---|
| **Owns** | Win/loss display Label nodes; rematch button |
| **Exposes** | `show_result(winner_id: int, config: MatchConfig)`, signal `rematch_requested()`, signal `menu_requested()` |
| **Consumes** | `GameStateMachine.state_changed` (listens for RESULT state), `GameModeManager.match_ended` |
| **Engine APIs** | `Label`, `Button`, `Control` (stable) |

---

## Data Flow

### Scenario 1: Core Flick Shot (Human Player)

```
Player drag-release gesture
    │
    ▼
InputSystem._input(event: InputEventScreenDrag / InputEventMouseMotion)
    │  Tracks drag_start → drag_end; displacement
    │  if displacement < TAP_MOVE_RADIUS_PX → route to Movement
    │  else → build FlickEvent
    ▼
FlickEvent{direction, power, timestamp}   ← typed RefCounted value object
    │
    ▼
TwoActionTurnSystem.on_action_selected(&"FIRE")
    │  Synchronous call to shot pipeline
    ▼
ShotSpreadCalculation.apply_spread(event, spread_degrees)
    │  spread_degrees from AIDifficultyConfig (humans get HUMAN_SPREAD_DEG)
    │  RngService.randf_range(-spread, +spread) → angular offset
    │  Returns final_direction: Vector2
    ▼
BodyZoneHitDetection.detect(figure_anchor, final_direction, target_player_id)
    │  Analytic ray vs circle (HEAD), ray vs rect (ARMS, LEGS)
    │  Returns zone: StringName ∈ {&"HEAD", &"ARMS", &"LEGS", &"MISS"}
    ▼
TwoActionTurnSystem (receives zone result)
    │  Calls WinCondition.check(zone, firing_player_id)
    │  if HEAD → WinCondition emits match_won → GameModeManager handles
    │  if ARMS → StatusEffects.set_disarmed(target_player_id)
    │  if LEGS → StatusEffects.set_immobilized(target_player_id)
    │  if MISS → no state change
    ▼
TrajectoryVisualization.commit_shot_line(origin, direction, player_color)
    │  Shot line persists; Tween fade timer starts
    ▼
FigureRenderer.update_figure(target_player_id)
    │  Reads StatusEffects → updates X overlay visuals
    ▼
HUDTurnIndicator.update_hud(...)
    │  Reflects new remaining_pool and status effects
    ▼
TwoActionTurnSystem continues (AWAITING_SECOND_ACTION or TURN_END)
```

**Communication type:** All calls in the critical path (FlickEvent → WinCondition) are
**synchronous direct method calls** for determinism. No signals used in the shot resolution chain.

---

### Scenario 2: AI Turn

```
TwoActionTurnSystem.begin_turn(P2)  [when GameModeManager.is_ai(P2) == true]
    │
    ▼
AITargeting.select_action(P2)
    │  Reads FigureGeometry.get_anchor(P1) for target position
    │  Reads AIDifficultyConfig.get_params() for zone_weights (incl. w_miss), accuracy_spread_deg
    │  Zone selection by weighted random (RngService) — includes MISS zone (w_miss)
    │  Gaussian pre-error applied to ideal direction (Box-Muller, sigma=accuracy_spread_deg)
    │  Synthesises FlickEvent with pre-error direction
    ▼
Returns {fire_event: FlickEvent, move_destination_x: float, spread_deg: float}
    │  AI synthesises FlickEvent directly — bypasses InputSystem
    │  Uses same spread formula as human: ShotSpreadCalculation.apply_spread()
    ▼
→ joins main shot pipeline at TwoActionTurnSystem.on_action_selected(&"FIRE")
   (identical to human path from this point)
```

---

### Scenario 3: Match Lifecycle

```
GameStateMachine (starts in MENU state)
    │
    ▼ [user taps "2 Players" or difficulty + "vs Computer"]
MainMenu emits mode_selected(mode) [and optionally difficulty_selected(level)]
    │
    ▼
GameModeManager.on_mode_selected(mode)
    │  Creates MatchConfig
    │  Emits match_ready(config)
    ▼
GameStateMachine.transition_to(&"IN_MATCH")
    │  gui_release_focus() then hides MainMenu, shows game canvas
    │  Calls TwoActionTurnSystem.begin_turn(P1) to start
    ▼
[match runs under TwoActionTurnSystem control — Scenarios 1 & 2]
    │
    ▼ [headshot lands]
WinCondition emits match_won(winner_id)
    │
    ▼
GameModeManager.on_match_won(winner_id)
    │  Emits match_ended(winner_id, config)
    ▼
TwoActionTurnSystem.halt()        ← discards in-progress turn, no TURN_END signal
    │
TrajectoryVisualization.freeze()  ← tween.kill() on all active Tweens; lines persist
    │
GameStateMachine.transition_to(&"RESULT")
    │  gui_release_focus() then shows MatchResultScreen
    ▼
[user taps Rematch]
MatchResultScreen emits rematch_requested()
    │
    ▼
GameStateMachine orchestrates reset (in order):
    TwoActionTurnSystem.halt()
    StatusEffects.reset_all()
    FigureGeometry.reset()
    TrajectoryVisualization.reset()
    FigureRenderer_P1.reset(), FigureRenderer_P2.reset()
    TwoActionTurnSystem.reset()
    GameModeManager.on_rematch()   ← re-emits match_ready(same_config)
    ▼
GameStateMachine.transition_to(&"IN_MATCH")
TwoActionTurnSystem.begin_turn(P1)
```

---

### Scenario 4: Orientation Gate

```
Godot viewport size change event
    │
    ▼
viewport.size.x < viewport.size.y detected
    │
    ▼
InputSystem: discard all active drags; all _input() events discarded while gate visible
GameStateMachine: show OrientationGate overlay (does NOT change game state)
    │
[user rotates device]
    │
    ▼
viewport.size.x ≥ viewport.size.y → OrientationGate hidden
InputSystem: input window reopened for active player
GameStateMachine: no state change — resumes from where it was
```

---

## API Boundaries

### ScreenLayout (Autoload) — Full public API

```gdscript
# All fields are constants — read-only by design
const CANVAS_SIZE:           Vector2  = Vector2(800, 450)
const HUD_H:                 float    = 90.0
const P1_ANCHOR:             Vector2  = Vector2(200, 338)
const P2_ANCHOR:             Vector2  = Vector2(600, 338)
const P1_ZONE:               Rect2    = Rect2(  0,  0, 320, 450)
const P2_ZONE:               Rect2    = Rect2(480,  0, 320, 450)
const CORRIDOR:              Rect2    = Rect2(320,  0, 160, 450)
const P1_GESTURE_RECT:       Rect2    = Rect2(  0, 90, 320, 360)
const P2_GESTURE_RECT:       Rect2    = Rect2(480, 90, 320, 360)
const P1_HUD_RECT:           Rect2    = Rect2(  0,  0, 320,  90)
const P2_HUD_RECT:           Rect2    = Rect2(480,  0, 320,  90)
const TURN_INDICATOR_RECT:   Rect2    = Rect2(280,  0, 240,  90)
const PLAYER_IDS:            Array    = [0, 1]  # P1 = 0, P2 = 1
```

### FlickEvent — Value object contract

```gdscript
class_name FlickEvent extends RefCounted:
    var direction: Vector2   # Normalised unit vector; points figure → release point
    var power: float         # [0.0, 1.0]; drag_distance / MAX_DRAG_PX
    var timestamp: int       # Time.get_ticks_msec() at pointer release

    # Invariants (must hold at construction):
    #   direction.is_normalized() == true
    #   0.0 <= power <= 1.0
```

### StatusEffects — Public API

```gdscript
class_name StatusEffects extends Node:
    func set_disarmed(player_id: int) -> void
        # Sets disarmed_counter[player_id] = 2
    func set_immobilized(player_id: int) -> void
        # Sets immobilized_counter[player_id] = 2
    func tick_effects(player_id: int) -> void
        # Decrements active counters; restores flags when counter reaches 0
    func can_fire(player_id: int) -> bool
    func can_move(player_id: int) -> bool
    func reset_all() -> void
        # Post-condition: all counters = 0, all flags = true
```

### FigureGeometry — Public API

```gdscript
class_name FigureGeometry extends Node:
    func get_anchor(player_id: int) -> Vector2
    func set_anchor(player_id: int, new_pos: Vector2) -> void
        # Invariant: new_pos.y == ScreenLayout.P1_ANCHOR.y (Y never changes)
    
    func get_zone_circle(player_id: int) -> Dictionary:
        # Returns: {"centre": Vector2, "radius": float}
    
    func get_zone_rect(player_id: int, zone: StringName) -> Rect2:
        # zone must be &"ARMS" or &"LEGS"
    
    func get_zone_centre(player_id: int, zone: StringName) -> Vector2:
        # zone ∈ {&"HEAD", &"ARMS", &"LEGS"}
    
    func reset() -> void:
        # Post-condition: anchors restored to ScreenLayout.P1_ANCHOR / P2_ANCHOR
```

### BodyZoneHitDetection — Public API

```gdscript
class_name BodyZoneHitDetection extends Node:
    func detect(
        ray_origin: Vector2,
        ray_direction: Vector2,    # must be normalised
        target_player_id: int
    ) -> StringName:
        # Returns: &"HEAD", &"ARMS", &"LEGS", or &"MISS"
        # Calls FigureGeometry accessors — never computes geometry inline
        # Precondition: ray_direction.is_normalized() == true
```

### TwoActionTurnSystem — Public API

```gdscript
class_name TwoActionTurnSystem extends Node:
    signal turn_started(player_id: int)
    signal turn_ended(player_id: int)

    func begin_turn(player_id: int) -> void
    func on_action_selected(action_type: StringName, flick_event: FlickEvent) -> void
        # action_type ∈ {&"FIRE", &"MOVE"}
        # flick_event: required when action_type == &"FIRE", null for &"MOVE"
    
    func halt() -> void
        # Discards current turn. TURN_END does not fire.
        # Called by GameStateMachine on match end.
    
    func reset() -> void
        # Post-condition: state = IDLE, active_player = P1, remaining_pool = []
```

### GameModeManager — Public API

```gdscript
class_name GameModeManager extends Node:
    signal match_ready(config: MatchConfig)
    signal match_ended(winner_id: int, config: MatchConfig)

    func on_mode_selected(mode: StringName) -> void
        # mode ∈ {&"TWO_PLAYER_LOCAL", &"ONE_PLAYER_VS_AI"}
    
    func on_match_won(winner_id: int) -> void
        # Connected to WinCondition.match_won signal
    
    func on_rematch() -> void
        # Re-emits match_ready with same config
    
    func is_ai(player_id: int) -> bool
```

---

## Architecture Principles

**1. Single Source of Spatial Truth**
All coordinate values derive from `ScreenLayout`. No system defines its own geometry constants.

**2. Synchronous Critical Path**
The shot resolution chain (FlickEvent → ShotSpreadCalculation → BodyZoneHitDetection → WinCondition)
uses direct synchronous method calls. Signals are used only for cross-layer notifications.

**3. No Physics Engine**
All spatial reasoning is analytic math. The physics server is never called.

**4. Reset-Safe Systems**
Every stateful system exposes a `reset()` method with an explicit post-condition. `StatusEffects`
uses `reset_all()` (self-documenting name). Rematch is a first-class operation.

**5. AI Uses the Same Pipeline**
The AI player synthesises a `FlickEvent` (with Gaussian pre-error applied before construction)
and feeds it into `TwoActionTurnSystem.on_action_selected()` — the identical entry point used
by human input. There is no separate AI shot resolution path.

---

## Open Questions

| # | Question | Blocking | Resolution Path |
|---|----------|---------|------------------|
| OQ-1 | Does `InputEventScreenDrag` fire continuously during drag on iOS Safari, or only on drag-end? | ADR-007 (Input System) | Build a one-page gesture prototype; test on Chrome mobile and Safari iOS |
| OQ-2 | What is the actual Godot 4.6 Compatibility renderer memory baseline for a 800×450 Line2D scene in-browser? | ADR-002 (Web Export) | Export a minimal Godot 4.6 scene to WebGL; profile with browser DevTools |

---

*End of Flick Duel Master Architecture v1.0*
