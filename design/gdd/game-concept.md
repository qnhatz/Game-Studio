# Game Concept: Flick Duel

*Created: 2026-05-06*
*Status: Draft*

---

## Elevator Pitch

> A 2-player local browser game where you take turns firing shots by dragging and releasing a virtual pen. Aim for body zones — head to win instantly, arms to disarm, legs to immobilize — in a tense turn-based duel on one shared screen. Play against a friend or go solo against the computer.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Turn-based action / Local multiplayer dueling |
| **Platform** | Web / Browser |
| **Target Audience** | Competitors and casual social players, ages 12–35 |
| **Player Count** | 2-player local (same device) or 1-player vs Computer |
| **Session Length** | 3–10 minutes per match |
| **Monetization** | None (free to play, no monetization in MVP) |
| **Estimated Scope** | Small (2–4 weeks, solo developer) |
| **Comparable Titles** | Pocket Tanks, Disc Golf Battle, Nocked |

---

## Core Fantasy

You are the sharpshooter who reads their opponent and places the perfect shot. Every turn is a micro-decision — do you move into position first or fire before they can reposition? Aim for the guaranteed arm disable, or risk the kill shot to the head? The fantasy is not just winning — it's winning *cleverly*, with a shot your opponent saw coming and couldn't stop.

---

## Unique Hook

Like a turn-based shooter, AND ALSO the entire mechanic is a direct digital translation of the physical classroom pen-flick game — your finger drag becomes a ballistic shot, the spread on release mirrors a pen's tips opening on impact. Anyone who ever played the paper version recognises it instantly.

---

## Visual Identity Anchor

**Direction: "Notebook Duel"**

*One-line rule*: Everything looks like it was drawn with a ballpoint pen on lined notebook paper.

**Supporting principles:**
1. **Hand-drawn geometry** — stick figures, shot lines, and UI elements are clean but imperfect, as if sketched by a steady hand. *Design test*: "Should we use smooth vector UI?" → Only if it reads as drawn, not as polished digital.
2. **Minimal palette** — high-contrast black lines on white/cream. Player differentiation through pen colour (blue vs. red ink). *Design test*: "Should we add shading or gradients?" → Only if it looks like ink wash, not digital colour.
3. **Paper-space arena** — the battlefield IS the notebook page. Ruled lines are visible. The edge of the page is the edge of the world. *Design test*: "Should we add a background environment?" → No. The page IS the environment.

**Colour philosophy**: Near-monochrome with two accent ink colours (Player 1: blue ink, Player 2: red ink). Hit effects use the attacker's ink colour — a red streak on a blue figure's head.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 2 | Snap of the flick gesture, line drawing across screen, haptic hit feedback |
| **Fantasy** (make-believe, role-playing) | N/A | No narrative identity layer |
| **Narrative** (drama, story arc) | N/A | No story — player-generated drama only |
| **Challenge** (obstacle course, mastery) | 1 | Precision aiming, positioning decisions, zone targeting under pressure |
| **Fellowship** (social connection) | 3 | Pass-the-phone local play creates shared physical moments |
| **Discovery** (exploration, secrets) | N/A | No hidden content |
| **Expression** (self-expression, creativity) | N/A | No build or customisation system in MVP |
| **Submission** (relaxation, comfort zone) | N/A | Not a relaxation game |

### Key Dynamics (Emergent player behaviors)

- Players will naturally develop preferred opening moves (aggressive headshot gamble vs. conservative arm-targeting)
- Players will begin reading opponent positioning to predict where they'll move before firing
- Players will debate shot calls after the match — "why did you aim there?" creates natural post-game conversation
- Against the computer, players will probe AI behaviour to find predictable patterns to exploit

### Core Mechanics (Systems we build)

1. **Drag-and-release shot mechanic** — player drags from their stick figure outward; release direction and distance determine shot trajectory, with slight spread variance on release to mirror pen-tip opening
2. **Body-zone hit detection** — each stick figure has three discrete hit zones (head, upper torso/arms, lower torso/legs) with distinct, permanent consequences per zone
3. **Two-action turn system** — each turn grants exactly 2 actions (move, fire) in any order; status effects (disarmed, immobilized) remove specific actions from the affected player's pool
4. **AI opponent** — a computer-controlled opponent for solo play with at least two difficulty settings; AI selects target zones and positioning using simple heuristics, not perfect play
5. **Win condition** — game ends immediately when a headshot lands; no health bar, no attrition

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Move-or-fire ordering, zone targeting choice, positioning decisions each turn | Supporting |
| **Competence** (mastery, skill growth) | Consistent aiming rewards practice; players visibly improve at landing zone shots | Core |
| **Relatedness** (connection, belonging) | Physical pass-the-phone format; shared screen creates side-by-side social moment | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — Landing a headshot under pressure is a clear, satisfying goal; winning streaks feel earned
- [ ] **Explorers** — No discovery layer; not this game's audience
- [x] **Socializers** — Pass-the-phone format creates social ritual; post-match discussion is part of the experience
- [x] **Killers/Competitors** — Direct PvP, skill-based, win/lose with no ambiguity; Competitor is the primary type

