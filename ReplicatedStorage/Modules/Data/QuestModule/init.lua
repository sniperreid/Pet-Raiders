local module = {}

for i, v in script:GetChildren() do
	local Keys = require(v)
	
	for i, v in Keys do
		table.insert(module, v)
	end
end

return module