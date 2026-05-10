# Architecture Review Report — Flick Duel

> **Date**: 2026-05-10
> **Reviewer**: /architecture-review skill (independent session)
> **Engine**: Godot 4.6 (Knowledge Risk: HIGH — post LLM cutoff)
> **GDDs Reviewed**: 19
> **ADRs Reviewed**: 10 (ADR-0007 pending — blocked on OQ-1)

---

## Traceability Summary

| Status | Count | % |
|--------|-------|---|
| ✅ Covered | 42 | 72% |
| ⚠️ Partial | 11 | 19% |
| ❌ Gap | 5 | 9% |
| **Total** | **58** | 100% |

---

## Coverage Gaps (No ADR Exists)

All 5 gaps trace to **ADR-0007 (Input System Architecture)**, which is explicitly blocked on OQ-1
(iOS Safari `InputEventScreenDrag` continuous-fire vs drag-end behaviour). This is expected and tracked.

| TR ID | GDD | Requirement | Suggested ADR | Engine Risk |
|-------|-----|-------------|---------------|-------------|
| TR-INP-003 | input-system.md | `InputEventScreenDrag` continuous vs drag-end behaviour | ADR-0007 | HIGH |
| TR-INP-004 | input-system.md | Input window deactivation on orientation change | ADR-0007 | HIGH |
| TR-SCRN-005 | input-system.md | Tap vs drag discrimination (dead zone radius) | ADR-0007 | MEDIUM |
| TR-MOV-002 | movement.md | Tap destination input routing (distinct from drag) | ADR-0007 | MEDIUM |
| TR-TVIS-003 | trajectory-visualization.md | Live aim line updates on drag events | ADR-0007 | MEDIUM |

**Resolution path**: Resolve OQ-1 (build iOS Safari drag event prototype) → write ADR-0007 → all 5 gaps close.

---

## Partial Coverage (11 Requirements)

Requirements where an ADR addresses the system but leaves one specific aspect implicit or underspecified:

| TR ID | System | Partial Issue | Action |
|-------|--------|---------------|--------|
| TR-TVIS-002 | Trajectory Visualization | freeze() implementation incorrect in ADR-0003 (set_meta vs tween.kill) | Update ADR-0003 |
| TR-AIR-002 | AI Targeting | Gaussian pre-error layer missing from ADR-0009 | Update ADR-0009 |
| TR-HUD-003 | HUD/Turn Indicator | MOUSE_FILTER_IGNORE cascade not specified in ADR-0010 | Update ADR-0010 |
| TR-HUD-004 | HUD/Turn Indicator | gui_release_focus() contract missing from ADR-0010 | Update ADR-0010 |
| TR-FIG-004 | Figure Geometry | P2 mirror boundary rule implicit in ADR-0001/0003 | Low risk — implicit in design |
| TR-GSM-001 | Game State Machine | GSM state routing not directly covered by any ADR | Implied by ADR-0001; low risk |
| TR-GSM-002 | Game State Machine | Scene visibility routing via show/hide | Implied by ADR-0001 |
| TR-GSM-003 | Game State Machine | State transitions trigger system resets | Covered in architecture.md data flow |
| TR-MNU-001 | Main Menu | show/hide Control subtree protocol | ADR-0010 covers hierarchy; gui_release_focus() missing |
| TR-MNU-002 | Main Menu | Difficulty selector subtree visibility | ADR-0010 covers; cascade not specified |
| TR-STE-005 | Status Effects | Method naming: set_disarmed/tick_effects/reset_all vs apply/tick/reset | Standardise across docs |

All partials are resolvable during ADR revision — no new ADRs required.

---

## Cross-ADR Conflicts

### 🔴 Conflict 1: ADR-0003 vs Figure Renderer GDD — Immobilized Visual

**ADR-0003 states**: Immobilized figure → `modulate = Color(0.4, 0.4, 0.4)` (grey shading over entire figure)

**Figure Renderer GDD states**: Immobilized → "bold X through the legs zone in the opponent's ink colour" — same treatment as Disarmed, different zone.

**Impact**: If ADR-0003 is implemented as written, the figure turns grey instead of showing a crossed-legs overlay. Contradicts Figure Renderer GDD Acceptance Criteria.

**Resolution**: Update ADR-0003. Immobilized visual = bold X through the legs rect in opponent ink colour, drawn by FigureRenderer. Grey shading removed. Consistent with Disarmed treatment (X through arms rect).

---

### 🔴 Conflict 2: ADR-0009 vs AI Targeting GDD — AI Accuracy Mechanism

**ADR-0009 states**: AI accuracy = single `spread_deg` passed to `ShotSpreadCalculation.apply_spread()` — same mechanism as human player.

