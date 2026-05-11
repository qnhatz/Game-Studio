# ADR-0004: System Communication Architecture

## Status
Accepted

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Signals, Callables) |
| **Knowledge Risk** | LOW — Godot signal system (typed connections via `signal.connect(callable)`) has been stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — all APIs in training data |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology — establishes which systems are siblings/parents) |
| **Enables** | All system implementation stories; defines the contract for how systems talk |
| **Blocks** | Any story where two systems must exchange data |
| **Ordering Note** | Must be Accepted before any inter-system wiring is implemented |

## Context

### Problem Statement

Flick Duel's systems must communicate — the shot pipeline must deliver a `FlickEvent` to the turn
system, status effects must be applied after a hit, and the win condition must propagate upward to
end the match. These communication paths have different requirements: some need synchronous
determinism (shot resolution), others need decoupling (match lifecycle events). We need a single
clear policy so every programmer makes consistent choices without case-by-case deliberation.

### Constraints

- No event bus / singleton message bus (would violate the Autoload policy from ADR-0001)
- All signal connections must be typed callables (deprecated string-based `connect()` is banned;
  see `deprecated-apis.md`)
- Systems must remain unit-testable: communication pattern must not require a full scene tree
- Shot resolution must be deterministic: result must be fully computed before any frame is drawn

### Requirements

- Shot pipeline (FlickEvent → spread → hit detection → win check) must resolve synchronously
  within a single `on_action_selected()` call
- Cross-layer notifications (Win Condition → Game Mode Manager) must decouple producer from consumer
- Reset and halt calls must be direct and ordered (see ADR-0001 reset sequence)

## Decision

**Two-pattern architecture: synchronous direct calls in the critical path; typed Godot signals
for cross-layer notifications.**

### Pattern A: Synchronous Direct Calls (Critical Path)

Used in the shot resolution chain and any sequence where:
1. The result must be available on the same call frame, AND
2. Call order is deterministic and must be controlled

```gdscript
# TwoActionTurnSystem.on_action_selected() — synchronous critical path
func on_action_selected(action_type: StringName, flick_event: FlickEvent) -> void:
    state = ACTION_EXECUTING
    match action_type:
        &"FIRE":
            var final_dir := ShotSpreadCalculation.apply_spread(flick_event, _spread_deg)
            var zone := BodyZoneHitDetection.detect(
                _figure_geo.get_anchor(active_player),
                final_dir,
                _opponent(active_player)
            )
            StatusEffects.set_immobilized(_opponent(active_player)) if zone == &"LEGS" else \
            StatusEffects.set_disarmed(_opponent(active_player)) if zone == &"ARMS" else null
            if WinCondition.check(zone, active_player):
                return    # match end handled by WinCondition signal
        &"MOVE":
            Movement.execute_move(active_player, _pending_tap_position)
    remaining_pool.erase(action_type)
    # ... continue turn
```

**Systems that use Pattern A (callee list):**
- `ShotSpreadCalculation.apply_spread()` — called by TwoActionTurnSystem
- `BodyZoneHitDetection.detect()` — called by TwoActionTurnSystem
- `StatusEffects.set_disarmed()` / `StatusEffects.set_immobilized()` — called by TwoActionTurnSystem
- `WinCondition.check()` — called by TwoActionTurnSystem
- `Movement.execute_move()` — called by TwoActionTurnSystem
- `ActionValidation.get_valid_actions()` — called by TwoActionTurnSystem at turn start
- `StatusEffects.tick_effects()` — called by TwoActionTurnSystem at TURN_START
- All `reset()` and `halt()` calls — called by GameStateMachine in defined order

### Pattern B: Typed Godot Signals (Cross-Layer Notifications)

Used when:
1. The producer should not know who consumes the event, OR
2. The consumer is in a higher layer than the producer (e.g., Presentation reacting to Feature)

Signal connections are made in `_ready()` of the consuming node. **String-based connect() is forbidden.**

```gdscript
# Typed signal declaration (in producer)
signal match_won(winner_id: int)          # WinCondition
signal match_ready(config: MatchConfig)   # GameModeManager
signal match_ended(winner_id: int, config: MatchConfig)  # GameModeManager
signal turn_started(player_id: int)       # TwoActionTurnSystem
signal turn_ended(player_id: int)         # TwoActionTurnSystem
signal state_changed(new_state: StringName)  # GameStateMachine

# Connection (in consumer _ready())
win_condition.match_won.connect(_on_match_won)          # GameModeManager connects to WinCondition
game_mode_manager.match_ready.connect(_on_match_ready)  # GameStateMachine connects to GameModeManager
game_mode_manager.match_ended.connect(_on_match_ended)  # GameStateMachine connects to GameModeManager
turn_system.turn_started.connect(_on_turn_started)      # HUDTurnIndicator connects to TurnSystem
```

**Signal routing map (producer → consumers):**

| Signal | Producer | Consumers |
|--------|----------|-----------|
| `match_won(winner_id)` | WinCondition | GameModeManager (sole listener) |
| `match_ready(config)` | GameModeManager | GameStateMachine |
| `match_ended(winner_id, config)` | GameModeManager | GameStateMachine |
| `turn_started(player_id)` | TwoActionTurnSystem | HUDTurnIndicator, AITargeting (in VS AI mode) |
| `turn_ended(player_id)` | TwoActionTurnSystem | HUDTurnIndicator |
| `state_changed(new_state)` | GameStateMachine | MainMenu, MatchResultScreen |
| `mode_selected(mode)` | MainMenu | GameModeManager |
| `difficulty_selected(level)` | MainMenu | AIDifficultyConfig |

