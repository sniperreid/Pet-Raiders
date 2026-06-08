local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Network = Services.get "Network"
local GuiService = Services.get "GuiService"
local TweenService = Services.get "TweenV2"
local RBXCleanUp = Services.get "RBXCleanUp"
local PlayerLevelService = Services.get "PlayerLevelService"

local LevelingClient = {}

function LevelingClient:DisplayLevel()
	if self.Active then
		return
	end
	
	self.Active = true
	
	local Maid = RBXCleanUp.new()
	
	local Interface = GuiService.Interface
	local Frames = Interface.Frames
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	
	local PlayerLevel = PlayerData.Level
	local PlayerExp = PlayerData.Exp
	
	local ExpRequired = PlayerLevelService:GetExpRequired()
	
	local LevelBar = script.LevelBar:Clone()
	LevelBar.Parent = Frames
	LevelBar.Position = UDim2.fromScale(0.5, -0.1)
	
	local Content = LevelBar.Content
	local Container = Content.Container
	
	local Bar = Container.Bar
	local Level = Container.Level
	local Progress = Container.Progress
	
	Level.Text = ("Level %s"):format(PlayerLevel)
	
	local StartExp = 0
	local Duration = 1
	
	local start = tick()
	
	self.Connection = Maid:add(RunService.RenderStepped:Connect(function()
		local now = tick()
		local alpha = TweenService:GetValue(
			math.clamp((now - start) / Duration, 0, 1),
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out
		)
		
		local CurrentExp = StartExp + (PlayerExp - StartExp) * alpha
		local Percentage = math.clamp(CurrentExp / ExpRequired, 0, 1)
		
		Progress.Text = ("%d/%d"):format(CurrentExp, ExpRequired)
		Bar.Size = UDim2.fromScale(Percentage, 1)
		
		if alpha >= 1 then
			return self.Connection:Disconnect()
		end
	end))
	
	Maid:add(coroutine.wrap(function()
		TweenService:Create(
			LevelBar,

			TweenInfo.new(
				1, Enum.EasingStyle.Back, Enum.EasingDirection.Out
			),

			{ Position = UDim2.fromScale(0.5, 0.05) }
		):Play()

		task.wait(3)
		
		TweenService:Create(
			LevelBar,

			TweenInfo.new(
				0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In
			),

			{ Position = UDim2.fromScale(0.5, -0.1) }
		):Play()
		
		task.wait(1)
		
		self.Active = nil
		Maid:Clean()
	end))()
end

Network:Bind("UpdateLevel", function(...)
	return LevelingClient:DisplayLevel(...)
end)

return LevelingClient
