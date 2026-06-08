local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local ImageModule = Services.get("ImageModule")
local QuestModule = Services.get("QuestModule")
local AnimationService = Services.get("AnimationService")
local TextAnimationService = Services.get("TextAnimationService")
local MaidClass = Services.get("RBXCleanUp")
local HoverManager = Services.get("HoverManager")
local Short = Services.get("Short")

local PetModule = Services.get("PetModule")
local BoostModule = Services.get("BoostModule")

local GuiService
local Interface
local Frames
local QuestsFrame
local AllQuestsFrame

local module = {}
module.Pages = {}

function module:GetQuestData(Quest: string)
	if not Quest then
		return
	end
	
	if typeof(Quest) ~= "string" then
		return
	end
	
	for i, v in QuestModule do
		if v.Name == Quest then
			return v
		end
	end
	
	return
end

function module:Update()
	if self.Maid then
		self.Maid:Clean()
		self.Maid = nil
	end
	
	self.Maid = MaidClass.new()
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	local PlayerQuests = PlayerData.Quests or {}
	
	local ActiveQuestNames = {}
	
	for _, q in PlayerQuests do
		if q.Name then
			ActiveQuestNames[q.Name] = true
		end
	end
	
	for QuestName in self.Pages do
		if not ActiveQuestNames[QuestName] then
			self.Pages[QuestName] = nil
		end
	end
	
	-- Quests Frame
	
	for _, v in QuestsFrame:GetChildren() do
		if not v:IsA("Frame") then
			continue
		end

		if not ActiveQuestNames[v.Name] then
			v:Destroy()
		end
	end
	
	-- All Quests Frame
	
	local Grid = AllQuestsFrame.Content.Grid
	
	for _, v in Grid:GetChildren() do
		if not v:IsA("Frame") or v.Name == "NO_QUESTS" then
			continue
		end

		if not ActiveQuestNames[v.Name] then
			v:Destroy()
		end
	end
	
	Grid.NO_QUESTS.Visible = #PlayerQuests <= 0
	
	for i, v in PlayerQuests do
		local QuestData = self:GetQuestData(v.Name)
		
		if not QuestData then
			continue
		end
		
		-- Quests Frame
		
		local Template = QuestsFrame:FindFirstChild(v.Name)
		
		if not Template then
			Template = script.Template:Clone()
			Template.Parent = QuestsFrame
			Template.Name = v.Name
		end
		
		local Content = Template.Content
		
		local Progress = Content.Progress
		local Bar = Progress.Bar
		local Amount = Progress.Amount
		
		Bar.Size = UDim2.fromScale(math.clamp(v.Progress / QuestData.Requirement, 0, 1), 1)
		Amount.Text = ("%s/%s"):format(v.Progress, QuestData.Requirement)
		
		local Icon = Content.Icon
		local Giver = Content.Giver
		local Task = Content.Task
		
		Icon.Image = ImageModule(QuestData.Giver)
		Giver.Text = QuestData.Giver
		Task.Text = QuestData.Description
		
		-- All Quests Frame
		
		if not self.Pages[v.Name] then
			self.Pages[v.Name] = 1
		end
		
		local _Template = Grid:FindFirstChild(v.Name)
		
		if not _Template then
			_Template = script.Quest:Clone()
			_Template.Parent = Grid
			_Template.Name = v.Name
			
			local _Content = _Template.Content
			local _PageFlip = _Content.PageFlip
			
			AnimationService:CreateButton(_PageFlip.Next, function()
				self.Pages[v.Name] += 1

				if self.Pages[v.Name] > #QuestData.Rewards then
					self.Pages[v.Name] = 1
				end

				return task.delay(.1, function()
					self:Update()
				end)
			end)

			AnimationService:CreateButton(_PageFlip.Previous, function()
				self.Pages[v.Name] -= 1

				if self.Pages[v.Name] <= 0 then
					self.Pages[v.Name] = #QuestData.Rewards
				end

				return task.delay(.1, function()
					self:Update()
				end)
			end)
		end
		
		local _Content = _Template.Content
		
		local _Progress = _Content.Progress
		local _Task = _Content.Task
		local _Reward = _Content:FindFirstChildOfClass("ImageButton")
		
		_Task.Text = QuestData.Description
		
		local _Bar = _Progress.Bar
		local _Amount = _Progress.Amount
		
		_Bar.Size = UDim2.fromScale(math.clamp(v.Progress / QuestData.Requirement, 0, 1), 1)
		_Amount.Text = ("%s/%s"):format(v.Progress, QuestData.Requirement)
		
		local _PageFlip = _Content.PageFlip
		
		local Rewards = QuestData.Rewards
		
		local CurrentPage = self.Pages[v.Name]
		
		_PageFlip.Title.Text = ("%s/%s"):format(CurrentPage, #Rewards)

		local Reward = Rewards[CurrentPage]

		if not Reward then
			continue
		end
		
		local RewardData = Reward.Type == "Pet" and PetModule[Reward.Name] or Reward.Type == "Boost" and BoostModule[Reward.Name]
		
		if not RewardData then
			continue
		end
		
		_Reward.Name = Reward.Name
		
		TextAnimationService:AnimateImage(_Reward.Glow, RewardData.Rarity or "Common")
		
		_Reward.Content.ItemIcon.Image = ImageModule(Reward.Name)
		
		local RewardAmt = Reward.Type == "Boost" and Short:FormatBoost(Reward.Amount)
		_Reward.Content.Amount.Text = RewardAmt or "x1"
	end
end

function module:init()
	HoverManager:Bind(AllQuestsFrame, AllQuestsFrame.Content.Grid, {
		HelpLabel = "Reward"
	})
	
	HoverManager:Bind(AllQuestsFrame, AllQuestsFrame.Content.Grid, {
		Boost = true,
		Prize = true,
		HelpLabel = "Reward"
	})
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		QuestsFrame = Frames.QuestsFrame
		AllQuestsFrame = Frames.AllQuestsFrame
		
		self:init()
		
		return self
	end,
})