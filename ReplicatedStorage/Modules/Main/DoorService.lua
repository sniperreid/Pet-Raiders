local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local InputManager = Services.get("InputManager")
local ImageModule = Services.get("ImageModule")
local Short = Services.get("Short")
local GuiService = Services.get("GuiService")
local DataService = Services.get("DataService")
local AnimationService = Services.get("AnimationService")
local CurrencyModule = Services.get("CurrencyModule")
local RichTextService = Services.get("RichTextService")
local WorldService = Services.get("WorldService")
local PromptService = Services.get("PromptService")
local AreaService = Services.get("AreaService")
local TweenV2 = Services.get("TweenV2")
local SoundService = Services.get("SoundService")

local BossClass = Services.get "BossClass"
local ActivationService = Services.get "ActivationService"

local CameraController = Services.get "CameraController"
local Class = Services.get "_class"

local qBosses = BossClass.BossData
local vBosses = {}

for i, v in qBosses do
	vBosses[v.world] = v
end

qBosses = vBosses

local Player = Players.LocalPlayer
local PlayerGui = Player and Player.PlayerGui
local Interface = PlayerGui and PlayerGui.Interface
local Frames = Interface and Interface.Frames
local DoorOpenFrame = Frames and Frames.DoorOpenFrame

local PromptButton = script.PromptButton

local DoorService = {}
DoorService.PromptRange = 15
DoorService.Door_Costs = {}

for _, World in WorldService.Worlds do
	for _, Area in World.Areas do
		if Area.Amount then
			DoorService.Door_Costs[Area.Name] = {
				Area.Currency,
				Area.Amount
			}
		end
	end
end

function DoorService:get_cost(Door)
	return self.Door_Costs[Door]
end

function DoorService:trigger_prompt(Door)

	if not Door then
		return
	end
	
	if DoorOpenFrame.Visible then
		return
	end
	
	local Cost = self:get_cost(Door.Name)
	local Currency, Amount = unpack(Cost)
	
	GuiService:OpenFrame(DoorOpenFrame)
	
	DoorOpenFrame.Content.Disclaimer.Text = (
		"Would you like to unlock %s?"
	):format(Door.Name)

	DoorOpenFrame.Content.Cost.Icon.Image = ImageModule(Currency)
	DoorOpenFrame.Content.Cost.Amount.Text = Short:AddCommas(Amount)
	
	AnimationService:CreateButton(
		DoorOpenFrame.Content.Buttons.Unlock,
		function()
			local Unlocked = Network:Invoke("PurchaseDoor", Door.Name)
			
			if not Unlocked then
				return
			end
			
			GuiService:CloseFrame(DoorOpenFrame)
		end
	)
end

function DoorService:create_portal(Door)
	local Portal = script.Portal:Clone()
	Portal.Parent = Door
	Portal.Name = "Portal"
	
	local PriorDoor
	
	for i, World in WorldService.Worlds do
		if PriorDoor then break end
		
		for i, Area in World.Areas do
			if Area.Name == Door.Name then
				PriorDoor = World.Areas[i - 1].Name
				
				break
			end
		end
	end
	
	if qBosses[PriorDoor] then
		local Activation = Portal:WaitForChild("Activation")
		Activation.Name = qBosses[PriorDoor].name .. "BossFight"
	
		ActivationService:GiveActivation(Activation)
	end

	local DoorCFrame = Door:GetPivot()
	local ForwardOffset = -DoorCFrame.LookVector * 21.5
	local UpOffset = Vector3.new(0, 20, 0)

	local StartPosition = DoorCFrame.Position + ForwardOffset + UpOffset
	local Rotation = DoorCFrame - DoorCFrame.Position

	local PortalCFrame = CFrame.new(StartPosition) * Rotation
	
	Portal:PivotTo(PortalCFrame)

	return Portal
end

function DoorService:impact_portal(Portal, StartY)
	local PortalCFrame = Portal:GetPivot()
	local TargetY = 93.5
	local Duration = 0.35
	local Elapsed = 0
	local Impacted = false

	task.wait(1)

	self.Connection = RunService.RenderStepped:Connect(function(Delta)
		Elapsed += Delta

		local Alpha = math.clamp(Elapsed / Duration, 0, 1)
		local Progress = 1 - math.pow(2, -10 * Alpha)
		local NewY = StartY + (TargetY - StartY) * Progress

		Portal:PivotTo(
			CFrame.new(
				PortalCFrame.Position.X,
				NewY,
				PortalCFrame.Position.Z
			) * PortalCFrame.Rotation
		)

		if not Impacted and Alpha >= 0.9 then
			Impacted = true

			self:bounce_portal(Portal, NewY, PortalCFrame.Rotation)
		end

		if Alpha >= 1 then
			self.Connection:Disconnect()
			self.Connection = nil
		end
	end)
end

