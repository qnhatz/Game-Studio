# Art Bible: Flick Duel

*Created: 2026-05-06*
*Status: Complete*
*Engine: Godot 4.6 | Platform: Web / Browser*

---

## Section 1: Visual Identity Statement

### One-Line Visual Rule

> **Every visual element must look like it was drawn with a ballpoint pen on a sheet of lined notebook paper — nothing on screen could not plausibly exist on that page.**

### Supporting Principles

#### Principle 1 — Ink on Paper, Nothing Else

All marks in the game world are pen strokes on a paper surface. There are no fills, gradients, glows, or rendered materials — only the illusion of ink deposited on a page.

**Design test:** When deciding whether a hit effect should glow or pulse, this principle says choose an ink splatter in the attacker's pen color — never a luminous or additive light effect, because light does not exist on a notebook page.

**Pillar served:** Skill Earns the Win — a clean, noise-free visual language ensures the outcome of every shot reads immediately and unambiguously, rewarding precise aim without visual distraction.

#### Principle 2 — Controlled Imperfection

Every geometric element carries the faint irregularity of a hand-drawn line: slight wobble at scale, non-machine-perfect curves, stroke weight that varies naturally at endpoints. Imperfection is calibrated — it communicates "hand-made," not "broken."

**Design test:** When sizing a UI button or arena boundary, choose a slightly uneven rectangular stroke over a pixel-perfect rectangle — the wobble should be visible at normal viewing distance but never so severe it breaks hitbox legibility.

**Pillar served:** Instant to Learn, Hard to Master — the hand-drawn aesthetic signals approachability and informality at first glance, lowering the perceived barrier to entry before a single rule is read.

#### Principle 3 — Two Inks Rule the Hierarchy

Black ink defines the world — figures, arena, ruled lines, neutral UI. Blue ink (Player 1) and red ink (Player 2) are the only colors on the page, and their sole purpose is ownership attribution. No third color may enter the palette for any reason; if a new visual element requires emphasis, increase stroke weight in black before considering color.

**Design test:** When a UI label needs emphasis or a zone needs highlighting, choose increased stroke weight in black before any color addition — color belongs exclusively to the two players, and adding it to neutral elements dilutes the ownership signal.

**Pillar served:** Read the Body — because hit effects, disabled zones, and trajectory lines all carry the attacker's ink color, players can reconstruct game state at a glance from color alone.

---

## Section 2: Mood & Atmosphere

### Design Principle

Each game state occupies a distinct band of the ink-and-paper emotional spectrum. The primary levers are: stroke weight (heavier = denser emotional stakes), line density (more marks = more cognitive noise), and page tone (the warmth or coolness of the underlying cream). A player glancing at the screen from across a table must be able to name the state without reading a single word.

### 2.1 Idle / Main Menu

**Primary emotion:** Anticipation held loosely — a blank page that knows something is about to be written on it.

**Ink character:** Light-to-medium stroke weight. Sparse line density — generous whitespace, ruled lines dominate. Brightest, most neutral cream page tone.

**Atmospheric adjectives:** Inviting, open, patient, unwritten, quiet

**Energy level:** Contemplative

### 2.2 Active Duel — Player's Turn (Deciding)

**Primary emotion:** The held breath before releasing a shot — cognitive pressure without panic.

**Ink character:** Medium stroke weight. Active player's ink color gains fractionally heavier weight on their figure and trajectory guide, pulling focus. Neutral cream, unchanged.

**Atmospheric adjectives:** Focused, deliberate, charged, sovereign, precise

**Energy level:** Measured

### 2.3 Active Duel — Opponent's Turn (Waiting)

**Primary emotion:** Watchful helplessness — you have done everything you can; the page is no longer yours.

**Ink character:** Waiting player's figure rendered at reduced stroke weight relative to the active player, visually subordinating them. Focus weighted toward the opponent's side.

**Atmospheric adjectives:** Watchful, taut, suspended, diminished, exposed

**Energy level:** Urgent

### 2.4 Handicapped State (Arm or Legs Disabled)

**Primary emotion:** Asymmetric pressure — the map of your own body has changed and you must adapt to its new borders.

**Ink character:** Disabled limb(s) rendered in broken dashes (faded-ink simulation). Attacker's color bleeds into the disabled zone as cross-hatch — marking the wound as belonging to the opponent. Remainder of body drawn at full weight for contrast.

**Atmospheric adjectives:** Damaged, asymmetric, constrained, resolute, scarred

**Energy level:** Urgent

### 2.5 Winning Moment (Headshot Lands — Match Over)

**Primary emotion:** Clean, immediate release — the satisfaction of a signature at the bottom of the page.

**Ink character:** Heavy impact — the headshot splatter is the single densest ink deposit on screen, in the winning player's color. Losing figure gains a secondary cross-hatch in winner's color. Page tone briefly shifts to warmest cream, then settles.

**Atmospheric adjectives:** Final, decisive, marked, still, earned

**Energy level:** Frenetic (impact frame) → Still (hold frame)

### 2.6 Losing Moment (You Receive the Headshot)

**Primary emotion:** The lurch of irreversibility — the recognition that the last decision was wrong and the page can no longer be changed.

**Ink character:** Losing player's figure drops to minimal stroke weight. Opponent's headshot splatter dominates in their color — the largest, boldest mark on screen. Page tone briefly shifts to slightly cooler, grey-tinged cream.

**Atmospheric adjectives:** Irrevocable, deflated, annotated, quiet, over

**Energy level:** Frenetic (impact frame) → Still (hold frame)

### 2.7 VS Computer Screen (Solo Mode)

**Primary emotion:** Mild, considered loneliness — dueling a figure who has no stake in the outcome.

**Ink character:** Computer opponent drawn entirely in black — no color, only definition. Lines are slightly more uniform than the hand-drawn player figure (a subtle signal it did not pick up this pen by choice). Neutral cream, no drama.

**Atmospheric adjectives:** Solitary, structured, clinical, preparatory, neutral

**Energy level:** Measured