### Pattern C: `@onready` References (Dependency Injection)

Systems receive references to their dependencies via `@onready` cached node paths set in the
Inspector, not via Autoload lookups or `get_node()` calls in logic methods. This keeps systems
unit-testable — a test can inject a mock node reference.

```gdscript
# In TwoActionTurnSystem
@onready var status_effects: StatusEffects = $"../Systems/StatusEffects"
@onready var figure_geometry: FigureGeometry = $"../Systems/FigureGeometry"
@onready var win_condition: WinCondition = $"../Systems/WinCondition"
```

### StatusEffects Method Names

The canonical method names match the Status Effects GDD (self-documenting, zone-specific):
- `set_disarmed(player_id: int)` — applies Disarmed (called when ARMS zone is hit)
- `set_immobilized(player_id: int)` — applies Immobilized (called when LEGS zone is hit)
- `tick_effects(player_id: int)` — decrements active counters at TURN_START
- `reset_all()` — restores clean state on rematch

### What This Architecture Explicitly Excludes

- **Event bus / message bus**: no central dispatch singleton. Direct calls and typed signals cover
  all cases without the hidden coupling of a global bus.
- **String-based signal connections**: `connect("signal_name", object, "method_name")` is deprecated
  since Godot 4.0. All connections use `signal.connect(callable)`.
- **Polling**: no system checks another system's state in `_process()`. State changes propagate
  via signals or are queried only when needed (e.g., `ActionValidation.get_valid_actions()` at
  TURN_START, not per-frame).

## Alternatives Considered

### Alternative A: Event Bus Singleton (Autoload)

- **Description**: A global `EventBus` Autoload with typed signals; all systems connect to it
- **Pros**: Complete producer/consumer decoupling; easy to add new listeners
- **Cons**: Violates the Autoload policy (ADR-0001 caps Autoloads at ScreenLayout + RngService);
  creates a hidden global dependency making unit testing harder; debugging signal chains through
  a bus is harder than following direct calls
- **Rejection**: Autoload policy violation; not needed for this game's simple signal topology

### Alternative B: All signals, no direct calls (fully reactive)

- **Description**: Every system communication is a signal; shot resolution is async
- **Pros**: Maximum decoupling
- **Cons**: Shot resolution becomes non-deterministic — signals in Godot are deferred by default
  when connected across threads (and can be deferred explicitly). For a game where “the shot
  resolved before the frame draws” is a correctness requirement, async signals are wrong. Also
  complicates unit testing of the shot pipeline.
- **Rejection**: Synchronous determinism is a hard requirement for shot resolution

## Consequences

### Positive

- Shot resolution chain is guaranteed to complete within a single function call — no frame-split bugs
- Signal consumers are decoupled from producers in the match lifecycle; adding a new listener
  (e.g., an audio system) requires only one new `connect()` call
- `@onready` injection makes every system mockable in unit tests
- No global state in the communication layer
- StatusEffects method names are self-documenting and match the GDD exactly

### Negative

- Direct call graph must be documented (this ADR); a developer who doesn't know Pattern A applies
  to the critical path might introduce an async signal in the wrong place
- `@onready` paths are scene-structure-dependent; if the scene tree reorganises, paths break

### Risks

- **Wrong pattern in critical path**: a developer uses a signal where a direct call is required,
  splitting shot resolution across frames. *Mitigation*: this ADR and the control manifest
  explicitly list which calls are Pattern A; code review enforces it.
- **Deferred signal execution**: if a signal is connected with `CONNECT_DEFERRED`, it fires on
  the next process frame, not immediately. **All connections in this project use the default
  (immediate) mode.** No `CONNECT_DEFERRED` without an explicit comment explaining why.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-TATS-004 | Two-Action Turn System | Synchronous orchestration in critical path | Pattern A (direct calls) mandated for shot → hit detect → win check chain |
| TR-WIN-002 | Win Condition | Signals GameModeManager (sole listener), not GameStateMachine directly | Signal routing map specifies `match_won` → GameModeManager only |
| TR-GMM-002 | Game Mode Manager | `match_won` → enriched to `match_ended(winner_id, config)` | GameModeManager listens to `match_won`, emits `match_ended` — both documented in routing map |
| TR-STE-005 | Status Effects | Method API: set_disarmed / tick_effects / reset_all | Canonical method names documented here; ADR-0004 pseudocode uses these names |

## Performance Implications

- **CPU**: Direct calls have no overhead beyond normal function dispatch. Signals in Godot 4 use
  `Callable` dispatch — negligible overhead for the call frequencies in a turn-based game.
- **Memory**: No event bus object; no queued event lists. Negligible.
- **Frame Budget**: Shot resolution completes synchronously within one `on_action_selected()` call;
  no frame-split risk.

## Migration Plan

Greenfield. All inter-system wiring follows this pattern from day one.

## Validation Criteria

- No `connect("string", ...)` calls anywhere in the codebase (grep check in CI)
- Shot resolution unit test: call `on_action_selected(&"FIRE", event)` → assert zone result
  and status effect applied within the same test call (no `await`)
- Signal routing: unit test that `WinCondition.match_won` is connected only to `GameModeManager`
- StatusEffects method names: grep confirms `set_disarmed`, `set_immobilized`, `tick_effects`, `reset_all` — no `apply()`, `tick()`, or `reset()` on StatusEffects

## Related Decisions

- ADR-0001: Scene Topology — `@onready` paths assume the scene structure defined there
- ADR-0008: FlickEvent Contract — the typed value object passed in direct calls
