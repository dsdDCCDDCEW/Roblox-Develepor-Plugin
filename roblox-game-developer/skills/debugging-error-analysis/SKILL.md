---
name: debugging-error-analysis
description: This skill should be used when the user reports a Roblox error or bug, pastes Output window text or a stack trace, or asks to "debug this script", "why is this nil", "attempt to index nil", "Infinite yield possible", "my script doesn't run", "remote not firing", "data not saving", "works in Studio but not in game", "fix this error", or describes unexpected behavior in a Roblox experience.
version: 1.0.0
---

# Roblox Debugging and Error Analysis

Find the root cause before changing code. Reproduce, read the evidence, form ranked hypotheses, test the cheapest one first, then make the narrowest fix.

## Process

1. **Collect evidence.**
   - Exact error text and stack trace (script path and line). With the Studio MCP connected, read it via `get_console_output` after reproducing in a playtest.
   - Where it happens: server, client, or both; Studio Play, Play Here, Run, Team Test, or live servers.
   - When: on join, on respawn, after a specific action, intermittently, after N minutes.
   - What changed recently.
2. **Read the code path end to end.** Open the erroring script, the modules it requires, and anything that fires or listens on the same remote, event or attribute. Do not guess from the error line alone.
3. **Classify the failure** with the table below and `references/common-errors.md`.
4. **Rank hypotheses** by likelihood times cheapness to verify. State them to the user.
5. **Verify** with the smallest probe: a targeted `print`/`warn` with context, a `debug.traceback()` at the suspect point, a breakpoint, or an `execute_luau` read of live state. Remove temporary prints afterward.
6. **Fix at the responsible layer.** Do not add `pcall`, `WaitForChild` or `task.wait` to mask a race or nil; fix the ordering or ownership instead.
7. **Confirm** by re-running the reproduction. If it cannot be run, say exactly what is unverified.

## Quick classification

| Symptom | First suspects |
|---|---|
| `attempt to index nil with 'X'` | Instance not loaded yet (client), wrong path, character respawned, `FindFirstChild` returned nil, module returned nil |
| `Infinite yield possible on 'X:WaitForChild("Y")'` | Wrong name/parent, object only exists on the other side (server-only container), StreamingEnabled has not streamed it in |
| Script never runs | Wrong container for its type or `RunContext`, `Disabled`/`Enabled` false, LocalScript outside a client-run location, required module errored on load |
| Remote does nothing | Listener connected after first fire, wrong remote instance (duplicate names), server handler errored silently, rate limit or validation rejecting it |
| Works in Studio, fails live | Studio API access setting for DataStores, latency/ordering assumptions, StreamingEnabled, `RunService:IsStudio()` branches, HTTP not enabled |
| Data not saving | No `BindToClose`, save failing without retry, session lock rejecting writes, Studio Run mode limits, writing during shutdown |
| Gets worse over time | Connection leaks, growing tables keyed by `Player`, un-destroyed clones, runaway `while true` loops |
| Physics jitter or teleporting parts | Network ownership changes, anchoring mid-simulation, client-moved server-owned parts |

## Debugging tools

- **Output window / console**: errors, warnings, prints. Filter by context (server/client).
- **Developer Console (F9)** in live servers: Log, Memory, Script Profiler, Network, MicroProfiler.
- **Breakpoints and Watch** in the Studio Script Editor; conditional breakpoints and logpoints to avoid editing code.
- **`debug.traceback()`** and `xpcall(fn, debug.traceback)` for full stacks from inside handlers.
- **`debug.info(level, "sln")`** for caller info in diagnostic helpers.
- **Studio Test tab**: multi-client Team Test simulates several players and real replication.
- **Studio MCP**: `get_console_output`, `execute_luau` (inspect state in Edit mode or during play where supported), `inspect_instance`, `search_game_tree`.

## Rules

- Never claim a fix works without running it or stating that it is unverified.
- Never "fix" by deleting the erroring feature or swallowing errors.
- Keep diagnostic prints prefixed (`[Combat]`) and remove them before finishing.
- If the root cause is architectural (race between independent scripts, client authority), explain it and propose the structural fix; apply only with approval if it spans many files.

## Additional resources

- **`references/common-errors.md`** - exact error messages, causes and fixes, plus replication and lifecycle gotchas.
