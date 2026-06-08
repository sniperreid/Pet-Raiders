local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local DataService = Services.get("DataService")

local PetClass = {}
PetClass.__index = PetClass

function PetClass:AddPet(Player)
	local PetData = {
		Name = self.Name,
		ID = self.ID,
		Tier = self.Tier,
		Exp = self.Exp or 0,
		Level = self.Level or 0
	}
	
	DataService:GivePet(
		Player,
		PetData
	)
	
end

function PetClass.new()
	local self = setmetatable({
		ID = HttpService:GenerateGUID(false)
	}, PetClass)
	
	return self
end

return PetClass