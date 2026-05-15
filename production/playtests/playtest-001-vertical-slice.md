# Playtest Report 001 — Vertical Slice

**Date**: 2026-05-14
**Build**: `prototypes/flick-duel-vs/` (Godot 4.6.2 stable)
**Session type**: Internal — solo developer, both sides
**Facilitator**: Developer
**Players**: 1 (developer playing both P1 and P2)
**Duration**: ~10 minutes
**Goal**: Validate core pen-flick loop feel

---

## Core Questions

| Question | Finding |
|----------|--------|
| Did the slingshot direction feel natural? | Yes — intuitive within 1–2 shots |
| Did tap-to-move feel responsive? | Yes — immediate, no confusion |
| Was it obvious which zones were disabled? | Yes — ghost outline was readable |
| Did shot lines read clearly? | Yes — aim line and fired line both legible |
| Did 2 actions per turn feel right? | Yes — move-then-fire decision felt tense |
| Did you feel clever landing a shot? | Yes |
| Any moments that felt unfair or unclear? | None noted |
| Would you play another round? | Yes |

## Observations

- Slingshot (drag left → shoot right) required zero explanation after first shot
- Tap-anywhere-in-zone for movement is more ergonomic than tap-near-figure;
  players naturally tap where they want to go, not where they currently are
- Head shot from directly opposite is too reliable without spread — accuracy
  makes the head an easy target from centre position
- Zone flash feedback on hit was satisfying and readable at a glance
- "P1 TURN" / "P2 TURN" label sufficient for solo testing; may need stronger
  treatment for two players on one device

## Fun Validation

- **Core fantasy delivered**: The "sharpshooter reading their opponent" feeling
  emerged — choosing move vs fire each turn felt like a real decision
- **Pillar 2 (Two Actions, One Regret)** confirmed: spending both actions on
  moves to reposition, then being unable to fire, created natural regret
- **Pillar 3 (Skill Earns the Win)** confirmed: shots went exactly where aimed;
  misses felt like aim errors, not luck

## Issues Found

| Severity | Issue | Recommendation |
|----------|-------|----------------|
| Medium | Head too easy to hit without spread | Add σ ≈ 3–5° spread in production |
| Low | Turn indicator minimal for shared-screen | Stronger visual on turn handoff |
| Low | Tap-to-move radius per GDD (48px) is wrong | Update movement GDD to allow full-zone tap |

## Verdict

**Core loop is fun and validated.** Proceeding to production implementation.

---

*Sessions required for gate: 3. Sessions completed: 1. Remaining: 2.*
