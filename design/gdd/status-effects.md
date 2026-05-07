# Status Effects

> **Status**: Designed (pending review)
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-06
> **Implements Pillar**: Read the Body / Two Actions One Regret

## Overview

Status Effects is the state layer that records and enforces the consequences of body-zone hits. It tracks two possible effects per player — **Disarmed** (arms hit: fire action removed from the turn pool for one turn) and **Immobilized** (legs hit: move action removed from the turn pool for one turn) — plus a **Healthy** baseline with no restrictions. Both effects can be active on the same player simultaneously. The system holds no logic of its own: it stores the current state of each player and exposes it to the four systems that read it (Action Validation, Two-Action Turn System, Figure Renderer, HUD/Turn Indicator). Status effects are written by Body-Zone Hit Detection when a shot resolves, ticked and cleared by the Turn System at the start of each affected player's turn, and reset by the Game State Machine on match end. There is no healing mechanic and no early-clearing rule.

## Player Fantasy

Your shot lands on their drawing arm. A hard X appears through it on the page. Next turn, your opponent stares at half a stick figure — they can move, but they can't fire back. For one turn, you are the author: you wrote them out of the fight, and now you choose where to go next.

From their side of the screen: the panic of an unloaded gun. They can reposition, but every direction is still inside your range. Disarmed, they can only run. Immobilized, they can only fire — from wherever they were standing when you decided their feet were yours.

The fantasy isn't damage. It is *editing your opponent's turn*. Two actions become one. The notebook shows the work in red ink (or blue). Both players read the crossed-out limb and know what's coming — the tension is shared, legible, and completely visible to anyone watching from across a table.

This is Pillar 2 made literal: *Two Actions, One Regret* — and now their two actions are one.

## Detailed Design

### Core Rules

1. Each player has two independent permission flags: **`can_fire`** and **`can_move`**, both `true` by default (Healthy state). These flags are the only state this system maintains.

2. **Disarmed** effect: `can_fire = false`. Applied when a shot resolves on the arms zone. The affected player cannot take the Fire action on their next turn.

3. **Immobilized** effect: `can_move = false`. Applied when a shot resolves on the legs zone. The affected player cannot take the Move action on their next turn.

4. Both effects can be active on the same player simultaneously. A player with `can_fire = false` AND `can_move = false` has zero valid actions. Their turn is **automatically skipped** with a visible indicator on the shared screen. This state is a valid and intentional outcome — two accurate shots earned it.

5. **Duration**: An effect persists for exactly **one turn of the affected player**. It is active when that player's turn begins and is cleared before their following turn starts. The opponent's turns between do not count.

6. **Writing rule**: Body-Zone Hit Detection is the only system that writes effects. It calls `set_disarmed(player_id)` or `set_immobilized(player_id)` when a shot resolves. It never clears effects.

7. **Clearing rule**: The Turn System is the only system that clears effects. It calls `tick_effects(player_id)` at the start of each affected player's turn — **before** action validation runs. The counter starts at **2** when the effect is applied. First tick: `2→1`, flag stays `false` (player is still restricted this turn). Second tick (following turn): `1→0`, flag restored to `true`. This ensures the restriction actually prevents the action on the affected turn.

8. **Match reset**: When the Game State Machine signals match end or new match start, `reset_all()` is called, returning both players to `can_fire = true, can_move = true`. No mid-match healing or early clearing exists.

### States and Transitions

| State | `can_fire` | `can_move` | How entered | How exited |
|-------|-----------|-----------|-------------|------------|
| Healthy | true | true | Default; after `tick_effects` clears both flags; after `reset_all` | Arms or legs hit |
| Disarmed | false | true | Arms zone hit resolves | `tick_effects` after 1 restricted turn |
| Immobilized | true | false | Legs zone hit resolves | `tick_effects` after 1 restricted turn |
| Both Restricted | false | false | Arms AND legs each hit (any order) | `tick_effects` clears each independently as their counters expire |

