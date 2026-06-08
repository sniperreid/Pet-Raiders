local GuiService

local Module = {}

function Module:Create(Grid, ...)
	local Template = script.Template:Clone()
	Template.Parent = Grid

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