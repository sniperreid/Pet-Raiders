local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local GuiService = Services.get("GuiService")
local RecipeModule = Services.get("RecipeModule")
local AnimationService = Services.get("AnimationService")
local TextAnimationService = Services.get("TextAnimationService")
local ImageModule = Services.get("ImageModule")
local HoverManager = Services.get("HoverManager")
local SoundService = Services.get("SoundService")

local PetModule = Services.get("PetModule")
local ItemModule = Services.get("ItemModule")
local AbilityModule = Services.get("AbilityModule")

local CraftingClient = {}

CraftingClient.CurrentTab = "Pets"
CraftingClient.Selected = nil

function CraftingClient:ClearGrid(Grid, Type)
	for i, v in Grid:GetChildren() do
		if v:IsA(Type) then
			v:Destroy()
		end
	end
end

function CraftingClient:CheckCrafting()
	local PlayerData = Network:Fetch("GetClientData")

	if not PlayerData then
		return "Something went wrong, please try again."
	end

	local Directory = RecipeModule[self.CurrentTab]
	
	if not Directory then
		return
	end

	local ProductData = Directory[self.Selected]
	
	if not ProductData then
		return
	end

	local CantCraft = {}

	for _, Ingredient in ProductData do
		local Type = Ingredient.Type
		local Name = Ingredient.Name
		local Amount = Ingredient.Amount or 1

		if Type == "Pet" then
			local Count = 0

			for _, Pet in PlayerData.Pets do
				if Pet.Name == Name and Pet.Tier == "Normal" then
					Count += 1
				end
			end

			if Count < Amount then
				table.insert(CantCraft, ("%s (%d/%d)"):format(Name, Count, Amount))
			end
		end

		if Type == "Item" then
			local Owned = PlayerData.Items[Name] or 0

			if Owned < Amount then
				table.insert(CantCraft, ("%s (%d/%d)"):format(Name, Owned, Amount))
			end
		end

		if Type == "Ability" then
			local Count = 0

			for _, Ability in PlayerData.Abilities do
				if Ability == Name then
					Count += 1
				end
			end

			if Count < Amount then
				table.insert(CantCraft, ("%s (%d/%d)"):format(Name, Count, Amount))
			end
		end
	end

	for _, Missing in CantCraft do
		Network:Fetch("DisplayNewItem", {
			Type = "Message",
			Message = ("You are missing %s"):format(Missing),
			TextColor = Color3.fromRGB(255, 60, 60)
		})
	end

	if #CantCraft >= 1 then
		return false
	end

	return true
end

function CraftingClient:UpdateSelection()
	if not self.Selected then
		return
	end
	
	local Directory = RecipeModule[self.CurrentTab]
	
	if not Directory then
		return
	end

	local ProductData = Directory[self.Selected]
	
	if not ProductData then
		return
	end
	
	local Interface = GuiService.Interface
	local Frames = Interface.Frames
	local CraftingFrame = Frames.CraftingFrame

	local Content = CraftingFrame.Content

	local Buttons = Content.Buttons
	local Left = Content.Left
	
	local Using = Left.Using
	local Product = Left:FindFirstChildOfClass("ImageButton")
	local Craft = Left.Craft
	
	Product.Visible = true
	Product.Name = self.Selected
	Product.Content.Icon.Image = ImageModule(self.Selected)

	self:ClearGrid(Using, "TextLabel")
	
	for i, v in ProductData do
		local IngredientData = v.Type == "Pet" and PetModule[v.Name] or v.Type == "Item" and ItemModule[v.Name] or v.Type == "Abilities" and AbilityModule[v.Name]
		
		if not IngredientData then
			continue
		end
		
		local TextTemplate = script.TextTemplate:Clone()
		TextTemplate.Parent = Using
		TextTemplate.Name = v.Name
		TextTemplate.LayoutOrder = -v.Amount
		
		TextTemplate.Text = ("x%s %s"):format(v.Amount, v.Name)
		
		TextAnimationService:AnimateText(TextTemplate, IngredientData.Rarity or "Common")
	end
	
	AnimationService:CreateButton(Craft, function()
		local Result = self:CheckCrafting()
		
		if Result ~= true then
			local Msg = typeof(Result) == "string" and Result or "You cannot craft this item."

			return Network:Fetch("DisplayNewItem", {
				Type = "Message",
				Message = Msg,
				TextColor = Color3.fromRGB(255, 60, 60)
			})
		end
		
		Network:Post("Craft", self.Selected)
		
		Network:Fetch("DisplayNewItem", {
			Type = "Message",
			Message = ("You have successfully crafted '%s'!"):format(self.Selected),
			TextColor = ProductData.Rarity or "Mutation"
		})
		
		SoundService:PlaySound("Legendary", .25)

		task.spawn(function()
			SoundService:PlaySound("Clank", {
				Volume = .3,
				PlaybackSpeed = (math.random(8, 12) / 10)
			})

			task.wait(.45)

			SoundService:PlaySound("Clank", {
				Volume = .3,
				PlaybackSpeed = (math.random(8, 12) / 10)
			})

			task.wait(.45)

			SoundService:PlaySound("Clank", {
				Volume = .3,
				PlaybackSpeed = (math.random(8, 12) / 10)
			})
		end)
	end)
