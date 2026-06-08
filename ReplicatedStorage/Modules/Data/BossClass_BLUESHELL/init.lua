--!strict

--[[

INHERITED CLASS:

SHOULD HAVE DEFAULTS, HEALTH, MAXHEALTH, TAKEDAMAGE, ETC.

]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Bosses = Assets.Bosses

local Services = require(Modules.Services)

local Network = Services.get "Network"

local Types = require(script.Types)
local Data = require(script.Data)
local Cycles = require(script.Cycles)

local BossClass = {}
BossClass.__index = BossClass

function BossClass.new(Player, Name)
	assert(Data[Name], ("ay bruh, %s aint a boss bruh."):format(Name))
	
	local BossData = Data[Name] :: Types.Data
	
	return setmetatable({
		Player = Player,
		Name = Name,
		Health = BossData.Health,
		MaxHealth = BossData.Health,
		Speed = BossData.Speed
	} :: Types.Meta, BossClass)
end

function BossClass:ToVector2(x)
	return Vector2.new(
		x.X,
		x.Z
	)
end

function BossClass:Raycast(Position: Vector3)
	local Position = Position or self.Position

	if not Position then
		return Vector3.new(), Vector3.new()
	end

	local RayOrigin = Position + Vector3.new(0, 500, 0)
	local RayDirection = Vector3.new(0, -1000, 0)

	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Include
	RaycastParameters.FilterDescendantsInstances = { workspace.Assets }
	RaycastParameters.RespectCanCollide = true

	local RaycastResult = workspace:Raycast(RayOrigin, RayDirection, RaycastParameters)

	if not RaycastResult then
		return Position, Vector3.new()
	end

	return RaycastResult.Position, RaycastResult.Instance.Orientation, RaycastResult.Normal
end

function BossClass:Spawn()
	if self.Model then
		return
	end
	
	local Model = Bosses:FindFirstChild(self.Name)
	
	self.Model = Model:Clone()
	self.Model.Parent = workspace
	
	--Cycles.new(self)
	
	local Player = self.Player
	
	Network:Post(
		Player,
		"UpdateBoss",
		self
	)
	
	task.spawn(function()
		while task.wait() do
			local Character = Player and Player.Character
			
			if not Character then
				continue
			end
			
			local _origin = Character:GetPivot()
			
			self:MoveTo()
			
			local MovePoint = self.MoveToPoint :: Vector3
			
			if not MovePoint then
				continue
			end
			
			local Pivot = self.Model:GetPivot() :: CFrame
			local Next_Position, TRotation, TNormal = self:Raycast(MovePoint)
			local FlatOffset = self:ToVector2(MovePoint - Pivot.Position)
			local isMoving = FlatOffset.Magnitude > .1

			MovePoint = Vector3.new(
				MovePoint.X,
				Next_Position.Y,
				MovePoint.Z
			)

			local distance = (Pivot.Position - MovePoint).Magnitude
			
			if distance <= 10.1 then
				continue
			end
			
			local speed = self.Speed :: number
			
			local t = (speed * (1/20)) / distance
			
			local EndP = Pivot * CFrame.new(0, 0, -distance)
			
			self.Position = (self.Position or self.Model:GetPivot().Position):Lerp(
				Next_Position,
				t
			)
			
			local Direction = Vector3.new(
				_origin.X - Pivot.X,
				0,
				_origin.Z - Pivot.Z
			).Unit
			
			if isMoving then
				Direction = Vector3.new(
					FlatOffset.X,
					0,
					FlatOffset.Y
				)
			end

			self.Turn = (self.Turn or CFrame.new()):Lerp(
				CFrame.lookAt(Vector3.new(), Direction),
				.1
			)
			
			self.Model:PivotTo(
				CFrame.new(self.Position) * self.Turn
			)
		end
	end)
end

function BossClass:MoveTo()
	local Player = self.Player
	local Character = Player and Player.Character
	
	if not Character then
		return
	end
	
	local Pivot = Character:GetPivot()
	local Origin = self.Model:GetPivot()
	
	local lookP = CFrame.new(
		Pivot.Position,
		Vector3.new(Origin.X, Pivot.Y, Origin.Z)
	).Position
	
	self.MoveToPoint = lookP + Vector3.new(0, 0, -10)
end

function BossClass:TakeDamage(Damage)
	local NewDamage = math.clamp(
		Damage,
		0,
		self.Health
	)
	
	self.Health -= NewDamage
	
	Network:Post(
		self.Player,
		"UpdateBoss",
		"Health",
		self.Health
	)
end

return BossClass