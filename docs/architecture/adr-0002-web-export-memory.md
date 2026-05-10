# ADR-0002: Web Export and Memory Strategy

## Status
Proposed

## Date
2026-05-10

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Rendering (Compatibility / WebGL 2) |
| **Knowledge Risk** | HIGH — Compatibility renderer settings and web export options changed in 4.4–4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/rendering.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | `rendering/renderer/rendering_method.web` platform override (4.4+) |
| **Verification Required** | Measure actual WASM heap + asset memory on Chrome and Safari iOS before shipping; confirm WASM Memory Size export preset is set to 128 MB |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Topology) — single persistent scene constrains the total live-memory profile |
| **Enables** | ADR-0003 (Rendering Primitives) — renderer choice determines which node APIs are available |
| **Blocks** | All rendering and export implementation stories |
| **Ordering Note** | Must be Accepted before any export template or project settings are committed |

## Context

### Problem Statement

Flick Duel targets desktop and mobile browsers. The renderer, physics, threading model, and memory
ceiling must be locked before any system implementation begins — wrong choices here affect every
subsequent system.

### Constraints

- **Browser target**: Chrome (desktop + mobile) and Safari iOS; must work without COOP/COEP headers
  (most hosting environments do not serve them)
- **Memory ceiling**: ≤128 MB total (browser safety limit; exceeding it causes tab crashes on
  low-RAM mobile devices)
- **No native plugins**: GDExtensions are not supported in Godot web exports
- **No 3D**: 2D-only project; 3D rendering pipeline overhead is wasted memory
- **Instant-feel UX**: shader compilation hitches must not occur during play (see ADR-0001)

### Requirements

- Broadest possible browser hardware support (WebGL 2 minimum)
- All collision detection must work without PhysicsServer (analytic ray math only — see ADR-0005)
- No mid-session memory spikes from asset loading
- Single-threaded execution to avoid COOP/COEP header dependency

## Decision

**Compatibility renderer (WebGL 2), single-threaded web export, 128 MB WASM memory cap.**

### Renderer Configuration

```
# project.godot
[rendering]
renderer/rendering_method = "gl_compatibility"          # local editor
renderer/rendering_method.mobile = "gl_compatibility"   # mobile platforms
renderer/rendering_method.web = "gl_compatibility"      # web export (required)
```

The `.web` override is required — without it, the web export falls back to the project default
but does not guarantee Compatibility mode if the project default was ever changed.

### Physics Server

Godot 4.6 always initialises PhysicsServer2D; there is no API to disable it. Overhead is
negligible (<1 MB) for a project that places no physics-enabled nodes. **No physics nodes are
allowed**: no `RigidBody2D`, `CharacterBody2D`, `StaticBody2D`, or `CollisionShape2D`.
All spatial reasoning uses analytic math (see ADR-0005). PhysicsServer2D methods are never called.

### Web Export Preset Settings

| Setting | Value | Reason |
|---------|-------|--------|
| `javascript/export/threads_enabled` | **false** | Threads require COOP/COEP headers; disabled for broad host compatibility |
| WASM Memory Size | **128 MB** | Hard cap matching browser memory ceiling; prevents runaway allocation |
| GDExtension | Not used | GDExtensions are unsupported in web exports |
| Export template | Release (non-debug) | Debug templates include ~30% more overhead |

### Memory Budget

| Component | Estimated Size |
|-----------|---------------|
| WASM binary (Godot engine) | ~18 MB |
| Engine heap (core, servers) | ~12–20 MB |
| WebGL context overhead | ~5–8 MB |
| **Engine baseline total** | **~35–46 MB** |
| Game assets (Line2D nodes, no textures) | <2 MB |
| **Projected peak usage** | **~37–48 MB** |
| **Headroom within 128 MB ceiling** | **~80–91 MB** |

The 128 MB ceiling is conservative for this game's asset profile. New systems that add significant
memory (textures, audio, large data structures) require an explicit memory budget review before
implementation.

### Shader Baker

Not applicable. Shader Baker (added in Godot 4.5) targets Vulkan/D3D12 pipeline state object
pre-compilation. Compatibility/WebGL 2 projects use GLSL compiled by the browser's WebGL driver —
the Shader Baker does not run for this export target. Shader compilation latency on Compatibility
is managed by the single persistent scene topology (ADR-0001) which ensures all shaders are compiled
at startup.

## Alternatives Considered

### Alternative A: Forward+ renderer with WebGL 2 fallback

- **Description**: Develop with Forward+ locally; rely on Godot's automatic fallback for web
- **Pros**: Access to advanced rendering features (SSAO, SSR, glow) for potential visual enhancement
- **Cons**: Forward+ is not supported in WebGL 2 — there is no automatic fallback. The game would
  be unplayable in the browser. The "Notebook Duel" aesthetic uses no effects that require Forward+.
