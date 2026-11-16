# Common Roblox Errors: Causes and Fixes

Error texts below are the usual shapes; exact wording can vary between engine versions. Match on the stable part.

## Indexing and nil

**`attempt to index nil with 'Humanoid'`**
- Cause: `player.Character` is nil (not spawned yet or respawning), or the character model is not fully assembled.
- Fix: use `player.CharacterAdded` and read the character passed in; for the current character use `player.Character or player.CharacterAdded:Wait()`, then `character:WaitForChild("Humanoid")`.

**`attempt to index nil with 'FindFirstChild'`**
- Cause: the parent itself is nil, usually a destroyed instance or a module that returned nothing.
- Fix: trace the parent's origin; check that every ModuleScript ends with `return`.

**`attempt to perform arithmetic (add) on nil and number`**
- Cause: missing table field or attribute (`GetAttribute` returns nil when unset).
- Fix: default explicitly (`(inst:GetAttribute("Coins") or 0) + 1`) or initialize at creation.

## Yields

**`Infinite yield possible on 'ReplicatedStorage:WaitForChild("Remotes")'`**
- Cause: name typo, created later than expected, or created only on the server under a non-replicated parent.
- Fix: create remotes at edit time (or in the server bootstrap before clients need them) under `ReplicatedStorage`.
- With `StreamingEnabled`, Workspace descendants may not exist on the client. Use `Model.ModelStreamingMode = Persistent` for models the client must always have, or handle `StreamingEnabled` with `WaitForChild` plus timeouts and `ChildAdded`.

## Script lifecycle

- `Script` with `RunContext = Legacy` runs only in server containers (Workspace, ServerScriptService). `RunContext = Client` runs on clients wherever it is placed, including ReplicatedStorage. Check `RunContext` before assuming a script is dead.
- `LocalScript` runs only under `StarterPlayerScripts`, `StarterCharacterScripts`, `StarterGui`/`PlayerGui`, a player's `Backpack`, the player's character, or `ReplicatedFirst`.
- `ModuleScript` code runs once per environment (server and each client) on first `require`; a load-time error makes every later `require` of it fail too.
- `Players.PlayerAdded` may fire before a script connects (especially in Studio). Loop over `Players:GetPlayers()` after connecting.

## Remotes

- **`Remote event invocation queue exhausted`**: client fired a remote with no server listener connected yet (or vice versa). Connect handlers in the bootstrap before gameplay starts.
- **`OnServerInvoke` yields forever**: the server handler errored or never returned; RemoteFunction callers hang. Never invoke a client from the server with `InvokeClient` for anything that matters (client can hang or error it).
- **Instance arrives as nil**: the client cannot send instances it created locally, and the server cannot send instances not replicated to that client (for example ServerStorage objects, or not-yet-streamed parts).
- **Tables lose keys**: mixed tables, non-string keys in dictionaries, metatables and functions do not replicate. Send plain arrays or string-keyed dictionaries.
- **`Unreliable event dropped`** or warnings about payload size: UnreliableRemoteEvent payload exceeded the documented 900-byte limit. Shrink the payload (buffers, quantized numbers) or use a reliable `RemoteEvent`.

## DataStores

- **`502: API Services rejected request`** / **`403: Cannot write to DataStore from studio if API access is not enabled`**: enable "Enable Studio Access to API Services" in Game Settings > Security (only for test places/universes where safe).
- **`DataStore request was added to queue`** warnings: request budget exhausted. Reduce frequency, batch per-player data into one key, check `GetRequestBudgetForRequestType`.
- Error codes 301-306: queue full, request dropped. See datastore-persistence skill `references/limits.md`.
- Data lost on shutdown: missing `game:BindToClose` waiting for saves to finish.

## Physics and network ownership

- Unanchored parts near a player may be owned by that client; their physics (including `Touched`) are client-controlled. Set `BasePart:SetNetworkOwner(nil)` for server-critical assemblies, or use the server authority model.
- `SetNetworkOwner` errors on anchored parts or parts not in Workspace; call it after parenting and only on the root of unanchored assemblies.

## Signal behavior

- With `Workspace.SignalBehavior = Deferred` (the default for new places), event handlers run later in the frame, not immediately when the event fires. Code that assumed immediate handlers (setting a property and reading a side effect on the next line) breaks. Restructure rather than switching back to `Immediate`.
