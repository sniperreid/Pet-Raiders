local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local AnimationService = Services.get("AnimationService")
local InputManager = Services.get("InputManager")
local PetService = Services.get("PetService")
local AbilityModule = Services.get("AbilityModule")

local GuiService
local Interface
local Frames

local HUD
local Abilities

local GuiUtil

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local module = {}

module.Buttons = {}

module.Binds = {
	{
		PC = Enum.KeyCode.One,
		-- Xbox = Enum.KeyCode.ButtonL2,
		-- Mobile = Enum.UserInputType.Touch
	},
	{
		PC = Enum.KeyCode.Two,
		-- Xbox = Enum.KeyCode.ButtonL2,
		-- Mobile = Enum.UserInputType.Touch
	},
	{
		PC = Enum.KeyCode.Three,
		-- Xbox = Enum.KeyCode.ButtonL2,
		-- Mobile = Enum.UserInputType.Touch
	}
}

local Keybinds = InputManager.newKeybinder({}, "Abilities")

Keybinds:ToggleMobileInput(false)
Keybinds:ToggleInputType("Disconnect")

function module:invoke(Name)
	local MousePosition = UserInputService:GetMouseLocation()
	
	local mouseRay = workspace.CurrentCamera:ViewportPointToRay(
		MousePosition.X,
		MousePosition.Y
	)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Assets, workspace.Bosses.Models}
	params.RespectCanCollide = true

	local cast = workspace:Raycast(
		mouseRay.Origin,
		mouseRay.Direction * 999,
		params
	)

	local Position = cast and cast.Position or mouseRay.Direction * 999

	Network:Post("InvokeAbility", Name, Position)
end

function module:CreateAbilityButton(Index, Name)
	local Button = GuiUtil:CreateAbility({Name, Index}, Abilities)
	local ValidateKeybind = self.Binds[Index]

	self.Buttons[Name] = { Button = Button }

	AnimationService:CreateButton(Button, function()
		self:invoke(Name)
	end)

	for key, bind in ValidateKeybind do
		InputManager.Begin(
			"Validate" .. Name .. key,
			bind,
			true,
			function()
				self:invoke(Name)
			end
		)
	end
end

function module:CreateVerifyAbilityButton(Index, Name)
	local Button = GuiUtil:CreateAbility({Name, Index}, Abilities)
	local ValidateKeybind = self.Binds[Index]

	self.Buttons[Name] = {
		Button = Button,
		verify_click = false
	}

	AnimationService:CreateButton(Button, function()
		self.Buttons[Name].verify_click = true
	end)

	for key, bind in ValidateKeybind do
		InputManager.Begin(
			"Validate" .. Name .. key,
			bind,
			true,
			function()
				if key == "Mobile" and not self.Buttons[Name].verify_click then
					return
				end

				self:invoke(Name)
				
				self.Buttons[Name].verify_click = false
			end
		)
	end
end

function module:Initialize()
	local PlayerData = Network:Fetch("GetClientData")
	
	for i, v in PlayerData.Abilities do
		local AbilityData = AbilityModule[v]
		
		if not AbilityData then
			continue
		end
		
		if AbilityData.Type == "Verify" then
			self:CreateVerifyAbilityButton(i, v)
		elseif AbilityData.Type == "Instant" then
			self:CreateAbilityButton(i, v)
		end
	end
	
	Keybinds:RenderKeybinds()
	
	Network:Bind("DisplayCooldown", function(Name: string, Time: number)
		local Button = Abilities:FindFirstChild(Name)
		
		if not Button then
			return
		end
		
		GuiUtil:CreateCooldown(Button, Time)
	end)
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames

		HUD = Frames.StatsFrame
		Abilities = HUD.Bottom

		GuiUtil = GuiService.GuiUtil
		
		local PlayerData = Network:Fetch("GetClientData")
		
		coroutine.wrap(function()
			repeat
				task.wait()
				PlayerData = Network:Fetch("GetClientData")
				
			until PlayerData
			
			self:Initialize()
		end)()

		return self
	end,
})