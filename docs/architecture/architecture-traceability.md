# Architecture Traceability Index — Flick Duel

> **Generated**: 2026-05-10 by `/architecture-review`
> **Coverage**: 42/58 covered (72%) · 11/58 partial (19%) · 5/58 gaps (9%)
> **ADRs in scope**: ADR-0001–0006, ADR-0008–0011 (ADR-0007 pending OQ-1)

## Coverage Key

| Symbol | Meaning |
|--------|---------|
| ✅ | ADR explicitly addresses this requirement |
| ⚠️ | ADR partially covers; one aspect implicit or missing |
| ❌ | No ADR addresses this requirement |

---

## Traceability Matrix

| TR ID | GDD | System | Requirement | ADR Coverage | Status |
|-------|-----|--------|-------------|--------------|--------|
| TR-SCRN-001 | screen-layout.md | Screen Layout | Canvas 800×450 px, 16:9 | ADR-0002 | ✅ |
| TR-SCRN-002 | screen-layout.md | Screen Layout | Keep Aspect letterbox scaling | ADR-0002 | ✅ |
| TR-SCRN-003 | screen-layout.md | Screen Layout | P1-left / P2-right spatial split | ADR-0001 | ✅ |
| TR-SCRN-004 | screen-layout.md | Screen Layout | HUD strip 90 px top band | ADR-0010 | ✅ |
| TR-SCRN-005 | screen-layout.md | Screen Layout | Gesture dead zone / tap vs drag discrimination | — (ADR-0007 pending) | ❌ |
| TR-STE-001 | status-effects.md | Status Effects | Disarmed state: can_fire = false for N turns | ADR-0004 | ✅ |
| TR-STE-002 | status-effects.md | Status Effects | Immobilized state: can_move = false for N turns | ADR-0004 | ✅ |
| TR-STE-003 | status-effects.md | Status Effects | tick_effects() called each turn start | ADR-0004 | ✅ |
| TR-STE-004 | status-effects.md | Status Effects | reset_all() restores clean state on rematch | ADR-0001 | ✅ |
| TR-STE-005 | status-effects.md | Status Effects | Method API: set_disarmed / tick_effects / reset_all | ADR-0004 | ⚠️ (naming mismatch with architecture.md) |
| TR-INP-001 | input-system.md | Input System | Mouse drag → FlickEvent (direction, power, timestamp) | ADR-0008 | ✅ |
| TR-INP-002 | input-system.md | Input System | Touch drag → FlickEvent (same as mouse) | ADR-0008 | ✅ |
| TR-INP-003 | input-system.md | Input System | InputEventScreenDrag: continuous vs drag-end | — (ADR-0007 pending OQ-1) | ❌ |
| TR-INP-004 | input-system.md | Input System | Input window deactivation on orientation change | — (ADR-0007 pending OQ-1) | ❌ |
| TR-SSC-001 | shot-spread-calculation.md | Shot Spread | apply_spread(event, spread_deg) → final Vector2 | ADR-0004, ADR-0009 | ✅ |
| TR-SSC-002 | shot-spread-calculation.md | Shot Spread | RngService seeded for determinism in tests | ADR-0006 | ✅ |
| TR-SSC-003 | shot-spread-calculation.md | Shot Spread | Spread range configurable per difficulty | ADR-0009 | ✅ |
| TR-FIG-001 | figure-geometry.md | Figure Geometry | get_zone_circle(player_id) → {centre, radius} for HEAD | ADR-0005 | ✅ |
| TR-FIG-002 | figure-geometry.md | Figure Geometry | get_zone_rect(player_id, zone) → Rect2 for ARMS/LEGS | ADR-0005 | ✅ |
| TR-FIG-003 | figure-geometry.md | Figure Geometry | Anchor repositions on MOVE; zones track with anchor | ADR-0001 | ✅ |
| TR-FIG-004 | figure-geometry.md | Figure Geometry | P2 mirror: X offsets negated; hit boundaries unchanged | ADR-0001, ADR-0003 | ⚠️ (implicit) |
| TR-ACV-001 | action-validation.md | Action Validation | get_valid_actions(player_id) respects Status Effects | ADR-0004 | ✅ |
| TR-ACV-002 | action-validation.md | Action Validation | AUTO_SKIP when no actions valid | ADR-0004 | ✅ |
| TR-TVIS-001 | trajectory-visualization.md | Trajectory Viz | Live aim line draws during drag | ADR-0003 | ✅ |
| TR-TVIS-002 | trajectory-visualization.md | Trajectory Viz | Shot line persists during HALTED state (freeze) | ADR-0003 | ⚠️ (freeze() implementation bug — tween.kill() missing) |
| TR-TVIS-003 | trajectory-visualization.md | Trajectory Viz | Live aim line updates on each drag event | — (ADR-0007 pending OQ-1) | ❌ |
| TR-TVIS-004 | trajectory-visualization.md | Trajectory Viz | Shot lines fade via Tween + is_instance_valid() guard | ADR-0003 | ✅ |
| TR-TVIS-005 | trajectory-visualization.md | Trajectory Viz | reset() clears all shot lines on rematch | ADR-0001 | ✅ |
| TR-MOV-001 | movement.md | Movement | MOVE action repositions anchor X within player zone | ADR-0004 | ✅ |
| TR-MOV-002 | movement.md | Movement | Tap destination routing (distinct from flick drag) | — (ADR-0007 pending OQ-1) | ❌ |
| TR-BZHD-001 | body-zone-hit-detection.md | Hit Detection | ray_vs_circle() for HEAD zone | ADR-0005 | ✅ |
| TR-BZHD-002 | body-zone-hit-detection.md | Hit Detection | ray_vs_aabb() (slab method) for ARMS/LEGS zones | ADR-0005 | ✅ |
| TR-BZHD-003 | body-zone-hit-detection.md | Hit Detection | Returns StringName: &"HEAD" / &"ARMS" / &"LEGS" / &"MISS" | ADR-0004, ADR-0005 | ✅ |
| TR-TATS-001 | two-action-turn-system.md | Turn System | begin_turn() → TURN_START → AWAITING_FIRST_ACTION | ADR-0004 | ✅ |
| TR-TATS-002 | two-action-turn-system.md | Turn System | on_action_selected() synchronous critical path | ADR-0004 | ✅ |
| TR-TATS-003 | two-action-turn-system.md | Turn System | reset() post-conditions: IDLE, pool cleared | ADR-0001 | ✅ |
| TR-TATS-004 | two-action-turn-system.md | Turn System | halt() discards in-progress turn without TURN_END | ADR-0001, ADR-0004 | ✅ |
| TR-TATS-005 | two-action-turn-system.md | Turn System | Turn states: IDLE/TURN_START/AWAITING_*/ACTION_EXECUTING/TURN_END/AUTO_SKIP/HALTED | ADR-0004 | ✅ |
| TR-WIN-001 | win-condition.md | Win Condition | Headshot → match_won signal | ADR-0004 | ✅ |
| TR-WIN-002 | win-condition.md | Win Condition | check() is stateless | ADR-0004 | ✅ |
| TR-GMM-001 | game-mode-manager.md | Game Mode Mgr | on_mode_selected() creates MatchConfig | ADR-0001 | ✅ |
| TR-GMM-002 | game-mode-manager.md | Game Mode Mgr | is_ai(player_id) → bool for AI routing | ADR-0009 | ✅ |
| TR-GMM-003 | game-mode-manager.md | Game Mode Mgr | on_rematch() re-emits match_ready with same config | ADR-0001 | ✅ |
| TR-GSM-001 | game-state-machine.md | Game State Machine | States: MENU / MODE_SELECT / IN_MATCH / RESULT | ADR-0001 | ⚠️ (implied by scene topology) |
| TR-GSM-002 | game-state-machine.md | Game State Machine | Scene visibility routing via show/hide (not change_scene) | ADR-0001 | ⚠️ (implied — single scene decision) |
| TR-GSM-003 | game-state-machine.md | Game State Machine | State transition orchestrates all system resets | ADR-0001 | ⚠️ (covered in architecture.md data flow; no ADR directly) |
| TR-MNU-001 | main-menu.md | Main Menu | show/hide Control subtree on state transitions | ADR-0010 | ⚠️ (gui_release_focus() contract missing) |
| TR-MNU-002 | main-menu.md | Main Menu | Difficulty selector subtree visibility | ADR-0010 | ⚠️ (cascade not specified) |
| TR-AIR-001 | ai-targeting.md | AI Targeting | select_action() reads FigureGeometry + AIDifficultyConfig | ADR-0009 | ✅ |
| TR-AIR-002 | ai-targeting.md | AI Targeting | Gaussian pre-error applied before FlickEvent construction | ADR-0009 | ⚠️ (Gaussian layer missing — only spread layer specified) |
| TR-AIR-003 | ai-targeting.md | AI Targeting | AI joins shot pipeline at on_action_selected() | ADR-0009 | ✅ |
| TR-AIR-004 | ai-targeting.md | AI Targeting | Zone selection by weighted random (w_miss for deliberate miss) | ADR-0009 | ⚠️ (w_miss not in AIDifficultyConfig spec) |
| TR-ADC-001 | ai-difficulty-config.md | AI Difficulty | get_params() → {accuracy_spread_deg, zone_weights, distances} | ADR-0009 | ✅ |
| TR-ADC-002 | ai-difficulty-config.md | AI Difficulty | Difficulty levels: Easy / Medium / Hard | ADR-0009 | ✅ |
| TR-FRD-001 | figure-renderer.md | Figure Renderer | Line2D nodes; jitter baked at _ready() | ADR-0003 | ✅ |
| TR-FRD-002 | figure-renderer.md | Figure Renderer | Disarmed overlay: bold X through arms in opponent colour | ADR-0003 | ✅ |
| TR-FRD-003 | figure-renderer.md | Figure Renderer | Immobilized overlay: bold X through legs in opponent colour | ADR-0003 | ⚠️ (ADR-0003 says grey shading — conflicts with GDD 🔴) |
| TR-HUD-001 | hud-turn-indicator.md | HUD/Turn Indicator | Turn arrow in active player ink colour | ADR-0010 | ✅ |
| TR-HUD-002 | hud-turn-indicator.md | HUD/Turn Indicator | CanvasLayer layer=1 for HUD | ADR-0010 | ✅ |
| TR-HUD-003 | hud-turn-indicator.md | HUD/Turn Indicator | MOUSE_FILTER_IGNORE on HUD subtree | ADR-0010 | ⚠️ (cascade behaviour not documented) |
| TR-HUD-004 | hud-turn-indicator.md | HUD/Turn Indicator | HUD input does not interfere with gesture area | ADR-0010 | ⚠️ (gui_release_focus() protocol not in ADR) |
| TR-MRS-001 | match-result-screen.md | Match Result Screen | show_result(winner_id, config) displays win/loss | ADR-0001 | ✅ |
| TR-MRS-002 | match-result-screen.md | Match Result Screen | rematch_requested() signal triggers full reset | ADR-0001 | ✅ |

