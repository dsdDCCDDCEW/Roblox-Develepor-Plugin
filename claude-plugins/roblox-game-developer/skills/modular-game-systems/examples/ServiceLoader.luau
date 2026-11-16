--!strict
--[[
	ServiceLoader
	Deterministic two-phase bootstrap for modular systems. Place in
	ReplicatedStorage.Shared (used by both server and client bootstraps).

	Phase 1 (init):  every module's init() runs serially, in order. Must not yield.
	Phase 2 (start): every module's start() runs in its own thread and may yield.

	Order: modules with a numeric `Priority` field load first (lower first),
	then the rest alphabetically by name.
]]

export type Module = {
	Priority: number?,
	init: (() -> ())?,
	start: (() -> ())?,
	[any]: any,
}

type Entry = { name: string, module: Module }

local ServiceLoader = {}

local function sortEntries(entries: { Entry })
	table.sort(entries, function(a, b)
		local pa = a.module.Priority or math.huge
		local pb = b.module.Priority or math.huge
		if pa ~= pb then
			return pa < pb
		end
		return a.name < b.name
	end)
end

local function runInit(name: string, init: () -> ())
	local thread = coroutine.create(init)
	local ok, err = coroutine.resume(thread)
	if not ok then
		error(`[ServiceLoader] {name}.init failed: {err}\n{debug.traceback(thread)}`, 0)
	end
	if coroutine.status(thread) ~= "dead" then
		error(`[ServiceLoader] {name}.init yielded; move yielding work to start()`, 0)
	end
end

-- Requires every ModuleScript directly under `container`, runs init then start.
-- Returns the loaded modules keyed by name.
function ServiceLoader.load(container: Instance): { [string]: Module }
	local entries: { Entry } = {}
	for _, child in container:GetChildren() do
		if child:IsA("ModuleScript") then
			local module = (require :: any)(child) :: Module
			assert(type(module) == "table", `[ServiceLoader] {child.Name} must return a table`)
			table.insert(entries, { name = child.Name, module = module })
		end
	end
	sortEntries(entries)

	for _, entry in entries do
		local init = entry.module.init
		if init then
			runInit(entry.name, init)
		end
	end

	for _, entry in entries do
		local start = entry.module.start
		if start then
			task.spawn(start)
		end
	end

	local byName: { [string]: Module } = {}
	for _, entry in entries do
		byName[entry.name] = entry.module
	end
	return byName
end

return ServiceLoader
