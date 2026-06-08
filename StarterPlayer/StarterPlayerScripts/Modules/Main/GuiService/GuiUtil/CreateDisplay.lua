-------------------------- Framework --------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local GuiService
local Interface
local Frames

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local AnimationService = Services.get("AnimationService")
local Network = Services.get("Network")
local Short = Services.get("Short")

---------------------- Services ----------------------

local GuiService

local Module = {}

Module.Combo_Hits = 0
Module.Total_Damage = 0

function Module:Create(Damage)
	local ComboFrame = Frames and Frames.ComboFrame
	
	if not ComboFrame then
		return
	end

	ComboFrame.Visible = true

	AnimationService:AnimateUI_Open(
		ComboFrame, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0.3, 0.8, 2
	);
	
	task.wait(1 / 20)

	AnimationService:AnimateUI(
		ComboFrame, 0.98, 0
	);
	
	self.Combo_Hits += 1
	self.Total_Damage += Damage
	
	if self.Combo_Timer then
		task.cancel(self.Combo_Timer)
	end
	
	self.Combo_Timer = task.delay(5, function()
		self.Combo_Hits = 0
		self.Total_Damage = 0
		
		task.delay(1 / 20, function()
			ComboFrame.Visible = false
		end)

		AnimationService:AnimateUI_Open(
			ComboFrame, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0.8, 0.3, 14
		);
	end)
	
	ComboFrame.Content.Combo.Text = ("Combo: %dx"):format(self.Combo_Hits or 0)
	ComboFrame.Content.Damage.Text = ("DMG: %s"):format(Short:AddSuffix(self.Total_Damage or 0))
end

function Module:Give(GS)
	GuiService = GS
	Interface = GuiService.Interface
	Frames = Interface.Frames
	
	Network:Bind("PlayEffectCreateDisplay", function(...)
		self:Create(...)
	end)

	return self
end

return function(Type, GSQ, ...)
	if Type == "Give" then
		return Module:Give(GSQ)
	end

	return Module:Create(Type, GSQ, ...)
end