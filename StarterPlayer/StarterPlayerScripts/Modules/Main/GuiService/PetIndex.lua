local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local PetModule = Services.get("PetModule")
local EggModule = Services.get("EggModule")
local ImageModule = Services.get("ImageModule")
local AnimationService = Services.get("AnimationService")
local TextAnimationService = Services.get("TextAnimationService")
local TiersModule = Services.get("TiersModule")
local Short = Services.get("Short")
local Roblox = Services.get("Roblox")
local HoverManager = Services.get("HoverManager")
local WorldService = Services.get("WorldService")

local GuiService
local Interface
local Frames

local IndexFrame

local Tabs
local Buttons

local Tab

local HoverRender
local RewardRender

local module = {}
module.Type = "Normal"
module.Area = 1

function module:Clear()
	local Right = Tab.Right
	local Left = Tab.Left

	for i, v in Roblox:GetChildrenOfClass(Right.Progress.Reward, "GuiButton") do
		v:Destroy()
	end

	for i, v in Roblox:GetChildrenOfClass(Left, "Frame") do
		v:Destroy()
	end
end

function module:SwitchTab(newTab: string)
	if not IndexFrame.Visible then
		return
	end

	self.Type = newTab or "Normal"

	HoverRender.Settings.DefaultDisplay["Tier"] = self.Type
	RewardRender.Settings.DefaultDisplay["Tier"] = self.Type

	task.delay(.1, function()
		self:Clear()
		self:Update()
	end)
end

function module:Update()
	if not Tab.Visible then
		return
	end
	
	local Right = Tab.Right
	local Left = Tab.Left
	local Tiers = Tab.Tiers
	
	local PlayerData = Network:Fetch("GetClientData")
	local Index = PlayerData.Index
	local IndexClaimed = PlayerData.IndexClaimed

	-- BUTTONS

	for i, v in Roblox:GetChildrenOfClass(Tiers, "GuiButton") do
		v.Content.BackgroundColor3 = self.Type == v.Name and Color3.fromRGB(0, 183, 255) or Color3.fromRGB(150, 150, 150)
	end

	-- LEFT

	local TotalInArea = 0
	local DiscoveredInArea = 0

	for Egg, EggData in EggModule do
		if type(EggData) ~= "table" or type(EggData.Pets) ~= "table" then
			continue
		end

		if EggData.Order ~= self.Area then
			continue
		end

		local _t = Left:FindFirstChild(Egg)

		if not _t then
			_t = script.Index:Clone()
			_t.Parent = Left
			_t.Name = Egg
		end

		local _Content = _t.Content
		local _Discovered = _Content.Discovered
		local _Pets = _Content.Pets
		local _EggIcon = _Content.EggIcon
		local _EggName = _Content.EggName

		--_EggIcon.Image = ImageModule(Egg)
		_EggName.Text = string.gsub(Egg, " Egg$", "")

		local Pets = EggData.Pets

		local amt_Pets = 0
		local amt_Discovered = 0

		for _, PetData in Pets do
			local PetName, PetChance = unpack(PetData)

			local pmData = PetModule[PetName]

			if pmData.Rarity == "Secret" then
				continue
			end

			local plrOwns = self.Type == "Normal" and table.find(Index, PetName) or table.find(Index, self.Type .. PetName)

			if plrOwns then
				amt_Discovered += 1
			end

			amt_Pets += 1

			local _p = _Pets:FindFirstChild(PetName)

			if not _p then
				_p = script.IndexPet:Clone()
				_p.Parent = _Pets
				_p.Name =  PetName
				
				_p:SetAttribute("Tier", self.Type)

				local __Glow = _p.Glow

				TextAnimationService:AnimateImage(__Glow, pmData.Rarity)

				AnimationService:CreateButton(_p, function()
					if not plrOwns then
						return
					end

					local HatchInfo = {
						Name = PetName,
						Tier = self.Type
					}

					Network:Fetch("HatchEggClient", {
						Speed = 1.5,
						Egg = Egg,
						Pets = {
							HatchInfo
						},
						Secret = PetData.Rarity == "Secret"
					})
				end)
			end

			local __Content = _p.Content
			local __PetIcon = __Content.PetIcon
			local __PetChance = __Content.PetChance

			local TierData = TiersModule[self.Type]

			local TierColor = TierData.Color
			local TierShade = TierData.Shade

			__Content.BackgroundColor3 = TierColor
			__Content.Inner.BackgroundColor3 = TierShade

			if self.Type == "Shiny" then
				AnimationService:AnimateShinyGradient(__Content)
			end

			__PetIcon.Image = ImageModule(PetName)
			__PetIcon.ImageColor3 = plrOwns and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)

			if PetChance <= 0 then
				PetChance = 0
			elseif PetChance >= 100 then
				PetChance = 100
			else
				PetChance = Short:RoundDecimal(PetChance)
			end

			__PetChance.Text = plrOwns and PetChance .. "%" or "???"
		end

		_Discovered.Label.Text = ("%s/%s"):format(amt_Discovered or 0, amt_Pets or 0)

		TotalInArea += amt_Pets
		DiscoveredInArea += amt_Discovered

		local Progress = Right.Progress
		local Amount = Progress.Amount
		local Reward = Progress.Reward
		local Claim = Progress.Claim

		Amount.Text = ("Discovered: %s/%s"):format(DiscoveredInArea, TotalInArea)

		if not EggData.IndexReward then
			continue
		end

		local rName = EggData.IndexReward
		local rData = PetModule[rName]

		local ClaimedReward = self.Type == "Normal" and table.find(IndexClaimed, rName) or table.find(IndexClaimed, self.Type .. rName)

		Claim.Content.BackgroundColor3 = ClaimedReward and Color3.fromRGB(150, 150, 150) or (DiscoveredInArea >= TotalInArea and Color3.fromRGB(0, 183, 255) or Color3.fromRGB(150, 150, 150))
		Claim.Content.Amount.Text = ClaimedReward and "Claimed" or "Claim"

		for i, v in Roblox:GetChildrenOfClass(Reward, "GuiButton") do
			v:Destroy()
		end

		local _r = script.Reward:Clone()
		_r.Parent = Reward
		_r.Name = rName

		local __Glow = _r.Glow

		TextAnimationService:AnimateImage(__Glow, rData.Rarity)

		local __Content = _r.Content

		local TierData = TiersModule[self.Type]

		local TierColor = TierData.Color
		local TierShade = TierData.Shade

		__Content.BackgroundColor3 = TierColor
		__Content.Inner.BackgroundColor3 = TierShade

		if self.Type == "Shiny" then
			AnimationService:AnimateShinyGradient(__Content)
		end

		__Content.PetIcon.Image = ImageModule(rName)
		__Content.Claimed.Visible = ClaimedReward
	end

	-- RIGHT

	local Areas = Right.Areas
	local World = WorldService.Worlds[1] -- TODO: Switching between Worlds

	for aIndex, aData in World.Areas do
		local _a = Areas:FindFirstChild(aData.Name)

		if not _a then
			_a = script.Area:Clone()
			_a.Parent = Areas
			_a.Name = aData.Name

			AnimationService:CreateButton(_a, function()
				self.Area = aIndex

				task.delay(.1, function()
					self:Clear()
					self:Update()
				end)
			end)
		end

		local _Content = _a.Content
		local _Background = _Content.Background
		local _World = _Content.World

		_Background.ImageColor3 = self.Area == aIndex and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
		_World.Text = aData.Name
	end
