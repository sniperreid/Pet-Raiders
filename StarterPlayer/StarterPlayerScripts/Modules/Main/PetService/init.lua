local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules
local Services = require(Modules.Services)

local FX = ReplicatedStorage.Assets.FX

local Network = Services.get("Network")
local InputManager = Services.get("InputManager")
local Short = Services.get("Short")
local EasyRender = Services.get("RenderUtil").Number
local FireworkService = Services.get("FireworkService")

local PlayerClass = require(script.Player)
PlayerClass.Players = {}

local Camera = workspace.CurrentCamera

local PetService = {}
PetService.target_range = 2500
PetService.attack_speed = 1.5
PetService.send_all_tick = .2
PetService.Cache = {}

local pets_visible = true

function PetService:HidePlayerPets(State)
	pets_visible = not State
	
	for i, Player in PlayerClass.Players do

		Player.Pets_Visible = pets_visible

	end
end

function PetService.Unequip(Player, PetData)
	local Cache = PetService.Cache
	local UserId = Player.UserId
	
	local Pets = Cache[UserId].Pets
	
	for i, Pet in PetService.get_local_pets() do
		if Pet.Pet.ID ~= PetData.ID then
			continue
		end
		
		PetService.toggle_target(Pet, false)
	end
	
	Network:Post(
		"SetPetTarget",
		PetData.ID,
		nil
	)

	return Cache[UserId]:UnequipPet(PetData)
end

function PetService.Equip(Player, PetData)
	local Cache = PetService.Cache
	local UserId = Player.UserId
	
	if not Cache[UserId] then
		PetService.new(Player)
	end
	
	return Cache[UserId]:EquipPet(PetData)
end

function PetService.new(Player)
	local Cache = PetService.Cache
	local UserId = Player.UserId
	
	Cache[UserId] = PlayerClass.new(Player)
	Cache[UserId].Pets_Visible = pets_visible
	
	PlayerClass.Players[UserId] = Cache[UserId]
end

function PetService.destroy(Player)
	local Cache = PetService.Cache
	local UserId = Player.UserId
	
	if not Cache[UserId] then
		return
	end
	
	Cache[UserId]:Destroy()
	Cache[UserId] = nil
	
	PlayerClass.Players[UserId] = nil
end

function PetService.get_local_pets(Player)
	local Player = Player or Players.LocalPlayer
	local UserId = Player.UserId

	return (PetService.Cache[UserId] or {}).Pets or {}
end

function PetService.toggle_target(Pet, State)
	if not Pet then
		return
	end
	
	local Target = Pet.Target
	
	if not Target then
		return
	end
	
	if not Target.PrimaryPart then
		return
	end
	
	if not State then
		return
	end
	
	if not Target.PrimaryPart:FindFirstChild("BillboardGui") then
		return
	end
	
	Target.PrimaryPart.BillboardGui.Enabled = State
end

function PetService.update_pickup(pickup)
	local PrimaryPart = pickup and pickup.PrimaryPart
	
	if not PrimaryPart then
		return
	end
	
	local Health = pickup:GetAttribute("Health")
	local MaxHealth = pickup:GetAttribute("MaxHealth")
	
	if not Health or not MaxHealth then
		return
	end
	
	if pickup:GetAttribute("LastHealth") == Health then
		return
	end
	
	pickup:SetAttribute("LastHealth", Health)

	local Scale = Health / MaxHealth

	local BillboardGui = PrimaryPart:WaitForChild("BillboardGui")
	local Content = BillboardGui:FindFirstChild("Content")
	
	if not Content then
		return
	end

	BillboardGui.Enabled = Health < MaxHealth

	local Label = Content:WaitForChild("Label")
	local Progress = Content:WaitForChild("Progress")

	local Bar = Progress.Bar
	local Curr = Progress.Current
	local Max = Progress.Max

	Label.Text = pickup.Name

	Curr.Text = Short:AddCommas(EasyRender:ReplaceDecimals(
		Health,
		1
	))

	Max.Text = Short:AddCommas(EasyRender:ReplaceDecimals(
		MaxHealth,
		1
	))

	TweenService:Create(
		Bar,
		TweenInfo.new(.1, Enum.EasingStyle.Sine),
		{
			Size = UDim2.fromScale(Scale, 1)
		}
	):Play()
end

function PetService.update_target(Pet)
	local Target = Pet.Target
	local PrimaryPart = Target and Target.PrimaryPart
	
	if not PrimaryPart then
		return
	end
	
	PetService.update_pickup(Target)
end
	
function PetService.get_next_pet(whitelist)
	local pets = PetService.get_local_pets()
	
	for i, pet in pets do
		if pet.Target then
			continue
		end
		
		return pet
	end
	
	for i, pet in pets do
		if pet.Target ~= whitelist then
			return pet
		end
	end
	
	if whitelist then
		for i, pet in pets do	
			PetService.toggle_target(pet, false)
			
			pet.Target = nil
			
			Network:Post(
				"SetPetTarget",
				pet.Pet.ID,
				nil
			)
		end
		
		return
	end
	
	return pets[1]
end

local target_params = RaycastParams.new()
target_params.FilterType = Enum.RaycastFilterType.Include
target_params.FilterDescendantsInstances = {workspace.Pickups, workspace.Bosses.Models}

