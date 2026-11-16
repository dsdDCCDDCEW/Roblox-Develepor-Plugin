---
name: performance-optimization
description: This skill should be used when the user asks to "optimize my Roblox game", "fix lag", "reduce server load", "improve FPS", "my game has memory leaks", "reduce network usage", "use Parallel Luau", "use actors", "use native code generation", "profile with MicroProfiler", "Script Profiler", or reports high ping, frame drops, rising memory, or slow server heartbeat in a Roblox experience.
version: 1.0.0
---

# Roblox Performance Optimization

Measure first, change one thing, measure again. Optimize the hot path the profiler shows, not the code that looks slow.

## Process

1. **Define the symptom and target**: client FPS on low-end mobile, server heartbeat (should hold near 60 Hz), memory over session length, network KB/s per player, or load time.
2. **Profile** with the right tool (table below). Capture before numbers.
3. **Locate the cost**: which script, which label, which frame phase.
4. **Fix the largest cost** with the narrowest change.
5. **Re-measure** with the same scenario. Report before and after numbers, or state clearly that no measurement was possible.

| Tool | Use for |
|---|---|
| Script Profiler (Developer Console / Studio) | CPU time per function, server or client |
| MicroProfiler (Ctrl+Alt+F6 / Ctrl+F6 in-game, Developer Console server profiler) | Frame breakdown: scripts, physics, rendering, replication. Add `debug.profilebegin("Label")` / `debug.profileend()` around suspect code |
| Developer Console > Memory, Luau Heap | Memory by category, Luau heap snapshots and growth |
| Developer Console > Network | Remote and replication bandwidth |
| `Stats` service | Programmatic stats in diagnostics |

## High-impact fixes by area

### Scripts (CPU)

- Replace polling loops (`while true do task.wait() ... end`) with events: `Changed`, `GetPropertyChangedSignal`, `AttributeChanged`, `CollectionService` tag signals.
- Run per-frame work in one place per side (`RunService.Heartbeat`, or `PreSimulation`/`PostSimulation`/`PreRender` for specific phases) instead of many connections.
- Cache service lookups, `FindFirstChild` results and config tables outside hot loops.
- Use spatial queries correctly: `workspace:Raycast`, `GetPartBoundsInBox`, `GetPartBoundsInRadius`, `GetPartsInPart` with reused `RaycastParams`/`OverlapParams`, instead of iterating every part.
- Avoid creating closures, tables and Vector3s per frame in hot code when it measurably matters.
- **Native codegen**: `--!native` at the top of a script or `@native` on a function compiles to native code on the server and supported clients. Best for numeric, typed, branchy Luau (math, simulation, serialization). Annotate types for best results. Measure; it gives no gain for API-call-bound code.
- **Parallel Luau**: put scripts under `Actor` instances, use `task.desynchronize()` or `RBXScriptSignal:ConnectParallel` for parallel work, `task.synchronize()` before writing to the DataModel. Communicate with `Actor:SendMessage` / `BindToMessage` or `SharedTable`. Read thread-safety tags on each API in the reference before calling it in parallel. A script that is not a descendant of an Actor cannot run in parallel.

### Memory

- Disconnect connections and `Destroy()` instances you create. Clear per-player tables on `PlayerRemoving`.
- Use a cleanup helper (Trove, Janitor, Maid pattern) per object lifetime; see modular-game-systems.
- Pool frequently created and destroyed objects (projectiles, effects) only when profiling shows churn.
- Unload streaming content: `StreamingEnabled` with sensible `StreamingTargetRadius`; `ModelStreamingMode` per model (`Atomic`, `Persistent`, `Nonatomic`, `PersistentPerPlayer`).

### Network

- Send intents and deltas, not full state each frame.
- Batch small messages per frame into one remote fire.
- `UnreliableRemoteEvent` for frequent, loss-tolerant, latest-value data (cursor positions, cosmetic effects). Keep payloads under the documented 900-byte limit.
- Pack numbers with `buffer` for high-frequency payloads; quantize where precision is not needed.
- Avoid replicating large instance trees repeatedly; replicate attributes or compact data and build visuals on the client.

### Physics

- Anchor static geometry. Use `CanCollide`, `CanTouch`, `CanQuery` false on purely visual parts.
- Use collision groups to cut pair checks.
- Simplify `CollisionFidelity` on complex MeshParts (`Box`/`Hull`), and use `RenderFidelity` appropriately.
- Avoid huge numbers of unanchored parts and constraints; merge where possible.

### Rendering (client)

- Reduce part and instance counts; use MeshParts and texture atlases.
- Limit dynamic lights with shadows, large transparent surfaces, `ParticleEmitter` rates and `Beam` counts.
- Keep UI updates event-driven; avoid rebuilding UI every frame.

## Reporting format

For each finding: location (script and line or profiler label), measured cost, fix, expected impact, risk. Separate measured facts from estimates.

## Additional resources

- **`references/profiling-guide.md`** - step-by-step MicroProfiler and Script Profiler workflow, Parallel Luau template, native codegen checklist.
