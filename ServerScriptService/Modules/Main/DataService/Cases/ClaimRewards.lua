local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")

return function(self, Player, Rewards)
	if typeof(Rewards) ~= "table" then
		return
	end

	local PlayerData = self:GetPlayerData(Player)

	if not PlayerData then
		return
	end

	Network:Post(Player, "DisplayNewItems", Rewards)

	for _, Reward in Rewards do
		if typeof(Reward) ~= "table" or typeof(Reward.Type) ~= "string" then
			continue
		end

		if Reward.Type == "Pet" then
			self:GivePet(Player, table.clone(Reward))
		elseif Reward.Type == "Ability" then
			if not table.find(PlayerData.AbilitiesOwned, Reward.Item) then
				table.insert(PlayerData.AbilitiesOwned, Reward.Item)
				self:SendUpdateSignal(Player, "AbilitiesOwned")
			end
		elseif Reward.Type == "Currency" then
			self:GiveCurrency(Player, Reward.Item, Reward.Amount, true)
		end
	end
end
