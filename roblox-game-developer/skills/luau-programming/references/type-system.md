# Luau Type System Reference

Sources: https://luau.org/typecheck and the Roblox "Luau type checking" docs. Verify edge cases there; the new type solver is still receiving fixes.

## Strict-safe class template

```lua
--!strict
local Weapon = {}
Weapon.__index = Weapon

export type WeaponData = {
	Name: string,
	Damage: number,
	Cooldown: number,
}

type WeaponFields = {
	_data: WeaponData,
	_lastFired: number,
}

export type Weapon = setmetatable<WeaponFields, typeof(Weapon)>

function Weapon.new(data: WeaponData): Weapon
	local self = setmetatable({
		_data = table.freeze(table.clone(data)),
		_lastFired = 0,
	}, Weapon)
	return self
end

function Weapon.canFire(self: Weapon, now: number): boolean
	return now - self._lastFired >= self._data.Cooldown
end

function Weapon.fire(self: Weapon, now: number): number?
	if not self:canFire(now) then
		return nil
	end
	self._lastFired = now
	return self._data.Damage
end

return Weapon
```

Notes:
- `setmetatable<T, MT>` is a built-in type function in the new solver. On codebases still pinned to the old solver (older luau-lsp configs), the older pattern is `export type Weapon = typeof(Weapon.new(...))` or an explicit intersection; match what the project already uses.
- Declare methods with explicit `self: Weapon` so the method type is precise.

## Generics

```lua
local function map<T, U>(list: { T }, fn: (T) -> U): { U }
	local out = table.create(#list)
	for i, v in list do
		out[i] = fn(v)
	end
	return out
end
```

Generic type packs: `type Callback<A...> = (A...) -> ()`.

## Refinement

| Check | Refines to |
|---|---|
| `if x then` | removes `nil`/`false` |
| `type(x) == "string"` | Lua primitive types |
| `typeof(x) == "Vector3"` | Roblox datatypes and Lua primitives |
| `typeof(x) == "Instance" and x:IsA("Model")` | `Model` |
| `x.kind == "a"` on a tagged union | that union member |
| `assert(x)` | non-nil after the call |

## Type functions

User-defined type functions run at type-check time over type values (`types` library). Use them sparingly, for example to derive a read-only or partial version of a record type. Built-ins include `keyof`, `rawkeyof`, `index`, `setmetatable`, `getmetatable`.

```lua
type function Partial(t)
	local result = types.newtable()
	for key, prop in t:properties() do
		result:setproperty(key, types.optional(prop.read))
	end
	return result
end
```
Check the `types` library API on luau.org before using any method not shown here.

## Read-only and write-only properties

`type Config = { read Name: string }` marks a property read-only for consumers (new solver).

## Common type errors and fixes

| Error shape | Usual cause | Fix |
|---|---|---|
| `Type 'nil' could not be converted into 'X'` | Optional value used without check | Refine with `if v then` or `assert` |
| `Key 'Foo' not found in table` | Misspelled field, or table built incrementally | Build the table in one literal, or annotate it |
| `Unknown require` | Dynamic require path | Use static `script.Parent.Module` paths, or `require(path) :: any` with a comment |
| `Instance has no member 'X'` | Child access on a generic `Instance` | `inst:FindFirstChild("X")` plus `IsA` refinement, or `WaitForChild` with a cast |
| Method type error on `self` | Method defined with `:` on an untyped table | Use explicit `self: ClassType` parameter |
