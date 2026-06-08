local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Debouncer = Services.get("Debouncer")

local Shop = {}

Shop.Type = "Client"
Shop.Color = Color3.fromRGB(160, 160, 160)

Shop.init = function(Activation)
	Activation.Tag.BillboardGui.Tag.TextColor3 = Shop.Color
	Activation.Texture.Decal.Color3 = Shop.Color
end

Shop.Callback = function(Player, Activation)
	local Area = string.split(Activation.Name, script.Name)[2]
	local PlayerData = Network:Fetch("GetClientData")
	
	if not table.find(PlayerData.Areas, Area) then
		return
	end
	
	local GuiService = Services.get("GuiService")
	local Interface = GuiService.Interface
	local Frames =  Interface.Frames
	local CraftingFrame = Frames.CraftingFrame
	
	CraftingFrame.Visible = true
end

return Shop