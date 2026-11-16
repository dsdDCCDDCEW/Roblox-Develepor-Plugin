---
name: game-architecture
description: This skill should be used when the user asks to "design a Roblox game architecture", "structure my Roblox project", "where should this script go", "plan a game's systems", "organize ServerScriptService and ReplicatedStorage", "single-script architecture", "design a game loop", "plan a round system", or wants architectural decisions explained for a Roblox experience (folder layout, service boundaries, data flow, places and universes).
version: 1.0.0
---

# Roblox Game Architecture

Design Roblox experiences that stay maintainable as they grow: clear ownership of state, few entry-point scripts, explicit boundaries between server, client and shared code, and data flowing in one direction.

## Before designing anything

1. **Analyze the existing project first.** Map containers (`ServerScriptService`, `ServerStorage`, `ReplicatedStorage`, `ReplicatedFirst`, `StarterPlayer`, `StarterGui`, `Workspace`), entry scripts, frameworks in use, and whether it is a Rojo (file-based) or Studio-only project. Use the analyze-project skill or the roblox-systems-architect agent for this.
2. Identify the experience's core loops (moment-to-moment, session, long-term progression). Architecture serves those loops; do not build generic infrastructure the game does not need.
3. Never restructure or move existing files without the user's approval. Propose a migration plan instead.

## Container responsibilities

| Container | Replicates to client? | Put here |
|---|---|---|
| `ServerScriptService` | No | Server entry script, server-only services and modules |
| `ServerStorage` | No | Server-only assets (maps, tools, NPC templates) cloned at runtime |
| `ReplicatedStorage` | Yes | Shared modules, remotes, shared config and types, client-needed assets |
| `ReplicatedFirst` | Yes, first | Loading screen and minimal bootstrap only |
| `StarterPlayer.StarterPlayerScripts` | Yes | Client entry script and client controllers |
| `StarterPlayer.StarterCharacterScripts` | Yes | Per-character scripts (re-run each spawn); keep minimal |
| `StarterGui` | Yes | UI layouts; logic belongs in client controllers |
| `Workspace` | Yes | The 3D world only, not scripts or secret data |

Anything in a replicated container can be read by exploiters, including ModuleScript source. Keep secrets, server logic, economy tables with hidden values, and admin lists on the server.

## Recommended shape: one entry script per side

- **Server**: one `Script` in `ServerScriptService` that requires every service module and runs a two-phase bootstrap (`Init` then `Start`).
- **Client**: one `LocalScript` in `StarterPlayerScripts` that does the same for controllers.
- Systems are ModuleScripts. This gives deterministic load order, no race conditions between scripts, explicit dependencies, and easy testing. See the modular-game-systems skill and its `ServiceLoader.luau` example.

Explain this decision to the user when proposing it, and keep the existing style if the project already uses a consistent alternative (for example a framework, or an ECS such as jecs or Matter).

## Authority and data flow

- The server owns all authoritative state: currency, inventory, progression, match state, damage, cooldowns.
- Clients send **intents** ("I want to buy item X"), never results ("I now have 500 coins").
- The server validates, mutates state, then replicates the result (attributes, values, remotes, or a replication module).
- For competitive physics and movement (shooters, racing, sports, combat), evaluate Roblox's **server authority model** (`Workspace.AuthorityMode = Server`, with client prediction and rollback). It requires `StreamingEnabled`, deferred signal behavior, fixed simulation, next-generation replication and the Input Action System; confirm current requirements at `https://create.roblox.com/docs/projects/server-authority.md`.

## Decision checklist for each new system

1. Who owns the state: server, client, or both (server authority plus client prediction or presentation)?
2. What crosses the network, how often, and how is it validated? (remote-networking skill)
3. What persists, and when is it saved? (datastore-persistence skill)
4. What happens when a player joins mid-session, leaves mid-action, or the server shuts down?
5. What is the worst thing an exploiter can do with it? (anti-exploit-security skill)
6. What are the per-frame and per-player costs at the target player count? (performance-optimization skill)

Record answers in the design summary given to the user.

## Multi-place experiences

- Use one universe with several places (lobby, match servers) and `TeleportService` (`TeleportAsync` with `TeleportOptions`) for movement between them.
- Share code across places with packages or a Rojo project per place that references a shared source folder.
- Cross-server communication: `MessagingService` (fire-and-forget, best effort), `MemoryStoreService` (fast, expiring shared state: queues, sorted maps, hash maps), DataStores (durable).

## Anti-patterns to flag

- Dozens of independent `Script`s each listening to the same events (race conditions, duplicated logic).
- Logic inside `StarterGui` or `Workspace` parts.
- `_G` or `shared` as a service locator.
- Client-authoritative economy or damage.
- One giant module that does everything; equally, a framework with more layers than the game has systems.
- Remotes created ad hoc at runtime by many scripts with no central definition.

## Additional resources

- **`references/project-layout.md`** - reference Rojo `default.project.json`, folder tree, and naming conventions for a mid-sized experience.
