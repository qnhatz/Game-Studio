# UX Spec: Main Menu

> **Screen**: MainMenu
> **Last Updated**: 2026-05-11
> **Status**: Draft — pending /ux-review
> **Accessibility Tier**: Standard (`design/accessibility-requirements.md`)
> **ADR References**: ADR-0010 (CanvasLayer hierarchy, button targets, focus)
> **Interaction Patterns**: `design/ux/interaction-patterns.md`

---

## 1. Purpose

The Main Menu is the entry point. The player arrives here on launch and after
every completed match. It must communicate the game's identity immediately and
get the player into a match with the minimum number of taps.

---

## 2. Player Goals

1. Start a 2-player local match
2. Start a vs-Computer match (select difficulty)
3. Understand what the game is without reading instructions

---

## 3. Screen Layout

```
┌──────────────────────────────────────────────────┐
│                                                  │
│                  FLICK DUEL                      │  ← TitleLabel (centred, large)
│           (tagline: "Draw. Flick. Win.")         │  ← SubtitleLabel (centred, small)
│                                                  │
│              [  2 Players  ]                     │  ← TwoPlayersButton (220×60)
│                                                  │
│              [ vs Computer ]                     │  ← VsComputerButton (220×60)
│                                                  │
│   ┌─────────────────────────────────────────┐   │
│   │  [ Easy ]   [ Medium ]   [ Hard ]       │   │  ← DifficultySelector (hidden by default)
│   └─────────────────────────────────────────┘   │
│                                                  │
└──────────────────────────────────────────────────┘
```

CanvasLayer layer = 10 (ADR-0010).
All layout is centred horizontally. Vertical distribution: title in top third,
buttons in middle third, difficulty selector below vs-Computer button.

---

## 4. Node Hierarchy

```
MainMenu (CanvasLayer, layer = 10)
├── CentreContainer (VBoxContainer, anchored centre)
│   ├── TitleLabel          (Label, "FLICK DUEL")
│   ├── SubtitleLabel       (Label, "Draw. Flick. Win.")
│   ├── Spacer              (Control, min height 32)
│   ├── TwoPlayersButton    (Button, min size 220×60)
│   ├── VsComputerButton    (Button, min size 220×60)
│   └── DifficultySelector  (HBoxContainer, hidden by default)
│       ├── EasyButton      (Button, min size 80×48)
│       ├── MediumButton    (Button, min size 80×48)
│       └── HardButton      (Button, min size 80×48)
```

---

## 5. Interaction Flow

### Entry
- On show: `difficulty_selector.hide()` → `two_players_button.grab_focus()`
  (ADR-0010: `_on_show()` contract)
- `gui_release_focus()` called by GameStateMachine before hiding any previous screen

### "2 Players" tap
- Immediately emits `mode_selected("TWO_PLAYER")` → GameModeManager
- Hides MainMenu (via GameStateMachine state transition)

### "vs Computer" tap
- Reveals DifficultySelector (DifficultySelector shows, `easy_button.grab_focus()`)
- "vs Computer" button remains visible
- Tapping "vs Computer" again re-opens difficulty selector if closed

### Difficulty tap (Easy / Medium / Hard)
- Emits `difficulty_selected("EASY" | "MEDIUM" | "HARD")` → AIDifficultyConfig
- Emits `mode_selected("VS_COMPUTER")` → GameModeManager
- Both signals fire before GameStateMachine transition

### Back navigation (keyboard Escape)
- If DifficultySelector visible: hide it, return focus to VsComputerButton
- If DifficultySelector hidden: no action (no back from main menu; this is the root screen)

---

## 6. Accessibility Requirements (Standard Tier)

- All buttons ≥48 px in smallest dimension (ADR-0010: 220×60 and 80×48 ✅)
- Tab order: TwoPlayersButton → VsComputerButton → [if visible: Easy → Medium → Hard]
- `grab_focus()` set on screen show (TwoPlayersButton is first tab stop)
- No colour-only differentiation: buttons use text labels, not colour-coded icons
- Font size: TitleLabel min 32px; button labels min 18px — scalable via theme

---

## 7. Visual Design Notes

(See `design/art/art-bible.md` — notebook sketch aesthetic)

- Background: off-white (`#F5F0E8`) ruled notebook paper — no solid fill
- Title text: handwritten-style font, P1-blue (`#1A33CC`)
- Subtitle text: lighter weight, same font, dark ink
- Buttons: no solid fills; ink-outline border, white interior, label in dark ink
- DifficultySelector: Easy = lighter ink, Hard = bold ink weight (communicates difficulty via visual weight)
- No hover states — buttons show focus ring (2px ink-colour outline) for keyboard nav

---

## 8. GDD Requirements Coverage

| Req | GDD Source | How addressed |
|-----|-----------|--------------|
| TR-MNU-001 | main-menu.md | show/hide Control on transitions — gui_release_focus() before hide |
| TR-MNU-002 | main-menu.md | DifficultySelector hidden by default; shows on vs-Computer tap |
| TR-GSM-001 | game-state-machine.md | MENU state → this screen visible |
| TR-HUD-003 | hud-turn-indicator.md | Not applicable (HUD not visible in MENU state) |

---

## 9. Open Questions

- OQ-M1: Should "vs Computer" be greyed out if only MEDIUM difficulty ships in MVP?
  Current plan: show all three difficulty buttons; Easy/Hard buttons emit signal
  normally (AIDifficultyConfig has params for all three); all ship in MVP.
- OQ-M2: Should there be a "How to Play" button? GDD omits it. Add in Polish if
  playtesting shows new players need guidance.

---

## 10. Acceptance Criteria

- [ ] MainMenu visible on game launch (GameStateMachine starts in MENU state)
- [ ] Tapping "2 Players" → match starts, MainMenu hides, HUD visible
- [ ] Tapping "vs Computer" → DifficultySelector reveals; tapping a difficulty → match starts
- [ ] Keyboard Tab navigates all buttons in order; Enter activates
- [ ] No gesture input (flick drag) processed while MainMenu is visible
- [ ] DifficultySelector hidden on every MainMenu show (not just first show)
- [ ] All button tap targets ≥48 px (visual inspection + layout check)
