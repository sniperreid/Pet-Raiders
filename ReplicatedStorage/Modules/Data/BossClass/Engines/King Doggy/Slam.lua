local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
local Assets = ReplicatedStorage.Assets

local FX = Assets.FX
local FX_Directory = FX:FindFirstChild(script.Parent.Name)

local Services = require(Modules.Services)

local Network = Services.get "Network"
local Rocks = Services.get "Rocks"

local module = {}

local function Slam(SELF)
	local rad = SELF.owner.phase == 1 and 50 or 65
	local hrad = rad + 3
	
	SELF.owner:CreateDanger(
		SELF.owner:Raycast(
			SELF.owner.model:GetPivot().Position
		).Position, hrad, .5
	)

	task.wait(.5)
	
	Network:PostAll(SELF.owner.boss_name .. "Attack1", SELF.owner.model, SELF.owner.phase)
	Network:PostAll("PlaySound", "Woosh", .45)

	local dur = SELF.owner.phase == 1 and .6 or .5

	task.wait(dur + .05)

	Network:PostAll("PlaySound", "Slam", .45)

	local wave = FX_Directory:FindFirstChild("Wave")

	assert(wave, "Could not retrieve attack FX for Wave")

	local model = SELF.owner.maid:add(wave:Clone()) :: Model

	model.Parent = workspace.Terrain
	model.PrimaryPart.CollisionGroup = "VFX"

	local raycast = SELF.owner:Raycast(SELF.owner.model:GetPivot().Position)

	assert(raycast, ("Could not raycast %s"):format(SELF.owner.boss_name))

	model:PivotTo(CFrame.new(raycast.Position))

	Rocks.GroundExpandV2(CFrame.new(raycast.Position), hrad/math.pi, 12)
	
	local ground = FX_Directory:FindFirstChild("Ground")
	
	assert(ground, "Could not retrieve attack FX for Ground")
	
	local ground_clone = SELF.owner.maid:add(ground:Clone()) :: Part
	
	ground_clone.Parent = workspace.Terrain
	ground_clone.Position = raycast.Position

	for i, v in ground_clone:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
	
	for i, v in Players:GetPlayers() do
		local c = v.Character
		local pp = c and c.PrimaryPart

		if not pp then continue end

		local normal = Vector3.new(raycast.Position.X, pp.Position.Y, raycast.Position.Z)

		local d = (pp.Position - normal).Magnitude
		
		if d > (hrad/2) then continue end

		c.Humanoid:TakeDamage(30)
	end

	local connection: RBXScriptConnection?

	connection = SELF.owner.maid:add(RunService.Heartbeat:Connect(function()
		local scale = model.PrimaryPart.Size.X
		local start_scale = 100
		local end_scale = 120

		if scale >= start_scale then
			local alpha = math.clamp((scale - start_scale) / (end_scale - start_scale), 0, 1)

			model.PrimaryPart.Transparency = alpha
			model.PrimaryPart.CanCollide = false
		end
		
		if model.PrimaryPart.Transparency >= 1 then
			if connection then
				connection:Disconnect()
				connection = nil
			end
			
			return model:Destroy()
		end

		model.PrimaryPart.Size += Vector3.new(1, 0, 1)
	end))
end

return function(SELF)
	pcall(function() return Slam(SELF) end)
	
	task.wait(0.5)
end