---
name: remote-networking
description: This skill should be used when the user asks to "create a RemoteEvent", "use a RemoteFunction", "send data from client to server", "fire a remote", "validate remote arguments", "rate limit remotes", "use UnreliableRemoteEvent", "reduce remote traffic", "organize remotes", "use a networking library", or mentions OnServerEvent, OnClientEvent, FireServer, FireClient, FireAllClients, InvokeServer or OnServerInvoke.
version: 1.0.0
---

# RemoteEvents and RemoteFunctions

Remotes are the only way clients talk to the server, and every remote is an attack surface. Design them as a small, typed, validated API.

## Choose the right primitive

| Primitive | Direction | Use for | Avoid for |
|---|---|---|---|
| `RemoteEvent` | Both | Intents (client to server), state pushes (server to client) | |
| `UnreliableRemoteEvent` | Both | Frequent, loss-tolerant, latest-value data (aim direction, cosmetic effects, cursor). Payload must stay under the documented 900-byte limit; unordered, may drop | Anything that must arrive (purchases, damage, inventory) |
| `RemoteFunction` | Client invokes server | Request/response where the client needs an answer (for example "can I afford this?" UI preview) | Server invoking client (`InvokeClient`): a client can hang or error the call. Never do this for gameplay |
| `BindableEvent` / `BindableFunction` | Same side | Rare; prefer direct module calls or a Signal module | Cross-boundary communication |

## Design rules

1. **Define remotes centrally.** One shared module (for example `ReplicatedStorage.Shared.Net`) lists every remote, its direction and argument types. The server creates the Instances once at startup (or they exist at edit time); clients `WaitForChild` them. No script creates remotes ad hoc.
2. **Name by intent.** `RequestPurchase(itemId)`, not `GiveItem(itemId, price)`. The client never sends values the server can compute (price, damage, position of the server-owned target, reward amount).
3. **Validate every argument on the server**, in order:
   - Argument count and types (`typeof`), including rejecting `NaN` and `inf` for numbers.
   - Ranges and lengths (string length, array size, integer-ness).
   - Instances: correct class, still in the expected place (`IsDescendantOf`), and that the player is allowed to act on them (ownership, distance from the character).
   - Game rules: cooldowns, currency, inventory, state machine (is the round active?).
4. **Rate limit per player per remote** (token bucket). Drop excess silently or log; kick only for clear abuse, and never on a single event (lag causes bursts).
5. **Fail closed.** Any validation failure returns without side effects. Never `error()` in a handler on bad input; log at most.
6. **Keep handlers short**; delegate to the owning service.
7. **Server-to-client**: send only what that client needs (`FireClient` over `FireAllClients` when the data is private). Never send other players' private data or server secrets.
8. **The first argument of `OnServerEvent` is always the real `Player`**, injected by the engine. It is the only argument the client cannot forge.

## What can cross the boundary

Replicates: `nil`, booleans, numbers, strings, `buffer`, Roblox datatypes (`Vector3`, `CFrame`, `Color3`, ...), `EnumItem`, Instances that exist on both sides, and tables that are pure arrays or string-keyed dictionaries. Does not replicate: functions, metatables, mixed tables (array plus dictionary keys), non-string dictionary keys (converted or dropped), Instances the receiver cannot see. Treat any received table as untrusted nested input and validate each field.

## Bandwidth

- Batch small updates per frame; send deltas.
- Encode high-frequency data with `buffer` and quantize.
- For larger projects, typed networking libraries (for example Zap or Blink, which generate serialization from an IDL; ByteNet; or Red) reduce boilerplate and bandwidth. Verify the library's current repository and docs before adding one; do not add one to a project that already has a networking layer.

## Pattern

`examples/RemoteGuard.luau` provides validator helpers and a per-player token bucket. Minimal use:

```lua
local Guard = require(ServerScriptService.Server.Util.RemoteGuard)

Guard.connect(Net.event("RequestPurchase"), {
	rate = 2, burst = 4,
	validators = { Guard.oneOf(ItemIds) },
}, function(player, itemId)
	ShopService.purchase(player, itemId) -- price, currency, ownership checked inside
end)
```

## Additional resources

- **`examples/RemoteGuard.luau`** - argument validators, NaN-safe number checks, token-bucket rate limiter, guarded `RemoteEvent` and `RemoteFunction` wiring.
- **`examples/Net.luau`** - central remote definition module shared by server and client.
- See the anti-exploit-security skill for threat modeling and the server-client-architecture skill for replication strategy.
