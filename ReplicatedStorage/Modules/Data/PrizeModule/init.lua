local PrizeModule = {}

for i, v in script:GetChildren() do
	for Prize, Data in require(v) do
		PrizeModule[Prize] = Data
		PrizeModule[Prize]["Type"] = v.Name
	end
end

return PrizeModule