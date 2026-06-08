local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local TextAnimationService = Services.get("TextAnimationService")

local GuiService

local Module = {}

function Module:Create(TitleName, TitleData, PlayerTitles, PlayerTitle, Grid, ...)
	local TemplateExists = Grid and Grid:FindFirstChild(TitleName)
	
	local Template = TemplateExists or script.Template:Clone()
	Template.Parent = Grid
	Template.Name = TitleName
	
	local Glow = Template.Glow
	local Content = Template.Content
	
	local _TitleName = Content.TitleName
	local _Blackout = Content.Blackout
		
	if not TemplateExists then
		if TitleData.Color then
			_TitleName.TextColor3 = TitleData.Color
		else
			TextAnimationService:AnimateText(_TitleName, TitleName)
		end
	end
	
	if PlayerTitle == TitleName then
		TextAnimationService:AnimateImage(Glow, "Legendary")
	else
		TextAnimationService:RequestCleanup(Glow)
	end
	
	_TitleName.Text = TitleName
	
	_Blackout.Visible = not table.find(PlayerTitles, TitleName)
	
	Glow.Visible = PlayerTitle == TitleName

	return Template
end

function Module:Give(GS)
	GuiService = GS

	return self
end

return function(Type, GSQ, ...)
	if Type == "Give" then
		return Module:Give(GSQ)
	end

	return Module:Create(Type, GSQ, ...)
end