function PetService.raycast_to_mouse()
	local MousePosition = UserInputService:GetMouseLocation()
	
	local mouseRay = Camera:ViewportPointToRay(
		MousePosition.X,
		MousePosition.Y
	)
	
	local cast = workspace:Raycast(
		mouseRay.Origin,
		mouseRay.Direction * PetService.target_range,
		target_params
	)
	
	return cast
end

function PetService.select_target(pet, target)
	local PlayerData = Network:Fetch("GetClientData")
	local Areas = PlayerData.Areas
	
	local Region = target and target:GetAttribute("Region")
	
	if Region and not table.find(Areas, Region) then
		return
	end
	
	local last_target = pet.Target
	local target_count = 0
	
	for i, new_pet in PetService.get_local_pets() do
		if new_pet == pet then
			continue
		end
		
		target_count += new_pet.Target == last_target and 1 or 0
	end
	
	if target_count <= 0 then
		PetService.toggle_target(pet, false)
	end
	
	pet.LastAttack = tick()
	pet.Target = target

	PetService.toggle_target(pet, true)
	PetService.update_target(pet)

	Network:Post(
		"SetPetTarget",
		pet.Pet.ID,
		target
	)
end

function PetService.register_input(send_all)
	local target = PetService.raycast_to_mouse()
	local coin = target and target.Instance.Parent

	if not coin then
		return
	end
	
	local next_pet = PetService.get_next_pet(coin)
	
	if send_all then
		for i, next_pet in PetService.get_local_pets() do
			PetService.select_target(next_pet, coin)
		end
		
		return
	end
	
	if not next_pet then
		return
	end
	
	local is_boss = coin:IsDescendantOf(workspace.Bosses.Models)
	
	if is_boss and (next_pet.Pet.Enchant ~= "Warrior" and next_pet.Pet.Enchant ~= "Raider") then
		return
	end
	
	if is_boss and coin.Parent.Name ~= "Models" then
		coin = coin.Parent
	end

	PetService.select_target(next_pet, coin)
end

function PetService.damage_targets()
	
	for i, pickup in workspace.Pickups:GetChildren() do
		PetService.update_pickup(pickup)
	end
	
	for i, pet in PetService.get_local_pets() do
		if not pet.Target then
			continue
		end
		
		if not pet.Target.Parent then
			PetService.toggle_target(pet, false)
			
			pet.Target = nil
			
			Network:Post(
				"SetPetTarget",
				pet.Pet.ID,
				nil
			)
			
			continue
		end
		
		PetService.update_target(pet)
		
		if pet.isMoving then
			continue
		end
		
		if (tick() - pet.LastAttack) < PetService.attack_speed then
			continue
		end
		
		pet.LastAttack = tick()

		Network:Post(
			"AttackTarget",
			pet.Pet.ID
		)
	end
end

function PetService.SetTarget(Player, PetID, Target)
	
	local Cache = PetService.Cache
	local UserId = Player.UserId
	
	if not Cache[UserId] then
		return
	end
	
	local Pets = PetService.get_local_pets(Player)
	
	for i, Pet in Pets do
		if Pet.Pet.ID ~= PetID then
			continue
		end

		Pet.Target = Target
		
		Cache[UserId]:UpdateOffsets(Player, Target)
		
		break
	end
end

function PetService.PlayAttack(Player, PetId)
	for i, Pet in PetService.get_local_pets(Player) do
		if Pet.Pet.ID ~= PetId then
			continue
		end

		Pet.Attacking = true
	end
end

PetService.target_keybinds = {
	PC = Enum.UserInputType.MouseButton1,
	XBOX = Enum.KeyCode.ButtonR2,
	Mobile = Enum.UserInputType.Touch
}

Players.PlayerAdded:Connect(PetService.new)
Players.PlayerRemoving:Connect(PetService.destroy)

for i, Player in Players:GetPlayers() do
	PetService.new(Player)
end

Network:Bind("SpawnPet", PetService.Equip)
Network:Bind("DespawnPet", PetService.Unequip)
Network:Bind("SetTarget", PetService.SetTarget)
Network:Bind("PlayAttack", PetService.PlayAttack)

Network:Bind("PlayLevelUpEffect", function(Player, PetId)
	local Pet
	
	for i, _pet in PetService.get_local_pets(Player) do
		if _pet.Pet.ID ~= PetId then
			continue
		end
		
		Pet = _pet
		
		break
	end
	
	if not Pet then
		return
	end
	
	local Fireworks = FireworkService.new(
		Pet.Model:GetPivot()
	)
	
	Fireworks:Explode(5)
end)

Network:Bind("PlayBreakEffect", function(size, position)
	if (Camera.CFrame.Position - position).Magnitude > 100 then
		return
	end
	
	local Break = FX.Break:Clone()
	local Attachment = Break:FindFirstChildOfClass("Attachment")

	Break.Parent = workspace.Terrain
	Break.Position = position + Vector3.new(0, size.Y/2, 0)
	
	Debris:AddItem(Break, 3)

	for i, v in Attachment:GetChildren() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount") * (size.Magnitude / 6))
		end
	end
end)

local MousePressStart = 0

for Device, Bind in PetService.target_keybinds do
	InputManager.Begin(
		"BeginPressTargetForPet" .. Device,
		Bind,
		true,
		function()
			MousePressStart = tick()
		end
	)
	
	InputManager.End(
		"ReleaseTargetForPet" .. Device,
		Bind,
		true,
		function()
			PetService.register_input(
				(tick() - MousePressStart) >= PetService.send_all_tick
			)
		end
	)
end

RunService.RenderStepped:Connect(PetService.damage_targets)

return PetService