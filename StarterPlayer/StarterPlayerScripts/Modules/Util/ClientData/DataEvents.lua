local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local CurrencyModule = Services.get("CurrencyModule")
local GuiService = Services.get("GuiService")
local SoundService = Services.get("SoundService")
local EggManager = Services.get("EggManager")
local MusicService = Services.get("MusicService")
local DoorService = Services.get("DoorService")
local LevelingClient = Services.get("LevelingClient")
local TradingClient = Services.get("TradingClient")

local HUD = GuiService.HUD
local Stats = HUD.Stats

local ClientData

local Player = Players.LocalPlayer

local DataEvents = {}

export type Data_Keys = {
	[string]: string
}

export type Data_Events = {
	[string]: (number, string) -> ()
}

local Keys: Data_Keys = {
	AutoDelete = "EggDisplay"
}

local Events: Data_Events = {
	Stats = function(Key, Amount, ...)

		Stats:Update(Key, ...)
		
		SoundService:PlaySound("Currency", {
			Volume = 0.75
		})
		
		-- update stuff here.
	end,
	
	Pets = function(New, Key)
		GuiService.PetInventory:Update()
	end,
	
	IndexClaimed = function(New, Key)
		GuiService.PetIndex:Update()
	end,
	
	Index = function(New, Key)
		GuiService.PetIndex:Update()
		EggManager:UpdatePets()
	end,
	
	Eggs = function(New, Key)
		GuiService.EggInventory:Update()
	end,
	
	Prizes = function(New, Key)
		GuiService.Prizes:Update()
	end,
	
	Items = function(New, Key)
		GuiService.ItemInventory:Update()
	end,
	
	EggDisplay = function()
		EggManager:UpdatePets()
	end,
	
	Boosts = function(Data, Key)
		HUD.Boosts:Update(Key)
	end,
	
	Quests = function(Data, Key)
		GuiService.Quests:Update()
	end,
	
	Tasks = function(Data, Key)
		DoorService:update_tasks(Key)
	end,
	
	Settings = function(Data, Key, Setting)
		if Setting == "Music" or not Setting then
			if Key["Music"] == false then
				MusicService:Clear()
			else
				local PlayerData = ClientData:Get()
				
				MusicService:Play(PlayerData.World)
			end
		end
		
		GuiService.Settings:Update()
	end,
	
	World = function(Data, Key)
		return MusicService:Play(Key)
	end,
	
	Rerolls = function()
		GuiService.Merchant:Update()
	end,
	
	Exp = function()
		-- was originally 2, I thought it would look bad so I decide to just do 1
		-- if this is my mistake please change. -Blueshell
		task.delay(1, function()
			LevelingClient:DisplayLevel()
		end)
	end,
	
	TradeDisabled = function()
		TradingClient:UpdateDisabledState()
	end,
}

function DataEvents:bind(binds, event)
	
	if typeof(binds) ~= "table" then
		binds = {binds}
	end
	
	for i, Key in binds do
		local display = i
		
		if typeof(display) == "number" then
			display = Key
		end

		Keys[display] = event
	end
end

DataEvents:bind(CurrencyModule, "Stats")

function DataEvents:fire_event(Key, ...)
	local ChangeType = Keys[Key] or Key
	
	if not ChangeType then
		return
	end
	
	if not Events[ChangeType] then
		return
	end

	return Events[ChangeType](Key, ...)
end

function DataEvents:Update_Singularity(idx, new, key)
	ClientData:UpdateData(idx, new, key)
	
	self:fire_event(key, new)
end

function DataEvents:Update(i, v, ...)
	ClientData:UpdateData(i, v)
	
	self:fire_event(i, v, ...)
end

function DataEvents:Load()
	local PlayerData = ClientData:Get()

	if not PlayerData then
		return TeleportService:Teleport(game.PlaceId, Player)
	end

	for i, v in PlayerData do
		self:Update(i, v)
	end
	
	for i, v in Keys do
		self:Update(i, PlayerData[i] or 0)
	end
	
	Network:Fetch("DisabledLoading", true)
end

Network:Bind("UpdateClientData", function(...)
	return DataEvents:Update(...)
end)

Network:Bind("SetClientData", function(...)
	return DataEvents:Update_Singularity(...)
end)

return setmetatable(DataEvents, {
	__call = function(self, CD)
		ClientData = CD

		task.delay(1, function()
			self:Load()
		end)

		return self
	end,
})