end

-- This is for the tab changing, should only be featured in THIS Index module.
function module:ChangeTab(tab: string)
	for i, v in Roblox:GetChildrenOfClass(Tabs, "Frame") do
		v.Visible = v.Name == tab
	end
end

function module:init()
	-- Unique for each Index module
	Tab = Tabs.Pets
	
	for i, v in Roblox:GetChildrenOfClass(Buttons, "GuiButton") do
		AnimationService:CreateButton(v, function()
			self:ChangeTab(v.Name)
		end)
	end
	
	Tab:GetPropertyChangedSignal("Visible"):Connect(function()
		if not Tab.Visible then
			return
		end
		
		self:Update()
	end)
	
	IndexFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not IndexFrame.Visible then
			return
		end
		
		self:Update()
	end)
	
	local Tiers = Tab.Tiers
	local Left = Tab.Left
	local Right = Tab.Right
	
	for i, v in Roblox:GetChildrenOfClass(Tiers, "GuiButton") do
		AnimationService:CreateButton(v, function()
			self:SwitchTab(
				self.Type == "Normal" and "Shiny" or "Normal"
			)
		end)
	end
	
	HoverRender = HoverManager:Bind(IndexFrame, Left, {
		HelpLabel = "Click to replay hatch",
		AccountForIndex = true
	})

	RewardRender = HoverManager:Bind(IndexFrame, Right.Progress.Reward, {
		HelpLabel = "Index Reward",
	})

	local Progress = Right.Progress
	local Claim = Progress.Claim

	AnimationService:CreateButton(Claim, function()
		local Success = Network:Invoke("ClaimIndexReward", self.Area, self.Type)

		if Success == true then
			return
		end

		Network:Fetch("DisplayNewItem", {
			Type = "Message",
			Message = Success or ("You have not completed this index."),
			TextColor = Color3.fromRGB(255, 60, 60)
		})
	end)
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		IndexFrame = Frames.IndexFrame
		Tabs = IndexFrame.Content.Tabs
		Buttons = IndexFrame.Content.Buttons
		
		self:init()
		
		return self
	end,
})