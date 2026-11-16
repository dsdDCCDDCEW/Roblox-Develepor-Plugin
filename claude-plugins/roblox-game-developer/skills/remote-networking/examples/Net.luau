--!strict
--[[
	Net
	Single source of truth for every remote in the experience.
	Place in ReplicatedStorage.Shared.

	Server bootstrap: call Net.init() once before any service connects handlers.
	Both sides: Net.event / Net.unreliable / Net.func return the Instance,
	waiting for it on the client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

type RemoteKind = "RemoteEvent" | "UnreliableRemoteEvent" | "RemoteFunction"

-- Add every remote here. Name by intent (Request*) for client -> server,
-- by fact (*Changed) for server -> client.
local DEFINITIONS: { [string]: RemoteKind } = {
	RequestPurchase = "RemoteEvent", -- client -> server: (itemId: string)
	RequestEquip = "RemoteEvent", -- client -> server: (itemId: string)
	InventoryChanged = "RemoteEvent", -- server -> client: (inventory: { [string]: number })
	AimDirection = "UnreliableRemoteEvent", -- client -> server: (direction: Vector3)
	GetShopPreview = "RemoteFunction", -- client -> server: (itemId: string) -> { canAfford: boolean }
}

local Net = {}

local function getFolder(): Instance
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing then
			return existing
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

function Net.init()
	assert(RunService:IsServer(), "Net.init is server-only")
	local folder = getFolder()
	for name, className in DEFINITIONS do
		local existing = folder:FindFirstChild(name)
		if existing then
			assert(
				existing.ClassName == className,
				`Remote {name} already exists as {existing.ClassName}, expected {className}`
			)
		else
			local remote = Instance.new(className :: any)
			remote.Name = name
			remote.Parent = folder
		end
	end
end

local function get(name: string, expected: RemoteKind): Instance
	local kind = DEFINITIONS[name]
	assert(kind ~= nil, `Unknown remote {name}; add it to Net DEFINITIONS`)
	assert(kind == expected, `Remote {name} is a {kind}, not a {expected}`)
	return getFolder():WaitForChild(name)
end

function Net.event(name: string): RemoteEvent
	return get(name, "RemoteEvent") :: RemoteEvent
end

function Net.unreliable(name: string): UnreliableRemoteEvent
	return get(name, "UnreliableRemoteEvent") :: UnreliableRemoteEvent
end

function Net.func(name: string): RemoteFunction
	return get(name, "RemoteFunction") :: RemoteFunction
end

return Net
