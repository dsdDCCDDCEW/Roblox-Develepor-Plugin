# Profiling Guide

Official references: https://create.roblox.com/docs/performance-optimization, https://create.roblox.com/docs/studio/microprofiler, https://create.roblox.com/docs/studio/script-profiler, https://create.roblox.com/docs/scripting/multithreading, https://create.roblox.com/docs/luau/native-code-gen. Check them for current hotkeys and UI, which change between Studio releases.

## MicroProfiler workflow

1. Reproduce the lag scenario (in a live server for server issues, on the slowest target device for client issues).
2. Open MicroProfiler, pause on a spike frame.
3. Expand the frame: look for wide bars under scripts (`$Script_...` / labels), `physicsStepped`, `Render`, `Replicator`.
4. Add custom labels around suspect code:
   ```lua
   debug.profilebegin("EnemyAI.Update")
   updateEnemies(dt)
   debug.profileend()
   ```
   Labels must be balanced on every code path, including early returns.
5. Dump frames to HTML for sharing or comparison.

## Script Profiler workflow

1. Start recording on the target context (server or client).
2. Run the scenario for 10 to 30 seconds.
3. Sort by total time; drill into the top functions.
4. Export the capture for before/after comparison.

## Memory leak hunt

1. Note `Luau Heap` and `PlaceMemory` categories at session start.
2. Repeat an action loop (respawn, join/leave with a test account, open/close UI) 20 times.
3. If memory climbs and does not fall, take Luau heap snapshots and compare object counts by type and by script.
4. Usual culprits: connections never disconnected, tables keyed by `Player` or `Instance` never cleared, clones parented to nil but still referenced, `task.delay` closures holding references.

## Parallel Luau template

```lua
-- Script inside an Actor (one Actor per independent work unit, e.g. per NPC group)
local actor = script:GetActor()
assert(actor, "This script must be a descendant of an Actor")

actor:BindToMessage("Step", function(dt: number)
	-- Parallel phase: read the DataModel and compute only.
	task.desynchronize()
	local results = computePaths(dt)

	-- Serial phase: write to the DataModel.
	task.synchronize()
	applyResults(results)
end)
```

The coordinator sends work with `actor:SendMessage("Step", dt)`. Split work across several Actors; one Actor uses one thread at a time.

## Native codegen checklist

- Code is CPU-bound Luau (math, loops, serialization), confirmed by the profiler.
- Hot functions have type annotations (numbers, vectors, buffers) so the compiler can specialize.
- Apply `@native` per function first; use `--!native` for whole modules dominated by such code.
- Measure before and after on the server (native codegen is always available on servers; client support depends on platform).
