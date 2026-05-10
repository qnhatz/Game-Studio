# ADR-0001: Scene Topology and System Lifecycle

## Status
Proposed

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Scene Management) |
| **Knowledge Risk** | LOW — scene tree, Node lifecycle, and visibility APIs are stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm `get_viewport().gui_release_focus()` clears dual-focus correctly on target browsers (Chrome mobile, Safari iOS) before shipping |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0002 (Web Export/Memory), ADR-0003 (Rendering Primitives), ADR-0004 (System Communication), all subsequent ADRs |
| **Blocks** | All Foundation-layer implementation — no code before this ADR is Accepted |
| **Ordering Note** | First ADR; all other ADRs build on the scene topology established here |

## Context

### Problem Statement

Flick Duel has three UI states (MENU, IN_MATCH, RESULT) and a rematch flow that must reset all match
systems to a clean state. We need to decide how Godot scenes are structured, how the game transitions
between states, and how systems reset for a rematch — without scene-loading latency on a browser
(WebGL 2) target.

### Constraints

- **WebGL 2 (Compatibility renderer)**: scene loading triggers lazy shader recompilation in the browser,
  causing visible frame drops. State transitions must be instant.
- **Memory ceiling**: ≤128 MB total (browser constraint from `technical-preferences.md`).
- **No persistent progression**: every match starts from a known-clean state; rematch is a first-class
  operation, not an afterthought.
- **GDScript**: no async scene-loading patterns from other engines apply.
- **60 fps target**, 16.6 ms frame budget.

### Requirements

- State transitions (MENU → IN_MATCH → RESULT → rematch) must feel instant — no loading screen.
- Every stateful system must be resettable to an explicit post-condition without reloading the scene.
- Mid-match abort (match ends while a turn is in progress) must not leave any system in a broken state.
- System reset order must be deterministic and documented in a single location.

## Decision

**Single persistent scene (Main.tscn) with in-place reset.**

All game systems — menus, match logic, presentation — live as nodes in one scene tree. The scene is
loaded once at startup and never unloaded. State transitions are visibility changes on CanvasLayer nodes,
not scene loads. Rematch resets systems in place via explicit `reset()` calls in a defined sequence.
There is no `change_scene_to_file()`, `PackedScene.instantiate()`, or any dynamic scene loading during
a session.

### Scene Structure

```
Main (Node2D)
├── ScreenLayout      (Autoload — spatial constants, no runtime state)
├── RngService        (Autoload — seeded RandomNumberGenerator)
│
├── Systems (Node — logical grouping, no behaviour)
│   ├── StatusEffects
│   ├── FigureGeometry
│   ├── ActionValidation
│   ├── ShotSpreadCalculation
│   ├── BodyZoneHitDetection
│   ├── Movement
│   ├── TwoActionTurnSystem
│   ├── WinCondition
│   ├── GameModeManager
│   ├── AITargeting
│   └── AIDifficultyConfig
│
├── Presentation (Node — logical grouping)
│   ├── TrajectoryVisualization
│   ├── FigureRenderer_P1
│   ├── FigureRenderer_P2
│   └── HUDTurnIndicator  (CanvasLayer, layer 1)
│
├── GameStateMachine
│
├── MainMenu          (CanvasLayer, layer 10 — shown in MENU state)
├── MatchResultScreen (CanvasLayer, layer 10 — shown in RESULT state)
└── OrientationGate   (CanvasLayer, layer 20 — shown when portrait detected)
```

### State Transition: Visibility Routing

`GameStateMachine` controls which CanvasLayer/node subtrees are visible. Before hiding any Control
subtree, it calls `get_viewport().gui_release_focus()` — required by the Godot 4.6 dual-focus system
(mouse/touch focus and keyboard/gamepad focus are tracked independently; hidden nodes do not
automatically release keyboard focus).

```gdscript
func _transition_to(new_state: StringName) -> void:
    get_viewport().gui_release_focus()   # Always clear focus before hiding anything
    match new_state:
        &"MENU":
            main_menu.show()
            match_result_screen.hide()
            game_canvas.hide()
        &"IN_MATCH":
            main_menu.hide()
            match_result_screen.hide()
            game_canvas.show()
        &"RESULT":
            main_menu.hide()
            match_result_screen.show()
            game_canvas.hide()
    state_changed.emit(new_state)
```

### reset() Contract

Every stateful system exposes `reset()` with an explicit post-condition documented in its GDD.
`GameStateMachine` calls these in the following order on rematch start — **order is enforced**:

| Step | Call | Post-condition |
|------|------|----------------|
| 1 | `TwoActionTurnSystem.halt()` | state = HALTED; no pending actions |
| 2 | `StatusEffects.reset()` | all counters = 0; can_fire = true; can_move = true |
| 3 | `FigureGeometry.reset()` | anchors = ScreenLayout.P1_ANCHOR / P2_ANCHOR |
| 4 | `TrajectoryVisualization.reset()` | all shot lines cleared; aim line hidden; frozen = false |
| 5 | `FigureRenderer_P1.reset()`, `FigureRenderer_P2.reset()` | figures redrawn at default visual state |
| 6 | `TwoActionTurnSystem.reset()` | state = IDLE; pool = []; active_player = P1 |
| 7 | `GameModeManager.on_rematch()` | re-emits `match_ready(same_config)` |

No system self-resets on a signal. `GameStateMachine` is the sole orchestrator of the rematch sequence.
Adding a new stateful system requires adding its `reset()` call to this table.

### halt() Contract

When `WinCondition` fires mid-turn, `GameStateMachine` calls `TwoActionTurnSystem.halt()` before
transitioning to RESULT state. `halt()` sets `state = HALTED` and discards the remaining action pool.
`turn_ended` does not fire. This prevents a second action from executing after match end.

