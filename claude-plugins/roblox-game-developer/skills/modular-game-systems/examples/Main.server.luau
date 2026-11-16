--!strict
-- Server entry point. The only Script in ServerScriptService.Server.
-- Expects: ServerScriptService.Server.Services (ModuleScripts),
--          ReplicatedStorage.Shared.ServiceLoader, ReplicatedStorage.Shared.Net

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ServiceLoader = require(Shared:WaitForChild("ServiceLoader"))
local Net = require(Shared:WaitForChild("Net"))

-- Remotes must exist before any service connects handlers or clients look for them.
Net.init()

ServiceLoader.load(script.Parent:WaitForChild("Services"))
