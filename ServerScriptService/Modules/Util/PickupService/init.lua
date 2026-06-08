local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local FX = Assets.FX

local RS_Pickups = Assets.Pickups

local Services = require(Modules.Services)

local PetUtil = Services.get("PetUtil")
local Network = Services.get("Network")

local server_attacks = PetUtil.server_attacks

local PickupRegions = workspace.PickupRegions
local Pickups = workspace.Pickups
local Map = workspace.Assets.Map

local PickupService = {}
PickupService.__index = PickupService

PickupService.raycast_params = RaycastParams.new()
PickupService.raycast_params.FilterType = Enum.RaycastFilterType.Include
PickupService.raycast_params.FilterDescendantsInstances = {Map}

PickupService.respawn_time = 5

function PickupService:destroy_model(model)
	for player, data in server_attacks do
		for id, target in data do
			if target.model ~= model then
				continue
			end
			
			server_attacks[player][id] = nil
		end
	end
	
	local pickups = self.pickups
	local pickup_idx = table.find(pickups, model)
	
	Network:PostAll(
		"PlayBreakEffect",
		model:GetExtentsSize() + Vector3.new(15, 0, 15),
		model.PrimaryPart.Position
	)
	
	model:Destroy()
	
	if not pickup_idx then
		return
	end
	
	table.remove(self.pickups, pickup_idx)
	
	task.delay(self.respawn_time, function()
		return self:generate_new_pickup()
	end)
end

function PickupService:get_random_pickup()
	local region = self.region
	local region_data = require(script:FindFirstChild(region))
	
	local max_weight = 0
	local max_ratio = 1
	
	for i, v in region_data.Pickups do
		if v.Health * max_ratio < max_weight * max_ratio then
			continue
		end
		
		max_weight = v.Health * max_ratio
	end
	
	local total_weight = 0
	
	for i, v in region_data.Pickups do
		total_weight += max_weight / v.Health
	end
	
	local current_weight = 0
	local random_weight = math.random() * total_weight
	
	for i, v in region_data.Pickups do
		current_weight += max_weight / v.Health
		
		if current_weight >= random_weight then
			return v
		end
	end
end

function PickupService:get_pickup_in_radius(position, range)
	for i, pickup in self.pickups do
		local origin = pickup:GetPivot()
		local p1 = origin.Position
		
		local dist = (p1 - position).Magnitude
		
		if dist < range then
			return pickup -- no need for getting the closest, just anything in range.
		end
	end
end

function PickupService:get_pickup_position()
	local region = self.region
	local area = self.pickup_area
	
	local area_size = area.Size
	
	local normalized = math.ceil(math.max(area_size.X, area_size.Z))
	
	local area_radius = normalized / 2
	
	local position = area.Position
	
	return Vector3.new(
		position.X + math.random(-area_radius, area_radius),
		position.Y + 200,
		position.Z + math.random(-area_radius, area_radius)
	)
end

function PickupService:generate_new_pickup()
	-- Bounded retry loop (was unbounded recursion — could stack-overflow when many slots failed back-to-back)
	local MaxAttempts = 50
	local random_pickup, pickup_model, new_position, size, sx, sz, pickup_area, cast

	for _attempt = 1, MaxAttempts do
		random_pickup = self:get_random_pickup()
		new_position = self:get_pickup_position()

		pickup_model = RS_Pickups:FindFirstChild(random_pickup.Name)

		if not pickup_model then
			task.wait()
			continue
		end

		size = pickup_model:GetExtentsSize()
		sx, sz = size.X, size.Z
		pickup_area = Vector2.new(sx, sz).Magnitude

		cast = workspace:Raycast(new_position, Vector3.new(0, -400, 0), self.raycast_params)

		if not cast then
			task.wait()
			continue
		end

		if cast.Instance.Name ~= "Grass" then
			task.wait()
			continue
		end

		if self:get_pickup_in_radius(new_position, pickup_area) then
			task.wait()
			continue
		end

		break
	end

	if not cast or cast.Instance.Name ~= "Grass" then
		-- Could not find a valid slot this round; will retry on the next respawn timer.
		return
	end
	
	local new_model = pickup_model:Clone()
	new_model.Parent = Pickups
	
	new_model:PivotTo(
		CFrame.new(
			cast.Position
		) * CFrame.Angles(
			0,
			math.rad(math.random(-180, 180)),
			0
		)
	)
	
	local BillboardGui = script.BillboardGui:Clone()
	BillboardGui.Parent = new_model.PrimaryPart
	BillboardGui.Enabled = false
	
	BillboardGui.StudsOffset = Vector3.new(0, size.Y + 1, 0)
	
	new_model:SetAttribute(
		"Health",
		random_pickup.Health
	)
	
	new_model:SetAttribute(
		"MaxHealth",
		random_pickup.Health
	)
	
	new_model:SetAttribute(
		"Region",
		self.region
	)

	local Amount, Currency = unpack(random_pickup.Reward)
	
	new_model:SetAttribute("Currency", Currency)
	new_model:SetAttribute("Amount", Amount)
	
	table.insert(
		self.pickups,
		new_model
	)
	
	new_model.AttributeChanged:Connect(function()
		
		if not new_model.PrimaryPart then
			return
		end
		
		Network:PostAll(
			"PlayBreakEffect",
			new_model:GetExtentsSize(),
			new_model.PrimaryPart.Position
		)
		
		if new_model:GetAttribute("Health") <= 0 then
			return self:destroy_model(new_model)
		end
	end)
	
	return new_model
end

function PickupService:generate_pickups()
	local region = self.region
	local region_data = require(script:FindFirstChild(region))
	
	for i = 1, region_data.PickupCount do
		self:generate_new_pickup()
	end
end

function PickupService.new(region)
	local self = setmetatable({
		region = region,
		pickup_area = PickupRegions:FindFirstChild(region),
		pickups = {}
	}, PickupService)
	
	self:generate_pickups()
	
	return self
end

for i, region in workspace.PickupRegions:GetChildren() do
	PickupService.new(region.Name)
end

return PickupService