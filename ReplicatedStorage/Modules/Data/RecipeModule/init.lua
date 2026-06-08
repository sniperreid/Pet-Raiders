local RecipeModule = {}

for i, v in script:GetChildren() do
	if not RecipeModule[v.Name] then
		RecipeModule[v.Name] = {}
	end
	
	for Item, Recipe in require(v) do
		RecipeModule[v.Name][Item] = Recipe
	end
end

return RecipeModule