local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules:WaitForChild("Services"))

local math = Services.get("MathUtility")
local ImageModule = Services.get("ImageModule")
local AnimationService = Services.get("AnimationService")

local InputManager = {
	Functions = {},
	States = {},
	
	LatencyEnabled = false,
	Latency = 0,
}

InputManager.LibraryController = {}
InputManager.LibraryController.__index = InputManager.LibraryController

function InputManager.LibraryController:CreateKeybinds()
	self.Keybinds = {}
end

function InputManager.LibraryController:NewKeybinds(Title)
	if not self.Keybinds then
		self:CreateKeybinds(self)
	end

	self.Keybinds[Title] = {}
end

function InputManager.LibraryController:NewBinds(Title, Binds, Callback, Button, BindType)
	if not self.Keybinds then
		self:CreateKeybinds()
	end

	if not self.Keybinds[Title] then
		self:NewKeybinds(Title)
	end
	
	if not self.Keybinds[Title].Icons then
		self.Keybinds[Title].Icons = {}
	end
	
	if BindType then
		self.Keybinds[Title].BindType = BindType
	end

	Binds.Playstation = Binds.Xbox

	self.Keybinds[Title].Binds = Binds
	
	for Device, Input in Binds do
		
		if not self.Keybinds[Title].Icons[Device] then
			self.Keybinds[Title].Icons[Device] = {}
		end
		
		if Device == "Xbox" and not Input then
			
			self.Keybinds[Title].Icons[Device][Input.Name] = "rbxassetid://"
			
			continue
		end
		
		self.Keybinds[Title].Icons[Device][Input.Name] = InputManager:GetInputIcon(Input, Device)
	end
	
	self:NewCallback(Title, Callback)
	self:NewButton(Title, Button)
	
	return self.Keybinds[Title]
end

function InputManager.LibraryController:NewCallback(Title, Callback)
	if not Callback then
		return
	end
	
	if not self.Keybinds then
		self:CreateKeybinds()
	end

	if not self.Keybinds[Title] then
		self:NewKeybinds(Title)
	end

	self.Keybinds[Title].Callback = function(...)
		return Callback(self, ...)
	end
end

function InputManager.LibraryController:NewButton(Title, Button)
	if not Button then
		return
	end
	
	if not self.Keybinds then
		self:CreateKeybinds()
	end

	if not self.Keybinds[Title] then
		self:NewKeybinds(Title)
	end
	
	if self.Keybinds[Title].Button and not self.Keybinds[Title].Button.Text then
		return -- Text is just a random parameter, means already binded.
	end
	
	self.Keybinds[Title].OriginalScale = Button.Content.UIScale.Scale
	
	if self.Keybinds[Title].BindType == "State" then
		self.Keybinds[Title].Button = Button
		self.Keybinds[Title].Button.NoSound = true
		
		self.Keybinds[Title].Button.MouseButton1Down:Connect(function()
			self.Keybinds[Title].Callback(true)
		end)
		
		return self.Keybinds[Title].Button.MouseButton1Up:Connect(function()
			self.Keybinds[Title].Callback(false)
		end)
	end
	
	self.Keybinds[Title].Button = Button
	
	AnimationService:CreateButton(Button, self.Keybinds[Title].Callback)
end

function InputManager.LibraryController:UpdateButton(Title)
	if not self.Keybinds then
		self:CreateKeybinds()
	end

	if not self.Keybinds[Title] then
		self:NewKeybinds(Title)
	end
	
	local Button = self.Keybinds[Title].Button
	local KeybindIcon = Button and Button:FindFirstChild("KeybindIcon")
	local KeybindLabel = Button and Button:FindFirstChild("Keybind")

	if not KeybindLabel then
		return
	end
	
	local Keybinds = self.Keybinds
	local userDevice = InputManager:GetUserDevice()
	
	local NewKeybind = Keybinds[Title]
	local Keybind = NewKeybind.Binds[userDevice]
	
	if not Keybind then
		return
	end
	
	local Name = Keybind.Name
	local toNum = math.toNumber(Name)
	
	if toNum then
		if toNum == 0 and Name == "Zero" then
			Name = toNum
		elseif toNum ~= 0 and Name ~= "Zero" then
			Name = toNum
		end
	end
	
	local Display = string.len(Name) <= 1

	if KeybindIcon then
		KeybindIcon.Visible = not Display
	end
	
	KeybindLabel.Visible = Display

	KeybindLabel.Text = Name
	
	if KeybindIcon then
		KeybindIcon.Image = NewKeybind.Icons[userDevice][Keybind.Name]
	end
end

function InputManager.LibraryController:ToggleInputType(Type)
	self.InputType = Type
end

function InputManager.LibraryController:ToggleMobileInput(State)
	self.MobileInputsEnabled = State
end

function InputManager.LibraryController:TweenButton(Title, Type)
	if not self.Keybinds then
		self:CreateKeybinds()
	end

	if not self.Keybinds[Title] then
		self:NewKeybinds(Title)
	end
	
	local Button = self.Keybinds[Title].Button
	local OriginalScale = self.Keybinds[Title].OriginalScale
	
	if not Button then
		return
	end
	
	AnimationService:HandleTween(Button, Type, OriginalScale)
end

