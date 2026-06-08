local u = {}

for _, t in script:GetChildren() do
	u[t.Name] = require(t)
end

return u