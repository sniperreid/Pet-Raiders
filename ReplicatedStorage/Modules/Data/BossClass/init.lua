--!strict

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local Debris = game:GetService "Debris"

local Modules = ReplicatedStorage:FindFirstChild "Modules"
local Assets = ReplicatedStorage:FindFirstChild "Assets"

local rBosses = Assets:FindFirstChild "Bosses"
local wBosses = workspace:FindFirstChild "Bosses"

local Spawns = wBosses:FindFirstChild "Spawns"
local Bounds = wBosses:FindFirstChild "Bounds"
local Models = wBosses:FindFirstChild "Models"

local Services = require(Modules.Services)

local RBXCleanUp = Services.get "RBXCleanUp"
local TweenModelService = Services.get "TweenModelService"
local TweenService = Services.get "TweenV2"
local Network = Services.get "Network"

local BossClass = {}
BossClass.__index = BossClass

local Types = require(script.Types)
local Data = require(script.Data)
local Engines = require(script.Engines)

BossClass.BossData = Data

local Grass = {} :: any

for i, v in workspace.Assets:GetDescendants() do
	if v.Name == "Grass" then
		table.insert(Grass, v)
	end
end

function BossClass.new(boss_name: string)
	local boss_data = Data[boss_name]
	local engine_module = Engines.locate(boss_name)

	local self = setmetatable({
		boss_name = boss_name,
		boss_data = boss_data,
		health = boss_data.max_health,
		hp_scale = boss_data.max_health,
		max_health = boss_data.max_health,
		damage_dealt = {},
		speed = boss_data.speed,
		area = boss_data.world,
		maid = RBXCleanUp.new(),
		phase = 1,
		transformed_health = 1,
		level = 1,
		
		model = nil,
		engine = nil,
	} :: Types.Boss, BossClass)
	
	self.max_health = self:GetMaxHealthFromScale()
	self.engine = engine_module.new(self)

	return self
end

function BossClass:GetMaxHealthFromScale()
	-- this is so simple for no reason :sob:
	-- it's legit just scale * level * phase
	-- did I even need a function :sob: :sob: :sob:
	
	-- i guess just default hp_scale & level -> 1
	local scale = self.hp_scale or 1
	local level = self.level or 1
	local phase = self.phase or 1
	
	return scale * level * phase
end

function BossClass:onLevelChange(new_level)
	if self.level == new_level then
		return
	end
	
	self.level = new_level
	
	-- DON'T fire to clients for level change
	-- onHealthChange signal will do that.
	-- it will cause bugs with phase changes
	-- and other peoples clients.
	
	-- here:
	
	-- set max health to GetMaxHealthFromScale
	-- set health based on change from max health
	local MAXHEALTH = self.max_health
	local NEWHEALTH = self:GetMaxHealthFromScale()
	
	local CHANGE = NEWHEALTH / MAXHEALTH
	
	self.max_health = NEWHEALTH
	self.health *= CHANGE
	
	if self.onHealthChange then
		self:onHealthChange()
	end
end

function BossClass:CreateDanger(position: Vector3, size: number, decay: number)
	local decal = self.maid:add(Instance.new("Decal"))
	decal.Texture = "rbxassetid://429500449"
	
	local part = self.maid:add(Instance.new("Part"))
	part.Size = Vector3.new(size, .1, size)
	part.CFrame = CFrame.new(position)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace.Terrain
	
	decal.Parent = part
	decal.Face = Enum.NormalId.Top
	decal.Color3 = Color3.fromRGB(255, 0, 0)
	decal.Transparency = 1
	
	TweenService:Create(
		decal,
		TweenInfo.new(.25),
		{ Transparency = 0 }
	):Play()
	
	task.delay(decay, function()
		TweenService:Create(
			decal,
			TweenInfo.new(.25),
			{ Transparency = 1 }
		):Play()
		
		Debris:AddItem(decal, .25)
		Debris:AddItem(part, .25)
	end)
end

function BossClass:Raycast(start_pos: Vector3)
	local raycast_params = RaycastParams.new()
	raycast_params.FilterType = Enum.RaycastFilterType.Include
	raycast_params.FilterDescendantsInstances = { Grass }
	
	local raycast = workspace:Raycast(
		start_pos + Vector3.new(0, 10, 0),
		Vector3.new(0, -1000, 0),
		raycast_params
	)
	
	return raycast
end

function BossClass:GenerateBounds(Wander: boolean | nil)
	local tag = Wander and "" or "-Attack"
	local bounds = Bounds:FindFirstChild(self.boss_name .. tag) :: Part
	
	assert(bounds, ("Could not retrieve bounds area for %s"):format(self.boss_name))
	
	local size = bounds.Size
	local pos = bounds.Position
	local area = (size.X + size.Z) / 2
	
	return area, area / 2, pos
end

function BossClass:Spawn()
	local model = rBosses:FindFirstChild(self.boss_name)
	
	assert(model, ("Could not retrieve model for %s"):format(self.boss_name))
	
	self.model = self.maid:add(model:Clone()) :: Model
	self.model.Parent = Models
	
	self.model:SetAttribute("Area", self.area)
	
	local spawn_location = Spawns:FindFirstChild(self.boss_name) :: Part
	
	assert(spawn_location, ("Could not retrieve spawn location for %s"):format(self.boss_name))
	
	local raycast = self:Raycast(spawn_location.Position) :: RaycastResult
	
	assert(raycast, ("Could not raycast %s, position is likely invalid"):format(self.boss_name))
	
	self.model:PivotTo(
		CFrame.new(raycast.Position)
	)
end

