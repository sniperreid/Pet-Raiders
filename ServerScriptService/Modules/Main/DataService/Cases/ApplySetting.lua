local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local UnicodeLib = Services.get("UnicodeLib")

return function(self, Player, Setting, State)
	
	if typeof(Setting) ~= "string" then
		return
	end
	
	if typeof(State) ~= "boolean" then
		return
	end
	
	if not UnicodeLib.valid_utf8(Setting) then
		return
	end
	
	local PlayerData = self:GetPlayerData(Player)
	local Settings = PlayerData.Settings
	
	if Settings[Setting] == nil then
		return
	end
	
	if Settings[Setting] == State then
		return
	end
	
	Settings[Setting] = State
	
	self:SendUpdateSignal(
		Player,
		"Settings"
	)
end