## Prototype Report: Flick Duel VS — Vertical Slice

**Date**: 2026-05-14
**Prototype**: `prototypes/flick-duel-vs/`
**Status**: CONCLUDED

---

### Hypothesis

The slingshot-drag-to-fire mechanic will feel satisfying and immediately legible.
A 2-action turn loop (tap-move + flick-fire) will create genuine tension and a
sense of clever play.

### Approach

Single GDScript file (~390 lines). Implemented: notebook-paper background, two
ink-colored stick figures with head/arms/legs hit zones, slingshot drag-to-fire,
tap-to-move (anywhere in own half), analytic ray hit detection, 2-action turn
system, fading shot lines, zone flash feedback, win condition. No spread, no AI,
no sound, no animations.

### Result

Playtest confirmed the core loop works and feels good. The slingshot direction
was intuitive within 1–2 shots. Tap-to-move anywhere in the player's half felt
responsive and more generous than expected. The 2-action structure produced
natural move-then-fire sequences with real decision pressure. Zone flash feedback
was visible and satisfying.

### Metrics

- Playtest sessions completed: 1
- Feel assessment: Core mechanic validated — slingshot feels natural, turns feel tense
- Slingshot confusion: none after first shot
- Tap-to-move: worked as expected
- Zone feedback: flash readable
- Would play again: yes

### Recommendation: PROCEED

The core pen-flick loop is fun and legible. The mechanic earns its design pillars:
Skill Earns the Win (shots go where aimed), Two Actions One Regret (move vs fire
decision is real), Instant to Learn (learnable in one turn). Production
implementation should proceed.

### If Proceeding

- Add shot spread (σ ≈ 3–5°) to restore physical pen-flick variance — perfect
  accuracy makes head shots too reliable from center position
- Implement status effect consequences: arms hit → fire only, legs hit → no move
- Turn indicator needs stronger visual treatment for shared-screen clarity
- Tap-to-move anywhere in zone (not 48px radius) is more ergonomic than GDD spec —
  recommend updating the movement GDD to reflect this finding
- Production must use Line2D nodes per ADR-0003, not _draw() calls

### Lessons Learned

- The 48px figure-drag radius for firing felt correct — natural to grab your figure
- Tap-anywhere-in-zone for movement is better UX than tap-near-figure; update GDD
- Without spread, the head is an easy target from directly opposite — spread is
  a necessary tuning knob for balance, not just feel
- Zone ghost-outline on disable was clear enough without additional text labels
