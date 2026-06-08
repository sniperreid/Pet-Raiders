local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Short = Services.get("Short")

return function(self, Player, Boost, Amount)
	local PlayerData = self:GetPlayerData(Player)
	
	if not PlayerData.Boosts[Boost] then
		PlayerData.Boosts[Boost] = Amount
	else
		PlayerData.Boosts[Boost] += Amount
	end
	
	Network:Post(Player, "DisplayNewItem", {
		Type = "Message",
		Message = ("You've recieved %s of '%s' boost!"):format(Short:FormatBoost(Amount), Boost)
	})
	
	self:SendUpdateSignal(Player, "Boosts")
end