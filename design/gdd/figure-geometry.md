# Figure Geometry

> **Status**: In Design
> **Author**: Claude Code + user
> **Last Updated**: 2026-05-08
> **Implements Pillar**: Skill Earns the Win / Read Your Opponent

## Overview

Figure Geometry defines the stick figure as a spatial object: its proportions, the positions of all drawn elements relative to the figure anchor, and the boundaries of its three hit zones. It is the single source of truth for where the figure occupies screen space. Hit Detection, the Figure Renderer, and AI Targeting all derive their spatial understanding of each figure from this system — none define their own geometry. Each figure has three non-overlapping hit zones: a **head** (circle), **arms** (wide rectangle), and **legs** (narrow rectangle). Regions between zones — the neck and mid-torso — are valid miss areas. Figure Geometry is pure data; it holds no state beyond the constants that describe the figure's shape.

## Player Fantasy

The stick figure is a target, and reading it is the skill. The head is small and high — a kill shot, but a demanding one. The arms are the widest zone, the safe reliable pick. The legs sit low. Every turn the active player scans the opponent's figure and decides: play it safe, or go for the head? The geometry makes the trade-off legible without any UI annotation — the zones are visible in the figure's proportions.

## Detailed Rules

[To be designed]

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Acceptance Criteria

[To be designed]