**Transitions:**

```
Healthy  →[arms hit]→  Disarmed  →[tick, 1 turn]→  Healthy
Healthy  →[legs hit]→  Immobilized  →[tick, 1 turn]→  Healthy
Healthy  →[arms + legs hit]→  Both Restricted  →[tick, after 1 turn each]→  Healthy
Any state  →[match reset]→  Healthy
```

The two duration counters are independent. If a player is Disarmed (fire counter = 2) and then takes a legs hit on the same turn, they enter Both Restricted with both counters at 2 — both clear after one restricted turn. If the legs hit lands one opponent turn later (fire counter already at 1), the move counter resets to 2 while fire counter is at 1; the fire restriction clears one tick before the move restriction does.

### Interactions with Other Systems

| System | Role | Interface |
|--------|------|-----------|
| Body-Zone Hit Detection | **Writer** — sets effects when shots resolve on arm/leg zones | `set_disarmed(player_id)`, `set_immobilized(player_id)` |
| Turn System | **Ticker/Clearer** — decrements duration counters at turn start | `tick_effects(player_id)` |
| Action Validation | **Reader** — queries flags before validating player actions | `can_fire(player_id)`, `can_move(player_id)` |
| Figure Renderer | **Reader** — queries flags to draw correct visual state (crossed arm/leg) | `get_status(player_id)` → `{can_fire, can_move}` |
| HUD / Turn Indicator | **Reader** — queries flags to display active status effect icons | `get_status(player_id)` |
| Game State Machine | **Resetter** — clears all effects on match end/start | `reset_all()` |

## Formulas

This system has no continuous formulas — all state transitions are discrete boolean and integer operations. The precise logic is specified as pseudocode below.

**State Transition Rules**

```
set_disarmed(player_id):
    can_fire[player_id]             = false
    turns_remaining_fire[player_id] = 2   # 2 ticks: first restricts, second clears

set_immobilized(player_id):
    can_move[player_id]             = false
    turns_remaining_move[player_id] = 2

reset_all():
    for each player_id in {P1, P2}:
        can_fire[player_id]             = true
        can_move[player_id]             = true
        turns_remaining_fire[player_id] = 0
        turns_remaining_move[player_id] = 0

tick_effects(player_id):   # called at START of player's turn, BEFORE action validation
    if turns_remaining_fire[player_id] > 0:
        turns_remaining_fire[player_id] -= 1
        if turns_remaining_fire[player_id] == 0:
            can_fire[player_id] = true
    if turns_remaining_move[player_id] > 0:
        turns_remaining_move[player_id] -= 1
        if turns_remaining_move[player_id] == 0:
            can_move[player_id] = true
# After tick_effects, action_validation queries can_fire / can_move.
# With counter 2→1: flag stays false → restriction is active this turn.
# With counter 1→0: flag restores to true → restriction has expired.
```

**Variable domains:**

| Symbol | Type | Valid values |
|--------|------|-------------|
| `can_fire`, `can_move` | bool | `{true, false}` |
| `turns_remaining_fire`, `turns_remaining_move` | int | `{0, 1, 2}` |
| `player_id` | enum | `{P1, P2}` |

## Edge Cases

- **If `set_disarmed` is called on a player who is already Disarmed** (`can_fire = false`, `turns_remaining_fire = 2`): idempotent — `turns_remaining_fire` resets to 2, restarting the duration. The flag stays `false`. A second arm hit resets the clock; it does not stack beyond one restricted turn.

- **If `set_disarmed` is called while `turns_remaining_fire = 1`** (restriction already expiring): `turns_remaining_fire` resets to 2, giving one more full restricted turn. The second hit extends the restriction.

- **If `tick_effects` is called on a player with no active effects** (both counters = 0, both flags = `true`): both `if > 0` branches are skipped. The call is a no-op. No side effects.

