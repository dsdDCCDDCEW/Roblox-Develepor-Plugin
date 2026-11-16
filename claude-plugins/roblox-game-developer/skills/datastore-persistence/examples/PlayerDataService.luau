--!strict
--[[
	PlayerDataService
	Session-locked player data on top of DataStoreService. Server-only.
	Place under ServerScriptService (for example ServerScriptService.Server.Services).

	Guarantees:
	  * Only the server holding the session lock writes a player's key.
	  * Every write uses UpdateAsync and passes the player's UserId (erasure support).
	  * Saves on leave, on an autosave interval, and on shutdown (BindToClose).
	  * Missing fields are filled from defaults on load (reconcile).

	For larger games, ProfileStore (MadStudioRoblox) implements the same idea with
	MessagingService-assisted lock handoff. Prefer it over growing this file.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local STORE_NAME = "PlayerData_v1"
local LOCK_TIMEOUT_SECONDS = 30 * 60 -- a lock older than this is treated as abandoned
local AUTOSAVE_INTERVAL_SECONDS = 120
local LOAD_ATTEMPTS = 5
local MAX_RETRIES = 5

export type PlayerData = {
	SchemaVersion: number,
	Coins: number,
	Inventory: { [string]: number },
	GrantedPurchases: { [string]: boolean },
}

type Record = {
	Data: PlayerData,
	LockJobId: string?,
	LockTime: number?,
}

local DEFAULT_DATA: PlayerData = table.freeze({
	SchemaVersion = 1,
	Coins = 0,
	Inventory = table.freeze({}),
	GrantedPurchases = table.freeze({}),
}) :: any

local store = DataStoreService:GetDataStore(STORE_NAME)
local sessions: { [Player]: PlayerData } = {}
local PlayerDataService = {}

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- Fill fields that exist in the template but are missing in data.
local function reconcile(data: any, template: any)
	for key, defaultValue in template do
		if data[key] == nil then
			data[key] = deepCopy(defaultValue)
		elseif type(defaultValue) == "table" and type(data[key]) == "table" then
			reconcile(data[key], defaultValue)
		end
	end
end

local function migrate(data: PlayerData): PlayerData
	-- Example: if data.SchemaVersion < 2 then ...; data.SchemaVersion = 2 end
	return data
end

local function retry<T>(label: string, callback: () -> T): (boolean, T?)
	local waitSeconds = 1
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		warn(`[PlayerDataService] {label} attempt {attempt} failed: {result}`)
		if attempt < MAX_RETRIES then
			task.wait(waitSeconds)
			waitSeconds *= 2
		end
	end
	return false, nil
end

-- Attempts to take the session lock and return the stored data.
-- Returns (data, lockedElsewhere).
local function tryAcquire(userId: number): (PlayerData?, boolean)
	local jobId = game.JobId
	local lockedElsewhere = false

	local ok, record = retry(`acquire {userId}`, function()
		return store:UpdateAsync(keyFor(userId), function(old: Record?)
			lockedElsewhere = false
			local now = os.time()
			if
				old
				and old.LockJobId ~= nil
				and old.LockJobId ~= jobId
				and old.LockTime ~= nil
				and now - old.LockTime < LOCK_TIMEOUT_SECONDS
			then
				lockedElsewhere = true
				return nil -- cancel the write; another server owns the session
			end
			local data = if old then old.Data else deepCopy(DEFAULT_DATA)
			local newRecord: Record = { Data = data, LockJobId = jobId, LockTime = now }
			return newRecord, { userId }
		end)
	end)

	if not ok or lockedElsewhere or record == nil then
		return nil, lockedElsewhere
	end
	local data = (record :: Record).Data
	reconcile(data, DEFAULT_DATA)
	return migrate(data), false
end

local function load(userId: number): PlayerData?
	for attempt = 1, LOAD_ATTEMPTS do
		local data, lockedElsewhere = tryAcquire(userId)
		if data then
			return data
		end
		if not lockedElsewhere then
			return nil -- DataStore failure after retries
		end
		-- Previous server may still be saving; give it time to release.
		task.wait(5 * attempt)
	end
	return nil
end

-- Returns true only if the data was actually written.
local function save(userId: number, data: PlayerData, release: boolean): boolean
	local jobId = game.JobId
	local lostLock = false
	local ok = retry(`save {userId}`, function()
		return store:UpdateAsync(keyFor(userId), function(old: Record?)
			lostLock = false
			if old and old.LockJobId ~= jobId then
				lostLock = true
				return nil -- lost the lock; never overwrite another server's session
			end
			local newRecord: Record = {
				Data = data,
				LockJobId = if release then nil else jobId,
				LockTime = if release then nil else os.time(),
			}
			return newRecord, { userId }
		end)
	end)
	if lostLock then
		warn(`[PlayerDataService] save {userId} skipped: session lock held by another server`)
	end
	return ok and not lostLock
end

local function onPlayerAdded(player: Player)
	local data = load(player.UserId)
	if not data then
		player:Kick("Your data could not be loaded. Please rejoin in a moment.")
		return
	end
	if player.Parent ~= Players then
		-- Player left while loading: release the lock immediately.
		save(player.UserId, data, true)
		return
	end
	sessions[player] = data
end

local function onPlayerRemoving(player: Player)
	local data = sessions[player]
	if not data then
		return
	end
	sessions[player] = nil
	save(player.UserId, data, true)
end

-- Public API -------------------------------------------------------------------

-- Returns the live data table, or nil while loading / after leaving.
-- Treat the result as read-only outside of PlayerDataService.update.
function PlayerDataService.get(player: Player): PlayerData?
	return sessions[player]
end

-- Mutates a player's data through a callback. Returns false if not loaded.
function PlayerDataService.update(player: Player, mutator: (PlayerData) -> ()): boolean
	local data = sessions[player]
	if not data then
		return false
	end
	mutator(data)
	return true
end

-- Forces an immediate save (for example after a developer product grant).
function PlayerDataService.saveNow(player: Player): boolean
	local data = sessions[player]
	if not data then
		return false
	end
	return save(player.UserId, data, false)
end

function PlayerDataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL_SECONDS)
			for player, data in sessions do
				task.spawn(save, player.UserId, data, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, data in sessions do
			pending += 1
			task.spawn(function()
				save(player.UserId, data, true)
				pending -= 1
			end)
		end
		-- Roblox allows roughly 30 seconds in BindToClose; stop waiting a little earlier.
		local deadline = os.clock() + 28
		while pending > 0 and os.clock() < deadline do
			task.wait()
		end
		if pending > 0 then
			warn(`[PlayerDataService] shutdown with {pending} save(s) unfinished`)
		end
	end)
end

return PlayerDataService
