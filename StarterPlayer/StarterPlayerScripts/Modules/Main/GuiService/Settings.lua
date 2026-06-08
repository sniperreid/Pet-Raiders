local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get "Network"
local AnimationService = Services.get "AnimationService"
local SettingModule = Services.get "SettingModule"
local TweenService = Services.get "TweenV2"

local GuiService: any
local Interface: ScreenGui
local Frames: Frame
local SettingsFrame: Frame

local module = {}

function module:Update()
	local PlayerData = Network:Fetch("GetClientData") or {}
	local PlayerSettings = PlayerData.Settings or {}

	local Content = SettingsFrame.Content :: Frame
	local Grid = Content.Grid :: ScrollingFrame

	for Setting: string, Value: boolean in PlayerSettings do
		local SettingData = SettingModule[Setting] or {}
		
		local Template = Grid:FindFirstChild(Setting) :: Frame
		
		if not Template then
			Template = script.Setting:Clone()
			Template.Parent = Grid
			Template.Name = Setting
			
			Template.Content.SettingName.Text = Setting
			Template.Content.Description.Text = SettingData.Description
			
			AnimationService:CreateButton(Template.Content.Lever, function()
				return Network:Post("ToggleSetting", Setting)
			end)
		end
		
		TweenService:Create(
			Template.Content.Lever.Container.Circle,
			TweenInfo.new(.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Position = Value and UDim2.fromScale(1, 0.5) or UDim2.fromScale(0, 0.5) }
		):Play()
		
		TweenService:Create(
			Template.Content.Lever,
			TweenInfo.new(.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ BackgroundColor3 = Value and Color3.fromRGB(123, 253, 87) or Color3.fromRGB(255, 66, 8) }
		):Play()
	end
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		SettingsFrame = Frames.SettingsFrame
		
		self:Update()
		
		return self
	end,
})