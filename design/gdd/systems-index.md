# Systems Index: Flick Duel

> **Status**: Approved
> **Created**: 2026-05-06
> **Last Updated**: 2026-05-06
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Flick Duel is a mechanically compact 1v1 dueling game. Its systems decompose into four tight clusters: a gesture-driven shot system, a turn engine that enforces the two-action structure and status effects, a lightweight AI for solo play, and a minimal presentation layer for shared-screen clarity. There is no progression, no economy, no persistence, and no narrative — every system exists to serve the core loop of drag-release-hit-react. The bottleneck systems are Figure Geometry (spatial ground truth for every collision and rendering decision) and the Two-Action Turn System (structural backbone of the game). Both must be designed and stabilised before the Feature layer can be built.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Screen Layout | Core Gameplay | MVP | Designed | design/gdd/screen-layout.md | — |
| 2 | Status Effects | Core Gameplay | MVP | Designed | design/gdd/status-effects.md | — |
| 3 | Input System | Core Gameplay | MVP | Designed | design/gdd/input-system.md | — |
| 4 | Shot Spread Calculation | Core Gameplay | MVP | Designed | design/gdd/shot-spread-calculation.md | — |
| 5 | Figure Geometry | Core Gameplay | MVP | Designed | design/gdd/figure-geometry.md | Screen Layout |
| 6 | Action Validation *(inferred)* | Core Gameplay | MVP | Designed | design/gdd/action-validation.md | Status Effects |
| 7 | Trajectory Visualization *(inferred)* | Core Gameplay | MVP | Designed | design/gdd/trajectory-visualization.md | Input System, Screen Layout |
| 8 | Body-Zone Hit Detection | Core Gameplay | MVP | Designed | design/gdd/body-zone-hit-detection.md | Figure Geometry |
| 9 | Two-Action Turn System | Core Gameplay | MVP | Designed | design/gdd/two-action-turn-system.md | Action Validation, Status Effects |
| 10 | Win Condition | Core Gameplay | MVP | Designed | design/gdd/win-condition.md | Body-Zone Hit Detection |
| 11 | Game Mode Manager *(inferred)* | Game Flow | MVP | Designed | design/gdd/game-mode-manager.md | Two-Action Turn System |
| 12 | Game State Machine *(inferred)* | Game Flow | MVP | Designed | design/gdd/game-state-machine.md | Win Condition, Game Mode Manager |
| 13 | Main Menu *(inferred)* | Game Flow | MVP | Designed | design/gdd/main-menu.md | Game State Machine |
| 14 | AI Targeting | AI | MVP | Designed | design/gdd/ai-targeting.md | Figure Geometry, Game Mode Manager |
| 15 | AI Difficulty Config *(inferred)* | AI | MVP | Designed | design/gdd/ai-difficulty-config.md | AI Targeting |
| 16 | Figure Renderer *(inferred)* | Presentation | MVP | Designed | design/gdd/figure-renderer.md | Figure Geometry, Status Effects |
| 17 | HUD / Turn Indicator *(inferred)* | Presentation | MVP | Not Started | — | Two-Action Turn System, Status Effects |
| 18 | Match Result Screen *(inferred)* | Presentation | V1.0 | Not Started | — | Game State Machine |

---

## Categories

| Category | Description | Systems in This Game |
|----------|-------------|----------------------|
| **Core Gameplay** | The raw gesture, geometry, collision, and turn mechanics | Screen Layout, Status Effects, Input System, Shot Spread Calculation, Figure Geometry, Action Validation, Trajectory Visualization, Body-Zone Hit Detection, Two-Action Turn System, Win Condition |
| **Game Flow** | Match lifecycle, mode routing, and entry/exit points | Game Mode Manager, Game State Machine, Main Menu |
| **AI** | Computer opponent behaviour and difficulty configuration | AI Targeting, AI Difficulty Config |
| **Presentation** | Visual rendering and shared-screen information display | Figure Renderer, HUD / Turn Indicator, Match Result Screen |

---

## Priority Tiers

| Tier | Definition | Systems |
|------|------------|---------|
| **MVP** | Required for the core loop to function — without these, "is this fun?" can't be tested | 17 systems |
| **V1.0** | Polish and flow improvements on top of a working MVP | 1 system (Match Result Screen) |
| **Full Vision** | Not yet identified — add here as scope expands | — |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Screen Layout** — defines P1-left / P2-right positions; all spatial decisions reference this
2. **Status Effects** — pure state data (disarmed, immobilized); depended on by 4 systems
3. **Input System** — reads hardware gesture; produces angle + power for the shot pipeline
4. **Shot Spread Calculation** — pure math; angular variance function called at shot resolution

### Core Layer (depends on Foundation)

1. **Figure Geometry** — depends on: Screen Layout. Defines stick figure as spatial object with three named hit zones and their collision boundaries. Bottleneck — gates Hit Detection, Renderer, and AI.
2. **Action Validation** — depends on: Status Effects. Determines which actions a player may take given current status.
3. **Trajectory Visualization** — depends on: Input System, Screen Layout. Draws live aim line during drag; fires and persists shot line on release.