### Flow State Design

- **Onboarding curve**: Zero tutorial needed — the mechanic mirrors a game players already know from childhood. First match teaches through play.
- **Difficulty scaling**: VS Player — self-scaling (players improve together). VS Computer — two difficulty settings ensure a winnable and a challenging option.
- **Feedback clarity**: Hit zone names display on impact; status effects are visually obvious (crossed-out arm, shaded legs). Players always know exactly what happened and why.
- **Recovery from failure**: Match length is 3–10 minutes; losing stings briefly and immediately invites a rematch. No persistent loss penalty.

---

## Core Loop

### Moment-to-Moment (30 seconds)

Player drags their finger outward from their stick figure — the aim line extends in real time, showing trajectory. On release, the shot fires: a line snaps across the screen toward the opponent. It either misses, hits a body zone, or scores a headshot win. The consequence is immediate and unambiguous. The other player takes their turn.

What makes this intrinsically satisfying: the physical snap of drag-and-release, the line visually crossing the battlefield, and the hit/miss verdict landing in under two seconds.

### Short-Term (5-15 minutes)

A turn = 2 actions. The decision is made, the actions play out, and control passes. Status effects compound — a disarmed opponent can only move; an immobilized one can only fire. The match escalates as options narrow. "One more turn" psychology lives here: you are always one headshot away from ending it.

### Session-Level (30-120 minutes)

A full session is a series of matches — best of 3, or as many as both players want. Natural stopping point: when someone stands up. The hook that makes you think about it later: the shot you should have taken.

### Long-Term Progression

No persistent progression in the MVP — the game is pure match replay value. Skill progression is internal: players learn optimal positioning, risk/reward targeting, and how to read opponent patterns. Mastery is knowing *when* to go for the head.

### Retention Hooks

- **Curiosity**: N/A (no hidden content)
- **Investment**: N/A (no persistent state)
- **Social**: Immediate rematch culture — "one more" after every loss
- **Mastery**: Players actively want to improve their aim and positioning strategy; the AI provides a consistent practice target

---

## Game Pillars

### Pillar 1: Read the Body
Every action targets a specific body zone with a specific, permanent consequence. There are no neutral hits.

*Design test*: "Should we add a graze hit that does partial damage over time?" → No. All outcomes are binary and immediately legible.

### Pillar 2: Two Actions, One Regret
Each turn grants exactly 2 actions. The order matters. There are no do-overs.

*Design test*: "Should we let players bank unused actions for a later turn?" → No. Every turn is a complete, self-contained decision.

### Pillar 3: Skill Earns the Win
The shot goes where you aimed it — with just enough spread variance to honour the physical origin of the mechanic. No hidden RNG or critical hits.

*Design test*: "Should we add random critical hit headshots?" → No. Outcomes must trace back to player decisions, not luck.

### Pillar 4: Instant to Learn, Hard to Master
A new player understands the game in 30 seconds. Depth comes from positioning and timing decisions, not rule complexity.

*Design test*: "Should we add a special ability system?" → Only if the ability can be explained in one sentence with no tutorial.

### Pillar 5: Local First
This is a local game on one device. Every UX decision optimises for sitting together — or picking it up alone. No online dependency, no accounts.

*Design test*: "Should we add online async multiplayer?" → Not in MVP. The shared screen IS the design constraint.

### Anti-Pillars (What This Game Is NOT)

- **NOT persistent progression**: No XP, unlocks, or carry-over power — would compromise *Instant to Learn*
- **NOT randomised environments**: No procedural maps or hazards — would compromise *Skill Earns the Win*
- **NOT 3+ players**: Always 1v1 — would compromise *Local First* and the clarity of *Two Actions, One Regret*
- **NOT a story or narrative mode**: Pure systems game — would compromise *Instant to Learn* and scope

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Pocket Tanks | Turn-based ballistic aiming on one screen; adjusting trajectory before firing | No terrain physics; body zones replace explosion radius | Proves the 1-device turn-based shooting format is fun |
| Disc Golf Battle | Drag-and-release gesture on mobile; satisfying arc physics | No golf course; direct 2D shot to opponent body | Proves the drag-release gesture translates well to touchscreen |
| Nocked (True Tales of Robin Hood) | Precision archery with tactile draw-and-release | No narrative; multiplayer not solo | Proves that aiming games with real consequence feel rewarding |

