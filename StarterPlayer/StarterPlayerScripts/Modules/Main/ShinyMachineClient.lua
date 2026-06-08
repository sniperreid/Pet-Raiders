local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local GuiService = Services.get("GuiService")
local AnimationService = Services.get("AnimationService")
local ImageModule = Services.get("ImageModule")
local HoverManager = Services.get("HoverManager")
local RichTextService = Services.get("RichTextService")
local SoundService = Services.get("SoundService")

local SelectionMenu = Services.get("SelectionMenu")
local PetCraftService = Services.get("PetCraftService")

local SMClient = {}

function SMClient:SelectPet(Pet)
	local Frames = GuiService.Interface.Frames
	local CraftPetFrame = Frames.CraftPetFrame
	local Content = CraftPetFrame.Content
	local Buttons = Content.Buttons
	local Context = Content.Context
	
	for i, v in Content:GetChildren() do
		if v:IsA("GuiButton") then
			v:Destroy()
		end
	end
	
	GuiService:OpenFrame(CraftPetFrame)
	
	local Display = RichTextService.new {}
	Display:AddSection("Craft x1")
	Display:AddSection(" ")
	Display:AddSection(("Shiny %s"):format(Pet.Name), "Yellow")
	Display:AddSection(" ")
	Display:AddSection("with x10")
	Display:AddSection(" ")
	Display:AddSection(Pet.Name, "Light Blue")
	
	Context.Text = Display.Message	
	
	local NormalPet = {
		ID = Pet.ID,
		Name = Pet.Name,
		Tier = "Normal",
		Exp = 0,
		Level = 1,
		Locked = false,
		Equipped = false
	}
	
	local ShinyPet = {
		ID = Pet.ID .. "SHINY",
		Name = Pet.Name,
		Tier = "Shiny",
		Exp = 0,
		Level = 1,
		Locked = false,
		Equipped = false
	}

	local Component = GuiService.GuiUtil:CreatePet(NormalPet, Content)
	local Product = GuiService.GuiUtil:CreatePet(ShinyPet, Content)
	
	Component.Name = NormalPet.ID
	Product.Name = ShinyPet.ID
	
	Component.AnchorPoint = Vector2.new(.5, .5)
	Product.AnchorPoint = Vector2.new(.5, .5)
	
	Component.Position = UDim2.fromScale(0.25, 0.5)
	Product.Position = UDim2.fromScale(0.75, 0.5)
	
	Component.Size = UDim2.fromScale(0.4, 0.4)
	Product.Size = UDim2.fromScale(0.4, 0.4)
	
	Component.ZIndex = 999
	Product.ZIndex = 999
	
	table.clear(ShinyPet)

	local HoverRender = HoverManager:Bind(CraftPetFrame, Content)

	HoverRender:SubscribeData(Component.Name, {
		ID = Component.Name,
		Name = NormalPet.Name,
		Tier = "Normal",
		Exp = 0,
		Level = 1,
		Locked = false,
		Equipped = false
	})

	HoverRender:SubscribeData(Product.Name, {
		ID = Product.Name,
		Name = NormalPet.Name,
		Tier = "Shiny",
		Exp = 0,
		Level = 1,
		Locked = false,
		Equipped = false
	})

	HoverRender:LoadHoverInfo()
	
	AnimationService:CreateButton(Buttons.Cancel, function()
		self:OpenMachine()
	end)
	
	AnimationService:CreateButton(Buttons.Craft, function()
		local Success = Network:Invoke("CraftShiny", Pet)
		
		if Success then
			self:Success(Pet.Name)
		else
			self:Failure()
		end
	end)
end

function SMClient:OpenMachine()
	SelectionMenu:CreateList({
		Type = "GetAmountsOfPets",
		Amount = PetCraftService.CraftExpectancy
	}, function(...)
		return self:SelectPet(...)
	end)
end

Network:Bind("OpenShinyMachine", function(...)
	return SMClient:OpenMachine(...)
end)

function SMClient:Success(PetName)
	task.delay(.1, function()
		SMClient:OpenMachine()
	end)
	
	Network:Fetch("DisplayNewItem",
		{
			Type = "Message",
			Message = ("You have crafted x1 Shiny %s!"):format(PetName),
			TextColor = Color3.fromRGB(255, 175, 35)
		}
	)
	
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
end

function SMClient:Failure()
	task.delay(.1, function()
		SMClient:OpenMachine()
	end)
	
	Network:Fetch("DisplayNewItem",
		{
			Type = "Message",
			Message = "Crafting failed!",
			TextColor = Color3.fromRGB(255, 60, 60)
		}
	)
	
	SoundService:PlaySound("Error", .45)
end

return SMClient