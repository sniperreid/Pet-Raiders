local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules
local Services = require(Modules.Services)

local Pets = Assets.Pets

local PetModule = Services.get("PetModule")
local Network = Services.get("Network")
local PetColorService = Services.get("PetColorService")
local PetBuffService = Services.get("PetBuffService")
local PetLevelService = Services.get("PetLevelService")
local TextAnimationService = Services.get("TextAnimationService")
local Short = Services.get("Short")

local Particle = script.Pet_Running_Particle

local Pets_Folder = Instance.new("Folder", workspace)
Pets_Folder.Name = "Pets"

local RNG = Random.new()
local Camera = workspace.CurrentCamera

local Max_Camera_Distance = 150

local Min_dt = 0.00001
local Max_dt = 1

local PetClass = {}
PetClass.__index = PetClass
PetClass.TitleSize = Vector2.new(1.75, 1.25)

function PetClass:Destroy()
	if self.Model then
		self.Model:Destroy()
		self.Model = nil
	end
	
	if self.Owned_Radius then
		self.Owned_Radius:Destroy()
		self.Owned_Radius = nil
	end
	
	if self.Attack_Radius then
		self.Attack_Radius:Destroy()
		self.Attack_Radius = nil
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

function PetClass.new(Player, Pet)
	local self = setmetatable({
		Player = Player,
		Pet = Pet,
		Visible = true,
		
		LastAttack = tick(),
		
		Offset = Vector3.new(),
		Position = Vector3.new(),
		
		Twist = CFrame.new(),
		Animation = CFrame.new()
	}, PetClass)
	
	local PetModel = Pets:FindFirstChild(Pet.Name)
	
	if not PetModel then
		return self
	end
	
	local Model = PetModel:Clone()
	local PetSize = PetModel:GetExtentsSize()
	
	local new_model = PetColorService:Update(Model, Pet.Tier)
	
	if new_model then
		Model = new_model
	end
	
	self.Phase = RNG:NextNumber(-math.pi, math.pi)
	self.Radius = 4 + math.ceil(math.max(PetSize.X, PetSize.Y, PetSize.Z) / 4)

	self.Size = PetSize
	
	Model:SetAttribute("GUID", Pet.ID)
	Model:SetAttribute("Tier", Pet.Tier)
		
	self.Model = Model
	
	local ParticleEffect = Particle:Clone()
	ParticleEffect.Parent = Model.PrimaryPart
	
	local OwnedRadius = script.Pet_Owned_Radius:Clone()
	OwnedRadius.Parent = workspace.Terrain
	
	local AttackRadius = script.Pet_Owned_Radius:Clone()
	AttackRadius.Parent = workspace.Terrain
	AttackRadius.Name = "Pet_Attack_Radius"
	
	OwnedRadius.Decal.Color3 = Color3.fromRGB(0, 255, 0)
	AttackRadius.Decal.Color3 = Color3.fromRGB(255, 0, 0)
	
	self.Running_Particle = ParticleEffect
	self.Owned_Radius = OwnedRadius
	self.Attack_Radius = AttackRadius
	
	OwnedRadius.CFrame = Model:GetPivot()
	
	local n_size = math.ceil(math.max(self.Size.X, self.Size.Y, self.Size.Z))
	
	OwnedRadius.Size = Vector3.new(
		n_size + 1,
		.1,
		n_size + 1
	)
	
	AttackRadius.Size = OwnedRadius.Size
	
	self.target_attach1 = Instance.new("Attachment", OwnedRadius)
	self.target_attach2 = Instance.new("Attachment", OwnedRadius)
	
	self.target_attach1.WorldCFrame *= CFrame.Angles(0, 0, math.rad(90))
	self.target_attach2.WorldCFrame *= CFrame.Angles(0, 0, math.rad(90))
	
	self.target_beam = script.Pet_Target_Beam:Clone()
	self.target_beam.Parent = OwnedRadius
	
	self.target_beam.Attachment0 = self.target_attach1
	self.target_beam.Attachment1 = self.target_attach2
	
	self.target_beam.Enabled = false
	
	self.PetTitle = script.PetTitle:Clone()
	self.PetTitle.Parent = self.Model
	
	self.PetTitle.AlwaysOnTop = self.Player == Players.LocalPlayer
	self.PetTitle.Adornee = self.Model.PrimaryPart
	
	self:UpdatePetTitle()
	
	return self
