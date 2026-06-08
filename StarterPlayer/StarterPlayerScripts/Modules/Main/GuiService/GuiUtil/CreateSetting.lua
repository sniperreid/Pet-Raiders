local GuiService

local Module = {}

function Module:Create(SettingName, Grid, ...)
	local TemplateExists = Grid and Grid:FindFirstChild(SettingName)
	
	local Template = TemplateExists or script.Template:Clone()
	Template.Parent = Grid
	Template.Name = SettingName
	
	local Content = Template.Content
	
	Content.Setting.Text = SettingName

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