**AI Targeting GDD states**: Two-layer accuracy model:
- Layer 1: Gaussian aim error (σ = `accuracy_spread_deg`) applied to the ideal direction vector *before* `FlickEvent` construction
- Layer 2: standard `ShotSpreadCalculation.apply_spread()` applied on top
- Additionally: `w_miss` zone weight in zone selection (deliberate miss at lower difficulties)

**Impact**: ADR-0009 as written produces a uniform spread distribution; GDD requires Gaussian. Difficulty scaling model is based on the Gaussian layer. The `w_miss` parameter for deliberate misses is entirely absent from ADR-0009.

**Resolution**: Update ADR-0009 to:
1. Add Gaussian pre-error layer before `FlickEvent` construction
2. Add `w_miss` to zone weight dictionary in `AIDifficultyConfig.get_params()`
3. Keep `apply_spread()` call — it is still used (both layers stack)

---

### ⚠️ Conflict 3: StatusEffects Method Naming Inconsistency

**architecture.md uses**: `apply(player_id, effect_type)`, `tick(player_id)`, `reset()`

**Status Effects GDD uses**: `set_disarmed()`, `set_immobilized()`, `tick_effects()`, `reset_all()`

**ADR-0004 critical path uses**: `StatusEffects.apply(target_player_id, zone)`

**Impact**: Naming inconsistency between documents. No runtime conflict but will cause implementation confusion.

**Resolution**: Standardise on GDD method names (more specific, self-documenting). Update `architecture.md` and ADR-0004 pseudocode:
- `apply()` → `set_disarmed()` / `set_immobilized()` (dispatched by zone inside StatusEffects)
- `tick()` → `tick_effects()`
- `reset()` → `reset_all()`

---

### ⚠️ Conflict 4: ADR-0003 freeze() Implementation — Tween Not Stopped

**ADR-0003 states**: `freeze()` marks lines via `line.set_meta(&"frozen", true)`.

**Problem**: `set_meta()` has no effect on an active `Tween`. The fade timer continues running and will free the `Line2D` node after `fade_duration`, violating TR-TVIS-002 (lines must persist during `HALTED` state).

**Resolution**: Store `Tween` references in `TrajectoryVisualization`. `freeze()` calls `tween.kill()` on each active tween, guarded by `is_instance_valid(tween)`. Update ADR-0003.

---

## ADR Dependency Order (Topologically Sorted)

No dependency cycles detected.

### Foundation (no dependencies — implement first)
1. ADR-0001: Scene Topology
2. ADR-0002: Web Export Memory
3. ADR-0003: Rendering Primitives ⚠️ needs revision before Accepted
4. ADR-0005: Physics Policy
5. ADR-0006: RNG Strategy
6. ADR-0008: FlickEvent Contract
7. ADR-0011: Test Framework

### Depends on Foundation
8. ADR-0004: System Communication (requires ADR-0001 scene contracts) ⚠️ needs naming update
9. ADR-0009: AI Pipeline (requires ADR-0008, ADR-0004) 🔴 needs revision before Accepted
10. ADR-0010: HUD Control Focus (requires ADR-0001, ADR-0003) ⚠️ needs engine findings added

### Pending
11. ADR-0007: Input System Architecture — blocked on OQ-1 (iOS Safari drag behaviour)

**ADRs clear to mark Accepted now** (no conflicts, no engine issues):
ADR-0001, ADR-0002, ADR-0005, ADR-0006, ADR-0008, ADR-0011

---

## GDD Revision Flags

**None.** All HIGH RISK engine findings affect ADR implementation details only.
GDD design assumptions are consistent with verified Godot 4.6 engine behaviour.

| Engine Finding | GDD Check | Result |
|---|---|---|
| `antialiased=false` wrong for Compatibility renderer | Figure Renderer GDD makes no assumption about `antialiased` property | ✅ No conflict |
| `MOUSE_FILTER_IGNORE` doesn't cascade to children | HUD GDD specifies design intent, not engine API | ✅ No conflict |
| `freeze()` needs `tween.kill()` | Trajectory Visualization GDD specifies intent, not implementation | ✅ No conflict |
| `gui_release_focus()` required before hiding Control subtrees | Menu GDDs define show/hide at design level only | ✅ No conflict |

---

## Engine Compatibility Issues

**Deprecated API References**: None — all ADRs are clean.

**Stale Version References**: None — all ADRs stamp Godot 4.6.

**Post-Cutoff Findings** (from godot-specialist consultation):

### Finding E1 — ADR-0003: Line2D.antialiased Default
ADR-0003 does not specify the `antialiased` property on `Line2D` nodes.
The Compatibility renderer (WebGL 2) has no hardware MSAA. Software anti-aliasing IS available and must be explicitly enabled.
**Action**: Add to ADR-0003 — set `antialiased = true` on all `Line2D` nodes.