function BossClass:Disconnect(RBXScriptConnection: RBXScriptConnection?, Callback: () -> ())
	if not RBXScriptConnection then
		return
	end
	
	RBXScriptConnection:Disconnect()
	RBXScriptConnection = nil
	
	return Callback()
end

function BossClass:Return(target: Vector3)
	local root: BasePart? = self.model.PrimaryPart

	if not root then
		return
	end

	local goal: CFrame = CFrame.new(target)
	local offset: CFrame = root.CFrame:ToObjectSpace(self.model:GetPivot()):Inverse()

	local tween = TweenService:Create(
		root,
		TweenInfo.new(
			0.5,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out
		),
		{ CFrame = offset * goal }
	)

	self.maid:add(tween)

	tween:Play()
	
	return tween
end

function BossClass:Rotate(target: Vector3)
	local root: BasePart? = self.model.PrimaryPart

	if not root then
		return
	end

	local pivot: CFrame = self.model:GetPivot()
	local direction: Vector3 = (target - pivot.Position).Unit
	local _, y, _ = CFrame.lookAt(pivot.Position, target):ToEulerAnglesYXZ()

	local goal: CFrame = CFrame.new(root.Position) * CFrame.Angles(0, y, 0)
	local offset: CFrame = root.CFrame:ToObjectSpace(pivot):Inverse()

	local tween = TweenService:Create(
		root,
		TweenInfo.new(
			0.4,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out
		),
		{ CFrame = offset * goal }
	)

	self.maid:add(tween)

	tween:Play()

	return tween
end

function BossClass:Wander()
	local area: number, radius: number, position: Vector3 = self:GenerateBounds(true)
	local start_position: Vector3 = self.model:GetPivot().Position

	local target: Vector3 = Vector3.new(
		position.X + math.random(-radius, radius),
		start_position.Y,
		position.Z + math.random(-radius, radius)
	)

	local phase: number = Random.new():NextNumber(-math.pi, math.pi)
	local walk_speed: number = self.speed or 8
	local start_time: number = tick()
	
	local distance: number = (target - start_position).Magnitude
	local travel_time: number = distance / walk_speed
	
	local rotation_tween = self:Rotate(target)
	
	rotation_tween.Completed:Wait()

	self.move_connection = RunService.Heartbeat:Connect(function(dt: number)
		if not self.model or not self.model:IsDescendantOf(workspace) then
			if not self.Disconnect then return end
			
			return self:Disconnect(self.move_connection, function()
				self:Return(target)
			end)
		end

		local current: Vector3 = self.model:GetPivot().Position
		local direction: Vector3 = target - current
		local dist: number = direction.Magnitude

		if dist < 1 then
			return self:Disconnect(self.move_connection, function()
				self:Return(target)
			end)
		end

		local velocity: Vector3 = direction.Unit * walk_speed * dt
		local new_pos: Vector3 = current + velocity

		local raycast: RaycastResult = self:Raycast(new_pos)
		
		if not raycast then
			raycast = self.model:GetPivot()
		end
		
		local grounded: Vector3 = Vector3.new(new_pos.X, raycast.Position.Y, new_pos.Z)

		local elapsed: number = tick() - start_time
		local angle: number = (elapsed + phase) % (math.pi * 2)

		local intensity: number = 0.5
		local bobbleY: number = math.abs(math.sin(angle * 10)) * 5 * intensity
		local tilt: number = math.rad(math.sin(angle * 10) * 50 * intensity)

		local anim_offset: CFrame = CFrame.new(0, bobbleY, 0) * CFrame.Angles(0, 0, tilt / 1.5)
		local look: CFrame = CFrame.lookAt(grounded, target)

		self.model:PivotTo(look * anim_offset)
	end)
	
	task.wait(travel_time + 1)
end

function BossClass:TransformHealth()
	if self.transformed_health >= self.phase then return end
	
	self.transformed_health = self.phase
	
	local MAXHEALTH = self.max_health
	local NEWHEALTH = self:GetMaxHealthFromScale()

	local CHANGE = NEWHEALTH / MAXHEALTH
	
	self.max_health = NEWHEALTH
	self.health *= CHANGE
	
	if self.onHealthChange then
		self:onHealthChange()
	end
end

function BossClass:PhaseChange()
	if self.phase > 1 then
		return
	end
	
	self.phase = 2
	self.speed *= 2.15
	
	self:TransformHealth()
	
	return self.engine:Transform()
end

function BossClass:TakeDamage(damage: number, dealer: Player)
	if dealer then
		local sub = math.clamp(damage, self.health, self.max_health)
		local c = self.damage_dealt[dealer] or 0
		
		self.damage_dealt[dealer] = c + sub
	end
	
	if self.model and self.model.PrimaryPart then
		Network:PostAll(
			"DamagePopup", 
			damage, 
			self.model.PrimaryPart
		)
		
		Network:Post(
			dealer,
			"PlayEffectCreateDisplay", 
			damage
		)
	end
	
	if self.health - damage <= 0 then
		-- it would make more sense to use a clamp function
		-- I don't know why Spidey Baldwin didn't do ts
		self.health = 0
		
		if self.onHealthChange then
			self:onHealthChange()
		end
		
		return pcall(function() self.model:Destroy() end) 
	end
	
	self.health -= damage
	
	if self.onHealthChange then
		self:onHealthChange()
	end
end

function BossClass:Destroy()
	if not self.maid then
		return
	end
	
	if self.move_connection then
		self.move_connection:Disconnect()
		self.move_connection = nil
	end
	
	self.maid:Clean()
	
	table.clear(self.maid)
	
	self.maid = nil
	
	table.clear(self)
	setmetatable(self, nil)
end

return BossClass