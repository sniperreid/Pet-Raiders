local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local TweenV2 = Services.get("TweenV2")
local Short = Services.get("Short")

local Module = {}

local RNG = Random.new()

local function BounceFX(FX)
	local Y = 3
	local X = RNG:NextNumber(-2, 2)
	local Z = RNG:NextNumber(-2, 2)
	
	local Begin = tick()

	FX.Position = FX.Position + Vector3.new(RNG:NextNumber(-0.3, 0.3), 0.3, RNG:NextNumber(-0.3, 0.3))
	
	repeat
		RunService.RenderStepped:Wait()
		Y -= 0.1
		FX.Position = FX.Position + Vector3.new(X, Y, Z) * 0.01
	until tick() - Begin >= 0.5
	
	TweenV2:Create(FX:FindFirstChildOfClass("BillboardGui").Damage, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
	TweenV2:Create(FX:FindFirstChildOfClass("BillboardGui").Damage.UIStroke, TweenInfo.new(0.1), {Transparency = 1}):Play()
	
	task.wait(0.1)
end

function Module:Popup(_Damage, _Parent)
	if not _Parent then return end
	
	local Holder = Instance.new("Part")
	Holder.CFrame = _Parent.CFrame
	Holder.Parent = workspace.Terrain
	Holder.Transparency = 1
	Holder.CanCollide = false
	Holder.Anchored = true
	
	local PopupPart = Instance.new("Part")
	PopupPart.Anchored = true
	PopupPart.CanCollide = false
	PopupPart.Position = Holder.Position
	PopupPart.Parent = Holder
	PopupPart.Size = Vector3.new(1, 1, 1)
	PopupPart.Transparency = 1
	
	local Popup = script.Template:Clone()
	Popup.Enabled = true
	Popup.Damage.Text = "-" .. Short:AddSuffix(_Damage)
	Popup.Parent = PopupPart

	BounceFX(PopupPart)
	
	Debris:AddItem(Holder, 0)
	Debris:AddItem(PopupPart, 0)
	Debris:AddItem(Popup, 0)
end

Network:Bind("DamagePopup", function(_Damage, _Parent)
	coroutine.wrap(function()
		Module:Popup(_Damage, _Parent)
	end)()
end)

return setmetatable(Module, {
	__call = function(self)
		return self
	end,
})