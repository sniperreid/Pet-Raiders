local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local Tiers = Services.get("TiersModule")

local PetCraftService = {}

PetCraftService.CraftExpectancy = 10 -- <- How much pets required to craft next tier.

function PetCraftService:GetNextTier(Tier)
	local TierData = Tiers[Tier]
	local CurrentIndex = TierData.Index
	
	for i, _t in Tiers do
		if _t.Index == (CurrentIndex + 1) then
			return _t
		end
	end
	
	-- invalid tier.
end

return PetCraftService