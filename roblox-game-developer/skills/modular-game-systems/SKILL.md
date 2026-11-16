---
name: modular-game-systems
description: This skill should be used when the user asks to "make my code modular", "create a service", "create a controller", "build an inventory system", "build a combat system", "build a quest system", "set up a module loader", "use Init and Start", "avoid duplicated scripts", "refactor into modules", "use a Signal module", "clean up connections with Trove/Janitor", "use CollectionService tags", or wants reusable, decoupled gameplay systems in Roblox.
version: 1.0.0
---

# Modular Game Systems

Build each gameplay system as one ModuleScript with a narrow public API, loaded by a single bootstrap per side. Systems communicate through explicit calls and signals, not globals or duplicated scripts.

## Module contract

Every service (server) or controller (client) follows the same shape:

```lua
local CombatService = {}

function CombatService.init()   -- synchronous: wire dependencies, create state. Must not yield.
end

function CombatService.start()  -- may yield: connect events, start loops.
end

-- Public API: verbs that other systems call.
function CombatService.applyDamage(target: Model, amount: number, source: Player?)
end

return CombatService
```

- `init` runs for every module before any `start`. This prevents load-order races.
- Dependencies are `require`d at the top of the module; cyclic requires indicate a boundary problem, so move shared logic into a third module or use a signal.
- Private state stays local to the module. Expose read access through functions.

`examples/ServiceLoader.luau` implements the loader (deterministic order, detects yielding `init`). `examples/Main.server.luau` and `examples/Main.client.luau` are the matching bootstrap scripts.

## Communication between systems

| Need | Mechanism |
|---|---|
| A asks B to do something | Direct call: `InventoryService.add(player, id)` |
| B announces something many systems care about | A Signal on B: `CombatService.Died:Connect(...)`. Use a maintained Signal implementation (for example GoodSignal-style), or a `BindableEvent` wrapped in the module |
| Behavior attached to many world objects | CollectionService tags: one system owns a tag, handles `GetTagged` plus `GetInstanceAddedSignal`/`GetInstanceRemovedSignal` |
| Per-object configuration | Attributes on the tagged instance, read by the owning system |
| Client to server | Remotes defined in the shared `Net` module (remote-networking skill) |

## Lifetime management

- Every object that connects events owns a cleanup container (Trove, Janitor, or a local `{ RBXScriptConnection }` list) and cleans it on destroy, respawn, or `PlayerRemoving`.
- Per-player state lives in tables keyed by `Player`, cleared on `PlayerRemoving`.
- Per-character state is rebuilt on `CharacterAdded` and cleaned on `CharacterRemoving` or `Humanoid.Died`.

## Configuration and data

- Static game data (items, enemies, levels) lives in frozen shared config modules (`ReplicatedStorage.Shared.Config.Items`) when clients need it, or server modules when values must stay secret.
- Never duplicate config values across scripts; derive from one table.

## Tagged-object system template

```lua
local CollectionService = game:GetService("CollectionService")

local TAG = "KillBrick"
local KillBrickService = {}
local connections: { [Instance]: RBXScriptConnection } = {}

local function onAdded(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	connections[part] = part.Touched:Connect(function(hit)
		local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

local function onRemoved(part: Instance)
	local connection = connections[part]
	if connection then
		connection:Disconnect()
		connections[part] = nil
	end
end

function KillBrickService.start()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(onAdded)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(onRemoved)
	for _, part in CollectionService:GetTagged(TAG) do
		onAdded(part)
	end
end

return KillBrickService
```

## Avoiding duplication

Before creating a system, search the project for an existing one covering the same responsibility (names, remotes, tags, DataStore names). Extend it, or propose a consolidation, rather than adding a parallel system.

## Frameworks and ECS

- Plain modules plus this loader suit most games. Knit is no longer maintained by its author (archived); do not introduce it into new projects, but keep working within it if a project already uses it.
- ECS libraries (jecs, Matter) suit simulation-heavy games with many entities. Adopt only with a clear reason and the user's agreement.
- Verify any library's current status on its repository before recommending it.

## Additional resources

- **`examples/ServiceLoader.luau`** - two-phase loader with yield detection and deterministic order.
- **`examples/Main.server.luau`**, **`examples/Main.client.luau`** - bootstrap scripts.
- **`references/system-recipes.md`** - outlines for inventory, combat, round, quest and shop systems with their state, remotes and validation.
