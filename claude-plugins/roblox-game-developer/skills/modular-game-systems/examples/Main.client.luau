--!strict
-- Client entry point. The only LocalScript in StarterPlayerScripts.Client.
-- Expects: StarterPlayerScripts.Client.Controllers (ModuleScripts),
--          ReplicatedStorage.Shared.ServiceLoader

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ServiceLoader = require(Shared:WaitForChild("ServiceLoader"))

ServiceLoader.load(script.Parent:WaitForChild("Controllers"))
