local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local PrizeModule = Services.get("PrizeModule")

local PrizeService = {}

function PrizeService:GetPrize(Type: string, Requirement: number)
	for i, v in PrizeModule do
		if v.Requirement == Requirement	and v.Type == Type then
			return v
		end
	end
	
	return
end

function PrizeService:HasPrize(Player: Player, Type: string, Requirement: number)
	local PlayerData = RunService:IsServer() and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	
	if not PlayerData then
		return
	end
	
	for i, v in PlayerData.Prizes do
		if v.Requirement == Requirement	and v.Type == Type then
			return v
		end
	end

	return
end

if RunService:IsServer() then
	Network:Bind("ClaimPrize", function(Player: Player, Type: string, Requirement: number)
		if not Player or not Type or not Requirement then
			return
		end
		
		if PrizeService:HasPrize(Player, Type, Requirement) then
			return
		end
		
		local PrizeData = PrizeService:GetPrize(Type, Requirement)

		if not PrizeData then
			return
		end

		if PrizeData.Type ~= Type then
			return
		end

		local PlayerData = DataService:GetPlayerData(Player)

		if not PlayerData then
			return
		end

		local Directory = Type == "Eggs" 
			and PlayerData["Eggs Hatched"] or Type == "Pickups"
			and PlayerData["Pickups Broken"] or Type == "Bosses"
			and PlayerData["Bosses Killed"]

		if not Directory then
			return
		end

		local Requirement = PrizeData.Requirement

		if Directory < Requirement then
			return
		end
		
		local Reward = PrizeData.Reward
		
		if Reward.Type == "Pet" then
			local PetData = {
				Name = Reward.Name,
				Tier = Reward.Tier
			}

			DataService:GivePet(Player, PetData, true)
		end

		if Reward.Type == "Boost" then
			DataService:GiveBoost(Player, Reward.Name, Reward.Amount)
		end

		table.insert(PlayerData.Prizes, {
			Requirement = PrizeData.Requirement,
			Type = PrizeData.Type
		})

		DataService:SendUpdateSignal(Player, "Prizes")
	end)
end

return PrizeService