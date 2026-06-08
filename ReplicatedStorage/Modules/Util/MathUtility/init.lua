local MathUtility = setmetatable({}, {__index = math})

for _, Util in script:GetChildren() do
	MathUtility[Util.Name] = require(Util)
end

return MathUtility