repeat task.wait()
	
until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

Services.get("StarterMenu") -- should be initialized first.
local MarketplaceService = game:GetService("MarketplaceService")
Services.get("EffectsService")

local Network = Services.get("Network")
local LS = Services.get "LoadingScreen"

local _Loaded = false

local SaveArgs = {
	LoadingHeader = "rbxassetid://106445353043597",
	LoadingContext = "Pet Raiders",
	TextColor = Color3.fromRGB(255, 255, 255),
	TextFont = Enum.Font.FredokaOne
}

local SaveTips = {
	"What are you doing here",
	"This is a framework place"
}

local _Screen = LS.new (SaveArgs)
_Screen:NewTips(SaveTips)
_Screen.FadeIn = false
_Screen:init()

local RegisteredScreen

Network:Bind("DisabledLoading", function(State)
	if _Loaded then return end
	if State == nil then return _Loaded end
	_Loaded = State
	if State then _Screen:Destroy() end
	return _Loaded
end)

Network:Bind("RegisterLoadingScreen", function(State, FadeInTime, Context)
	if RegisteredScreen and RegisteredScreen.Destroy then
		RegisteredScreen:Destroy()
		RegisteredScreen = nil
	end
	
	if not State then return end
	
	RegisteredScreen = LS.new(SaveArgs)
	RegisteredScreen.ui_info.LoadingContext = 
		Context
		or
		RegisteredScreen.ui_info.LoadingContext
	
	RegisteredScreen:NewTips(SaveTips)
	RegisteredScreen.FadeIn = FadeInTime or false
	RegisteredScreen:init()
end)

Services.get("States")

Services.get("GuiController")

Services.get("ClientData")
Services.get("PetService")

Services.get("EggManager")
Services.get("EggService")

Services.get("DoorService")

Services.get("MusicService")

Services.get("ActivationService")
Services.get("SelectionMenu")
Services.get("ShinyMachineClient")
Services.get("CraftingClient")

Services.get("BossFightClient")
Services.get("LevelingClient")

Services.get("TradingClient")