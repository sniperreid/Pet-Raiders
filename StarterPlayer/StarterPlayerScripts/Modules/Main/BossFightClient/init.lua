local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Network = Services.get "Network"
local WorldService = Services.get "WorldService"
local GuiService = Services.get "GuiService"
local ImageModule = Services.get "ImageModule"
local BossClass = Services.get "BossClass"
local AnimationService = Services.get "AnimationService"

local PetBuffService = Services.get "PetBuffService"
local Short = Services.get "Short"
local TextAnimationService = Services.get "TextAnimationService"
local PetModule = Services.get "PetModule"

local GuiUtil = GuiService.GuiUtil

local qBosses = BossClass.BossData
local vBosses = {}

for i, v in qBosses do
	vBosses[v.world] = v
end

qBosses = vBosses

local Interface = GuiService.Interface
local Frames = Interface.Frames

local BossQueueFrame = Frames.BossQueueFrame
local BQFContent = BossQueueFrame.Content

local BossFightClient = {}
BossFightClient.BossAnimations = {}

local ClientBossInfo = {}

for i, v in script:GetChildren() do
	if not v:IsA("ModuleScript") then
		continue
	end

	BossFightClient.BossAnimations[v.Name] = require(v)()
end

function BossFightClient:GetUserAreas()
	return WorldService:GetUserWorld().Areas
end

function BossFightClient.isOpen()
	return BossQueueFrame.Visible
end

function BossFightClient.EnterPortal(Area: string)
	if BossFightClient.isOpen() then return end
	
	BossFightClient.CurrentArea = Area
	
	local Areas = BossFightClient:GetUserAreas()
	local PlayerData = Network:Fetch("GetClientData")
	
	local Boss = qBosses[Area]
	
	local AreaExist
	
	for i, v in Areas do
		if v.Name == Area then
			AreaExist = v; break
		end
	end
	
	assert(AreaExist, ("'%s' is not a valid area."):format(Area))
	assert(table.find(PlayerData.Areas, Area), ("You don't own area '%s'"):format(Area))
	assert(Boss, ("there is no boss for area '%s'"):format(Area))
	
	local BossName = Boss.name
	local BossRewards = Boss.rewards
	
	assert(BossName, "boss has no name assigned to it.")
	assert(BossRewards, "boss has no rewards assigned to it.")
	
	BQFContent.Area.Image = ImageModule(Area)
	BQFContent.Area.AreaTitle.Text = Area
	
	BQFContent.Area.BossIcon.Image = ImageModule(BossName)
	BQFContent.Area.BossName.Text = BossName
	
	local LocalBossData = ClientBossInfo[Area] or {}
	local Level = LocalBossData.Level or 1
	local Health = LocalBossData.Health or Boss.max_health
	local MaxHealth = LocalBossData.MaxHealth or Boss.max_health
	local Transformed = (LocalBossData.phase or 1) > 1
	
	local TransformColor = Transformed and Boss.transform_color or Color3.new(1,1,1)
	local TransformTag = Transformed and "-TRANSFORMED" or ""
	
	BQFContent.Area.BossIcon.ImageColor3 = TransformColor
	BQFContent.Area.BossName.Text = BossName .. TransformTag
	
	BQFContent.Area.Level.Text = ("Lvl. %s"):format(Level)
	BQFContent.Area.Health.Text = ("%s/%s"):format(
		Short:AddCommas(Health),
		Short:AddCommas(MaxHealth)
	)
	
	local Team = PlayerData.Pets
	
	for i, v in BQFContent.Team.Grid:GetChildren() do
		if not v:IsA("GuiButton") then
			continue
		end
		
		v:Destroy()
	end
	
	for i, v in BQFContent.Rewards.Grid:GetChildren() do
		if not v:IsA("GuiButton") then
			continue
		end

		v:Destroy()
	end
	
	for i, v in PetBuffService:GetEquippedPets(Team) do
		local Template = GuiUtil:CreatePet(v, BQFContent.Team.Grid)
		local Content = Template.Content
		
		Content.Info.Mutated.Visible = false
		Content.Info.Secret.Visible = false
		Content.Equipped.Visible = false
		Content.Selected.Visible = false
		Content.PetSerial.Visible = false
	end
	
	for i, v in BossRewards do
		local Template = script.UI.RewardsTemplate:Clone()
		Template.Name = v.Item
		Template.Content.ItemIcon.Image = ImageModule(v.Item)
		Template.Content.Info.Chance.Text = ("1/%s"):format(
			Short:AddSuffix(100 / v.Chance)
		)
		
		if v.Type == "Pet" then
			TextAnimationService:AnimateImage(Template.Glow, PetModule[v.Item].Rarity)
		end
		
		Template.Parent = BQFContent.Rewards.Grid
	end
	
	AnimationService:CreateButton(BQFContent.Choose, function()
		GuiService:CloseFrame(BossQueueFrame)
		
		Network:Post("JoinBossFight", Area)
	end)
	
	GuiService:OpenFrame(BossQueueFrame)
