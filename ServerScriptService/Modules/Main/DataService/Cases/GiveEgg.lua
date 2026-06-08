local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")

return function(self, Player, Egg, Amount, Display)
	local PlayerData = self:GetPlayerData(Player)
	local Eggs = PlayerData.Eggs
	
	local CurrentAmount = Eggs[Egg] or 0
	
	Eggs[Egg] = CurrentAmount + Amount
	
	if Eggs[Egg] <= 0 then
		Eggs[Egg] = nil
	end
	
	if Display then
		Network:Post(Player, "DisplayNewItem", {
			Type = "Egg", 
			Name = Egg, 
			Amount = Amount
		})
	end
	
	self:SendUpdateSignal(Player, "Eggs")
end