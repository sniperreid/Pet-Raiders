local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local PrizeService = Services.get("PrizeService")
local PrizeModule = Services.get("PrizeModule")
local Short = Services.get("Short")
local AnimationService = Services.get("AnimationService")
local ImageModule = Services.get("ImageModule")
local TextAnimationService = Services.get("TextAnimationService")
local HoverManager = Services.get("HoverManager")
local Roblox = Services.get("Roblox")

local PetModule = Services.get("PetModule")
local BoostModule = Services.get("BoostModule")

local GuiService
local GuiUtil
local Interface
local Frames
local PrizesFrame
local Grid

local module = {}
module.Type = "Eggs"
module.Prefix = {
	["Eggs"] = "Hatch %s Eggs",
	["Pickups"] = "Break %s Pickups",
	["Bosses"] = "Defeat %s Bosses"
}

function module:Clear()
	for _, v in Roblox:GetChildrenOfClass(Grid, "Frame") do
		v:Destroy()
	end
end

function module:Update()
	local PlayerData = Network:Fetch("GetClientData")
	local PlayerPrizes = PlayerData.Prizes
	
	for i, v in ipairs(PrizeModule) do
		if v.Type ~= self.Type then
			continue
		end
		
		local Template = Grid:FindFirstChild(v.Requirement)
		
		if not Template then
			Template = script.Prize:Clone()
			Template.Parent = Grid
			Template.Name = v.Requirement
			
			AnimationService:CreateButton(Template.Content.Claim, function()
				Network:Post("ClaimPrize", v.Type, v.Requirement)
			end)
			
			local Reward = v.Reward
			local RewardData = Reward.Type == "Pet" and PetModule[Reward.Name] or Reward.Type == "Boost" and BoostModule[Reward.Name]

			if not RewardData then
				continue
			end
			
			local RewardEntry = Template.Content.Reward
			RewardEntry.Name = Reward.Name

			TextAnimationService:AnimateImage(RewardEntry.Glow, RewardData.Rarity or "Legendary")

			RewardEntry.Content.ItemIcon.Image = ImageModule(Reward.Name)

			local RewardAmt = Reward.Type == "Boost" and Short:FormatBoost(Reward.Amount)
			RewardEntry.Content.Amount.Text = RewardAmt or "x1"
		end
		
		local Prefix = self.Prefix[v.Type]
		
		Template.Content.Task.Text = string.format(Prefix, v.Requirement)
		
		local Directory = v.Type == "Eggs" 
			and PlayerData["Eggs Hatched"] or v.Type == "Pickups"
			and PlayerData["Pickups Broken"] or v.Type == "Bosses"
			and PlayerData["Bosses Killed"]

		if not Directory then
			continue
		end
		
		if PrizeService:HasPrize(nil, v.Type, v.Requirement) then
			Template.Content.Claim.Visible = true
			Template.Content.Progress.Visible = false
			Template.Content.Claim.Content.Amount.Text = "Claimed"
			Template.Content.Claim.Content.BackgroundColor3 = Color3.fromRGB(112, 112, 112)
		else
			local HasEnough = Directory >= v.Requirement
			
			Template.Content.Claim.Visible = HasEnough
			Template.Content.Progress.Visible = not HasEnough
			
			Template.Content.Progress.Bar.Size = UDim2.fromScale(
				math.clamp((Directory / v.Requirement), 0, 1), 1
			)
			
			Template.Content.Progress.Amount.Text = ("%s/%s"):format(
				Short:AddSuffix(Directory),
				Short:AddSuffix(v.Requirement)
			)
		end
	end
end

function module:init()
	HoverManager:Bind(PrizesFrame, Grid, {
		HelpLabel = "Reward"
	})
	
	HoverManager:Bind(PrizesFrame, Grid, {
		HelpLabel = "Reward",
		Boost = true,
		Prize = true
	})
	
	for i, v in Roblox:GetChildrenOfClass(PrizesFrame.Content.Buttons, "GuiButton") do
		AnimationService:CreateButton(v, function()
			self.Type = v.Name
			
			task.delay(.1, function()
				self:Clear()
				self:Update()
			end)
		end)
	end
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		PrizesFrame = Frames.PrizesFrame
		Grid = PrizesFrame.Content.Grid
		
		self:init()

		return self
	end,
})