local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules:WaitForChild("Services"))

local Network = Services.get("Network")

return function(self, Player, idx, Value, ...)
	local PlayerData = self:GetPlayerData(Player)
	
	Network:Post(
		Player,
		"SetClientData",
		idx,
		Value,
		...
	)
end