end

function PetClass:UpdatePetTitle()
	local Pet = self.Pet
	local Model = self.Model
	
	local PetTitle = self.PetTitle
	
	local Size = self.Size
	
	local min_x = 8
	local min_y = 3

	local y_offset = Size.Y + 2
	
	local new_x = math.clamp(
		Size.X / 2,
		min_x,
		math.huge
	)
	
	local new_y = math.clamp(
		Size.Y / 2,
		min_y,
		math.huge
	)
	
	PetTitle.StudsOffset = Vector3.new(0, y_offset, 0)
	PetTitle.Size = UDim2.fromScale(new_x, new_y)

	local Title_Name = PetTitle.Pet_Name
	local Title_Level = PetTitle.Pet_Level
	local Title_Exp = PetTitle.Exp_Display
	
	local PetName = Pet.Name
	local PetTier = Pet.Tier
	local PetExp = Pet.Exp
	local PetLevel = Pet.Level
	
	local MaxExp = PetLevelService:GetMaxExp(Pet)
	
	local Scale = math.clamp(
		PetExp / MaxExp,
		0,
		1
	)
	
	Title_Name.Text = PetName
	Title_Level.Text = ("Lvl. %d"):format(PetLevel)
	Title_Exp.ExpBar.Size = UDim2.fromScale(Scale, 1)
	
	if PetTier ~= "Normal" then
		TextAnimationService:AnimateText(
			Title_Name,
			PetTier
		)
	end
	
end

function PetClass:ToVector2(x)
	return Vector2.new(
		x.X,
		x.Z
	)
end

function PetClass:CanRender()
	local Player = self.Player
	local Character = Player.Character
	local Pivot = Character:GetPivot()
	
	local dist = (Pivot.Position - Camera.CFrame.Position).Magnitude
	
	if dist > Max_Camera_Distance and Player ~= Players.LocalPlayer then
		return false
	end
	
	return true
end

function PetClass:Raycast(Position)
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

