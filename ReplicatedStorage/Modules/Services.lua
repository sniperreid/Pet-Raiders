local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SSS_Modules = ServerScriptService:FindFirstChild("Modules")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Player = Players.LocalPlayer
local PlayerScripts = Player and Player.PlayerScripts

local RunType = RunService:IsServer() and "Server" or "Client"

local Services = {}

Services.Dictionary = {}

Services.Dictionary.Client = {
	RS_Modules,
	PlayerScripts
}

Services.Dictionary.Server = {
	RS_Modules,
	SSS_Modules
}

function Services:Search(Dict, Key)
	for _, v in Dict:GetDescendants() do
		if v.Name ~= Key then
			continue
		end

		if not v:IsA("ModuleScript") then
			continue
		end

		return require(v)
	end
end

function Services.get(Module)
	local Dictionary = Services.Dictionary
	local Dictionary = Dictionary[RunType]

	local ModuleExists = Services[Module]

	for _, Dict in Dictionary do
		if ModuleExists then
			return ModuleExists
		end

		local module_data = Services:Search(Dict, Module)

		if not module_data then
			continue
		end

		Services[Module] = module_data

		ModuleExists = module_data
	end

	return ModuleExists
end

return Services