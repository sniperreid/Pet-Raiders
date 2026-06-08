local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules:WaitForChild("Services"))

local Network = Services.get("Network")

local function UpdateOverHead(Player, level)
	local Character = Player.Character
	local Head = Character and Character:FindFirstChild("Head")
	local PlayerTitle = Head and Head:FindFirstChild("PlayerTitle")
	
	if not PlayerTitle then return end
	
	PlayerTitle.PlayerLevel.Text = ("Lvl. %d"):format(level)
end

return function(self, Player, Key, ...)
	local PlayerData = self:GetPlayerData(Player)
	local Value = PlayerData[Key]
	
	if Key == "Level" then UpdateOverHead(Player, Value) end
	
	Network:Post(
		Player,
		"UpdateClientData",
		Key,
		Value,
		...
	)
end