### State Differentiation Matrix

| State | Dominant Ink Weight | Page Tone | Energy | Distinguishing Mark |
|---|---|---|---|---|
| Idle / Menu | Light | Bright neutral cream | Contemplative | Maximum whitespace; ruled lines dominant |
| Your Turn | Medium, player color heavier | Neutral cream | Measured | Active player's ink commands the frame |
| Opponent's Turn | Medium, your figure subordinated | Neutral cream | Urgent | Your lines visibly lighter than theirs |
| Handicapped | Full body / broken limb contrast | Neutral cream | Urgent | Broken dashes on disabled zone; opponent color cross-hatch |
| Win Moment | Heavy splatter + settle | Warm cream (brief) | Frenetic → Still | Largest single ink deposit on screen |
| Lose Moment | Opponent heavy / you minimal | Cool cream (brief) | Frenetic → Still | Your strokes near-disappear; their mark dominates |
| VS Computer | Uniform black opponent | Neutral cream | Measured | Opponent has no color; slightly mechanical line quality |

---

## Section 3: Shape Language

### 3.1 Character Silhouette Philosophy

The stick figure is seven marks: one circle, one vertical line, two diagonal arm lines, two diagonal leg lines. Every proportion decision protects instant recognisability while solving two readability problems — thumbnail legibility and player differentiation on a shared screen.

**Canonical proportions:**
- Head circle: diameter = 1/5 total figure height (~24px at 120px total height)
- Neck gap: zero — head circle rests directly on the body line's top terminus
- Body line: 2/5 of total figure height (torso in one stroke)
- Arm lines: begin at upper third of body line (shoulder junction), extend at ~45° outward and downward; arm span (tip to tip) equals total figure height
- Leg lines: begin at body line bottom, splay at ~30° outward; total leg height = 2/5 figure height, forming a shallow inverted-V
- Total figure height: 120px at 1:1 camera scale (subject to playtest calibration)

**Player differentiation beyond ink color:**
Player 1 stands on the left half of the page, arms angled right (toward opponent). Player 2 stands on the right, arms angled left. Mirrored arm orientation creates a facing signal readable from silhouette alone — a colorblind player pair still reads "mine is the left one" without decoding ink color.

**Distinguishing silhouette trait:**
The arm lines form an arrowhead pointing toward the opponent. The figure reads as aimed even at rest — the visual vocabulary of "about to act" is baked into the resting pose.

*Pillar: Instant to Learn — the silhouette communicates "duel in progress" before any animation plays.*

### 3.2 Hit Zone Visual Grammar

Three zones, distinguished by shape behavior — not labels, not color, not UI overlays:

- **Head zone:** The circle. The only closed shape on the figure. Closure is the strongest Gestalt grouping cue. Already declared as a discrete region — no additional marking needed.
- **Arm zone (upper torso):** Defined by the spreading geometry of the arm lines — a triangular/diamond region of space around the upper body. Players target the spread geometry, not a pixel-precise line.
- **Leg zone (lower body):** The inverted-V of the legs encloses a triangular region of space (legs + ground). Grounded triangular containment distinguishes it from the arm zone's upward radiation.

**Zone separator:** At the shoulder junction (where arm lines meet body line), stroke weight increases to ~1.5x. This node visually divides the body line into upper (arm zone) and lower (leg zone). It reads as a natural shoulder before it reads as a UI element.

*Pillar: Read the Body — three distinct shape behaviors (closure, radiation, containment) mean zone targeting is a visual read, not a memorized map.*

### 3.3 Arena Geometry

**Ground plane:** Single horizontal stroke at ~15% from bottom edge, 1.5x ruled-line weight. Slight wobble — a machine-straight line would read as a UI progress bar, not a drawn surface.

**Ruled lines:** Full-width at 24px vertical intervals (calibrated to the head circle diameter so figures read as at-home on the page). Lightest stroke weight: ~0.5x character stroke weight. Always present, always recessive.

**Page boundary:** Soft rectangular stroke at viewport edge — slightly irregular, as if torn or cut. Same weight as ground plane (heavier than ruled lines, lighter than characters). Corners slightly rounded.

**The shape grammar binary:** Rectilinear = environment (ruled lines, ground, boundary). Curved = living things and projectiles (head circles, shot arcs). Any curved line on screen is player-relevant. Any straight horizontal line is world structure.

*Pillar: Instant to Learn — the rectilinear/curved dichotomy creates a visual vocabulary absorbed passively.*

### 3.4 UI Shape Grammar

All UI lives on the page, not above it. Every UI element must pass the test: would this mark appear on a notebook page?

**UI as margin annotation:** UI elements occupy margin space (above the ground line, below the top ruled line). Turn indicators and action counters are handwritten annotations — circled numbers, tally marks, check marks, cross-outs — the kind a student makes at the edge of a page.

**Turn indicator:** A circled initial or arrow glyph in the active player's ink color, at ~1.5x stroke weight. Inactive state: the same circle with a diagonal cross-stroke (same grammar as disabled limb = crossed out = inactive).

**Action counter:** Two tally strokes per player in the margin — upright stroke = available, diagonal cross-stroke added = spent. No label required. The grammar: upright = present/active, struck-through = canceled/spent. Used throughout the game world and UI identically.

*Pillar: Two Actions, One Regret — tally mark grammar makes both actions and their consumption legible at a glance without interrupting the spatial read.*

### 3.5 Hero Shapes vs. Supporting Shapes

**Hero shapes (draw the eye first):**
1. Head circles — the only closed shapes; win condition; highest attentional anchor. Always resolved first.
2. Active player ink color — the only non-black marks on the page; immediately separated from cream background.
3. Shot line at firing moment — fastest stroke crossing the largest horizontal space on screen; highest-contrast moving mark; resolves in under 0.4 seconds.

**Supporting shapes (recede to context):**
1. Ruled lines — minimum stroke weight, horizontal, non-competing with diagonal figure dynamism
2. Ground plane — load-bearing context, never looked at directly
3. Tally marks and turn indicators — peripheral placement, sub-figure stroke weight; found when sought
4. Page boundary — present at the edge of vision