- **If `tick_effects` is called twice in one turn start** (defensive guard): on the second call, counters have already been decremented. If they are now 0, flags are already `true`. If they are 1 (mid-restriction), a second call would incorrectly clear the flag one turn early. **`tick_effects` must not be called more than once per player per turn start.** The Turn System owns this guarantee.

- **If a player is in Both Restricted state** (both counters = 2) and it is their turn: `tick_effects` fires — both counters go `2→1`, both flags stay `false`. Action validation sees `can_fire = false AND can_move = false`. The turn is **automatically skipped** with a visible indicator. This is the intended outcome of two earned hits landing simultaneously (on the same opponent turn cycle).

- **If a player exits Both Restricted at different times** (staggered hits — e.g., fire counter = 1, move counter = 2): on the affected player's next turn, `tick_effects` decrements fire `1→0` (flag restored) and move `2→1` (flag stays `false`). The player can fire but not move. Move restriction clears the following turn. Staggered Both Restricted does **not** produce an auto-skip.

- **If a headshot resolves while the target is Disarmed or Both Restricted**: the match ends immediately. Status effects are irrelevant — headshot bypasses the action pool entirely. `reset_all()` fires on match end as usual.

- **If `reset_all` is called while any player has active effects**: all counters set to 0, all flags set to `true`, unconditionally. No effect survives a match reset regardless of its current counter value.

- **If `set_disarmed` is called during the affected player's own turn** (shot resolves mid-sequence): the counter is set to 2. `tick_effects` has already fired for this turn, so the restriction takes effect on the affected player's **next** turn. The current turn is unaffected.

## Dependencies

Status Effects has no upstream dependencies.

**Downstream dependents:**

| Dependent System | Nature | What It Reads / Calls |
|-----------------|--------|----------------------|
| Body-Zone Hit Detection | **Writer** (Hard) | Calls `set_disarmed(player_id)` or `set_immobilized(player_id)` when arm/leg zone hit resolves |
| Two-Action Turn System | **Ticker** (Hard) | Calls `tick_effects(player_id)` at the start of each affected player's turn, before action validation |
| Action Validation | **Reader** (Hard) | Queries `can_fire(player_id)` and `can_move(player_id)` to determine legal actions |
| Figure Renderer | **Reader** (Hard) | Queries `get_status(player_id)` to draw visual state (crossed arm/leg geometry) |
| HUD / Turn Indicator | **Reader** (Hard) | Queries `get_status(player_id)` to display active status effect icons |
| Game State Machine | **Resetter** (Hard) | Calls `reset_all()` on match end and new match start |

No system writes back to Status Effects except Body-Zone Hit Detection. All other relationships are read-only or lifecycle-management.

When each dependent system's GDD is authored, it must list Status Effects as a dependency and cite `design/gdd/status-effects.md` as the source for flag and counter definitions.

## Tuning Knobs

| Knob | Current Value | Safe Range | Too High | Too Low | Notes |
|------|--------------|-----------|----------|---------|-------|
| Effect duration (turns) | 1 restricted turn | 1–2 turns | 2 turns: opponent has 2 safe turns after landing a disabling shot; pacing slows, disabling shots feel overpowered | 0 turns: effects have no consequence, arm/leg hits are meaningless; breaks *Read the Body* | Implemented via counter initial value: 1 turn = counter 2, 2 turns = counter 4 |
| Both Restricted auto-skip | On | On / Off | N/A — On is always stricter | Off: player still acts but Action Validation must handle 0-valid-actions gracefully; reduces punishment for double-disabling | Toggle in config; does not affect single-effect behaviour |

There are no continuous parameters. Effect duration is the only meaningful design lever.

## Visual/Audio Requirements

Not applicable — Status Effects is pure state data with no visual output. Visual feedback for active effects belongs to Figure Renderer (crossed-out geometry) and HUD/Turn Indicator (status icons), both of which read from this system's `get_status()` interface.