### Feature Layer (depends on Core)

1. **Body-Zone Hit Detection** — depends on: Figure Geometry. Tests fired shot line against zone boundaries; resolves hit zone or miss.
2. **Two-Action Turn System** — depends on: Action Validation, Status Effects. Manages 2-action pool, action ordering, turn-end handoff. Bottleneck — gates Game Mode Manager, HUD, AI.

### Feature+ Layer (depends on Feature)

1. **Win Condition** — depends on: Body-Zone Hit Detection. Fires on headshot; triggers match end.
2. **Game Mode Manager** — depends on: Two-Action Turn System. Routes VS Player (human/human) vs VS Computer (human/AI) through a unified turn interface.
3. **AI Targeting** — depends on: Figure Geometry, Game Mode Manager. Selects target zone and position each AI turn.
4. **AI Difficulty Config** — depends on: AI Targeting. Parameter tables (accuracy, zone weights) defining difficulty without separate code paths.
5. **Figure Renderer** — depends on: Figure Geometry, Status Effects. Draws stick figure with correct visual state per active status effect (crossed arm, shaded legs).

### Presentation Layer (depends on Feature+)

1. **Game State Machine** — depends on: Win Condition, Game Mode Manager. Owns top-level match lifecycle: menu → mode select → in-match → result.
2. **HUD / Turn Indicator** — depends on: Two-Action Turn System, Status Effects. Displays whose turn it is, actions remaining, and active status effects. Critical for shared-screen clarity.
3. **Main Menu** — depends on: Game State Machine. VS Player / VS Computer entry point.
4. **Match Result Screen** *(V1.0)* — depends on: Game State Machine. Win/loss display and rematch flow.

---

## Circular Dependencies

None detected.

---

## Recommended Design Order

| Order | System | Priority | Layer | Effort |
|-------|--------|----------|-------|--------|
| 1 | Screen Layout | MVP | Foundation | S |
| 2 | Status Effects | MVP | Foundation | S |
| 3 | Input System | MVP | Foundation | M |
| 4 | Shot Spread Calculation | MVP | Foundation | S |
| 5 | Figure Geometry | MVP | Core | M |
| 6 | Action Validation | MVP | Core | S |
| 7 | Trajectory Visualization | MVP | Core | M |
| 8 | Body-Zone Hit Detection | MVP | Feature | M |
| 9 | Two-Action Turn System | MVP | Feature | M |
| 10 | Win Condition | MVP | Feature+ | S |
| 11 | AI Targeting | MVP | Feature+ | L |
| 12 | AI Difficulty Config | MVP | Feature+ | S |
| 13 | Game Mode Manager | MVP | Feature+ | S |
| 14 | Figure Renderer | MVP | Feature+ | M |
| 15 | Game State Machine | MVP | Presentation | S |
| 16 | HUD / Turn Indicator | MVP | Presentation | M |
| 17 | Main Menu | MVP | Presentation | S |
| 18 | Match Result Screen | V1.0 | Presentation | S |

*Effort: S = 1 session, M = 2–3 sessions, L = 4+ sessions.*

Systems at the same layer with no inter-dependencies (e.g., Screen Layout, Status Effects, Input System, Shot Spread Calculation) may be designed in parallel if multiple sessions are available.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Figure Geometry | Design | Zone boundary sizes must reward intent without making headshots trivial or impossible. Wrong sizing kills the core fantasy. | Design with explicit formulas for zone dimensions. Prototype with adjustable zone sizes and playtest with 3–5 pairs before finalising. |
| Input System | Technical | Drag-and-release must feel satisfying on both glass (touch) and mouse. Imprecision or input lag breaks the core loop at a physical level. | Build a one-screen gesture prototype before any game logic — validate feel first. Run on target browsers (Chrome mobile, Safari iOS) as primary test targets. |
| AI Targeting | Design + Scope | An AI that aims randomly feels pointless; one that aims perfectly feels unfair. Believable difficulty calibration is a hidden design problem that can balloon in scope. | Start with heuristic rules (not ML). Define target AI win rates per difficulty as design constraints, not implementation afterthoughts. Design AI Difficulty Config alongside AI Targeting in the same session. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 18 |
| Design docs started | 2 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 2 / 17 |
| V1.0 systems designed | 0 / 1 |

---

## Next Steps

- [ ] Design MVP systems in the order above — run `/design-system [system-name]`
- [ ] Prototype the Input System and Figure Geometry before finalising zone size specs — run `/prototype flick-shot-mechanic`
- [ ] Run `/design-review design/gdd/[system].md` after each completed GDD
- [ ] Run `/gate-check pre-production` when all MVP GDDs are authored and reviewed
- [ ] Update this index (Status column, Progress Tracker) as each GDD is completed