**The hierarchy law (stroke weight = importance):**

| Element | Stroke Weight |
|---|---|
| Ruled lines | 0.5x |
| Characters (resting) | 1x |
| Shoulder junction node | 1.5x |
| Ground plane / turn indicator (active) | 1.5x |
| Shot line (firing moment) | 2x briefly → 1x trace |
| Headshot splatter (impact) | 2.5x, attacker's color |

*Pillar: Read the Body — the impact mark is always the most visually prominent thing on screen at the moment it lands.*

---

## Section 4: Color System

### 4.1 Primary Palette

Five colors. No color outside this set may appear anywhere on screen — not in UI, not in effects, not in transitions.

| Name | Hex | Physical Reference | Role |
|---|---|---|---|
| **Ink Black** | `#1A1A1A` | Fresh ballpoint ink — almost but not fully black; faint warmth | World definition: all neutral marks, arena geometry, ruled lines, UI text |
| **Page Cream** | `#F5F0E8` | Standard college-ruled notebook paper under indoor light | The surface everything is drawn on; absence of mark |
| **Rule Grey** | `#C8C0B0` | Printed blue-grey ruled lines of a college notebook at normal distance | Horizontal ruled lines only — zero semantic meaning |
| **Bic Blue** | `#2853A0` | Standard Bic Cristal blue ballpoint, medium pressure, full ink | Player 1 ownership: figures, shot lines, hit effects, UI indicators |
| **Red Bic** | `#C0282A` | Standard red Bic ballpoint, medium pressure, full ink | Player 2 ownership: figures, shot lines, hit effects, UI indicators |

Ink Black is not `#000000` — ballpoint ink carries faint warmth; full black reads as digital. Page Cream is not white — a notebook page has tooth and age. Rule Grey is explicitly lighter than Ink Black and carries zero semantic information; if emphasis is needed, use Ink Black at increased stroke weight instead.

### 4.2 Semantic Color Usage

Every color has one non-negotiable semantic assignment. The moment a color carries two meanings, player literacy degrades.

- **Ink Black:** The world. Everything neutral, structural, or informational without ownership. Arena geometry, UI text labels, zone confirmation text, all menu elements. Black does not mean danger — it means "the page knows about this."
- **Bic Blue:** Player 1 did this. Player 1's figure, shot lines, hit effects, turn indicator, action counter. Never appears in a context where Player 2 could be associated with it.
- **Red Bic:** Player 2 did this. Identical semantic structure to Blue, mirrored. Red here does not mean danger, warning, or low health. Red means "the pen on the right."
- **Page Cream:** Absence of mark. No active meaning. The default surface state.
- **Rule Grey:** Ruled lines only. Carries zero semantic meaning. Never use to indicate state.

### 4.3 Hit and Status Effect Color Rules

All hit and status effect visuals are drawn in the attacker's ink color. The person who threw the shot leaves their mark.

**Shot trajectory:** Single-weight line in firing player's color, drawn from origin to terminus. Persists for ≥1 second then fades (opacity reduction only — no new color). Stroke weight: 1.5px at base resolution.

**Hit on body zone (non-lethal):**
- Ink splatter at contact: irregular radial burst of 4–7 short strokes in attacker's color (~12–16px radius). Permanent for the match.
- Cross-hatch overlay on the zone: 45°, 4px spacing, attacker's color at 70% opacity over existing geometry.
- The zone remains visible beneath the cross-hatch. A blue shot on a red figure leaves a blue cross-hatch on the red figure.

**Permanently disabled zone:**
1. Solid Ink Black strokes of the limb switch to broken dashes (8px dash, 4px gap).
2. The attacker's cross-hatch from the hit moment persists permanently.
- The disabled state = broken-dash geometry + permanent color attribution. Broken dashes communicate disabled without color — a colorblind player reads the geometry.

**Zone confirmation label:** Text reads zone name + status in Ink Black ("ARM-L: DISABLED"). Disappears after 2 seconds. No color in labels — color is already carried by the cross-hatch.

### 4.4 UI Color Rules

All UI defaults to Ink Black on Page Cream. Color in UI appears only to communicate player ownership.

**Turn indicator:** Renders in the active player's ink color. Includes an Ink Black text label ("P1" / "P2") — never color-only. Always positioned on the active player's side of the screen (redundant positional cue).

**Action counter:**
- Unused action (P1): filled circle, Bic Blue `#2853A0`
- Unused action (P2): filled circle, Red Bic `#C0282A`
- Spent action: empty circle outline, Ink Black `#1A1A1A`

**Win/Lose screen:** Winner's color applied as dense radial cross-hatch across full screen at 40% opacity over Page Cream. Win text ("P1 WINS" / "P2 WINS") in winner's color at maximum stroke weight, plus Ink Black at smaller size. Losing figure fades to near-minimum stroke weight; their ink color remains visible but subordinated. Rematch and menu labels: Ink Black only.

**Menus:** All non-gameplay UI is Ink Black on Page Cream. Player colors appear only where both are present together in equal weight (e.g., character select with both figures shown).

### 4.5 Colorblind Safety

The blue/red player distinction is the single most critical accessibility concern. Protanopia is the primary risk (~1% of males): Red Bic `#C0282A` desaturates significantly toward brown-grey, potentially reading closer to Ink Black.

**Non-color redundant cue system (must work without any color):**

| Cue | How It Carries Ownership Without Color |
|---|---|
| Screen position | P1 always left half, P2 always right half — never violated by any layout decision |
| Text labels | Every colored ownership element includes an Ink Black "P1" / "P2" label |
| Shot-line origin | A shot line always originates from the firing player's figure; trace to origin = determine ownership from position |
| Broken-dash geometry | Disabled state is communicated by dash pattern independently of color cross-hatch |
| Figure numbering (recommended) | Small "1" or "2" label in Ink Black near each figure's head, rendered as part of the figure — reads as if someone wrote a number next to each doodle. Makes the game fully accessible to achromatopic players. |

