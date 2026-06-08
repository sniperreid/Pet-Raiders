local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local DataService = Services.get("DataService")

local Currency = {
	Coins = {
		DefaultValue = 0,
		Color = Color3.fromRGB(255, 207, 33)
	},
	
	MoonCoins = {
		DefaultValue = 0,
		Color = Color3.fromRGB(231, 231, 231)
	},
	
	Gems = {
		DefaultValue = 0,
		Color = Color3.fromRGB(190, 85, 255)
	}
}

for Stat, Data in Currency do
	if not DataService then
		continue
	end
	
	DataService.DefaultData[Stat] = Data.DefaultValue
end

return Currency