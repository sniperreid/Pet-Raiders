-------------------------- Framework --------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local Network = Services.get("Network")
local AnimationService = Services.get("AnimationService")

---------------------- Services ----------------------

local GuiService
local Interface
local GuiFrames

local PreviousFrame
local Frames = {}

function Frames:OpenFrame(Frame, HUD)
	local Type = typeof(Frame)

	if Type == "string" then
		Frame = GuiFrames:FindFirstChild(Frame)
	end

	if not Frame then
		return
	end

	if HUD and Frame.Visible then
		return self:CloseFrame(Frame)
	end

	if PreviousFrame and PreviousFrame.Name == Frame.Name then
		return
	end

	if PreviousFrame then
		self:CloseFrame(PreviousFrame)
	end

	PreviousFrame = Frame
	Frame.Visible = true

	AnimationService:AnimateUI_Open(
		Frame,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0.8, 1, 5
	)
end

function Frames:CloseFrame(Frame)
	if not Frame and PreviousFrame then
		Frame = PreviousFrame
	end
	
	if not Frame then return end
	
	local Type = typeof(Frame)

	if Type == "string" then
		Frame = GuiFrames:FindFirstChild(Frame)
	end

	if not Frame then
		return
	end

	PreviousFrame = nil
	Frame.Visible = false
end

Network:Bind("OpenFrame", function(...)
	Frames:OpenFrame(...)
end)

Network:Bind("CloseFrame", function(...)
	Frames:CloseFrame(...)
end)

return setmetatable(Frames, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		GuiFrames = Interface.Frames

		return self
	end,
})