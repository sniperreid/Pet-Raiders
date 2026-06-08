local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local SoundService = Services.get("SoundService")
local CameraShaker = Services.get("CameraShaker")
local EasyRender = Services.get("RenderUtil").Number

local Camera = workspace.CurrentCamera

local function Destroy(Model)
	for i, v in Model:GetDescendants() do
		if v:IsA("BasePart") then
			v.Material = Enum.Material.Plastic
			v.Transparency = 1
			v.CanCollide = false
		end

		if v:IsA("SurfaceGui") then
			v:Destroy()
		end

		if v:IsA("Highlight") then
			v:Destroy()
		end
	end
end

return function(DoorName, DestroyDoor)
	local Doors = workspace.Doors
	
	local DoorModel = Doors:FindFirstChild(DoorName)
	local Door = DoorModel and DoorModel:FindFirstChild("Door")
	local Display = DoorModel and DoorModel:FindFirstChild("Display")
	local GUI = Display and Display:FindFirstChild("SurfaceGui")
	local Shard = GUI and Door:FindFirstChild("Shard")
	local Shard2 = Shard and Door:FindFirstChild("Shard2")
	
	if not DoorModel then
		return
	end
	
	if DestroyDoor and DoorModel then
		return Destroy(DoorModel)
	end
	
	local Freeze = SoundService:PlaySound("Freeze", {
		Volume = 1
	})
	
	task.delay(2, function()
		TweenService:Create(
			Freeze,
			TweenInfo.new(1),
			{
				Volume = 0
			}
		):Play()
	end)
	
	Debris:AddItem(Freeze, 3)
	
	local Bass = SoundService:PlaySound("Bass", {
		Volume = 1
	})
	
	task.delay(2, function()
		TweenService:Create(
			Bass,
			TweenInfo.new(.2),
			{
				Volume = 0
			}
		):Play()
	end)
	
	Debris:AddItem(Bass, 3)
	
	Door.Material = Enum.Material.Neon
	Door.Transparency = 1
	Door.Color = Color3.fromRGB(128, 187, 219)
	Door.CanCollide = false
	
	local Shake_Mul = 0
	
	local ShakeInstance = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(ShakeCFrame)
		Camera.CFrame = Camera.CFrame * (ShakeCFrame:Lerp(CFrame.new(), Shake_Mul))
	end)

	ShakeInstance:Start()

	ShakeInstance:StartShake(3.5, 5, 0.5, 1)
	
	local Tween1 = TweenService:Create(
		Door,
		TweenInfo.new(2),
		{
			Transparency = 0
		}
	)
	
	task.delay(2, function()
		EasyRender.new({
			UpdateSpeed = 2
		}, function(x)
			Shake_Mul = x
			
			if x >= 1 then
				ShakeInstance:Destroy()
			end
		end)
	end)
	
	Tween1:Play()
	
	Tween1.Completed:Wait()
	
	Door.Transparency = 1
	
	SoundService:PlaySound("Glass", {
		Volume = 2
	})
	
	SoundService:PlaySound("Magic", {
		Volume = 1.5
	})
	
	GUI:Destroy()
	
	Shard:Emit(50)
	Shard2:Emit(50)
	
	Destroy(DoorModel)
end