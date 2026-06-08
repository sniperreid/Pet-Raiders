local Cases = {}

for _, Case in script:GetChildren() do
	Cases[Case.Name] = require(Case)
end

return function(self)
	for i, v in Cases do
		self[i] = v
	end
end