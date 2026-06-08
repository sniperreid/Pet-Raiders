-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")

-------------------------- Framework --------------------------

local GuiService

local GuiUtil = {}

function GuiUtil:LoadSource()
	for _, Util in script:GetChildren() do
		local Utility = require(Util)("Give", GuiService)

		self[Util.Name] = function(self, ...)
			return require(Util)(...)
		end
	end
end

return setmetatable(GuiUtil, {
	__call = function(self, GS)
		GuiService = GS
		
		self:LoadSource()

		return self
	end,
})