function DoorService:bounce_portal(Portal, BaseY, Rotation)
	local Peak = BaseY + 2
	local Duration = 0.15
	local Elapsed = 0

	RunService:BindToRenderStep("PortalBounce", 201, function(Delta)
		Elapsed += Delta
		local Alpha = math.clamp(Elapsed / Duration, 0, 1)
		local Progress = math.sin(Alpha * math.pi)
		local BounceY = BaseY + (Peak - BaseY) * (1 - Progress)

		Portal:PivotTo(
			CFrame.new(
				Portal:GetPivot().Position.X,
				BounceY,
				Portal:GetPivot().Position.Z
			) * Rotation
		)

		if Alpha >= 1 then
			RunService:UnbindFromRenderStep("PortalBounce")
			self:finalize_portal(Portal)
		end
	end)
end

function DoorService:finalize_portal(Portal)
	local Smoke = Assets.FX.Portal.Smoke.Attachment:Clone()
	Smoke.Parent = Portal.Dome

	for _, v in Smoke:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end

	task.delay(3, function()
		Smoke:Destroy()
	end)

	SoundService:PlaySound("Impact", .45)
	SoundService:PlaySound("Puff", .65)
	SoundService:PlaySound("Legendary", .45)
end

function DoorService:summon_portal(Door, SkipCutscene)
	if Door:FindFirstChild("Portal") then
		return
	end

	local Portal = self:create_portal(Door)
	
	if SkipCutscene then
		return Portal:PivotTo(
			CFrame.new(
				Vector3.new(Portal:GetPivot().Position.X, 95.906, Portal:GetPivot().Position.Z)
			)
		)
	end

	task.delay(0.1, function()
		self:impact_portal(Portal, Portal:GetPivot().Position.Y)
	end)

	local Camera = Class.new("CameraController")
	local CameraObject = workspace.CurrentCamera
	local StartPos = CameraObject.CFrame.Position
	local PortalPos = Door:GetPivot().Position + Vector3.new(0, -24, 21.5)
	local FinalPos = PortalPos - Door:GetPivot().LookVector * 10 + Vector3.new(0, 20, 50)
	local FinalCFrame = CFrame.new(FinalPos, PortalPos)

	Camera:PivotTo(CFrame.new(StartPos))
	Camera:UpdateIntensity("Dramatic", 0.25)
	Camera:Transform(FinalCFrame, 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	task.delay(3, function()
		Camera:Destroy()
		
		Portal:PivotTo(
			CFrame.new(
				Vector3.new(Portal:GetPivot().Position.X, 95.906, Portal:GetPivot().Position.Z)
			)
		)
	end)

	local Bass = Assets.Sounds.Bass:Clone()
	Bass.Parent = workspace.Terrain
	Bass.Volume = 1
	Bass:Play()

	task.delay(0.75, function()
		Bass:Destroy()
	end)
end

function DoorService:has_completed_all_except_boss(PlayerData, AreaName)
	local Tasks = PlayerData.Tasks or {}
	local BossTask = nil
	local Incomplete = {}

	for _, Task in Tasks do
		if Task.Area ~= AreaName then
			continue
		end

		if Task.Type == "Boss" then
			BossTask = Task
		end

		if not Task.Completed then
			table.insert(Incomplete, Task)
		end
	end
	
	if #Incomplete == 0 then
		return true, nil
	end

	if #Incomplete == 1 and Incomplete[1] == BossTask then
		return true, BossTask
	end

	return false
end

function DoorService:spawn_boss_portal_if_eligible(Door, Skip)
	local PlayerData = Network:Fetch("GetClientData")
	
	local Eligible, BossTask = self:has_completed_all_except_boss(PlayerData, Door.Name)

	if not Eligible then
		return
	end

	if not Door:FindFirstChild("Portal") then
		self:summon_portal(Door, Skip)
	end
end

function DoorService:update_tasks()
	local PlayerData = Network:Fetch("GetClientData") or {}
	local PlayerTasks = PlayerData.Tasks or {}
	
	local NextArea

	for _, v in PlayerTasks do
		if v.Area then
			NextArea = v.Area
			
			break
		end
	end
	
	if not NextArea then
		return
	end

	local Door = workspace.Doors:FindFirstChild(NextArea)
	
	if not Door then
		return
	end

	local Display = Door:FindFirstChild("Display")
	
	if not Display then
		return
	end

	local SurfaceGui = Display:FindFirstChildOfClass("SurfaceGui")
	
	if not SurfaceGui then
		return
	end
	
	local Content = SurfaceGui.Content
	local Tasks = Content.Tasks

	local ValidIdentifiers = {}

	for Index, Task in PlayerTasks do
		if Task.Area ~= NextArea then
			continue
		end

		local Identifier = ("%s%s"):format(Task.Area, Index)
		
		ValidIdentifiers[Identifier] = true

		local TaskTemplate = Tasks:FindFirstChild(Identifier)

		if not TaskTemplate then
			TaskTemplate = script.Task:Clone()
			TaskTemplate.Parent = Tasks
			TaskTemplate.Name = Identifier
		end

		TaskTemplate.Progress.Task.Text = Task.Description

		local Progress

		if Task.Type == "Pickups" then
			Progress = Task.Completed and 1 or math.clamp((Task.PickupsBroken or 0) / Task.Amount, 0, 1)
		elseif Task.Type == "Boss" then
			Progress = Task.Completed and 1 or 0
		end

		if not Progress then
			continue
		end

		TaskTemplate.Progress.Progress.Text = ("%s%%"):format(math.floor(Progress * 100 + 0.5))
		TaskTemplate.Progress.Bar.Size = UDim2.fromScale(Progress, 1)
	end

	if not Door:FindFirstChild("Portal") then
		if not table.find(PlayerData.AreasUnlockedOnJoin, Door.Name) then
			self:spawn_boss_portal_if_eligible(Door, true)
		else
			self:spawn_boss_portal_if_eligible(Door)
		end
		
	end

	for _, v in Tasks:GetChildren() do
		if not ValidIdentifiers[v.Name] and v:IsA("Frame") then
			v:Destroy()
		end
	end

	table.clear(ValidIdentifiers)
end

function DoorService:update_door(Door)
	
	local Display = Door:FindFirstChild("Display")
	
	if not Display then
		return
	end
	
	local Cost = self:get_cost(Door.Name)
	
	local Currency, Amount = unpack(Cost)

	local Index = nil

	for _, World in WorldService.Worlds do
		for i, Area in World.Areas do
			if Area.Name == Door.Name then
				Index = i
				
				break
			end
		end
	end

	if not Index then
		return
	end
	
	local CurrencyData = CurrencyModule[Currency]
	local CurrencyColor = CurrencyData.Color or Color3.new(1, 1, 1)
	
	if not Display:FindFirstChildOfClass("SurfaceGui") then
		return
	end
	
	local SurfaceGui = Display.SurfaceGui
	local Content = SurfaceGui.Content
	local Cost = Content.Cost
	
	Cost.Currency.Image = ImageModule(Currency)
	Cost.Amount.Text = Short:AddCommas(Amount)
	Cost.Amount.TextColor3 = CurrencyColor
	
	Content.Area.Text = ("Area %s"):format(Index)
	
	local Display = RichTextService.new {}

	Display:AddSection(Door.Name, WorldService.Colors[Door.Name] or "White")
	
	Content.World.Text = Display.Message
end

function DoorService:init_client()
	
	local PlayerData = Network:Fetch("GetClientData")
	
	for i, Area in PlayerData.Areas do
		Network:Fetch(
			"PlayEffectDestroyDoor",
			Area,
			true
		)

		local Door = workspace.Doors:FindFirstChild(Area)
		
		if not Door then
			continue
		end
		
		if table.find(PlayerData.Areas, Area) then
			self:spawn_boss_portal_if_eligible(Door, true)
		end
	end
	
	for i, v in workspace.Doors:GetChildren() do
		if not v:IsA("Model") then
			continue
		end
		
		for a, b in script.Effects:GetChildren() do
			b:Clone().Parent = v.Door
		end
		
		local Prompt = PromptService.new(
			v,
			"PromptingDoor",
			self.PromptRange
		)

		Prompt:triggerException(function()
			local PlayerData = Network:Fetch("GetClientData")

			if table.find(PlayerData.Areas, v.Name) then
				return
			end

			if DoorOpenFrame.Visible then
				return
			end
			
			return true
		end)
		
		Prompt:onTrigger(function(...)
			self:trigger_prompt(...)
		end)
		
		self:update_door(v)
		
	end

end

function DoorService:init()
	
	if RunService:IsClient() then
		return self:init_client()
	end
	
	Network:Bind("PurchaseDoor", function(Player, DoorName)
		local PlayerData = DataService:GetPlayerData(Player)
		local Areas = PlayerData.Areas

		if table.find(Areas, DoorName) then
			return
		end

		local Tasks = PlayerData.Tasks or {}
		
		local Completed = 0
		
		for i, v in Tasks do
			if v.Completed then
				Completed += 1
			end
		end

		if Completed < 2 then
			return Network:Post(Player, "DisplayNewItem", {
				Type = "Message",
				Message = "You haven't completed the task(s)!",
				TextColor = Color3.fromRGB(255, 60, 60)
			})
		end

		local Cost = self:get_cost(DoorName)
		local Currency, Amount = unpack(Cost)

		if PlayerData[Currency] < Amount then
			return Network:Post(Player, "DisplayNewItem", {
				Type = "Message",
				Message = "You cannot afford this area!",
				TextColor = Color3.fromRGB(255, 60, 60)
			})
		end

		DataService:GiveCurrency(
			Player,
			Currency,
			-Amount
		)

		table.insert(PlayerData.Areas, DoorName)

		local NextArea = WorldService:GetNextArea(DoorName)
		
		if NextArea then
			AreaService:AssignTasks(Player, NextArea)
		end

		DataService:SendUpdateSignal(
			Player,
			"Areas",
			NextArea
		)

		Network:Post(
			Player,
			"PlayEffectDestroyDoor",
			DoorName
		)

		return true
	end)

end

DoorService:init()

return DoorService