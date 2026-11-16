--!strict
--[[
	RemoteGuard
	Server-only helpers that wrap remote handlers with argument validation and
	per-player rate limiting. Place under ServerScriptService (never replicate it;
	exploiters should not see validation rules).

	Usage:
		local Guard = require(path.to.RemoteGuard)
		Guard.connect(Net.event("RequestEquip"), {
			rate = 4, burst = 8,
			validators = { Guard.string(1, 32) },
		}, function(player, itemId)
			EquipService.equip(player, itemId)
		end)
]]

local Players = game:GetService("Players")

export type Validator = (value: any) -> boolean

export type Options = {
	rate: number?, -- tokens refilled per second (default 5)
	burst: number?, -- bucket capacity (default 10)
	validators: { Validator }, -- one per expected argument, in order
	onReject: ((player: Player, reason: string) -> ())?,
}

local RemoteGuard = {}

-- Validators -------------------------------------------------------------------

local function isFiniteNumber(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function RemoteGuard.number(min: number, max: number): Validator
	return function(value)
		return isFiniteNumber(value) and value >= min and value <= max
	end
end

function RemoteGuard.integer(min: number, max: number): Validator
	return function(value)
		return isFiniteNumber(value) and value % 1 == 0 and value >= min and value <= max
	end
end

function RemoteGuard.string(minLength: number, maxLength: number): Validator
	return function(value)
		if typeof(value) ~= "string" then
			return false
		end
		local length = utf8.len(value) -- nil for invalid UTF-8
		return length ~= nil and length >= minLength and length <= maxLength
	end
end

function RemoteGuard.boolean(): Validator
	return function(value)
		return typeof(value) == "boolean"
	end
end

-- Accepts only listed values (string ids, enum-like options).
function RemoteGuard.oneOf(allowed: { any }): Validator
	local set = {}
	for _, v in allowed do
		set[v] = true
	end
	return function(value)
		return value ~= nil and set[value] == true
	end
end

function RemoteGuard.vector3(maxMagnitude: number): Validator
	return function(value)
		return typeof(value) == "Vector3"
			and isFiniteNumber(value.X)
			and isFiniteNumber(value.Y)
			and isFiniteNumber(value.Z)
			and value.Magnitude <= maxMagnitude
	end
end

-- Instance of a class that lives under a given ancestor (for example workspace.Shops).
function RemoteGuard.instanceOf(className: string, ancestor: Instance): Validator
	return function(value)
		return typeof(value) == "Instance" and value:IsA(className) and value:IsDescendantOf(ancestor)
	end
end

function RemoteGuard.optional(validator: Validator): Validator
	return function(value)
		return value == nil or validator(value)
	end
end

-- Rate limiting ----------------------------------------------------------------

type Bucket = { tokens: number, last: number }

local function newLimiter(capacity: number, refillPerSecond: number): (Player) -> boolean
	local buckets: { [Player]: Bucket } = {}
	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)
	return function(player: Player): boolean
		local now = os.clock()
		local bucket = buckets[player]
		if not bucket then
			bucket = { tokens = capacity, last = now }
			buckets[player] = bucket
		end
		bucket.tokens = math.min(capacity, bucket.tokens + (now - bucket.last) * refillPerSecond)
		bucket.last = now
		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end
end

local function check(options: Options, allow: (Player) -> boolean, player: Player, ...: any): boolean
	local reject = options.onReject
	if not allow(player) then
		if reject then
			reject(player, "rate")
		end
		return false
	end
	local validators = options.validators
	-- Extra arguments are rejected. Missing trailing arguments arrive as nil and
	-- are judged by their validator (only RemoteGuard.optional accepts nil).
	if select("#", ...) > #validators then
		if reject then
			reject(player, "argcount")
		end
		return false
	end
	for index, validate in validators do
		if not validate((select(index, ...))) then
			if reject then
				reject(player, `arg{index}`)
			end
			return false
		end
	end
	return true
end

-- Wiring -----------------------------------------------------------------------

function RemoteGuard.connect(
	remote: RemoteEvent | UnreliableRemoteEvent,
	options: Options,
	handler: (Player, ...any) -> ()
): RBXScriptConnection
	local allow = newLimiter(options.burst or 10, options.rate or 5)
	return (remote :: any).OnServerEvent:Connect(function(player: Player, ...: any)
		if check(options, allow, player, ...) then
			handler(player, ...)
		end
	end)
end

-- Rejected invocations return nil; the client must handle a nil response.
function RemoteGuard.handle(remote: RemoteFunction, options: Options, handler: (Player, ...any) -> any)
	local allow = newLimiter(options.burst or 10, options.rate or 5)
	remote.OnServerInvoke = function(player: Player, ...: any)
		if check(options, allow, player, ...) then
			return handler(player, ...)
		end
		return nil
	end
end

return RemoteGuard
