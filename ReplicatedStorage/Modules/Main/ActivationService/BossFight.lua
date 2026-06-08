local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Debouncer = Services.get("Debouncer")
local BossClass = Services.get("BossClass")

local BF = {}

BF.Type = "Client"
BF.Color = Color3.fromRGB(160, 160, 160)

BF.init = function(Activation)
	CollectionService:AddTag(Activation, "BossFight")
	
	local BossFight = Activation.Name
	local Final = BossFight:sub(1, BossFight:len() - script.Name:len())
	
	Activation:SetAttribute("Boss", Final)
	
	Activation.Tag.BillboardGui.Title.Text = ("⚔️ %s ⚔️"):format(Final)
	Activation.Tag.BillboardGui.Description.Text = "Nobody fighting."
	
	--Activation.Tag.BillboardGui.Tag.TextColor3 = BF.Color
	--Activation.Texture.Decal.Color3 = BF.Color
end

BF.Callback = function(Player, Activation)
	local BossFight = Activation.Name
	local Final = BossFight:sub(1, BossFight:len() - script.Name:len())
	
	for i, v in BossClass.BossData do
		if v.name == Final then
			Network:Fetch("EnterPortal", v.world)
			
			break
		end
	end
end

return BF