## UI Requirements

Not applicable — Status Effects has no UI of its own. See HUD/Turn Indicator GDD for how active effects are communicated to players.

## Acceptance Criteria

- **GIVEN** a new match has started, **WHEN** I read a player's status flags, **THEN** `can_fire = true`, `can_move = true`, and both duration counters are `0`.

- **GIVEN** a player is Healthy, **WHEN** `set_disarmed(player_id)` is called, **THEN** `can_fire = false`, `turns_remaining_fire = 2`, and `can_move` is unchanged.

- **GIVEN** a player is Healthy, **WHEN** `set_immobilized(player_id)` is called, **THEN** `can_move = false`, `turns_remaining_move = 2`, and `can_fire` is unchanged.

- **GIVEN** `can_fire = false` and `turns_remaining_fire = 2`, **WHEN** `tick_effects(player_id)` is called once, **THEN** `turns_remaining_fire = 1` and `can_fire` is still `false`.

- **GIVEN** `can_fire = false` and `turns_remaining_fire = 1`, **WHEN** `tick_effects(player_id)` is called, **THEN** `turns_remaining_fire = 0` and `can_fire = true`.

- **GIVEN** `set_disarmed` was called (counter = 2), **WHEN** the affected player's next turn begins and `tick_effects` fires (2→1), **THEN** the player cannot fire this turn; **AND WHEN** `tick_effects` fires again the following turn (1→0), **THEN** the player can fire freely.

- *(Integration)* **GIVEN** both `set_disarmed` and `set_immobilized` were called for the same player in the same turn window (both counters = 2), **WHEN** `tick_effects(player_id)` fires at the start of that player's turn (both 2→1), **THEN** `can_fire = false` and `can_move = false` and the turn is automatically skipped with a visible indicator. *(Visual component requires advisory screenshot evidence.)*

- *(Code review gate)* **GIVEN** a shot resolves on an arms zone, **WHEN** Body-Zone Hit Detection processes the hit, **THEN** `set_disarmed(player_id)` is called exactly once and no other system calls `set_disarmed` or `set_immobilized`. Verify via code review — not runtime-testable.

- *(Code review gate)* **GIVEN** an effect is active, **WHEN** the affected player's turn begins, **THEN** `tick_effects` is called exactly once and only by the Turn System, before action validation queries `can_fire`/`can_move`. Ordering is testable by asserting action validation reads the post-tick flag.

- **GIVEN** `can_fire = false` and `turns_remaining_fire = 1` (effect expiring), **WHEN** `set_disarmed(player_id)` is called again, **THEN** `turns_remaining_fire = 2` and `can_fire` remains `false`.

- **GIVEN** `turns_remaining_fire = 1` and `turns_remaining_move = 2`, **WHEN** `tick_effects(player_id)` is called, **THEN** `can_fire = true` (fire counter hit 0) and `can_move = false` (move counter is now 1).

- **GIVEN** both players have active effects with non-zero counters, **WHEN** `reset_all()` is called, **THEN** both players have `can_fire = true`, `can_move = true`, `turns_remaining_fire = 0`, and `turns_remaining_move = 0`.

*Automated unit tests target: `tests/unit/status_effects/`. Integration ACs require a running Godot scene. Code review gate ACs are architectural invariants not runtime-verifiable.*

## Open Questions

- **Architecture: where does this system live?** Could be an Autoload singleton (global access), a node in the match scene tree (scoped), or a plain Resource passed between systems. This choice affects how all six downstream systems reference it. *Owner: lead-programmer. Resolve before: `/create-architecture` sprint. → Becomes an ADR.*

- **Both Restricted auto-skip: who renders the indicator?** The auto-skip is defined here as producing "a visible indicator." Whether this is rendered by HUD/Turn Indicator, Game State Machine, or a dedicated overlay is unspecified. *Resolve when: HUD/Turn Indicator GDD is authored.*