end

Network:Bind("EnterPortal", BossFightClient.EnterPortal)

-- UI DOWN BELOW --

local BattleTimer
local HealthBarGui

Network:Bind("UpdateBattleTimer", function(Time)
	-- have global var set up
	-- because more than 1 timers
	-- shouldn't show up.

	if not Time then
		if BattleTimer then
			BattleTimer:Destroy()
			BattleTimer = nil
		end

		return
	end

	if Time < 0 then
		-- send in nil to indicate destruction of BattleTimer
		return Network:Fetch("UpdateBattleTimer")
	end
	
	BattleTimer = BattleTimer or script.UI.TimerTemplate:Clone()
	BattleTimer.Parent = Frames.BattleContext
	
	BattleTimer.Label.Text = (
		"⏰ %s ⏰"
	):format(Short:FormatTime(Time))
	BattleTimer.Label.TextColor3 = Time > 5 and Color3.new(1, 1, 1) or Color3.new(1, 0, 0)
end)

Network:Bind("SendBattleInvites", function(Area)
	if not Area then return end
	
	local Boss = qBosses[Area]
	local BossName = Boss and Boss.name
	
	if not BossName then return end
	
	local Invite = script.UI.PortalInvite:Clone()
	Invite.Name = Area .. "-Invite"
	
	local iContent = Invite.Content
	
	iContent.BossIcon.Image = ImageModule(BossName)
	iContent.BossName.Text = BossName
	
	Invite.Parent = Frames.BattleContext
	
	local iButtons = iContent.Buttons
	
	local Cancel = iButtons.Cancel
	local Join = iButtons.Join
	
	AnimationService:CreateButton(Cancel, function()
		-- originally was gonna fetch "StartedBattleClient"
		-- but assumed it would be a bad idea in the future.
		
		Invite:Destroy()
	end)
	
	AnimationService:CreateButton(Join, function()
		-- do same as Cancel, but add "JoinBossFight" invoke to it.
		Invite:Destroy()
		
		Network:Post("JoinBossFight", Area)
	end)
end)

Network:Bind("StartedBattleClient", function(Area)
	-- this will not indicate if the player has joined
	-- rather if the entire battle has started.
	
	-- destroy any invites still floating around on LocalPlayer's ui :>
	local InviteFrame = Frames.BattleContext:FindFirstChild(Area .. "-Invite")
	
	if InviteFrame then
		InviteFrame:Destroy()
	end
end)

Network:Bind("LeaveBattleClient", function(Area)
	-- this ties back to global var
	-- Destroy BattleTimer (if exists.)
	-- and more.
	
	if BattleTimer then
		BattleTimer:Destroy()
		BattleTimer = nil
	end
	
	if HealthBarGui then
		HealthBarGui:Destroy()
		HealthBarGui = nil
	end
	
	-- reset the client info for debug reasons
	-- allows healthbar to be shown properly again
	ClientBossInfo[Area] = {}
	
	-- destroy healthbar next.
end)

