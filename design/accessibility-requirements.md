# Accessibility Requirements — Flick Duel

> **Tier**: Standard
> **Committed**: 2026-05-11
> **Review**: Re-evaluate before Polish phase

## Tier Definition

**Standard** — Basic + colorblind modes + scalable UI.

Minimum public release bar for a browser game with a broad casual audience.
Flick Duel's ink-colour player identity (P1 blue / P2 red) makes colorblind
modes a first-class requirement, not an afterthought.

---

## Required Features (Standard Tier)

### Input
- [ ] **Gesture remapping** — not applicable for flick gesture (position-intrinsic);
      but button tap targets must be ≥48×48 px on all buttons (ADR-0010 ✅)
- [ ] **Keyboard navigation** — main menu and result screen navigable via Tab/Enter
      (ADR-0010: `grab_focus()` on show)

### Vision
- [ ] **Colorblind modes** — minimum: Deuteranopia and Protanopia safe palettes for P1/P2
      ink colours. Default P1=blue (#1A33CC) and P2=red (#CC1A1A) are unsafe for red-green
      colorblindness. Alternative: offer a shape/pattern discriminator (e.g. dotted vs solid
      line) alongside colour.
- [ ] **UI text scalable** — HUD counter labels and button labels must not use fixed pixel
      font sizes that become unreadable on small displays. Use `theme_override_font_size`
      relative to viewport height or expose a font-size setting.
- [ ] **Sufficient contrast** — all text on HUD: ≥4.5:1 contrast ratio against background
      (WCAG AA). Ink lines: ≥3:1 against canvas background.

### Cognitive
- [ ] **Clear turn indication** — HUD turn arrow and player label must be unambiguous
      to a new player; cannot rely on colour alone (pairs with colorblind requirement above).

---

## Out of Scope (Standard Tier — revisit for Comprehensive)

- Screen reader / VoiceOver support
- Motor accessibility settings (dwell time, switch access)
- Full settings menu
- External audit

---

## Implementation Notes

### Colorblind palette candidates

| Mode | P1 (Blue player) | P2 (Red player) |
|------|-----------------|------------------|
| Default | `#1A33CC` (blue) | `#CC1A1A` (red) |
| Deuteranopia / Protanopia safe | `#0066FF` (blue) | `#FF6600` (orange) |
| High contrast | `#0000FF` (blue) | `#FFD700` (gold) |

The colorblind palette swap is a runtime option — store in a `UserPreferences`
resource and apply via `FigureRenderer` at `_ready()` using the `P1_COLOR` /
`P2_COLOR` constants (ADR-0003).

### Pattern discriminator (alternative / complement to colour swap)

P1 Line2D nodes: solid strokes (default)
P2 Line2D nodes: dashed strokes (pattern via shader or segmented Line2D)

This allows colour-independent player discrimination with no palette change
required — but adds shader complexity. Evaluate in Polish phase.

---

## Gate Requirements

This document must exist and have a committed tier before advancing from
Technical Setup to Pre-Production (gate-check artifact).

All key screen UX specs (`design/ux/`) must reference this document and
state how the Standard tier requirements are addressed in that screen.
