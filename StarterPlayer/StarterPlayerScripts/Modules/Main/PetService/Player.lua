local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Services = require(Modules.Services)

local Network = Services.get("Network")
local PetClass = Services.get("PetClass")
local MaidClass = Services.get("MaidClass")
local PetBuffService = Services.get("PetBuffService")

local Player = {}
Player.__index = Player

function Player:Destroy()
	if self.Maid then
		self.Maid:Clean()
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

function Player:GetAllPets()
	
	local all_pets = {}
	
	for i, plr in Player.Players do
		local pets = plr.Pets
		
		for a, b in pets do
			table.insert(all_pets, b)
		end
		
	end
	
	return all_pets
end

function Player:GetPet(PetID)
	for i, Pet in self.Pets do
		if Pet.Pet.ID == PetID then
			return i, Pet
		end
	end
end

function Player:UpdateOffsets(User, SelectedTarget)
	
	local User = User or Players.LocalPlayer
	
	local Pets = self.Pets
	local NumPets = #self.Pets
	
	local AllPets = self:GetAllPets()
	
	local TargetCounts = {}
	
	for i, Pet in AllPets do
		local Owner = Pet.Player
		local Target = Pet.Target or Owner.UserId

		if SelectedTarget and typeof(Target) == "number" and Target ~= User.UserId then
			continue
		end
		
		TargetCounts[Target] = TargetCounts[Target] or {}
		
		table.insert(
			TargetCounts[Target],
			Pet
		)
	end
	
	local RNG = Random.new()

	for model, target in TargetCounts do
		local AngleOffset = (2 * math.pi) / #target

		for Index, Pet in target do
			if not Pet.Model then
				continue
			end

			local Target = Pet.Target

			local PetSize = Pet.Model:GetExtentsSize()
			
			local t_size = Target and Target:GetExtentsSize()
			local n_size = t_size or PetSize
			
			local Offset = 5
			
			local Radius = Offset + math.ceil(math.max(n_size.X, n_size.Y, n_size.Z) / Offset)
			local Angle = (Index - 1) * AngleOffset

			Pet.Offset = Vector3.new(
				math.cos(Angle) * Radius,
				0,
				math.sin(Angle) * Radius
			)
		end
	end
end

function Player:UnequipPet(PetData)
	local PetID = PetData.ID
	local Pets = self.Pets
	local id, Pet = self:GetPet(PetID)

	if not Pet then
		return
	end

	Pet:Destroy()
	Pets[id] = nil

	self:UpdateOffsets()
end

function Player:EquipPet(PetData)
	local PetID = PetData.ID
	local Pets = self.Pets
	
	local id, Pet_Exists = self:GetPet(PetID)
	
	if Pet_Exists then
		
		Pet_Exists.Pet = PetData
		Pet_Exists.Stats = PetBuffService:GetLocalBuff(PetData)
		
		return Pet_Exists:UpdatePetTitle()
	end
	
	local Pet = self.Maid:GiveTask(
		PetClass.new(
			self.Player,
			PetData
		)
	)
	
	Pet.Stats = PetBuffService:GetLocalBuff(PetData)

	table.insert(
		Pets,
		Pet
	)
	
	Pet:Spawn()
	
	self:UpdateOffsets()
end

function Player:render_pets(...)
	for PetID, Pet in self.Pets do
		if not Pet.Render then
			continue
		end
		
		if not self.Pets_Visible then
			Pet:Despawn()
			
			continue
		end
		
		Pet:Render(...)
	end
end

function Player:init()
	local Player = self.Player
	local Character = Player.Character
	
	if Player == Players.LocalPlayer then
		Network:Post("LoadPets")
	end

	local LastPosition = nil
	
	self.Maid:GiveTask(
		RunService.RenderStepped:Connect(function(dt)
			local Character = Player.Character
			
			if not Character then
				return
			end
			
			local Humanoid = Character:FindFirstChild("Humanoid")
			local Health = Humanoid and Humanoid.Health or 0
			
			if Health <= 0 then
				return
			end
			
			local Pivot = Health > 0 and Character:GetPivot() or CFrame.new()
			
			local LastPos = LastPosition or Pivot.Position
			local NextPosition = Pivot.Position
			
			local dist = (LastPos - NextPosition).Magnitude
			
			LastPosition = Pivot.Position
			
			if dist > 20 then
				for i, Pet in self.Pets do
					Pet.Position = NextPosition
				end
				
				return
			end
			
			self:render_pets(dt)
		end)
	)
end

function Player.new(Subject)
	local self = setmetatable({
		Pets = {},
		Player = Subject,
		Maid = MaidClass.new()
	}, Player)
	
	self:init()
	
	return self
end

return Player