### Finding E2 — ADR-0010: MOUSE_FILTER_IGNORE Does Not Cascade
`MOUSE_FILTER_IGNORE` set on a parent Control does NOT propagate to child nodes.
Godot 4.5+ provides a recursive Control disable mechanism.
ADR-0010 must specify: either set `MOUSE_FILTER_IGNORE` on every Control node in the HUD individually, OR use the Godot 4.5+ recursive approach.
**Action**: Update ADR-0010 with an explicit per-node vs recursive decision.

### Finding E3 — ADR-0003: freeze() Tween Lifecycle
`set_meta()` has no effect on Tween timers. (See Conflict 4 above.)
**Action**: Update ADR-0003 freeze() to call `tween.kill()` with `is_instance_valid()` guard.

### Finding E4 — ADR-0010: gui_release_focus() Before Hiding Control Subtrees
Godot 4.6 dual-focus system: if a `Control` inside a subtree holds focus when the subtree is hidden, input routing breaks. `gui_release_focus()` must be called before any `hide()` or `visible = false` on Control subtrees.
**Action**: Add to ADR-0010 as an explicit contract in show/hide lifecycle.

---

## Architecture Document Coverage

All **19/19** systems from `systems-index.md` appear in `architecture.md`. No orphaned architecture. No missing systems.

Data flow scenarios cover all four key multi-system paths:
- ✅ Core Flick Shot (human player) — full pipeline from gesture to state update
- ✅ AI Turn — Gaussian pre-error + spread + join at on_action_selected()
- ✅ Match Lifecycle — start, win, halt, result, rematch/reset
- ✅ Orientation Gate — viewport change, input suspend, resume

---

## Verdict: CONCERNS

### Passing criteria
- ✅ All Foundation layer requirements have ADR coverage
- ✅ No deprecated API usage across all ADRs
- ✅ Engine version consistent (Godot 4.6) across all 10 ADRs
- ✅ All 19 systems present in architecture.md
- ✅ No ADR dependency cycles
- ✅ No GDD revision flags

### Concerns (resolve before marking ADRs Accepted)
- 🔴 ADR-0003: Immobilized visual incorrect — update before Accepted
- 🔴 ADR-0009: AI accuracy mechanism incomplete — update before Accepted
- ⚠️ ADR-0003: freeze() implementation bug — update before Accepted
- ⚠️ ADR-0003: Line2D.antialiased not specified — add before Accepted
- ⚠️ ADR-0009: w_miss zone weight missing — update before Accepted
- ⚠️ ADR-0010: MOUSE_FILTER_IGNORE cascade undocumented — update before Accepted
- ⚠️ ADR-0010: gui_release_focus() contract missing — update before Accepted
- ⚠️ ADR-0007: 5 input requirements uncovered (blocked on OQ-1 — tracked)
- ⚠️ StatusEffects method names inconsistent across architecture.md + ADR-0004

### Not blocking
- ADR-0007 absence is expected; OQ-1 has a clear resolution path (iOS Safari prototype)
- All conflicts require ADR revisions only — no new GDDs or new ADRs needed
- Architecture document is structurally complete; no layer gaps

---

## Required Actions Before Pre-Production Gate

### Priority 1 — Fix RED conflicts (before any ADR marked Accepted)
1. Update ADR-0003: Immobilized visual → bold X in opponent colour (not grey shading)
2. Update ADR-0003: freeze() → store Tween refs + `tween.kill()` + `is_instance_valid()` guard
3. Update ADR-0003: add `Line2D.antialiased = true` specification
4. Update ADR-0009: add Gaussian pre-error layer before FlickEvent construction
5. Update ADR-0009: add `w_miss` parameter to `AIDifficultyConfig.get_params()` spec
6. Update ADR-0010: document MOUSE_FILTER_IGNORE per-node vs recursive decision
7. Update ADR-0010: add `gui_release_focus()` contract to show/hide lifecycle
8. Standardise StatusEffects method names: update architecture.md + ADR-0004 pseudocode

### Priority 2 — Complete ADR set
9. Resolve OQ-1 (build iOS Safari drag event prototype to test continuous vs drag-end)
10. Write ADR-0007 from OQ-1 findings

### Priority 3 — Accept clean ADRs
11. Mark ADR-0001, ADR-0002, ADR-0005, ADR-0006, ADR-0008, ADR-0011 → **Accepted**
    (no conflicts, no engine issues; these are ready)

### After all above complete
- Run `/create-control-manifest` (requires all ADRs to be Accepted)
- Run `/gate-check pre-production`