function PetClass:Render(dt)
	local Model = self.Model
	
	if not Model then
		return
	end
	
	local Player = self.Player
	local Character = Player.Character

	local PrimaryPart = Character and Character.PrimaryPart
	
	if not PrimaryPart then
		return self:Destroy()
	end
	
	local PlayerData = Network:Fetch("GetClientData")
	
	if not PlayerData then
		return
	end
	
	local Settings = PlayerData.Settings or {}

	local All_Visible = Settings["All Pets"]
	local Other_Visible = Settings["Other Pets"]

	if All_Visible == nil then
		All_Visible = true
	end

	if Other_Visible == nil then
		Other_Visible = true
	end
	
	local Despawning = false

	if not All_Visible then
		self:Despawn()
		
		Despawning = true
	end
	
	if not Other_Visible and Player ~= Players.LocalPlayer then
		self:Despawn()

		Despawning = true
	end

	if not self:CanRender() then
		self:Despawn()
		
		Despawning = true
	end
	
	local Target = self.Target
	
	self.Owned_Radius.Decal.Transparency = self.Player == Players.LocalPlayer and 0 or 1

	local p_target = Target or Character
	local Origin = Target and Target:GetPivot().Position or PrimaryPart.Position
	
	if not Despawning then
		self:Spawn()
	end

	local CurrentTime = tick()
	local PetData = PetModule[self.Model.Name]
	local State = PetData.State or "Walk"
	
	local Buffs = self.Stats
	
	local Speed = (Buffs.Speed or 1) * 2.25
	
	if Target and Target.Parent and Target.Parent.Parent == workspace.Bosses.Models then
		-- preset speed.
		Speed = 13
	end
	
	local Target = Vector3.new(Origin.X, 0, Origin.Z) + self.Offset
	local Next_Position, TRotation, TNormal = self:Raycast(Target)
	local Ground, GRotation, GNormal = self:Raycast(self.Position)
	local FlatOffset = self:ToVector2(Target - self.Position)
	local isMoving = FlatOffset.Magnitude > 0.05
	
	Target = Vector3.new(
		Target.X,
		Next_Position.Y,
		Target.Z
	)
	
	self.isMoving = isMoving
	
	self.Attack_Radius.Decal.Transparency = (self.Player == Players.LocalPlayer and self.Target and isMoving) and 0 or 1

	local Angle = (CurrentTime + self.Phase) % (math.pi * 2)
	local AnimationCFrame = CFrame.new()

	local Framerate = math.exp(-15 * dt)
	local FPS = 1 - Framerate

	local dist = FlatOffset.Magnitude
	local t = (Speed * dt) / dist

	local alpha = math.clamp(
		1 - (dist / 15),
		0,
		1
	)
	
	local min_p = 1
	local max_p = 1.4
	
	local s_p = math.clamp(min_p + (Speed / 10), min_p, max_p)

	local p = min_p + (s_p - min_p) * alpha
	
	local Sprinting = dist > 25
	local SpeedMul = Sprinting and 2 or 1
	
	if isMoving and State == "Walk" then
		local Number = 4
		
		local i_mi = 1
		local i_ma = 4
		
		local i_a = math.clamp(
			alpha * i_ma,
			i_mi - i_mi,
			i_ma - i_mi
		) + i_mi
		
		local AnimationIntensity = (Sprinting and .25 or .5) / i_a --math.clamp(FlatOffset.Magnitude / Number, 0, 1)
		local BobbleY = math.abs(math.sin(Angle * 10)) * 5 * AnimationIntensity
		local TiltR = math.rad(math.sin(Angle * 10)) * 50 * AnimationIntensity
		AnimationCFrame = CFrame.new(0, BobbleY, 0) * CFrame.Angles(0, 0, TiltR / 1.5)
	elseif State == "Fly" then
		AnimationCFrame = CFrame.new(0, 3, 0) * CFrame.Angles(math.rad(math.cos(Angle * 3)) * 8, 0, 0) + Vector3.new(0, math.sin(Angle * 3) * 0.5, 0)
	end

	local TwistCFrame

	if isMoving then
		
		local Direction = Vector3.new(
			FlatOffset.X,
			0,
			FlatOffset.Y
		)
		
		TwistCFrame = CFrame.lookAt(Vector3.new(), Direction)
		
		if self.Target then
			local a1 = self.target_attach1
			local a2 = self.target_attach2
			
			local Fixed = CFrame.new(Target + Vector3.new(0, .1, 0))
			
			local LookAtPet = CFrame.new(
				Fixed.Position,
				self.Model.PrimaryPart.Position
			) * CFrame.new(0, 0, -(self.Size.X + 1) / 2)

			a2.WorldCFrame = LookAtPet * CFrame.Angles(0, 0, math.rad(90))
		end
	else
		local Direction = Vector3.new(
			Origin.X - self.Position.X,
			0,
			Origin.Z - self.Position.Z
		).Unit

		TwistCFrame = CFrame.lookAt(Vector3.new(), Direction)
	end
	
	self.target_beam.Enabled = self.Attack_Radius.Decal.Transparency == 0

	if Sprinting then
		self.Running_Particle:Emit(1 * (self.Size.Magnitude / 5))
	end
	
	local _min = (Min_dt * SpeedMul) ^ p
	local _max = Max_dt > _min and Max_dt or _min

	-- This is for higher framerates
	-- Don't even ask why this happens.
	if _max >= _min then
		t = math.clamp(
			(t * SpeedMul) ^ p,
			_min,
			_max
		)
	else
		t = _max
	end
	
	
	self.Position = Vector3.new(
		self.Position.X,
		Ground.Y,
		self.Position.Z
	)

	self.Twist = self.Twist:Lerp(TwistCFrame, FPS)
	self.Animation = self.Animation:Lerp(AnimationCFrame, 0.25)
	self.Position = self.Position:Lerp(Next_Position, t)

	self.Owned_Radius.Position = self.Position
	self.Owned_Radius.Orientation = GRotation
	
	self.Attack_Radius.Position = Target
	self.Attack_Radius.Orientation = TRotation

	local beam_cframe = CFrame.new(self.Position) * self.Twist
	local TargetCFrame = beam_cframe * self.Animation
	
	local PetSize = math.ceil(math.max(self.Size.X, self.Size.Y, self.Size.Z))
	
	local Angle = 45
	local a_step = 10
	
	local n_angle = math.clamp(Angle * (a_step / PetSize), Angle - (a_step * 2), Angle + (a_step / 2))
	
	local JumpHeight = 1.25
	local LungeDistance = 1
	local Tilt = math.rad(15)
	
	local AttackStart = TargetCFrame
	
	local AttackPeak = TargetCFrame * CFrame.new(0, JumpHeight, -LungeDistance / 2) * CFrame.Angles(Tilt, 0, 0)
	local AttackEnd = TargetCFrame * CFrame.new(0, 0, -LungeDistance / 2)
	
