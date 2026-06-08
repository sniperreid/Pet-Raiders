return function(recursiveModule, Pet)
	for i, v in pairs(Pet:GetDescendants()) do
		if v.Name == "Outline" then
			continue
		end
		
		if v:IsA("Decal") then
			if v.Color3 ~= Color3.fromRGB(255, 255, 255) then
				v.Color3 = recursiveModule:Invert(v.Color3)
			end
		end
		
		if v:IsA("BasePart") then
			
			local WhitelistedMaterial = Enum.Material.Neon
			
			if recursiveModule:IdentifiedShade(v.Color) and v.Material == WhitelistedMaterial then
				v.Material = Enum.Material.SmoothPlastic
			end
			
			local isTextureChange = v:FindFirstChild("TextureChange")
			
			if v:IsA("MeshPart") and isTextureChange then
				v.TextureID = isTextureChange.Texture
			end
			
			recursiveModule:UpdatePart(v)
			
			continue
		end
		
		if v:IsA("Color3Value") then
			v.Value = recursiveModule:Invert(v.Value)
			
			continue
		end
		
		if v:IsA("ParticleEmitter") or v:IsA("Trail") then
			recursiveModule:UpdateParticles(v, true)
			
			continue
		end
		
		local canInvert = v.Name == "CanInvert"
		
		if v:IsA("Decal") and canInvert then
			v.Color3 = recursiveModule:Invert(v.Color3)
		end
		
		if v:IsA("Mesh") or v:IsA("SpecialMesh") then
			if v.VertexColor.x + v.VertexColor.y + v.VertexColor.z == 3 then
				v.VertexColor = Vector3.new(v.VertexColor.x, v.VertexColor.y, 0)
			else
				local Inverted = recursiveModule:Invert(Color3.fromRGB(v.VertexColor.x * 255, v.VertexColor.y * 255, v.VertexColor.z * 255))
				
				v.VertexColor = Vector3.new(Inverted.R, Inverted.G, Inverted.B)
			end
		end
	end
end