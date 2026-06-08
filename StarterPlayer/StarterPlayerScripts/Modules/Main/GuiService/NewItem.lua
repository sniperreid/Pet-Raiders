local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(RS_Modules.Services)

local Network = Services.get("Network")
local ImageModule = Services.get("ImageModule")
local TextAnimationService = Services.get("TextAnimationService")
local HoverManager = Services.get("HoverManager")

local PetModule = Services.get("PetModule")
local ItemModule = Services.get("ItemModule")
local AbilityModule = Services.get("AbilityModule")

local GuiService
local Interface
local Frames
local NewItemFrame
local Content
local Grid

local module = {}

function module:Clear()
	for i, v in Grid:GetChildren() do
		if v:IsA("GuiButton") then
			v:Destroy()
		end
	end
end

function module:Create(Items)
	if not Items then return end
	if typeof(Items) ~= "table" then return end
	
	if NewItemFrame.Visible then return end
	
	GuiService:OpenFrame(NewItemFrame)
	
	self:Clear(Grid)
	
	local Counts = {}
	local NewUniqueItems = {}
	
	-- state item count as Item .. Chance e.g Doggy10
	-- this will create actual unique counts.
	for i, v in Items do
		local Item, Type, Chance = v.Item, v.Type, v.Chance
		
		if not Item or not Type or not Chance then continue end
		
		local isUnique = true

		for a, k in NewUniqueItems do
			if k.Item == Item and k.Type == Type and k.Chance == Chance then isUnique = false break end
		end

		if isUnique then
			table.insert(NewUniqueItems, v)
		end
		
		if Counts[Item .. Chance] then
			Counts[Item .. Chance] += 1
		else
			Counts[Item .. Chance] = 1
		end
	end
	
	for i, v in NewUniqueItems do
		local Item, Type, Chance = v.Item, v.Type, v.Chance

		if not Item or not Type or not Chance then continue end
		if not Counts[Item .. Chance] then Counts[Item .. Chance] = 1 end
		
		local Data = Type == "Pet" and PetModule[Item] or Type == "Item" and ItemModule[Item] or Type == "Ability" and AbilityModule[Item] or {}
		
		local NewItem = script.Template:Clone()
		NewItem.Name = Item
		NewItem.Parent = Grid
		NewItem.Content.ItemIcon.Image = ImageModule(Item)
		NewItem.Content.Amount.Text = ("x%s"):format(Counts[Item .. Chance])
		
		TextAnimationService:AnimateImage(NewItem.Glow, Data.Rarity)
	end
end

function module:Init()
	HoverManager:Bind(NewItemFrame, Grid, {
		HelpLabel = "Display only"
	})

	HoverManager:Bind(NewItemFrame, Grid, {
		HelpLabel = "Display only",
		isItem = true
	})
	
	Network:Bind("DisplayNewItems", function(...)
		return self:Create(...)
	end)
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = GS.Frames
		NewItemFrame = Frames.NewItemFrame
		Content = NewItemFrame.Content
		Grid = Content.Grid

		self:Init()

		return self
	end,
})
