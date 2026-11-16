---
name: server-client-architecture
description: This skill should be used when the user asks "should this run on the server or client", "how does replication work", "client-server model in Roblox", "replicate state to clients", "network ownership", "client prediction", "server authority", "StreamingEnabled", "sync state between server and client", "make this feel responsive without trusting the client", or is deciding where game logic, UI, physics or effects should execute.
version: 1.0.0
---

# Server-Client Architecture

Decide, for every piece of logic and state, which side owns it and how the other side learns about it. The rule is simple: **the server decides, the client presents and requests.** The craft is keeping it responsive.

## Ownership matrix

| Concern | Owner | Client role |
|---|---|---|
| Currency, inventory, progression, purchases | Server | Display; send purchase intents |
| Damage, health, kills, cooldowns | Server | Predict visuals (hit markers, animations) optimistically; reconcile |
| Match/round state, timers | Server (publish `workspace:GetServerTimeNow()`-based end time) | Render countdown locally from the synced end time |
| Player movement | Client by default (character network ownership); server with the server authority model | Input |
| Physics of gameplay-critical objects | Server (`SetNetworkOwner(nil)`) or server authority | Visuals |
| Cosmetic effects, sounds, camera, UI | Client | Full ownership |
| Input handling | Client | Converts input into intents |
| NPC AI | Server | Optional client-side smoothing/animation |

## Replication channels (pick the lightest that works)

1. **Instance properties and Attributes** set by the server replicate automatically. Use attributes for small per-object state (`Health`, `Team`, `State`). Clients listen with `GetAttributeChangedSignal`.
2. **Value objects / folders under the Player** (for example `leaderstats`) for simple per-player public state.
3. **`RemoteEvent` pushes** for private data, events and batched deltas (`InventoryChanged`).
4. **A replication module** (state container with diff-based sync) for complex state; build or adopt one only when 1 to 3 are insufficient.

Do not replicate the same state through two channels.

## Responsiveness without trust

- **Optimistic presentation**: the client plays the swing animation and sound immediately, sends the intent, and the server decides the outcome. If the server rejects it, the client rolls back the visual.
- **Server-side lag tolerance**: when validating hits or distances, allow tolerance proportional to latency (`player:GetNetworkPing()`), capped, instead of rejecting legitimate laggy players.
- **Server authority model** (`Workspace.AuthorityMode = Server`): the engine predicts and rolls back physics and movement for you; clients only send inputs. Use it for competitive movement-heavy games. It requires next-generation replication, `PlayerScriptsUseInputActionSystem`, deferred `SignalBehavior`, fixed simulation and `StreamingEnabled`; `RunService:SetPredictionMode()` controls prediction per instance. Read `https://create.roblox.com/docs/projects/server-authority.md` and its techniques page before adopting it, because it changes how input and movement code must be written.

## Network ownership (default model)

- Unanchored parts are simulated by the server or by a nearby client. A client that owns a part controls its physics completely, including `Touched` events.
- For server-critical unanchored assemblies, call `part:SetNetworkOwner(nil)` on the server after parenting to Workspace.
- Never trust positions of client-owned parts for rewards. Validate with server-side spatial queries and plausibility checks.

## StreamingEnabled

- Client may not have distant parts. Never assume `workspace.Map.Part` exists on the client; use `WaitForChild` with timeouts, `ChildAdded`, or CollectionService `GetInstanceAddedSignal`.
- Server code is unaffected: the server has everything.
- Use `ModelStreamingMode` (`Persistent`, `Atomic`, `PersistentPerPlayer`) for models a client must always have or must receive whole. `Player:RequestStreamAroundAsync(position)` before teleports.

## Script placement by RunContext

- `Script` with `RunContext = Server` runs on the server from any location, `RunContext = Client` runs on clients from any location (including ReplicatedStorage), `Legacy` follows the classic container rules.
- Prefer the single-entry-script pattern (game-architecture skill), which makes placement explicit.

## Checklist when adding a feature

1. List its state; assign each piece an owner from the matrix.
2. List each client-to-server message; specify validation (remote-networking skill).
3. Choose the replication channel for each server-to-client update.
4. Decide what the client predicts and how it rolls back.
5. Check StreamingEnabled implications for any Workspace reference on the client.
6. Write down the decision and its reason for the user.