function InputManager.LibraryController:HandleTween(Title, Bind)
	local KeybindTitle = self.KeybindTitle
	
	local CallbackKey = KeybindTitle .. "_" .. Bind.Name
	local AnimateKey = "BA: " .. CallbackKey
	
	InputManager.Begin(
		AnimateKey,
		Bind,
		true,
		function()
			
			local Button = self.Keybinds[Title].Button
			
			if not Button then
				return
			end
			
			if not Button.Visible then
				return
			end
			
			if self.Keybinds[Title].BindType == "State" then
				return self.Keybinds[Title].Callback(true)
			end
			
			self:TweenButton(Title, "KeybindDown")
		end
	)
	
	InputManager.End(
		AnimateKey,
		Bind,
		true,
		function()
			
			local Button = self.Keybinds[Title].Button

			if not Button then
				return
			end

			if not Button.Visible then
				return
			end
			
			if self.Keybinds[Title].BindType == "State" then
				return self.Keybinds[Title].Callback(false)
			end
			
			self:TweenButton(Title, "KeybindUp")
		end
	)
end

function InputManager.LibraryController:UnrenderKeybinds()
	
end

function InputManager.LibraryController:RenderKeybinds()
	local KeybindTitle = self.KeybindTitle

	for Title, Info in self.Keybinds or {} do
		local Binds = Info.Binds

		for Device, Bind in Binds do
			if not self.MobileInputsEnabled and Device == "Mobile" then
				continue
			end
			
			local CallbackKey = KeybindTitle .. "_" .. Title .. "_" .. Bind.Name

			self:HandleTween(Title, Bind)
			
			InputManager.new(
				CallbackKey,
				Bind,
				self.InputType or "Connect",
				true,
				function()
					
					local Button = self.Keybinds[Title].Button

					if not Button then
						return
					end
					
					if not Button.Visible then
						return
					end
					
					if self.Keybinds[Title].BindType == "State" then
						return
					end
					
					return Info.Callback()
				end
			)
		end
	end
end

function InputManager.newKeybinder(Lib, Title)
	Lib.KeybindTitle = Title or "NoTitleUsed"
	Lib.MobileInputsEnabled = true
	Lib.InputType = "Connect"
	
	return setmetatable(Lib, InputManager.LibraryController)
end

function InputManager:GetUserDevice()
	if GuiService:IsTenFootInterface() then
		return "Xbox"
	end
	
	if UserInputService.GamepadEnabled then
		return "Playstation"
	end
	
	if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return "PC"
	end
	
	return "Mobile"
end

function InputManager:GetBind(Keybinds)
	return (Keybinds or {})[self:GetUserDevice() or "Xbox"]
end

function InputManager:GetInputIcon(Keycode, Device)
	local Device = Device or self:GetUserDevice()
	local Input = Keycode.Name
	
	if Device == "Mobile" then
		Input = "Touch"
	end
	
	return ImageModule(Device .. Input)
end

InputManager.ControllerConnected = UserInputService.GamepadConnected
InputManager.ControllerDisconnected = UserInputService.GamepadDisconnected

function InputManager:SetLatency(Latency)
	self.LatencyEnabled = Latency and true or false
	self.Latency = Latency or 0
end

function InputManager:Disconnect(Tag)
	self.Functions[Tag] = nil
	self.States[Tag] = nil
end

function InputManager:DisconnectState(Tag)
	self.States[Tag] = nil
end

function InputManager.new(Tag, Keybind, InputType, gpe, Callback)
	local self = InputManager

	if not Keybind then
		self.Functions[Tag] = nil
		self.States[Tag] = nil

		return
	end

	self.States[Tag] = nil
	self.Functions[Tag] = {
		Disconnect = function(self)
			return InputManager:Disconnect(Tag)
		end,
		
		Keybind = Keybind,
		Callback = Callback,
		InputType = InputType,
		gpe = gpe
	}
	
	return self.Functions[Tag]
end

function InputManager.Begin(Tag, Keybind, gpe, Callback)
	return InputManager.new(
		Tag .. "Begin",
		Keybind,
		"Connect",
		gpe,
		Callback
	)
end

function InputManager.End(Tag, Keybind, gpe, Callback)
	return InputManager.new(
		Tag .. "End",
		Keybind,
		"Disconnect",
		gpe,
		Callback
	)
end

function InputManager.Hold(Tag, Keybind, gpe, Callback)
	return InputManager.new(
		Tag .. "Hold",
		Keybind,
		"Hold",
		gpe,
		Callback
	)
end

function InputManager:GetKeybinds(Keybind)
	local Keys = {}
	
	for i, v in pairs(self.Functions) do
		
		if Keybind.KeyCode == v.Keybind or Keybind.UserInputType == v.Keybind then
			Keys[i] = v
		end

	end
	
	return Keys
end

function InputManager:CreateInputs()
	
	if not RunService:IsClient() then
		return
	end
	
	if self.Initialized then
		return
	end
	
	self.Initialized = true
	
	UserInputService.InputBegan:Connect(function(Input, gpe)	

		for i, v in self:GetKeybinds(Input) do
			
			if v.gpe and gpe then
				continue
			end
			
			if self.LatencyEnabled then
				task.wait(self.Latency)
			end

			if v.InputType == "Hold" then
				self.States[i] = true
			end
			
			if v.InputType == "Connect" then
				v.Callback()
			end
		end
		
	end)
	
	UserInputService.InputEnded:Connect(function(Input, gpe)
		for i, v in self:GetKeybinds(Input) do
			
			if v.gpe and gpe then
				continue
			end
			
			if self.LatencyEnabled then
				task.wait(self.Latency)
			end
			
			if v.InputType == "Hold" then
				self.States[i] = nil
			end
			
			if v.InputType == "Disconnect" then
				v.Callback()
			end
		end
	end)
	
	RunService.RenderStepped:Connect(function()
		for i, v in self.Functions do
			if not self.States[i] then
				continue
			end

			v.Callback()
		end
	end)

end

InputManager:CreateInputs()

return InputManager