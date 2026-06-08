local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage.Modules
local Assets = ReplicatedStorage.Assets

local FX = Assets.FX
local FX_Directory = FX:FindFirstChild(script.Parent.Name)

local Services = require(Modules.Services)

local Network = Services.get "Network"
local Rocks = Services.get "Rocks"
local math = Services.get "MathUtility"
local TweenService = Services.get "TweenV2"

local module = {}

local placed_positions = {}

local function far(pos: Vector3, min_dist: number): boolean
	for _, p in placed_positions do
		if (p - pos).Magnitude < min_dist then
			return false
		end
	end
	return true
end

local function Strike(SELF)
	local strike = FX_Directory:FindFirstChild("Strike")
	local impact = FX_Directory:FindFirstChild("Impact")
	
	assert(strike and impact, "Could not retrieve attack FX for Strike")
	
	local strike_clone = SELF.owner.maid:add(strike:Clone()) :: Part
	local impact_clone = SELF.owner.maid:add(impact:Clone()) :: Part
	
	local area, radius, position = SELF.owner:GenerateBounds()
	local target_y = SELF.owner:Raycast(SELF.owner.model:GetPivot().Position).Position.Y

	local spawn_pos: Vector3
	local max_attempts = 10
	local attempts = 0
	local min_distance = 30
	
	repeat
		spawn_pos = Vector3.new(
			math.clamp(position.X + math.random(-radius, radius), position.X - radius, position.X + radius),
			target_y + 100,
			math.clamp(position.Z + math.random(-radius, radius), position.Z - radius, position.Z + radius)
		)
		
		attempts += 1
	until far(spawn_pos, min_distance) or attempts >= max_attempts

	table.insert(placed_positions, spawn_pos)
	
	local land_pos = Vector3.new(spawn_pos.X, target_y, spawn_pos.Z)
	
	-- +3 to account for hrp size & danger & g-expansion.
	local rad = 10
	local hrad = rad + 3
	
	-- use hrad because of danger extents. (image 1:1)
	SELF.owner:CreateDanger(
		land_pos,
		hrad,
		SELF.phase == 1 and 1 or .5
	)
	
	task.wait(
		SELF.phase == 1 and 1 or .5
	)
	
	strike_clone.Parent = workspace.Terrain
	strike_clone.Position = land_pos
	
	for i, v in strike_clone:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
	
	Network:PostAll("PlaySound", "Zap", .45)
	
	task.wait(0.25)
	
	for i, v in Players:GetPlayers() do
		local c = v.Character
		local pp = c and c.PrimaryPart
		
		if not pp then continue end
		
		local normal = Vector3.new(land_pos.X, pp.Position.Y, land_pos.Z)
		
		local d = (pp.Position - normal).Magnitude
		
		if d > (hrad/2) then continue end
		
		c.Humanoid:TakeDamage(30)
	end
	
	impact_clone.Parent = workspace.Terrain
	impact_clone.Position = land_pos
	
	for i, v in impact_clone:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
	
	Network:PostAll("PlaySound", "Lightning", .45)
	Rocks.GroundExpandV2(CFrame.new(land_pos), rad, 10)
	
	Debris:AddItem(strike_clone, 3)
	Debris:AddItem(impact_clone, 3)
end

return function(SELF)
	local Interval = SELF.owner.phase == 2 and .25 or .45
	local rep = SELF.owner.phase == 2 and {20, 25} or {10, 15}
	
	for i = 1, math.random(unpack(rep)) do
		task.spawn(function()
			pcall(function() return Strike(SELF) end)
		end)

		task.wait(Interval)
	end
	
	task.wait(Interval)
	
	table.clear(placed_positions)
end
