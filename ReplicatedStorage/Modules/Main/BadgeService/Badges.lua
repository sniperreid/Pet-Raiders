local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

return {
	["Welcome!"] = {
		BadgeId = 2274572631071494,
		OnRecieved = nil
	},
	
	["You met a developer!"] = {
		BadgeId = 786706243951400,
		OnRecieved = nil,
	}
}