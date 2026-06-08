local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Network = Services.get("Network")

local PlayerData

local Data = {}

function Data:load_player()
	return Network:Post("LoadPlayer")
end

function Data:Get()
	return PlayerData or Network:Invoke("InvokePlayerData")
end

function Data:UpdateData(Key, newData, idx)
	if not idx then
		PlayerData[Key] = newData
		
		return
	end
	
	PlayerData[idx][Key] = newData
end

function Data:load()
	PlayerData = self:Get()
	
	self:load_player()

	repeat task.wait()
		self:load_player()
		
		PlayerData = self:Get()
	until PlayerData

	return PlayerData
end

Data:load()

Network:Bind("GetClientData", function()
	return Data:Get()
end)

require(script.DataEvents)(Data)

return Data