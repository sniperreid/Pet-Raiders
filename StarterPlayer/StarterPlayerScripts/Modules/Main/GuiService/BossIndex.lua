local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local ImageModule = Services.get("ImageModule")
local AnimationService = Services.get("AnimationService")
local BossClass = Services.get "BossClass"
local Roblox = Services.get "Roblox"
local RichTextService = Services.get("RichTextService")

local GuiService
local Interface
local Frames

local IndexFrame

local Tabs
local Buttons

local Tab

local module = {}
module.Selection = nil

function module:UpdateSelection()
	if not self.Selection then
		return
	end
	
	local Selection = Tab.Selection
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	local BossesDefeated = PlayerData.BossesDefeated or {}
	local AmountDefeated = BossesDefeated[self.Selection] or 0
	
	local BossData = BossClass.BossData[self.Selection]
	local Rewards = BossData.rewards
	
	Selection.BossIcon.Image = ImageModule(self.Selection)
	Selection.BossName.Text = self.Selection
	Selection.DefeatCount.Text = ("Defeated %s times"):format(AmountDefeated)
	
	for i, v in Roblox:GetChildrenOfClass(Selection.Rewards, "TextLabel") do
		v:Destroy()
	end
	
	for i, v in Rewards do
		local RewardTemplate = script.Reward:Clone()
		RewardTemplate.Parent = Selection.Rewards
		RewardTemplate.Name = i
		RewardTemplate.LayoutOrder = i
		
		local Display = RichTextService.new {}
		
		Display:AddSection(("%s"):format(v.Item), "Light Blue")
		Display:AddSection((" %s "):format(v.Type), "White")
		Display:AddSection(("(%s%%)"):format(v.Chance), "Yellow")

		RewardTemplate.Text = Display.Message
	end
end

function module:Init()
	
	Tab = Tabs.Bosses
	
	local Grid = Tab.Grid
	
	local Bosses = BossClass.BossData
	
	for i, v in Bosses do
		local BossButton = script.Boss:Clone()
		BossButton.Parent = Grid
		BossButton.Name = i
		
		BossButton.Content.PetIcon.Image = ImageModule(i)
		
		AnimationService:CreateButton(BossButton, function()
			self.Selection = i
			
			task.delay(.1, function()
				self:UpdateSelection()
			end)
		end)
	end
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		IndexFrame = Frames.IndexFrame
		Tabs = IndexFrame.Content.Tabs
		Buttons = IndexFrame.Content.Buttons
		
		self:Init()
		
		return self
	end,
})