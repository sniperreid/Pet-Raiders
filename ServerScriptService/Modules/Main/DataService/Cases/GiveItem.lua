local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")

return function(self, Player, Item, Amount)
	local PlayerData = self:GetPlayerData(Player)
	local Items = PlayerData.Items
	
	local CurrentAmount = Items[Item] or 0
	
	Items[Item] = CurrentAmount + Amount
	
	if Items[Item] <= 0 then
		Items[Item] = nil
	end
	
	self:SendUpdateSignal(Player, "Items")
end