---

## Coverage by System

| System | Requirements | ✅ | ⚠️ | ❌ |
|--------|-------------|----|----|-----|
| Screen Layout | 5 | 4 | 0 | 1 |
| Status Effects | 5 | 4 | 1 | 0 |
| Input System | 4 | 2 | 0 | 2 |
| Shot Spread Calculation | 3 | 3 | 0 | 0 |
| Figure Geometry | 4 | 3 | 1 | 0 |
| Action Validation | 2 | 2 | 0 | 0 |
| Trajectory Visualization | 5 | 3 | 1 | 1 |
| Movement | 2 | 1 | 0 | 1 |
| Body-Zone Hit Detection | 3 | 3 | 0 | 0 |
| Two-Action Turn System | 5 | 5 | 0 | 0 |
| Win Condition | 2 | 2 | 0 | 0 |
| Game Mode Manager | 3 | 3 | 0 | 0 |
| Game State Machine | 3 | 0 | 3 | 0 |
| Main Menu | 2 | 0 | 2 | 0 |
| AI Targeting | 4 | 2 | 2 | 0 |
| AI Difficulty Config | 2 | 2 | 0 | 0 |
| Figure Renderer | 3 | 2 | 1 | 0 |
| HUD/Turn Indicator | 4 | 2 | 2 | 0 |
| Match Result Screen | 2 | 2 | 0 | 0 |
| **Total** | **58** | **42** | **11** | **5** |

---

## Foundation Layer Gap Check

> Pre-Production gate requires zero Foundation layer gaps.

Foundation layer systems: Screen Layout, Status Effects, Input System, Shot Spread Calculation

| System | Gaps | Notes |
|--------|------|-------|
| Screen Layout | 1 ❌ | TR-SCRN-005 — tap vs drag discrimination (ADR-0007, blocked on OQ-1) |
| Status Effects | 0 ❌ | ✅ Clean |
| Shot Spread Calculation | 0 ❌ | ✅ Clean |
| Input System | 2 ❌ | TR-INP-003, TR-INP-004 — both ADR-0007, blocked on OQ-1 |

> ⚠️ **3 Foundation gaps exist** — all trace to ADR-0007 (pending OQ-1).
> The Pre-Production gate will require ADR-0007 to be written and Accepted
> before this traceability matrix can show zero Foundation gaps.
