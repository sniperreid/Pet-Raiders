local GuiService

local HUD = {}

function HUD:LoadSource()
	for i, v in script:GetChildren() do
		self[v.Name] = require(v)(GuiService)
	end
end

return setmetatable(HUD, {
	__call = function(self, GS)
		GuiService = GS
		
		self:LoadSource()
		
		return self
	end,
})