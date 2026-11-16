# Luau / Roblox Standard Library Cheatsheet

Confirm signatures at https://luau.org/library and https://create.roblox.com/docs/reference/engine/globals/LuaGlobals before relying on anything unusual.

## Deprecated to modern replacements

| Deprecated | Use instead | Why |
|---|---|---|
| `wait(t)` | `task.wait(t)` | Accurate, scheduler-integrated |
| `spawn(fn)` | `task.spawn(fn)` or `task.defer(fn)` | `spawn` delays unpredictably |
| `delay(t, fn)` | `task.delay(t, fn)` | |
| `tick()` | `os.clock()` (durations), `os.time()` / `DateTime.now()` (wall clock), `workspace:GetServerTimeNow()` (synced) | `tick` is timezone-dependent |
| `Instance.new("X", parent)` | create, set properties, then set `Parent` last | Avoids extra replication work |
| `game.Workspace` | `workspace` or `game:GetService("Workspace")` | |
| `table.getn`, `unpack` | `#t`, `table.unpack` | |
| `:connect`, `:wait` (lowercase) | `:Connect`, `:Wait` | |
| `BodyVelocity`, `BodyPosition`, etc. | Mover constraints (`LinearVelocity`, `AlignPosition`, ...) | Legacy body movers are deprecated |
| `CollectionService:AddTag(inst, tag)` | `inst:AddTag(tag)` / `inst:HasTag(tag)` | Both work; instance methods are current |
| `UserInputService`/`ContextActionService` bindings for new games | Consider the Input Action System (`InputContext`, `InputAction`, `InputBinding`) | Cross-platform bindings declared as instances |

## task

`task.spawn`, `task.defer`, `task.delay`, `task.wait`, `task.cancel`, `task.synchronize`, `task.desynchronize`.

## table

`table.clone`, `table.freeze`, `table.isfrozen`, `table.create`, `table.find`, `table.clear`, `table.move`, `table.insert`, `table.remove`, `table.sort`, `table.concat`, `table.pack`, `table.unpack`, `table.maxn`.

## string

`string.split`, `string.format`, `string.find/match/gmatch/gsub` (Lua patterns, not regex), `string.pack/unpack`, `string.len`, `string.sub`, `string.rep`, `string.byte/char`. `utf8` library for user text.

## math

`math.clamp`, `math.sign`, `math.round`, `math.noise`, `math.lerp` (verify availability in your target, added later than the rest), `math.map` (same caveat), plus Lua 5.1 functions. `Random.new(seed)` for deterministic RNG; prefer it over `math.random` for per-system streams.

## buffer

`buffer.create`, `buffer.fromstring`, `buffer.tostring`, `buffer.len`, `buffer.readu8/i8/u16/i16/u32/i32/f32/f64`, matching `write*`, `buffer.readstring/writestring`, `buffer.copy`, `buffer.fill`. Check luau.org for bit-level read/write additions before using them.

## Roblox globals and datatypes

`game`, `workspace`, `script`, `plugin` (plugins only), `shared` (avoid; use modules), `_G` (avoid). Datatypes: `Vector3`, `Vector2`, `CFrame`, `Color3`, `UDim2`, `NumberRange`, `NumberSequence`, `ColorSequence`, `Ray`, `RaycastParams`, `OverlapParams`, `TweenInfo`, `DateTime`, `Random`, `Enum`.

## Signals

`RBXScriptSignal:Connect`, `:Once`, `:Wait`, `:ConnectParallel`. `Instance:GetPropertyChangedSignal(prop)`, `Instance:GetAttributeChangedSignal(name)`, `Instance.AttributeChanged`.
