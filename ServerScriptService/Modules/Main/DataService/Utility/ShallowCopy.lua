--!strict

local function ShallowCopy(t: { [any]: any }): { [any]: any }
	local new = {}
	
	for i, v in t do
		if typeof(v) == "table" then
			v = ShallowCopy(v)
		end
		
		new[i] = v
	end
	
	return new
end

return ShallowCopy