### Autoload Policy

Exactly two Autoloads:
- `ScreenLayout` — spatial constants only; no runtime state; no signals
- `RngService` — seeded `RandomNumberGenerator`; deterministic output

All other systems are scene-tree nodes, not Autoloads. Systems receive references to siblings/children
via `@onready` in `_ready()`, not via Autoload name lookups. This ensures all systems are unit-testable
in isolation without a running scene tree.

## Alternatives Considered

### Alternative A: Scene-per-state (menu.tscn / match.tscn / result.tscn)

- **Description**: Each state is a separate scene; `change_scene_to_file()` on transition
- **Pros**: Clean separation; each scene holds only what it needs; familiar in other engines
- **Cons**: `change_scene_to_file()` triggers WebGL shader recompilation on every transition —
  visible frame hitches in-browser. Rematch requires a full scene reload with state serialisation.
- **Rejection**: Incompatible with the instant-feel UX requirement on a WebGL 2 target. The shader
  recompilation cost on Compatibility renderer is a hard browser constraint, not a tunable parameter.

### Alternative B: Persistent root + sub-scenes loaded per state (hybrid)

- **Description**: Root scene always present; MainMenu.tscn, Match.tscn, Result.tscn loaded/unloaded
  dynamically
- **Pros**: Reduces live memory by only loading the active state's assets; cleaner separation than
  monolithic scene
- **Cons**: Still incurs shader compilation cost on first sub-scene load. Match system state must be
  serialised/deserialised between sub-scene loads for rematch — significant complexity. For this game's
  memory profile (line drawings, no textures), the memory saving is negligible against the complexity cost.
- **Rejection**: Adds meaningful complexity with no practical benefit given this game's asset footprint
  and session length (3–10 min matches on a ≤128 MB budget).

## Consequences

### Positive

- **Zero shader recompilation hitches**: all shaders compile at startup warmup; no cold-load hitches
  during transitions — a genuine WebGL 2 / Compatibility renderer advantage of this topology
- **Zero mid-session GC pressure**: no scene instantiation or destruction during gameplay
- **Instant rematch**: `reset()` sequence completes in one frame; no loading screen between RESULT
  and IN_MATCH
- **Single reset source of truth**: the reset sequence table (above) is the only place to audit
  match lifecycle

### Negative

- **All system memory is live from startup**: even on the menu, match systems occupy memory. Acceptable
  for this game's node profile (<2 MB estimated), but this topology cannot justify adding
  memory-intensive systems later without a separate memory budget review.
- **Reset order manually maintained**: if a new stateful system is added, it must be registered in the
  `GameStateMachine` reset sequence — no engine mechanism enforces this.

### Risks

- **Dual-focus orphan (Godot 4.6)**: hiding a Control subtree without `gui_release_focus()` leaves
  keyboard focus on a hidden node, causing invisible tab-stop bugs.
  *Mitigation*: `GameStateMachine` always calls `gui_release_focus()` before any `hide()` call;
  validated by a UI integration test on both Chrome and Safari.

- **Forgotten reset registration**: a developer adds a stateful system but omits its `reset()` from
  the sequence, causing dirty state on rematch.
  *Mitigation*: reset sequence documented here and in the Control Manifest; `/story-done` review
  requires reset() post-conditions for any stateful system story; code review gate.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-TATS-003 | Two-Action Turn System | `halt()` discards turn without TURN_END; `reset()` restores IDLE | Defines both as first-class contracts with post-conditions in the reset sequence table |
| TR-GMM-003 | Game Mode Manager | Rematch re-emits `match_ready` with same config | `GameStateMachine` calls `GameModeManager.on_rematch()` as the final step of the reset sequence |
| TR-FIG-004 | Figure Geometry | Zone accessors are the single source of geometry truth | `FigureGeometry` reset restores anchors to `ScreenLayout` defaults; all spatial state flows through it |
| TR-WIN-002 | Win Condition | Signals `GameModeManager` (sole listener), not `GameStateMachine` directly | Scene topology places `WinCondition` and `GameModeManager` as siblings; signal connection made at `_ready()` in `GameModeManager` |
| TR-TVIS-002 | Trajectory Visualization | Shot lines frozen on match end; cleared on `reset()` | `TrajectoryVisualization.reset()` is step 4 of the reset sequence; freeze called by `GameStateMachine` on match end before `halt()` |

## Performance Implications

- **CPU**: Negligible — `reset()` calls are one-frame O(1) operations across all systems
- **Memory**: All systems live from startup. Estimated overhead: <2 MB (Line2D nodes, no textures).
  Well within the 128 MB browser ceiling.
- **Load Time**: Startup is slightly longer (all systems initialise together) vs. deferred loading.
  Acceptable: one cold startup load is better than repeated mid-session shader recompilation hitches.
- **Network**: N/A — local-only game

## Migration Plan

Greenfield project — no existing code to migrate.

## Validation Criteria

- Rematch completes in ≤1 frame (no loading screen visible between RESULT and IN_MATCH states)
- `gui_release_focus()` prevents focus-on-hidden-node regression in the 4.6 dual-focus system;
  verified on Chrome (desktop + mobile) and Safari iOS
- All stateful systems pass unit tests verifying post-conditions of their `reset()` methods
- Memory profile at startup ≤128 MB measured with Godot profiler in Compatibility/WebGL 2 export

## Related Decisions

- `docs/architecture/architecture.md` — master architecture document (this ADR implements its
  "Single persistent scene" principle)
- ADR-0002: Web Export and Memory Strategy — budget this topology must fit within
- ADR-0003: Rendering Primitives — Line2D nodes placed in the Presentation subtree defined here
- ADR-0004: System Communication — signal connections wired at `_ready()` within this scene topology
