local PetModule = {}

for i, v in script:GetChildren() do
	for Pet, Data in require(v) do
		PetModule[Pet] = Data
	end
end

return PetModule