-- Health change; this might be long script :( --

Network:Bind("UpdateBossLevel", function(Area, Level, Phase)
	local Boss = qBosses[Area]
	
	ClientBossInfo[Area] = ClientBossInfo[Area] or {}
	
	local RecentPhase = ClientBossInfo[Area].Phase or 1
	
	ClientBossInfo[Area].Level = Level
	ClientBossInfo[Area].Phase = Phase or 1
	
	local Transformed = ClientBossInfo[Area].Phase > 1
	local TransformColor = Transformed and Boss.transform_color or Color3.new(1,1,1)
	local TransformTag = Transformed and "-TRANSFORMED" or ""
	
	if Area == BossFightClient.CurrentArea then
		BQFContent.Area.Level.Text = ("Lvl. %d"):format(Level)
		
		BQFContent.Area.BossIcon.ImageColor3 = TransformColor
		BQFContent.Area.BossName.Text = Boss.name .. TransformTag
	end
	
	if HealthBarGui and HealthBarGui:FindFirstChild("Content") then
		HealthBarGui.Content.BossLevel.Text = ("Lvl. %d"):format(
			ClientBossInfo[Area].Level or 1
		)
		
		HealthBarGui.Content.BossName.Text = Boss.name .. TransformTag
		
		if RecentPhase ~= (Phase or 1) then
			TweenService:Create(
				HealthBarGui.Content.Container.BossIcon,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{
					ImageColor3 = TransformColor
				}
			):Play()
		else
			HealthBarGui.Content.Container.BossIcon.ImageColor3 = TransformColor
		end
	end
end)

Network:Bind("UpdateBossHealth", function(in_battle, Area, Health, MaxHealth)
	Health = math.floor(Health)
	MaxHealth = math.floor(MaxHealth)
	
	local Boss = qBosses[Area]
	
	local was_null = HealthBarGui == nil
	
	ClientBossInfo[Area] = ClientBossInfo[Area] or {}
	
	-- check to see if the health and max health are equal
	-- if it is, don't update the healthbar
	-- health & maxhealth should be nil if this is a new battle
	-- so no need to worry about that
	if HealthBarGui and ClientBossInfo[Area].Health == Health and ClientBossInfo[Area].MaxHealth == MaxHealth then
		return
	end
	
	ClientBossInfo[Area].Health = Health
	ClientBossInfo[Area].MaxHealth = MaxHealth
	
	local Display = (
		"%s/%s"
	):format(
		Short:AddCommas(Health),
		Short:AddCommas(MaxHealth)
	)
	
	if Area == BossFightClient.CurrentArea then
		BQFContent.Area.Health.Text = Display
	end
	
	if Health <= 0 and HealthBarGui then
		return HealthBarGui:Destroy()
	end
	
	if Health <= 0 then return end
	if not in_battle then return end
	
	local HBG_Content
	
	if not HealthBarGui then
		HealthBarGui = script.UI.HealthBarUI:Clone()
		HealthBarGui.Parent = Frames.BattleContext
		
		HBG_Content = HealthBarGui.Content
		
		local TextInfo = {
			TextTransparency = 0
		}
		
		local ImageInfo = {
			ImageTransparency = 0
		}
		
		local StrokeInfo = {
			Transparency = 0
		}
		
		local FrameInfo = {
			BackgroundTransparency = 0
		}
		
		HBG_Content.BossName.TextTransparency = 1
		HBG_Content.BossName.UIStroke.Transparency = 1
		HBG_Content.Container.BossIcon.ImageTransparency = 1
		HBG_Content.Container.HP.TextTransparency = 1
		HBG_Content.Container.HP.UIStroke.Transparency = 1
		HBG_Content.Container.Bar.BackgroundTransparency = 1
		
		local Info = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		
		TweenService:Create(
			HBG_Content.BossName,
			Info,
			TextInfo
		):Play()
		
		TweenService:Create(
			HBG_Content.BossName.UIStroke,
			Info,
			StrokeInfo
		):Play()
		
		TweenService:Create(
			HBG_Content.Container.BossIcon,
			Info,
			ImageInfo
		):Play()
		
		TweenService:Create(
			HBG_Content.Container.HP,
			Info,
			TextInfo
		):Play()
		
		TweenService:Create(
			HBG_Content.Container.HP.UIStroke,
			Info,
			StrokeInfo
		):Play()
		
		TweenService:Create(
			HBG_Content.Container.Bar,
			Info,
			FrameInfo
		):Play()
	end
	
	HBG_Content = HealthBarGui.Content
	
	local Transformed = ClientBossInfo[Area].Phase > 1
	
	local TransformColor = Transformed and Boss.transform_color or Color3.new(1,1,1)
	local TransformTag = Transformed and "-TRANSFORMED" or ""
	
	HBG_Content.Container.BossIcon.Image = ImageModule(Boss.name)
	
	if was_null then
		HBG_Content.BossName.Text = Boss.name .. TransformTag
		HBG_Content.Container.BossIcon.ImageColor3 = TransformColor
	end
	
	local RecentHPBar = HBG_Content.Container.Bar:Clone()
	RecentHPBar.Parent = HBG_Content.Container
	RecentHPBar.Name = "DamageBar"
	RecentHPBar.ZIndex -= 1
	RecentHPBar.BackgroundColor3 = Color3.new(1,1,1)
	
	task.delay(.25, function()
		if not RecentHPBar.Parent then
			return
		end
		
		TweenService:Create(
			RecentHPBar,
			TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 1
			}
		):Play()
		
		Debris:AddItem(RecentHPBar, .55)
	end)
	
	HBG_Content.Container.HP.Text = Display
	HBG_Content.BossLevel.Text = ("Lvl. %d"):format(
		ClientBossInfo[Area].Level or 1
	)

	TweenService:Create(
		HBG_Content.Container.Bar,
		TweenInfo.new(.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromScale(
				math.clamp(Health / MaxHealth, 0, 1),
				1
			)
		}
	):Play()
end)

return BossFightClient