- **Rejection**: Forward+ is simply not available on the web target.

### Alternative B: Mobile renderer

- **Description**: Use the Mobile renderer (optimised for mobile OpenGL ES 3.0)
- **Pros**: Slightly better mobile GPU optimisation than Compatibility in some scenarios
- **Cons**: Less broad hardware support than Compatibility (OpenGL ES 3.0 vs. WebGL 2 which maps
  to OpenGL 3.3). Compatibility is the correct choice for maximum browser reach.
- **Rejection**: Compatibility is Godot's recommended renderer for WebGL 2 targets and has wider
  compatibility than Mobile for browser environments.

### Alternative C: Multithreaded export (threads_enabled = true)

- **Description**: Enable JavaScript threads for potential performance gains
- **Pros**: Could benefit heavy computation (not applicable here — game has minimal CPU load)
- **Cons**: Requires COOP/COEP HTTP headers (`Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Embedder-Policy: require-corp`). Most web hosts do not serve these by default.
  Failure to serve them silently breaks `SharedArrayBuffer` and causes the game to crash on load.
- **Rejection**: The hosting constraint makes threads an availability risk with no benefit for
  this game's CPU profile (turn-based, 2D, analytic math).

## Consequences

### Positive

- Broadest browser compatibility: WebGL 2 is supported by all modern desktop and mobile browsers
- No COOP/COEP header dependency: game works on any static host (GitHub Pages, itch.io, etc.)
- Memory-efficient: game is projected to use <50 MB of the 128 MB ceiling
- No physics server overhead beyond idle initialisation cost

### Negative

- No post-processing effects (glow, SSAO, SSR): acceptable — the Notebook Duel aesthetic
  does not use them
- Single-threaded: heavy computation would block the main thread. Not a concern for this game's
  workload but limits future scope if compute-heavy systems are added
- 128 MB WASM cap is a hard ceiling: any future system adding significant assets must be budget-reviewed

### Risks

- **Safari iOS WebGL 2**: historically lags on some WebGL 2 extensions. If custom shaders are added
  later that rely on `EXT_color_buffer_float`, test on Safari early.
  *Mitigation*: MVP uses only Line2D (no custom shaders); validate on Safari before any shader work.
- **Memory measurement gap**: the 35–46 MB baseline estimate is from pre-release profiling data.
  Actual value must be measured from a real Godot 4.6 web export.
  *Mitigation*: OQ-2 (open question from architecture doc) — measure with browser DevTools before
  ADR reaches Accepted.

## GDD Requirements Addressed

| TR ID | GDD System | Requirement | How This ADR Addresses It |
|-------|------------|-------------|---------------------------|
| TR-REND-002 | Figure Renderer | Compatibility renderer (WebGL 2); no Forward+ | Defines `gl_compatibility` as the mandated renderer with exact project setting keys |
| TR-BZHD-002 | Body-Zone Hit Detection | No PhysicsServer usage; pure geometry | Confirms PhysicsServer2D cannot be disabled but will sit idle; physics nodes are forbidden |
| TR-SCRN-001 | Screen Layout | Fixed 800×450 logical canvas, Keep Aspect letterbox | Compatibility renderer supports `Window` stretch mode with Keep Aspect correctly |

## Performance Implications

- **CPU**: Single-threaded; all game logic runs on the main thread. Turn-based game with analytic
  math — no bottleneck concerns.
- **Memory**: Projected peak ≤48 MB; 80 MB headroom within ceiling.
- **Load Time**: WASM binary (~18 MB) is the dominant load-time factor. Acceptable for browser;
  compress with gzip/brotli on the server.
- **Network**: N/A — local-only game, no runtime network calls.

## Migration Plan

Greenfield. Set project settings before any rendering code is written. Export preset configured
before first test export.

## Validation Criteria

- Project exports and runs in Chrome (desktop + mobile) and Safari iOS without errors
- `rendering/renderer/rendering_method.web` = `"gl_compatibility"` confirmed in `project.godot`
- WASM Memory Size export preset = 128 MB
- `threads_enabled` = false in web export preset
- Peak memory ≤128 MB measured via browser DevTools Memory tab on a real device
- No `RigidBody2D`, `CharacterBody2D`, or `CollisionShape2D` nodes in the scene tree

## Related Decisions

- ADR-0001: Scene Topology — single persistent scene keeps memory profile flat and predictable
- ADR-0003: Rendering Primitives — Line2D nodes confirmed compatible with Compatibility renderer
- ADR-0005: Physics Policy — analytic ray math replaces PhysicsServer entirely
