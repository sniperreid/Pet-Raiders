local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local AnimationService = Services.get("AnimationService")

local GuiService
local Interface
local Frames
local CodesFrame

local module = {}

function module:init()
	local Redeem = CodesFrame.Content.Redeem
	local TextBox = CodesFrame.Content.Box.TextBox
	
	AnimationService:CreateButton(Redeem, function()
		local Code = TextBox.Text
		TextBox.Text = ""
		
		local Msg, Clr = Network:Invoke("RedeemCode", Code)
		
		if not Msg or not Clr then
			return
		end
		
		return Network:Fetch("DisplayNewItem", {
			Type = "Message",
			Message = Msg,
			TextColor = Clr
		})
	end)
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		CodesFrame = Frames.CodesFrame
		
		self:init()
		
		return self
	end,
})