**Accessibility test protocol (required before ship):**
1. Greyscale filter on an active match screenshot → can you identify which figure belongs to which player? (Yes — position + "1"/"2" label)
2. Protanopia simulation filter → can you read the turn indicator? (Yes — "P1"/"P2" text label)
3. Protanopia filter → can you identify disabled zones? (Yes — broken-dash geometry)
4. Protanopia filter → can you trace a shot to its owner? (Yes — shot-line origin position)

All four confirmations required before ship.

---

## Section 5: Character Design Direction

### 5.1 Visual Archetype

The Flick Duel figure is a **purposeful doodle** — the type drawn by someone who has done it hundreds of times and converged on a stable, confident mark. No hesitation in the strokes. Every line arrives at the correct angle and terminates with intention.

**Proportional weight:** The figure reads as front-heavy without adding lines. The head circle at 1/5 total height is large relative to stick-figure convention (~24px diameter in a 120px body). Combined with arm-span equal to total height, the upper body carries the optical weight — exactly where hit zones and aiming geometry live. The leg inverted-V is a light base, a tripod, not a feature.

**Gestural energy at rest:** The canonical resting pose is not neutral. Arms at 45° aimed toward the opponent read as perpetual low-level readiness — the figure always faces a target. This directionality is structural, not animated. The silhouette communicates *duelist* before any animation plays.

*Pillar: Instant to Learn — the archetype is "thing I have seen before" before it is "game character."*

### 5.2 Expression and Pose Style

The head is a featureless circle. No face, no plan to add one. Every emotional register is communicated through **body posture, stroke weight, and damage state geometry**.

Pose vocabulary — discrete states, each legible as a thumbnail:

