# Cross-GDD Review Report — Flick Duel

> **Date**: 2026-05-08
> **Reviewer**: Claude Code + review-all-gdds skill (full pass)
> **GDDs Reviewed**: 18
> **Systems Covered**: Screen Layout, Status Effects, Input System, Shot Spread Calculation, Figure Geometry, Action Validation, Trajectory Visualization, Body-Zone Hit Detection, Two-Action Turn System, Win Condition, Game Mode Manager, Game State Machine, Main Menu, AI Targeting, AI Difficulty Config, Figure Renderer, HUD/Turn Indicator, Match Result Screen

---

## Executive Summary

All 18 MVP and V1.0 GDDs have been reviewed for cross-document consistency and
game design holism. **6 blocking issues** must be resolved before architecture
begins. **11 warnings** should be resolved before implementation. **7 info items**
are worth tracking but will not block work.

The most critical gap is a missing **Movement GDD** — the MOVE action is referenced
by seven systems but never specified. The second most critical is an undefined
**reset contract** across all systems, which will cause incomplete state on rematch.

---

## Blocking Issues — Must resolve before architecture begins

### B1 — No Movement GDD: MOVE action entirely unspecified

`two-action-turn-system.md`, `action-validation.md`, and `game-mode-manager.md` all
reference MOVE as a valid action, but no GDD defines what MOVE does. There is no
formula for how far a player moves, no spatial constraints (corridor rules, min/max
position, whether players can cross into the opponent's zone), and no specification
of whether MOVE affects figure anchor position in real time or at end of turn.

Without this, the MOVE action cannot be implemented. Every system that depends on
player position is affected. **Author a Movement GDD before architecture begins.**

**GDDs affected**: two-action-turn-system.md, action-validation.md, figure-geometry.md, figure-renderer.md, ai-targeting.md

---

### B2 — Signal routing contradiction: Win Condition vs Game Mode Manager

`win-condition.md` emits `match_won(winner_id)` and states the Game State Machine
is the listener. `game-mode-manager.md` states it "receives `match_won` and forwards
it to the State Machine." These cannot both be true simultaneously.

**Resolution**: Win Condition should signal the Game State Machine directly. Game
Mode Manager does not need to intercept this signal — it has no logic to add at
match-end. Update game-mode-manager.md to remove the forwarding claim. Update
win-condition.md's dependency table to confirm Game State Machine as the sole listener.

**GDDs affected**: win-condition.md, game-mode-manager.md

---

### B3 — Difficulty selector UI unmodelled in Main Menu GDD

`ai-difficulty-config.md` specifies: "The player selects difficulty via a 3-option
selector shown after tapping 'vs Computer' on the Main Menu." `main-menu.md` defines
only two buttons with no difficulty selector, no sub-screen flow, and no
`difficulty_selected` signal.

**Resolution**: Extend `main-menu.md` to include:
- A difficulty selector (3 options: Easy / Medium / Hard) that appears inline after
  "vs Computer" is tapped
- A `difficulty_selected(level)` signal emitted when a difficulty is confirmed
- Default selection: MEDIUM
- The selector must close and emit before the match starts

**GDDs affected**: main-menu.md

---

### B4 — Body-Zone Hit Detection hardcodes head geometry

`body-zone-hit-detection.md` duplicates `anchor + (0, −162)` and `radius = 18`
inline rather than calling Figure Geometry. The arm and leg tests correctly call
`figure_geometry.get_zone_rect()`, but the head test is hardcoded. If head zone
values are tuned in Figure Geometry, Hit Detection silently diverges.

**Resolution**: Add a `get_zone_circle() → {centre: Vector2, radius: float}` method
to Figure Geometry. Update Body-Zone Hit Detection to call it for the head test,
matching the pattern used for arms and legs.

**GDDs affected**: body-zone-hit-detection.md, figure-geometry.md

---

### B5 — `reset_all()` undefined: no system exposes a reset interface

`game-state-machine.md` calls `reset_all()` on rematch start, but no system GDD
defines what this call does or what each system must implement. Without a defined
reset contract, rematch can leave stale state: old shot lines visible from the
previous match, status effects persisting, the turn system frozen in a mid-turn
intermediate state.

**Resolution**: Each system GDD must declare a `reset()` method with an explicit
post-condition stating the system's state immediately after reset. For example:
- Status Effects: `reset()` → all `can_fire` and `can_move` set to `true`, all
  counters to `0`
- Trajectory Visualization: `reset()` → all shot lines cleared, aim line hidden
- Turn System: `reset()` → state machine returns to initial state, ready for P1's
  first turn

**GDDs affected**: All system GDDs — see Recommended Resolution Order for priority.

---

### B6 — Attacker identity lost at Win Condition boundary

`body-zone-hit-detection.md` signals a zone hit but does not include attacker
identity in the signal. `win-condition.md` needs `winner_id` to emit
`match_won(winner_id)`, but has no way to derive who fired the shot from the hit
signal alone.

**Resolution**: The hit signal from Body-Zone Hit Detection must carry both
`zone: ZoneEnum` and `attacker_id: PlayerID`. Win Condition passes `attacker_id`
directly as `winner_id` to `match_won`. Alternatively, Win Condition may query the
Turn System for the current active player — but passing it through the signal is
simpler and avoids a new dependency.

**GDDs affected**: body-zone-hit-detection.md, win-condition.md

---

## Warning Issues — Should resolve before implementation

### W1 — Status effect tick not scoped to affected player's turn

`status-effects.md` says effects tick "at TURN_START before action validation"
without specifying that only the *affected player's* TURN_START counts. If
implemented as "every TURN_START," effects expire twice as fast.

**Fix**: Add to status-effects.md: "The counter decrements only when the *affected
player's* turn begins. The opponent's TURN_START does not tick the counter."

---

### W2 — AI Targeting does not check Action Validation

`ai-targeting.md` always selects FIRE or MOVE without first calling Action
Validation. A Disarmed AI player would still attempt to FIRE.

**Fix**: Add to ai-targeting.md: "Before selecting an action, AI Targeting calls
`action_validation.get_valid_actions(ai_player_id)` and constrains its selection
to the returned set."

---

### W3 — Shot line timer fate on match-end freeze undefined

Shot lines have a `SHOT_LINE_DISPLAY_MS` lifetime. On match end, the canvas is
frozen beneath the result screen. If timers keep running, the winning shot line
disappears from the freeze-frame mid-display.

**Fix**: Add to trajectory-visualization.md: "On receiving the match-end signal,
all active shot line timers are frozen at their current state. No fade or removal
occurs until `reset()` is called."

---

### W4 — Turn System mid-turn termination state undefined

When a match ends on the first action of a turn, the Turn System is in
`AWAITING_SECOND_ACTION`. Neither `TURN_END` behaviour nor `halt()` post-state
is defined.

**Fix**: Add to two-action-turn-system.md: "On `halt()`, the current turn is
discarded immediately. `TURN_END` does not fire. The state machine transitions
to a `HALTED` state and takes no further action until `reset()` is called."

---

### W5 — HARD AI accuracy undermined by AI_POWER spread

At HARD, `AI_POWER = 0.80` produces `half_angle = 24.4°` of spread, nearly
matching EASY at power 0.55 (`half_angle = 17.4°`). The `AIM_ERROR_DEG = 3°`
advantage is largely consumed by spread.

**Fix**: Consider reducing HARD `AI_POWER` to 0.55–0.65, or add a tuning note
acknowledging the interaction: "High AI_POWER increases spread, which partially
offsets AIM_ERROR_DEG accuracy. Tune both parameters together."

---

### W6 — Minimum power is dominant strategy; no incentive for hard flicks

`MIN_POWER = 0.05` produces `half_angle = 3.4°` — extremely accurate. Players
should always flick lightly. There is no mechanical cost to low-power shots.

**Fix options**: (a) Add a minimum spread floor independent of power. (b) Add a
note to shot-spread-calculation.md that this is accepted design (binary hit/miss
means power is purely cosmetic). (c) Reserve for V1.0 rebalancing.

---

### W7 — Disarmed strictly better than Immobilized

Until MOVE is defined (see B1), Immobilized removes access to an action with no
specified mechanical effect. After Movement is designed, revisit whether the two
status effects are balanced relative to each other.

---

### W8 — `TURN_INDICATOR_RECT` undefined in Screen Layout

`hud-turn-indicator.md` references `TURN_INDICATOR_RECT` (x 280–520, y 0–90) but
`screen-layout.md` does not define this constant.

**Fix**: Add `TURN_INDICATOR_RECT = Rect2(280, 0, 240, 90)` to screen-layout.md
constants, or document that HUD/Turn Indicator owns this value locally.

---

### W9 — REMATCH_CONFIRM state ambiguous

`game-state-machine.md` includes `REMATCH_CONFIRM` between MATCH_END and MATCH,
but `match-result-screen.md` handles the rematch button directly with no separate
confirmation screen. The state appears redundant with MATCH_END.

**Fix**: Either define what REMATCH_CONFIRM renders (a distinct confirmation
screen), or simplify the state diagram to `MATCH_END → MATCH` and remove the
intermediate state.

---

### W10 — AUTO_SKIP must still tick status effects

`two-action-turn-system.md` must explicitly state that TURN_START fires (and
status effects tick) even during AUTO_SKIP. Without this, a both-restricted
player's counters never decrement and the restriction becomes permanent.

**Fix**: Add to two-action-turn-system.md AUTO_SKIP section: "TURN_START fires
normally at the beginning of an auto-skipped turn. Status effects tick as usual.
The turn is then immediately ended without player input."

---

### W11 — One-directional dependency declarations

Five dependency relationships are declared by one GDD but not reciprocated:

| GDD A declares | GDD B does not reciprocate |
|---|---|
| body-zone-hit-detection.md → win-condition.md (signals) | win-condition.md missing Hit Detection as dependency |
| figure-renderer.md → body-zone-hit-detection.md (reads hit result) | body-zone-hit-detection.md missing Figure Renderer as consumer |
| game-mode-manager.md → ai-targeting.md (controls) | ai-targeting.md missing Game Mode Manager as controller |
| two-action-turn-system.md (provides interface to HUD) | hud-turn-indicator.md missing this in "provides to" |
| action-validation.md (consumed by Turn System) | two-action-turn-system.md missing Action Validation as dependency |

**Fix**: Update each GDD's Dependencies table to be bidirectional.

---

## Info Items — Low impact, worth tracking

| # | Item | Location |
|---|------|----------|
| I1 | `figure_centre` vs `figure_anchor` naming inconsistency across Input System, Trajectory Visualization, Figure Geometry | Standardise on `figure_anchor` |
| I2 | Shot line information asymmetry — previous-turn lines visible during aiming phase | May be intentional; document as such |
| I3 | No in-game quit affordance except completing the match | Acceptable for MVP browser game |
| I4 | EASY `AIM_ERROR_DEG = 18°` may feel random rather than "sparring partner" | Playtest at 12° as alternative |
| I5 | HUD pip draw order under simultaneous status overlay and hit flash undefined | Minor — add draw order note to hud-turn-indicator.md |
| I6 | `halt()` and `reset()` not named as interface methods in Turn System GDD | Minor — resolve during architecture |
| I7 | No target AI win rate defined as playtesting baseline | Recommend: EASY ~25%, MEDIUM ~50%, HARD ~70% |

---

## Cross-System Scenario Issues

| Scenario | Systems Involved | Severity | Issue |
|----------|-----------------|----------|-------|
| Headshot on first action | Hit Detection → Win Condition | BLOCKER | Attacker identity not in hit signal (B6) |
| Headshot on first action | Turn System → Game State Machine | WARNING | Mid-turn halt state undefined (W4) |
| Headshot on first action | Trajectory Visualization → Game State Machine | WARNING | Shot line timer freeze undefined (W3) |
| Auto-skip turn | Status Effects → Turn System | WARNING | TURN_START must fire during AUTO_SKIP (W10) |
| Auto-skip turn | Status Effects tick scope | WARNING | Tick only on affected player's turn (W1) |
| AI FIRE action | AI Targeting → Action Validation | WARNING | AI doesn't check Action Validation (W2) |
| AI FIRE action | AI Difficulty Config → Shot Spread | WARNING | HARD power undermines accuracy (W5) |
| Match end → rematch | Game State Machine → all systems | BLOCKER | reset_all() undefined (B5) |
| Match end → rematch | Game State Machine → Match Result | WARNING | REMATCH_CONFIRM state ambiguous (W9) |

---

## Recommended Resolution Order Before Architecture

| Priority | Issue | Action |
|----------|-------|--------|
| 1 | B1 | Author Movement GDD |
| 2 | B5 | Add `reset()` contract to each system GDD |
| 3 | B6 | Pass attacker_id through hit signal |
| 4 | B2 | Fix signal routing in win-condition.md and game-mode-manager.md |
| 5 | B3 | Extend main-menu.md with difficulty selector |
| 6 | B4 | Add `get_zone_circle()` to figure-geometry.md; update body-zone-hit-detection.md |
| 7 | W1, W2, W4, W10 | Add spec text to status-effects.md, ai-targeting.md, two-action-turn-system.md |
| 8 | W3 | Add freeze-on-match-end spec to trajectory-visualization.md |
| 9 | W11 | Update asymmetric dependency tables across 5 GDDs |
| 10 | W8 | Add `TURN_INDICATOR_RECT` to screen-layout.md |

---

## Next Steps

- [ ] Author Movement GDD (`design/gdd/movement.md`) — system #19
- [ ] Apply fixes to flagged GDDs in resolution order above
- [ ] Re-run `/design-review` on each revised GDD
- [ ] Run `/gate-check pre-production` when all issues resolved