--[[
	local AttackC0 = TargetCFrame * CFrame.new(0, 0, .2) * CFrame.Angles(math.rad(n_angle/4), 0, 0)
	local AttackC1 = TargetCFrame * CFrame.new(0, 0, -.75) * CFrame.Angles(math.rad(-n_angle), 0, 0)
]]
	
	local attack_t = (tick() - self.LastAttack) * 2

	if self.Attacking then
		local elapsed = tick() - self.LastAttack

		if elapsed < 0.15 then
			local alpha = elapsed / 0.15

			alpha = math.sin(alpha * math.pi * 0.5)
			
			TargetCFrame = AttackStart:Lerp(AttackPeak, alpha)
			
		elseif elapsed < 0.3 then
			local alpha = (elapsed - 0.15) / 0.15

			alpha = 1 - math.cos(alpha * math.pi * 0.5)
			
			TargetCFrame = AttackPeak:Lerp(AttackEnd, alpha)
			
		elseif elapsed < 0.5 then
			local alpha = (elapsed - 0.3) / 0.2

			TargetCFrame = AttackEnd:Lerp(TargetCFrame, alpha)
		else
			self.Attacking = false
		end
	end
	
	self.Model:PivotTo(TargetCFrame)
	
	local Fixed = beam_cframe * CFrame.new(0, .1, -(self.Size.X + 1) / 2)
	
	self.target_attach1.WorldCFrame = Fixed * CFrame.Angles(0, 0, math.rad(90))
end

function PetClass:is_parented()
	for i, Pet in Pets_Folder:GetChildren() do
		local GUID = Pet:GetAttribute("GUID")
		
		if GUID ~= self.Pet.ID then
			continue
		end
		
		return i
	end
end

function PetClass:Spawn()
	local Model = self.Model
	local Player = self.Player
	
	if not Model then
		return
	end
	
	if self:is_parented() then
		return
	end
	
	Model.Parent = Pets_Folder
	
	if self.Target then
		return
	end
	
	self.Position = Player.Character:GetPivot().Position
end

function PetClass:Despawn()
	local Model = self.Model

	if not Model then
		return
	end

	if not self:is_parented() then
		return
	end

	Model.Parent = nil
end

return PetClass