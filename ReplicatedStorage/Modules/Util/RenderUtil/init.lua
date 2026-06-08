local RenderUtil = {}

for _, Util in script:GetChildren() do
	RenderUtil[Util.Name] = require(Util)
end

return RenderUtil