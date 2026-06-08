local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Roblox = Services.get("Roblox")
local DataService = Services.get("DataService")
local PetModule = Services.get("PetModule")
local PetService = Services.get("PetService")
local RunService = Services.get("RunService")
local TweenV2 = Services.get("TweenV2")
local SoundService = Services.get("SoundService")
local AnimationService = Services.get("AnimationService")
local Network = Services.get("Network")
local ImageModule = Services.get("ImageModule")
local NumberUtil = Services.get("RenderUtil").Number
local GuiService = Services.get("GuiService")

local Interface = GuiService and GuiService.Interface
local Frames = Interface and Interface.Frames
local WheelFrame = Frames and Frames.WheelFrame

local Player = Players.LocalPlayer

local Camera = workspace.CurrentCamera

local Wheels = workspace.Wheels

local WheelService = {}
WheelService.Prizes = require(script.Prizes)
WheelService.WheelInfo = {}

local PrizeRotations = {
	[1] = -24,
	[2] = -68,
	[3] = -113,
	[4] = -156,
	[5] = -202,
	[6] = -247,
	[7] = -289,
	[8] = -338,
}

function WheelService:ExitWheel()

	if self.WheelInfo.Spinning then
		return
	end

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	Camera.CameraType = Enum.CameraType.Custom

	if Humanoid then
		Humanoid.WalkSpeed = 32
	end

	for _, v in Roblox:GetDescendantsOfClass(Character, "BasePart") do
		if v.Name == "HumanoidRootPart" then
			continue
		end

		v.Transparency = 0
	end

	local PlayerTitle = Character:FindFirstChildOfClass("BillboardGui")

	if PlayerTitle then
		PlayerTitle.Enabled = true
	end

	PetService:HidePlayerPets(false)

	table.clear(self.WheelInfo)
end

function WheelService:EnterWheel(WheelName)
	local WheelModel = Wheels:FindFirstChild(WheelName)

	if not WheelModel then
		return
	end

	Camera.CameraType = Enum.CameraType.Scriptable

	Camera.CFrame = CFrame.new(
		(WheelModel:GetPivot() * CFrame.new(0, 6, -10)).Position,
		WheelModel.Wheel.Position
	)

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	if Humanoid then
		Humanoid.WalkSpeed = 0
	end

	for _, v in Roblox:GetDescendantsOfClass(Character, "BasePart") do
		v.Transparency = 1
	end

	local PlayerTitle = Character:FindFirstChildOfClass("BillboardGui")

	if PlayerTitle then
		PlayerTitle.Enabled = false
	end

	PetService:HidePlayerPets(true)

	self.WheelInfo.WheelModel = WheelModel
end

function WheelService:GetClosestWheel(Player)

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Origin = Character:GetPivot()

	local Position = Origin.Position

	local NearestWheel = {nil, math.huge}

	for _, Wheel in Wheels:GetChildren() do
		local WheelPivot = Wheel:GetPivot()
		local WheelPosition = WheelPivot.Position

		local Distance = (WheelPosition - Position).Magnitude

		if NearestWheel[2] < Distance then
			continue
		end

		NearestWheel = {Wheel, Distance}
	end

	return NearestWheel[1]
end