**Non-game inspirations**: The classroom ballpoint pen game — the physical ritual of pressing the pen down, the tips spreading on impact, the argument about whether it was a headshot. The game is a direct digital translation of a shared childhood memory.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 12–35 |
| **Gaming experience** | Casual to mid-core; recognises the source material |
| **Time availability** | 5–15 minute sessions; spontaneous play |
| **Platform preference** | Mobile browser or desktop browser |
| **Current games they play** | GTA Online, casual mobile games, childhood pen games |
| **What they're looking for** | A quick, competitive game to play with someone next to them — no setup, no accounts |
| **What would turn them away** | Long tutorials, paywalls, complicated mechanics, requires internet account |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | TBD — run `/setup-engine` for platform-specific recommendation |
| **Key Technical Challenges** | Gesture hit detection accuracy; hit zone collision on stick figure geometry; AI difficulty calibration |
| **Art Style** | 2D vector / hand-drawn — "notebook page" aesthetic |
| **Art Pipeline Complexity** | Low — stick figures are geometric shapes, no illustration required |
| **Audio Needs** | Minimal — flick snap, hit impact sounds, win/lose sting |
| **Networking** | None — local only, same device |
| **Content Volume** | 1 arena, 2 characters, 3 hit zones each, 2 game modes, 2 AI difficulties |
| **Procedural Systems** | None |

---

## Risks and Open Questions

### Design Risks

- Hit zone sizing calibration — zones must be large enough to reward intent but small enough to make headshots feel skilled, not easy
- Turn clarity on shared screen — two players on one device means UI must unambiguously indicate whose turn it is and what actions remain
- AI believability — an AI that aims too randomly feels pointless; one that aims too well feels unfair; calibration is a hidden design problem

### Technical Risks

- Gesture precision on touchscreen — the drag-and-release mechanic must feel satisfying and readable on glass; imprecision kills the core loop
- Hit detection on stick figure geometry — stick figures are thin; hit zone boundaries need generous hit areas or players will feel cheated by misses

### Market Risks

- Niche audience — pass-the-phone local multiplayer is underserved on purpose (few people build it); the audience exists but must be reached via nostalgia/social sharing
- Zero discoverability — browser games require active sharing; no store algorithm to surface it

### Scope Risks

- AI system underestimated — simple-looking AI can balloon into significant implementation time if targeting logic is under-specified
- Polish creep — "notebook page" aesthetic is simple to describe but requires careful execution to not look cheap

### Open Questions

- Does the drag-and-release gesture feel satisfying enough on a browser (mouse and touch)? → Answered by: build a one-screen prototype with just the gesture mechanic, no game logic.
- What's the correct hit zone size? → Answered by: prototype with adjustable zone sizes and playtest with 3–5 pairs of players.
- Does the AI feel fair at both difficulty levels? → Answered by: playtest AI-only matches and tune hit rate vs. zone preference per difficulty.

---

## MVP Definition

**Core hypothesis**: Players find the drag-and-release flick mechanic intrinsically satisfying, and the body-zone hit system creates meaningful tension in a 1v1 match.

**Required for MVP**:
1. Drag-and-release shot gesture — fires a line from player figure toward opponent, with light spread variance on release
2. Body-zone hit detection — head (instant win), arms (disarm 1 turn), legs (immobilize 1 turn)
3. Two-action turn system — each turn: 2 actions (move + fire), any order, passing to opponent after
4. VS Player mode — two humans, same device, alternating turns
5. VS Computer mode — AI opponent with at least 1 playable difficulty setting
6. Win screen — match ends immediately on headshot

**Explicitly NOT in MVP** (defer to later):
- Sound effects and music
- Visual polish, animations, hit particles
- Multiple AI difficulty settings (ship 1, tune later)
- Arena variety or customisation
- Match history or stats

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 arena, 2 stick figures, 3 hit zones | Flick shot, hit zones, turn system, VS Player, basic VS Computer | 2–3 weeks |
| **V1.0** | Same content, polished | Sound effects, visual hit feedback, polished UI, 2 AI difficulties | +1–2 weeks |
| **Full Vision** | Multiple arenas, figure customisation | Match history, stats, unlockable cosmetics, harder AI personalities | Months |

---

## Next Steps

- [ ] Run `/setup-engine` — configure engine for browser target, populate version-aware reference docs
- [ ] Run `/art-bible` — specify the Notebook Duel visual direction before writing any GDDs
- [ ] Run `/design-review design/gdd/game-concept.md` — validate concept completeness
- [ ] Run `/map-systems` — decompose concept into individual systems with dependencies
- [ ] Run `/design-system` — author per-system GDDs (shot mechanic, turn system, AI, hit zones)
- [ ] Run `/create-architecture` — produce master architecture blueprint
- [ ] Run `/prototype flick-shot-mechanic` — validate the core gesture before full implementation
- [ ] Run `/playtest-report` — document prototype playtest findings
- [ ] Run `/gate-check` — validate readiness before committing to production
- [ ] Run `/sprint-plan new` — plan the first sprint
