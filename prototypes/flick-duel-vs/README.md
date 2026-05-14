# Flick Duel VS — Vertical Slice Prototype

**PROTOTYPE — NOT FOR PRODUCTION**

## Purpose

Answers the core pre-production question:

> Does the slingshot-drag-to-fire mechanic feel satisfying and legible? Does a full tap-move + flick-fire turn loop feel tense and decisive?

## How to Run

1. Open Godot 4.6
2. **Import** this folder (`prototypes/flick-duel-vs/`) as a project
3. Press **F5** or click **Play**

The game runs at 800×450. Works in the Godot editor viewport and in browser export.

## Controls

| Action | Mouse | Touch |
|--------|-------|-------|
| Move figure | Tap/click anywhere in your half | Tap in your half |
| Aim shot | Drag from within ~48px of your figure | Drag from your figure |
| Fire shot | Release the drag | Release |
| Cancel shot | Release with tiny drag (< 7.5px) | Same |
| Restart | Click after game ends | Tap after game ends |

**Slingshot model**: drag LEFT → shot goes RIGHT (opposite to drag, like a pen flick).

## Rules

- **P1 (blue ink)** owns the left half; **P2 (red ink)** owns the right half
- **2 actions per turn** — any mix of moves and shots
- **Hit zones**: Head (instant win) · Arms · Legs
- Hitting all 3 zones on one player also wins
- No shot spread in this prototype — shots are perfectly accurate

## What's Intentionally Missing

This prototype answers *feel*, not *features*:

- No status effect consequences (hitting arms/legs has no effect beyond the visual mark)
- No shot spread / RNG
- No AI opponent
- No sound
- No animations
- No menus, score tracking, or match history

## Playtest Notes Template

After each session, answer:

1. Did the slingshot direction feel natural or confusing?
2. Did tapping to move feel responsive and intentional?
3. Was it obvious which zones were already hit?
4. Did the shot lines read clearly — both the aim line and the fired line?
5. Did 2 actions per turn feel like the right pressure?
6. Did you feel clever when you landed a shot? Tense when your opponent fired?
7. Any moment that felt unfair, unclear, or frustrating?
8. Would you play another round?

See `production/playtests/` for the playtest report template.
