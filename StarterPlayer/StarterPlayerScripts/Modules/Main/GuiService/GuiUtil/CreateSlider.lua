local GuiService

local Module = {}

function Module:Create(Setting, State, ...)
	local Template = script.Template:Clone()
	Template.Name = Setting
	
	local Content = Template.Content
	
	local Label = Content.Label
	
	Label.Text = Setting
	
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