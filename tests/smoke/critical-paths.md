# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (reads this file)
**Update**: Add new entries as core systems are implemented.

## Core Stability (always run)

1. Game launches to main menu without crash
2. "2 Players" mode can be started from the main menu
3. "vs Computer" mode can be started from the main menu
4. Main menu responds to tap/click input without freezing

## Core Mechanic (update per sprint)

5. Drag gesture in player's gesture zone → aim line appears
6. Release gesture → shot fires, trajectory visible
7. Shot reaches opponent figure → hit detection triggers
8. Headshot → match-won state reached, MatchResultScreen shown
9. Rematch button → board resets, new match begins

## AI Turn

10. AI completes FIRE + MOVE actions without hanging
11. AI shot travels through ShotSpreadCalculation path (same as human)

## HUD

12. Turn indicator arrow updates each turn
13. Action counters decrement correctly

## Orientation Gate

14. Rotating device to portrait → rotate-prompt overlay appears, input blocked
15. Restoring landscape → overlay hides, input resumes

## Performance

16. No visible frame drops during a full 10-turn match (60fps target)
17. Memory stable over 3 consecutive matches (no growth leak)
