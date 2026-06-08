local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local module = {}

local cooldowns = {}

function module:ToggleSetting(Player: Player, Setting: string)
	if cooldowns[Player] then
		return
	end
	
	cooldowns[Player] = true
	
	task.delay(.29, function()
		cooldowns[Player] = nil
	end)
	
	local PlayerData = DataService:GetPlayerData(Player)
	local PlayerSettings = PlayerData.Settings
	
	-- Had to do a for-loop because for whatever reason PlayerSettings[Setting] would not work
	
	local _Setting = nil
	
	for i, v in PlayerSettings do
		if i == Setting then
			_Setting = i
		end
	end
	
	if not _Setting then
		return
	end
	
	PlayerData.Settings[_Setting] = not PlayerData.Settings[_Setting]
	
	DataService:SendUpdateSignal(Player, "Settings", _Setting)
end

Network:Bind("ToggleSetting", function(...)
	return module:ToggleSetting(...)
end)

Players.PlayerRemoving:Connect(function(Player: Player)
	cooldowns[Player] = nil
end)

return module