end

function CraftingClient:UpdateGrid()
	if not self.CurrentTab then
		return
	end
	
	local Interface = GuiService.Interface
	local Frames = Interface.Frames
	local CraftingFrame = Frames.CraftingFrame

	local Content = CraftingFrame.Content
	local Right = Content.Right
	
	local Grid = Right.Grid

	self:ClearGrid(Grid, "Frame")

	local Directory = RecipeModule[self.CurrentTab]
	
	if not Directory then
		return
	end

	for i, v in Directory do
		local ProductData = self.CurrentTab == "Pets" and PetModule[i] or self.CurrentTab == "Items" and ItemModule[i] or self.CurrentTab == "Abilities" and AbilityModule[i]
		
		if not ProductData then
			continue
		end
		
		local RecipeTemplate = script.RecipeTemplate:Clone()
		RecipeTemplate.Parent = Grid
		RecipeTemplate.Name = i
		
		local _Content = RecipeTemplate.Content
		local _Select = _Content.Select
		local _Icon = _Content.Icon
		local _Recipe = _Content.Recipe
		local _Product = _Content.Product
		
		_Product.Text = i
		_Product.Name = i
		
		TextAnimationService:AnimateText(_Product, ProductData.Rarity or "Common")
		
		_Icon.Image = ImageModule(i)
		
		for a, b in v do
			local IngredientData = b.Type == "Pet" and PetModule[b.Name] or b.Type == "Item" and ItemModule[b.Name] or b.Type == "Abilities" and AbilityModule[b.Name]
			
			if not IngredientData then
				continue
			end
			
			local IngredientTemplate = script.IngredientTemplate:Clone()
			IngredientTemplate.Parent = _Recipe
			IngredientTemplate.Name = b.Name
			IngredientTemplate.LayoutOrder = -b.Amount
			
			local __Icon = IngredientTemplate.Icon
			local __Amount = IngredientTemplate.Amount
			
			__Icon.Image = ImageModule(b.Name)
			__Amount.Text = ("x%s"):format(b.Amount)
		end
		
		AnimationService:CreateButton(_Select, function()
			self.Selected = i
			
			task.delay(.1, function()
				self:UpdateSelection()
			end)
		end)
	end
end

function CraftingClient:Open()
	if not GuiService then
		return
	end
	
	local Interface = GuiService.Interface
	local Frames = Interface.Frames
	local CraftingFrame = Frames.CraftingFrame
	
	local Content = CraftingFrame.Content
	
	local Buttons = Content.Buttons
	
	for i, v in Buttons:GetChildren() do
		if not v:IsA("GuiButton") then
			continue
		end
		
		AnimationService:CreateButton(v, function()
			self.CurrentTab = v.Name
			
			task.delay(.1, function()
				self:UpdateGrid()
			end)
		end)
	end
	
	self.CurrentTab = "Pets"
	self.Selected = nil
	
	return self:UpdateGrid()
end

function CraftingClient:init()
	local Interface = GuiService.Interface
	local Frames = Interface.Frames
	local CraftingFrame = Frames.CraftingFrame :: Frame
	
	local Content = CraftingFrame.Content
	
	HoverManager:Bind(CraftingFrame, Content, {
		HelpLabel = "Ingredient"
	})

	HoverManager:Bind(CraftingFrame, Content, {
		HelpLabel = "Ingredient",
		isItem = true
	})
	
	CraftingFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if CraftingFrame.Visible then
			CraftingClient:Open()
		end
	end)
end

CraftingClient:init()

return CraftingClient