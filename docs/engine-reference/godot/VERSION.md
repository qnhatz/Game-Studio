# Godot Engine — Version Reference

*Last verified: 2026-05-06*

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.6 (latest patch: 4.6.2) |
| **Release Date** | January 2026 |
| **Project Pinned** | 2026-05-06 |
| **Last Docs Verified** | 2026-05-06 |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | HIGH |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4, 4.5,
and 4.6 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Godot API calls.
Use `/setup-engine refresh` to update these docs when needed.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, OS.read_string_from_stdin breaking |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, TileMapLayer physics chunking |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, AnimationPlayer StringName changes, scene format |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.3→4.4 migration: https://docs.godotengine.org/en/4.4/tutorials/migrating/upgrading_to_godot_4.4.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/4.5/tutorials/migrating/upgrading_to_godot_4.5.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.6/

## Reference Files in This Directory

| File | Contents |
|------|---------|
| `breaking-changes.md` | Per-version breaking changes (4.4, 4.5, 4.6) |
| `deprecated-apis.md` | "Don't use X — use Y instead" quick reference |
| `current-best-practices.md` | New GDScript patterns available since 4.4 |