| Game State | Posture Signal | Mechanism |
|---|---|---|
| Waiting (opponent's turn) | Canonical pose, slightly reduced stroke weight | Subordination without geometry change |
| Your Turn | Canonical pose at full stroke weight; arm lines fractionally heavier | Color and weight shift, no new geometry |
| Arm disabled | Arm line(s) converted to broken dashes | Geometry mutation — limb is there but not there |
| Leg disabled | Leg line(s) converted to broken dashes | Same mechanism; inverted-V partially dissolves |
| Win | Canonical pose at maximum stroke weight | Standing full after the splatter reads as triumph |
| Lose | Canonical pose at near-minimum stroke weight; head carries opponent cross-hatch | Figure shrinks into the background it was drawn on |

Why no expressive gestures beyond damage state: the figure's job is to be a legible target map, not to perform. A broken-dash arm is more emotionally resonant than a drooping arm because it says *the pen ran dry here*.

*Pillar: Read the Body — with no face to read, the player's eye reads posture and damage state — precisely the game-relevant signals.*

### 5.3 Animation Philosophy

**Four animation events. No others.**

#### Firing Gesture
Brief single-axis arm extension in firing direction, then snap back.
- Timing: 3 frames out (80ms) → 1 frame hold (26ms) → 2 frames back (53ms). Total ~160ms.
- Arm extends ~15px beyond canonical angle terminus, overshoots 2–3px, pulls back 1px before settling — a stroke-termination overshoot, the same micro-behaviour a flicked ballpoint makes.

#### Hit Reaction
Single-axis recoil: figure displaces 3–4px away from attacker, returns.
- Timing: 2 frames out (53ms) → 1 frame hold (26ms) → 2 frames back (53ms). Total ~130ms.
- Figure does not deform — all seven marks translate as a rigid unit. During the 2-frame return, stroke weight increases ~0.2x momentarily (pressure artifact), then returns to baseline.
- Ink splatter and cross-hatch land on the same frame as peak displacement.

#### Disabled State Transition
Geometry mutation over 3 frames (~80ms):
- Frame 1: Solid stroke at 60% opacity
- Frame 2: Solid stroke at 20% opacity
- Frame 3: Broken-dash geometry (8px dash / 4px gap), Ink Black. Final state locked.
- Dash endpoints carry a 1px overshoot in Ink Black — the same endpoint artifact used across all stroke geometry.

#### Move Action
Figure slides along ground plane. No walking cycle — rigid translation.
- Speed: ~200px/second. Minimum duration: 200ms.
- At midpoint: a faint Ink Black ghost at origin position persists for 2 frames (~53ms) at 30% opacity — residual ink, not motion blur.

**Animation style target:** Snappy and decisive, with pen-physics artifacts replacing organic easing. Anticipation absent. Follow-through expressed as overshoot, pressure spike, residual trace. Easing: linear-to-sharp-stop, not sinusoidal.

*Pillar: Controlled Imperfection — animation carries the hand-drawn quality by imitating what a pen does when moved quickly, not what a body does.*

### 5.4 Computer Opponent Differentiation

The computer opponent is drawn in **Ink Black only** — no player color. Same hit zone geometry and proportions. Differentiation lives in line character and one structural addition.

**Stroke uniformity:** Computer figure strokes are marginally more uniform — arm and leg angles land at exactly 30°/45° with no wobble, stroke weight constant end-to-end without endpoint flare. Reads as a stick figure first; reads as slightly uncanny second. This ordering matters.

**The clock-tick annotation:** A small arc-segment (60°) at the lower-right quadrant of the head circle, Ink Black, same stroke weight as the head circle. References a clock or compass — visual signal of systematic decision-making. The only structural difference from the player figure's seven marks.

**Ownership label:** Instead of a "1"/"2" label near the head, the computer figure carries a small hollow square (4×4px, Ink Black). Circle = player (organic). Square = computer (constructed).

**Computer shot lines are Ink Black.** When the computer fires, the shot line and hit cross-hatch are Ink Black — the world's ink, not a player's ink. The computer's actions carry the color of the environment, reinforcing the "you are dueling the page itself" register from Section 2.7.

*Pillar: Instant to Learn — the computer figure must read as "the opponent" before it reads as "not human."*

### 5.5 LOD Philosophy

**One primary camera scale** — 120px figure height at 1:1 canvas scale. No zoom system.

**Minimum legible size: 60px total figure height (0.5× scale).**

At 60px:
- Head circle: ~12px diameter — remains a visible closed circle
- Shoulder junction node: still resolves as distinct density on the body line
- Zone distinction: 45° vs. 30° arm/leg angle difference preserved; three zone behaviors readable
- Broken dashes: scale proportionally — at 60px use 4px dash / 2px gap (not 8px/4px)

**Critical threshold:** The shoulder junction node must render at minimum 2px effective diameter at all supported viewport scales. If viewport scaling would reduce it below 2px, the UI layer locks minimum figure scale to preserve node legibility.

**Mobile layout constraint:** At 375px viewport width (smallest common browser target), two figures with margin occupy ~150px each of horizontal space. Figures never overlap in canonical layout — horizontal margin between arm-tip and arm-tip must be ≥1× figure height (~120px) to preserve aiming-geometry clarity.

---

## Section 6: Environment Design Language

### 6.1 The Notebook Page as Arena

The arena is a specific object — a sheet of college-ruled notebook paper. Its identity is established entirely by structural pen marks, not by texture fills, grain overlays, or background renders.

**The three structural marks:**
- **Ruled lines:** Full viewport width, 24px intervals (calibrated to head circle diameter — a figure occupies ~2 ruled-line intervals, the scale of a student doodle). Rule Grey `#C8C0B0`, 0.5× character stroke weight. Always present, always recessive.
- **Ground line:** Single horizontal stroke at ~15% from bottom. Ink Black `#1A1A1A`, 1.5× character stroke weight, hand-drawn wobble. Heavier than ruled lines, lighter than characters. The slight wobble prevents it reading as a progress bar or UI divider.
- **Page boundary:** Soft rectangular stroke at viewport edge, slightly irregular (torn/cut), corners slightly rounded. Same weight as ground line. No background behind the boundary.

**What the page does not have:** No watermark, no texture fill, no paper grain overlay, no vignette, no drop shadow. Page identity is carried by structural marks alone. Paper grain rendered by a shader is not a pen mark and violates the One-Line Rule.

### 6.2 Persistent Ink Accumulation

Shot trajectories remain on the page for the duration of the match. The arena accumulates a record of every decision. By round ten of a long match, the page is significantly marked.

**Aesthetic intent: a record, not noise.** Every persistent mark has an owner (blue or red), an origin (a player's figure), and a path. A player who looks at the marked page can reconstruct the sequence of decisions that produced it. This is intentional.

**Why it does not become clutter:** Persistent trajectory lines step down to 0.6× opacity permanently. Active gameplay signals (current figures, current turn indicator, the aimed shot) are at full stroke weight. Heavier stroke weight wins the visual hierarchy regardless of mark density behind it.

**Accumulation rules:**

| Mark type | Initial state | Persistent state | Opacity floor |
|---|---|---|---|
| Shot trajectory line | 1× stroke, full opacity | Step-down to 0.6× opacity, same stroke weight | 0.6 (never erases) |
| Non-lethal hit splatter | Full color at impact | Permanent, no opacity change | 1.0 |
| Cross-hatch on disabled zone | Full color at application | Permanent, no opacity change | 1.0 |
| Headshot splatter (match-ending) | 2.5× stroke at impact | Permanent, no opacity change | 1.0 |

**Layering:** Two persistent lines crossing are drawn as two pen strokes cross on real paper — no erasure, no disambiguation tint. Blue and red differentiate ownership at any intersection.

**If playtesting reveals legibility failure at high mark density:** Reduce trajectory line stroke weight to 0.4× before any other intervention. Erasing marks or fading them to invisibility would contradict the record-keeping intent.

*Pillar: Skill Earns the Win — the complete record of shot paths allows both players to analyze decisions.*

### 6.3 Prop Density and Decoration

**Match start: the page is bare.** No margin doodles, no pre-existing annotations, no spiral binding texture, no decorative marks of any kind.

**Rationale:** The ruled lines, ground line, and page boundary already fully establish paper identity. Pre-placed doodles add warmth but cost clarity — a non-player mark introduces a false positive that could be briefly misread as a gameplay element by a first-time player. The correct location for character-building marks is the player-authored ink accumulation from actual play.

**One optional late-session addition:** A very faint spiral-binding impression at the left edge (Rule Grey, 0.3× stroke weight, printed-regular rather than hand-drawn). This is not in MVP scope. Revisit only if playtesting shows new players take more than a glance to identify the surface as notebook paper.

### 6.4 Environmental Storytelling

The notebook page communicates the game's nature in three layers without text:

**Layer 1 — the object.** A ruled notebook page is a student object. It lives in a backpack, a classroom, a desk. It signals immediately: this is informal, approachable play. Not a neon tournament stage. Something two people could do while pretending to pay attention to something else.

**Layer 2 — the blankness.** Blank space on a notebook page is potential, not emptiness. The two figures placed in the open expanse read as marks placed deliberately on an available surface — doodles that have come to life, or marks placed with specific intent.

**Layer 3 — the permanence of marks.** Every decision leaves a permanent trace. No undo, no respawn, no mid-match clean slate. The page remembers. The game's consequence system is represented in its surface — what you do to the opponent stays there, annotated in your ink color.

Together: a focused, high-stakes duel dressed in informal clothes.

*Pillar: Two Actions, One Regret — the persistent page is a direct visual representation of the mechanic's name. Every action is visible. Every regret is inked.*

### 6.5 Arena as Player Canvas — The Finished Page

**Intended aesthetic: a legible record of two intentions.** Not chaos — a document of the match.

- Blue marks document Player 1's decisions; red marks document Player 2's. Ownership never ambiguous.
- Trajectory lines are thin and recessive (0.6× opacity). Splatters and cross-hatches are bold and permanent.
- The headshot splatter is the densest, boldest single mark on the page — always legible as the final event.

**Visual narrative the finished page tells:** Trajectory lines show the sequence of attempts and their spatial range. Cross-hatches on disabled zones document the turning points. The headshot splatter documents the resolution. A player who photographs the finished page can reconstruct who took the early initiative, who was put on the back foot, and who ended it.

**End-state hold:** At match resolution, before the win/lose screen overlays, the game holds on the finished page for 1.5 seconds — long enough for both players to read the record. The design intention: "lifting a pen from paper and looking at what was drawn."

**What the finished page must not look like:** A black mass (trajectory weight kept thin prevents this), a symmetric decorative pattern (marks are authored by player decisions — unpredictable placement), or a nearly blank page covered by one splatter (acceptable and communicates a quick decisive duel).

*Pillar: Read the Body — the finished page is the ultimate expression of this pillar. The entire spatial record of the duel is readable from the marks left on the surface.*

---

## Section 7: UI/HUD Visual Direction

### 7.1 Diegetic vs. Screen-Space HUD

**All HUD lives on the page. No exceptions for gameplay elements.**

Every HUD element is a mark on the notebook page — visually indistinguishable in kind from arena geometry and figures. There is no separate "HUD layer" in the player's perception.

**Margin region assignments:**

| Region | Location | Contents |
|---|---|---|
| Top margin | Above first ruled line | Match context only (VS label, mode indicator) — never per-turn state |
| Left gutter | Left of figures, 40px wide | P1 turn indicator + P1 action counter |
| Right gutter | Right of figures, 40px wide | P2 turn indicator + P2 action counter |
| Bottom margin | Below ground line | Zone status confirmation text (transient, 2s) |

*Note: Gutter marks are visual indicators only — not interactive. Touch input is handled by gesture zones over the main page area. No conflict with the art direction.*

**Menus:** All non-gameplay screens are blank notebook page. Menu text hand-lettered on the page as if annotated. No panels, no card UI, no background regions.

### 7.2 Typography Direction

**Font personality:** "Student handwriting that has legibility as a discipline." Not casual brush script; not digital sans; not mechanical monospace. The model is someone who writes neatly under mild time pressure — slightly irregular letterforms, consistent baseline, no serifs, moderate stroke weight variation at endpoints.

**Recommended font category:** Hand-printed sans with controlled irregularity. Reference: Architects Daughter, Caveat (at heavier weights for UI), or a custom bitmap hand-lettered set. Avoid script (too cursive), geometric sans (too digital), serif (wrong era for notebook).

**Minimum text size: 14px.** Below 16px, reduce baseline wobble. Below 14px, switch to a regularized hand-print variant. The identity permits "less wobbly at small sizes" — it does not require illegibility.

**Type size hierarchy:**

| Element | Size | Style | Color |
|---|---|---|---|
| Win/lose announcement ("P1 WINS") | 48px | Max stroke, all-caps | Winner's ink color |
| Secondary win label ("HEADSHOT") | 24px | Medium, all-caps | Ink Black |
| Turn label ("P1" / "P2") | 18px | Medium | Ink Black |
| Zone confirmation ("ARM-L: DISABLED") | 16px | Medium, all-caps | Ink Black |
| Action counter / tally marks | 14px | Integrated with tally marks | Player color / Ink Black |
| Main menu options | 20px | Medium | Ink Black |
| Mode labels | 18px | Medium, all-caps | Ink Black |
| Contextual sub-labels | 13px min | Light | Ink Black |

All-caps for gameplay-state text (turn labels, zone status, win announcement). Title case for menus.

### 7.3 Iconography Style

**No icons.** All state is communicated through text labels, tally marks, and the shape grammar from Section 3.

| Communication need | Solution |
|---|---|
| Whose turn | Circled "P1"/"P2" in active player's ink color |
| Actions available / spent | Tally marks (upright = available, crossed = spent) |
| Disabled zone | Broken-dash geometry + zone text in bottom margin |
| Mode select | Text label + inline figure pair or "CPU" text label |
| Win/lose | Text announcement + full-page cross-hatch |

*Interactive elements are declared by a dashed underline or hand-drawn bracket — a conventional "this is a choice" annotation — not a button-shaped icon.*

### 7.4 Action Buttons and Gesture Areas

No conventional buttons. Interactive areas are declared by dashed-underline or bracket annotation.

**Gameplay gesture zones:** Each player's half of the page is their gesture surface. A tap/drag within your half inputs your action. P1 = left half, P2 = right half (consistent with all positional grammar).

**Visual declaration of gesture zones:** A faint dashed rectangle (0.3× stroke weight) outlines each player's half. On active-player turn, their zone advances to 0.6× stroke weight with a small "MOVE" or "FIRE" margin note. Opposing zone fades to 0.1× — not their turn.

**Fire action:** Declared by a real-time trajectory-preview line in the active player's ink color, drawn from the figure as angle is set. No additional button affordance needed — the preview line is the affordance.

**Rematch and Back to Menu:** Text underlined with an irregular hand-drawn stroke in resting state. A hand-drawn bracket draws in on focus/active (not hover — hover does not exist on mobile). Minimum 44×44px invisible touch region around all interactive labels.

### 7.5 Animation Feel for UI

**Core verb: drawing.** Elements appear by having their stroke trace from a starting point. Elements disappear by un-drawing — the line retreats along its path.

| Animation | Duration | Description |
|---|---|---|
| Tally mark draw-in | 80ms | Quick note |
| Turn indicator cross-out | 150ms | Deliberate cancellation |
| Turn indicator new draw-in | 200ms | Confident writing |
| Zone confirmation text draw-in | 250ms | Urgent annotation |
| Zone confirmation text erase-out | 150ms | Quick removal |
| Win cross-hatch sweep | 400–600ms | Emphatic marking left to right |
| Win text draw-in | 300ms | Declaration |
| Screen transition (erase phase) | 250ms | Page clearing outward from center |
| Screen transition (draw phase) | 350ms | New page drawing top to bottom |
| Button bracket draw-in (focus) | 120ms | Quick selection mark |

**Reduced-motion:** All draw-in/erase-out animations must degrade to instant-appear/instant-disappear when `prefers-reduced-motion` is active. A mark that simply exists on the page is fully consistent with the visual identity — animation is enhancement only.

### 7.6 Accessibility Flags and Resolutions

All identified conflicts between art direction and readability/usability, with binding resolutions:

| Flag | Risk | Resolution |
|---|---|---|
| Hand-lettered font at small sizes | Irregular letterforms become noise below 14px | Minimum text size 14px. Baseline wobble disabled below 16px. Regularized letterforms at small sizes. |
| Touch targets for margin annotations | Gutter marks too small to tap reliably | Margin indicators are visual-only. All touch input via half-page gesture zones (≥44px). |
| Rematch button touch targets | Hand-lettered text may not read as tappable | Minimum 44×44px invisible touch regions. Dashed underline in resting state for persistent affordance cue. |
| Color-only turn indication | Turn indicator fails for colorblind players without text | Turn indicator always includes "P1"/"P2" in Ink Black. Color is redundant, not primary. |
| Reduced-motion requirement | Draw-in animations may trigger vestibular response | All UI animations respect `prefers-reduced-motion`. Static state fully legible without animation. |
| Mode select contrast on small screens | Hand-lettered text on Page Cream — sufficient contrast? | Ink Black `#1A1A1A` on Page Cream `#F5F0E8` = ~11.5:1 contrast ratio. Exceeds WCAG AAA (7:1). |
| Win text over cross-hatch layer | Cross-hatch may reduce text contrast | Win text renders above cross-hatch layer. Bic Blue 40% on Cream → ~8.1:1 for Ink Black. Red Bic 40% on Cream → ~8.8:1. Both pass AAA. |

---

## Section 8: Asset Standards

### 8.1 Implementation Architecture

All in-game geometry — figures, arena boundaries, UI chrome, trajectory lines — is rendered via **`Line2D` nodes** and **`_draw()` calls**. There are no sprite sheets for drawn geometry. The sole exception is impact splatters and paper-texture overlays, which use **PNG-8 raster assets** (see §8.4).

This distinction is absolute: if an element is a stroke, it is a `Line2D` or `_draw()` primitive. If it is a mark that cannot exist as a vector stroke (e.g., an ink blot with irregular fill), it is a PNG-8 asset.

### 8.2 Color Constants

All palette values are defined once in `src/core/game_constants.gd` and referenced everywhere else. Never define a color inline.

```gdscript
const INK_BLACK  := Color(0.08, 0.08, 0.10, 1.0)   # #1A1A1A — figures, arena, neutral UI
const PAPER      := Color(0.97, 0.96, 0.92, 1.0)   # #F5F0E8 — background fill
const RULE_GREY  := Color(0.78, 0.75, 0.69, 1.0)   # #C8C0B0 — ruled lines, secondary UI
const INK_BLUE   := Color(0.10, 0.25, 0.72, 1.0)   # #2853A0 — Player 1 ink
const INK_RED    := Color(0.80, 0.12, 0.12, 1.0)   # #C0282A — Player 2 ink
```

### 8.3 Line2D Standards

Every `Line2D` node must conform to these properties:

| Property | Value | Rationale |
|----------|-------|-----------|
| `width` | `2.0` px | Single ballpoint stroke at 1× scale |
| `cap_mode` | `LINE_CAP_ROUND` | Pen-tip termination |
| `joint_mode` | `LINE_JOINT_ROUND` | Smooth direction changes |
| `antialiased` | `true` | Sub-pixel smoothing at all zoom levels |
| `default_color` | From `game_constants.gd` | Never inline |

For UI elements at higher hierarchy (section labels, player name plates), width may increase to `3.0` px. Nothing exceeds `4.0` px.

### 8.4 Wobble Standard

Hand-drawn irregularity is **baked at scene-edit time**, not computed per frame.

- Static geometry (arena walls, figure limbs at rest): apply wobble via a `@tool` script using Perlin noise displacement on the `Line2D` point array. Run once at edit time; the result is serialized into the scene file.
- Runtime-spawned geometry (trajectory lines, hit effects): apply a one-shot displacement function at instantiation. The displacement is fixed for the lifetime of that node — it does not animate.
- **Never** recalculate wobble in `_process()` or `_physics_process()`.

Maximum wobble amplitude: `±1.5 px` perpendicular to the stroke direction. Beyond this threshold, legibility breaks.

### 8.5 Persistent Trajectory Lines — Draw Call Budget

Persistent ink (shot trajectories that remain on screen across turns) must not accumulate `Line2D` nodes without bound. Use the **SubViewport accumulation canvas** pattern:

1. A `SubViewport` holds all in-flight `Line2D` trajectory nodes.
2. When a shot resolves, its `Line2D` is rendered into the SubViewport's texture (blit), then the node is freed.
3. The entire history of resolved trajectories renders as a single `Sprite2D` draw call.

This caps trajectory draw calls at **1** regardless of match length. Trade-off: individual trajectory lines cannot be erased once committed — this is acceptable and thematically appropriate (ink is permanent).

### 8.6 Animation Standards

All figure and UI animation uses **`Tween` + `_draw()` parameters**. `AnimationPlayer` is not used for character or stroke animation.

| Animation Event | Duration | Easing |
|-----------------|----------|--------|
| Firing Gesture | 160 ms (80 out / 26 hold / 53 back) | `TRANS_BACK / EASE_OUT` for overshoot snap |
| Hit Reaction | 130 ms (53 out / 26 hold / 53 back) | `TRANS_ELASTIC / EASE_OUT` for stagger |
| Disabled Transition | 80 ms (3-frame geometry mutation) | `TRANS_LINEAR` — clinical, not bouncy |
| Move Action | ~200 px/sec, minimum 200 ms, 2-frame ghost at origin | `TRANS_QUAD / EASE_IN_OUT` |

Tween all float and Vector2 parameters that drive `_draw()` calls. Do not interpolate `Line2D.points` arrays directly — drive a scalar offset and reconstruct the array in `_draw()`.

### 8.7 Font Standards

| Property | Value |
|----------|-------|
| Format | OTF |
| Rendering mode | Bitmap (not SDF) |
| Import size | Exact display size (no runtime scaling) |
| Texture filter | Nearest |
| Anti-aliasing | Off |

The chosen typeface must read as handwritten or stencilled — consistent with the notebook context. It must be legible at `14 px` for body labels and `10 px` for secondary annotations. Do not use SDF mode; the blurring at small sizes contradicts the sharp-ink principle.

### 8.8 PNG-8 Raster Assets (Impact Splatters & Overlays)

Used only for: ink splatter hit effects, paper texture overlay (background), and any mark that requires irregular fill not achievable with strokes alone.

| Property | Requirement |
|----------|-------------|
| Color depth | PNG-8 (256-colour palette) |
| Max dimensions | 128 × 128 px |
| Transparency | Index 0 is always transparent |
| Texture filter | Nearest |
| Mip maps | Off |
| Palette source | `game_constants.gd` palette only — no custom colours |

Splatters are authored in the attacker's ink color and imported as neutral (grayscale), then tinted at runtime via `modulate` to the correct player color. This ensures a single asset set serves both players.

### 8.9 Naming Conventions

| Asset Type | Convention | Example |
|------------|------------|---------|
| GDScript files | `snake_case.gd` matching class name | `flick_trajectory.gd` |
| Scene files | `PascalCase.tscn` matching root node | `PlayerFigure.tscn` |
| PNG assets | `snake_case_descriptor.png` | `splatter_small.png` |
| Constants | `UPPER_SNAKE_CASE` | `INK_BLACK` |
| Signals | `snake_case` past tense | `shot_fired`, `hit_resolved` |
| `Line2D` nodes | `PascalCase` describing the stroke | `LeftArm`, `TorsoLine`, `ArenaWallTop` |

### 8.10 Asset Compliance Checklist

Before any asset is committed, verify:

- [ ] All colors sourced from `game_constants.gd` — no inline `Color()` literals
- [ ] All `Line2D` nodes set to round caps, round joints, `antialiased: true`
- [ ] Wobble baked at edit time — no per-frame recalculation
- [ ] Trajectory lines using SubViewport accumulation (not unbounded node spawning)
- [ ] PNG-8 raster assets within 128 × 128 px, palette-restricted
- [ ] Fonts in Bitmap mode at exact display size, Nearest filter
- [ ] Animation durations match §8.6 timing table
- [ ] No `AnimationPlayer` used for stroke or figure animation

---

## Section 9: Reference Direction

### Purpose

These five references are not style targets — they are constraints on specific decisions. Each one resolves a design question that would otherwise produce inconsistent results across artists and sessions.

---

### Reference 1: Charles Schulz — *Peanuts* (1950–2000)

**The decision it resolves:** How much do we draw?

Schulz built some of the most emotionally legible characters in the medium using the fewest marks necessary. A raised eyebrow is two curved lines. Grief is a downward arc. He never drew what the reader could infer.

**Applied rule:** Every figure element must justify its presence against Schulz's economy test: *"If I removed this stroke, would the read change?"* If not, remove it. Flick Duel figures are constructed from the minimum viable geometry — the constraint is not a limitation, it is the aesthetic.

---

### Reference 2: *Papers, Please* (Lucas Pope, 2013)

**The decision it resolves:** How does the document surface carry emotional weight?

In *Papers, Please*, paper is not neutral — stamps, smears, and marks accumulate on documents and communicate history. The surface becomes a record of decisions made under pressure.

**Applied rule:** Trajectory lines are permanent. Hit marks do not disappear at turn end. The page accumulates evidence of the match, and a player reading the page midgame can reconstruct every decision. Never clean the canvas between turns; impermanence would contradict the notebook-as-record-keeper principle.

---

### Reference 3: A Physical College-Ruled Notebook

**The decision it resolves:** What is the structural grammar of the playing field?

The reference is not a photograph or an artist's interpretation — it is the object itself. Ruling lines are `#C8C0B0` (`RULE_GREY`), spaced at `24 px` (representing the standard 8.7 mm college rule at the game's internal scale). The margin line is a single vertical stroke in the same color, left of the playing area. The paper color is `#F5F0E8` (`PAPER`), not white.

**Applied rule:** The ruled-line grid is the background, not an overlay. It renders first, below all other elements. Spacing and color must match this reference exactly — any deviation reads as a different paper type (graph paper, legal pad) and breaks the ground truth.

---

### Reference 4: *Superhot* (SUPERHOT Team, 2016)

**The decision it resolves:** How do we maintain visual contrast during live gameplay?

*Superhot* keeps its world legible under extreme action by enforcing a ruthless hierarchy: one dominant value for background, one for environment, one for the player-critical object (the red enemy). Everything else is subordinate.

**Applied rule:** The Flick Duel contrast hierarchy, from most to least prominent:
1. **Active player's ink color** (the action being taken right now)
2. **Hit result geometry** (the outcome of the just-resolved shot)
3. **Player figures** (black ink, always present)
4. **Arena and UI chrome** (black ink, reduced weight)
5. **Ruling lines** (grey, lowest weight)

When adding any new visual element, assign it a hierarchy level before determining its color or weight. An element without a hierarchy assignment is not ready to implement.

---

### Reference 5: Ben Shahn — *Love and Joy About Letters* (1963)

**The decision it resolves:** What makes irregularity feel intentional rather than buggy?

Shahn's hand-lettering demonstrates the difference between controlled imperfection (each letter slightly different from its neighbours, but consistent in character and weight) and random noise (inconsistent pressure, wandering baselines, lost stroke endings). The former reads as craftsmanship; the latter reads as error.

**Applied rule:** Wobble parameters (Perlin noise seed, amplitude, frequency) are set once per geometry class and held constant within that class. A figure's left arm has the same wobble character as its right arm. The arena wall's wobble character matches the figure outlines. Imperfection must be *coherent* — a consistent hand, not a random one. Random seeds must be fixed constants, not generated at runtime.

---

*Art Bible complete. Status: Approved for asset production.*
