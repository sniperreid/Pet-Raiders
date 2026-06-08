local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")

return function(self, Player, Currency, Amount, Display)
	if Amount > 0 then
		local ChallengeService = Services.get("ChallengeService")
		
		ChallengeService:onCurrencyGained(Player, Currency, Amount)
	end
	
	local PlayerData = self:GetPlayerData(Player)
	
	PlayerData[Currency] += Amount
	
	self:SendUpdateSignal(Player, Currency, Display and Amount)
end