function WheelService:PickRandomPrize(Prizes)
	local TotalWeight = 0

	for _, Prize in Prizes do
		TotalWeight += Prize.chance or (100/#Prizes)
	end

	local RandomWeight = math.random() * TotalWeight
	local CurrentWeight = 0

	for i, Prize in Prizes do
		CurrentWeight += Prize.chance or (100/#Prizes)

		if CurrentWeight < RandomWeight then
			continue
		end

		return i, Prize
	end
end

function WheelService:initWheel(Wheel)
	local PrizeData = self.Prizes[Wheel.Name]

	for i, Prize in PrizeData do
		local WheelSpinPart = Wheel:WaitForChild("Wheel")

		local SurfaceGui = WheelSpinPart.SurfaceGui
		local Content = SurfaceGui.Content

		local item = Content.Items:FindFirstChild(i)
		local i_content = item.Content

		local prize = Prize.prize
		local chance = Prize.chance or (100 / #PrizeData)

		i_content.EggIcon.Image = ImageModule(prize)
		i_content.Amount.Text = ("%s%s"):format(NumberUtil:ReplaceDecimals(chance, 2), "%")
	end
end

if RunService:IsServer() then
	Network:Bind("SpinWheel", function(Player, Wheel)
		local PlayerData = DataService:GetPlayerData(Player) or {}

		if (PlayerData.Tickets or 0) <= 0 then
			return Network:Post(Player, "DisplayNewItem", {
				Type = "Message",
				Message = "You do not have any tickets!",
				TextColor = Color3.fromRGB(255, 60, 60)
			})
		end

		PlayerData.Tickets -= 1

		DataService:SendUpdateSignal(Player, "Tickets")

		local NearestWheel = WheelService:GetClosestWheel(Player)

		if NearestWheel ~= Wheel then
			return
		end

		local PrizeData = WheelService.Prizes[Wheel.Name]
		local PrizeIndex, RandomPrize = WheelService:PickRandomPrize(PrizeData)

		if RandomPrize._type == "Pet" then
			-- FIX: DataService:GivePet (not AddPet), and use Name/Tier (not PetName/PetTier)
			DataService:GivePet(Player, {
				Name = RandomPrize.prize,
				Tier = RandomPrize.tier or "Normal",
				CantAutoDelete = true
			})
		elseif RandomPrize._type == "Currency" then
			DataService:GiveCurrency(
				Player,
				RandomPrize.prize,
				RandomPrize.amount
			)
		end

		return PrizeIndex, RandomPrize
	end)
else
	for _, Wheel in Wheels:GetChildren() do
		WheelService:initWheel(Wheel)
	end
end

function WheelService:SpinWheel()
	if not self.WheelInfo.WheelModel or self.WheelInfo.Spinning then
		return
	end

	local WheelModel = self.WheelInfo.WheelModel
	local WheelSpinPart = WheelModel.Wheel

	local PrizeIndex, Prize = Network:Invoke("SpinWheel", WheelModel)

	if not PrizeIndex or not Prize then
		return
	end

	self.WheelInfo.Spinning = true

	WheelFrame.Spin.Content.Letter.Text = "Spinning..."
	WheelFrame.Exit.Content.Letter.Text = "Wait..."

	local SurfaceGui = WheelSpinPart.SurfaceGui
	local Content = SurfaceGui.Content

	math.randomseed(tick())

	local FinalRotation = PrizeRotations[PrizeIndex]

	local FullSpins = math.random(4, 6)

	local NextRotation = (FullSpins * 360) + FinalRotation + math.random(-20, 20)

	local SpinTime = FullSpins
	local StartTime = tick()

	self.WheelInfo.Connection = RunService.Heartbeat:Connect(function()
		local Elapsed = tick() - StartTime

		if Elapsed >= SpinTime then
			self.WheelInfo.Connection:Disconnect()
			self.WheelInfo.Connection = nil

			Content.Rotation = NextRotation

			SoundService:PlaySound("Sparkle", .5)
			SoundService:PlaySound("Reveal", .2)

			AnimationService:AnimateUI_Open(
				Content.Items:FindFirstChild(PrizeIndex),
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out,
				0.6, 1, 1.75
			)

			local PetData = PetModule[Prize.prize]

			if Prize._type == "Currency" then
				Network:Fetch("PlayEffectDisplayCurrency", Prize.prize, Prize.amount or 0)
			end

			Network:Fetch("DisplayItem", {
				Prize.prize,
				Prize.amount,
				PetData and PetData.Rarity
			})

			task.delay(1, function()
				TweenV2:Create(
					Content, 
					TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
					{ Rotation = 0 }
				):Play()

				task.wait(.5)

				self.WheelInfo.Spinning = false

				WheelFrame.Spin.Content.Letter.Text = "Spin"
				WheelFrame.Exit.Content.Letter.Text = "Exit"
			end)

			return
		end

		local Progress = Elapsed / SpinTime
		local EasedProgress = 1 - math.pow(1 - Progress, 3)
		local CurrentRotationX = NextRotation * EasedProgress

		Content.Rotation = CurrentRotationX
	end)
end

return WheelService
