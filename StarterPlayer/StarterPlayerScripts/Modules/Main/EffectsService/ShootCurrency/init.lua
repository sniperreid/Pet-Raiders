local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local TweenV2 = Services.get("TweenV2")
local ImageModule = Services.get("ImageModule")
local MaidClass = Services.get("MaidClass")

local Camera = workspace.CurrentCamera

local Module = {}

local RNG = Random.new()

function Module:Lerp(a, b, t)
	return a + (b - a) * t
end

function Module:ReturnSurface(Origin, Direction)
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Include
	RaycastParameters.FilterDescendantsInstances = { workspace.Assets }
	RaycastParameters.RespectCanCollide = true

	local Cast = workspace:Raycast(
		Origin.Position + Vector3.new(0, 10, 0), 
		-Origin.UpVector * 1000,
		RaycastParameters
	)

	if not Cast then
		return
	end

	return Cast.Position, Cast
end

function Module:Shoot()
	return require(script.Shoot)
end

function Module:Create(Player, Currency, Position)
	local Maid = MaidClass.new()
	
	local FX = Maid:GiveTask(script.FX:Clone())
	FX.Parent = workspace.Terrain
	
	FX.Content.Enabled = true
	FX.Content.Currency.Image = ImageModule(Currency)

	local Offset = RNG:NextNumber(-5, 5)
	
	FX.Position = Position + Vector3.new(Offset, 0, Offset)
	FX.Anchored = true

	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	local Origin = FX.Position
	
	local Start = tick()
	local Max = RNG:NextNumber(8, 12)
	
	local Offset1 = RNG:NextNumber(3, 5)
	local Offset2 = RNG:NextNumber(0.4, 0.6)
	
	task.delay(0.35, function()
		
		local Content = FX:FindFirstChild("Content")
		
		if not Content then
			return
		end
		
		TweenV2:Create(Content.Currency, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0, 0) }):Play()
	end)

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local Destination = Character.PrimaryPart.Position
		
		if (Origin - Destination).Magnitude > 100 then
			return Maid:Clean()
		end
		
		local Update = math.min((tick() - Start) * 2, 1)

		local NewPosition = Vector3.new(
			self:Lerp(Origin.X, Destination.X, Update),
			0,
			self:Lerp(Origin.Z, Destination.Z, Update)
		)

		local Arch = Max * Offset1 * (Update - Offset2) * (Update - Offset2)
		NewPosition = NewPosition + Vector3.new(0, Max - Arch, 0)

		FX.Position = NewPosition

		if Update >= 1 then
			Maid:Clean()
		end
	end))
end

Network:Bind("ShootCurrency", function(Amount, ...)
	for i = 1, Amount do
		Module:Create(...)
	end
end)

return setmetatable(Module, {
	__call = function(self, GS)
		task.delay(math.random()*.1, function()
			Module:Shoot()
		end)
		
		return self
	end,
})