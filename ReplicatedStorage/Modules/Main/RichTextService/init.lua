-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local PsuedoMeta = Services.get("PsuedoMeta")

---------------------- Services ----------------------

local RichText = {}

function RichText:Destroy()
	table.clear(self)
end

function RichText:UpdateLabel(Label)
	Label.RichText = true
	Label.Text = self.Message
end

function RichText:AddSection(Msg, Color)
	local ChangeFunction = self.StringTransformer
	local Color = Color or self.DefaultColor
	
	self.Message = self.Message .. ChangeFunction(Msg, Color)
end

function RichText.new(Args)
	
	if not Args then
		Args = {}
	end
	
	return PsuedoMeta.set({
		Message = Args.Message or "",
		StringTransformer = require(script[Args.StringTransformer or "RichHint"]),
		DefaultColor = Args.DefaultColor or "White"
	}, RichText)
end

return RichText