local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local GuiService = Services.get("GuiService")
local AnimationService = Services.get("AnimationService")
local ImageModule = Services.get("ImageModule")
local HoverManager = Services.get("HoverManager")

local PetInventory = GuiService.PetInventory

local Interface = GuiService.Interface
local Frames = Interface.Frames
local SelectFrame = Frames.SelectPetFrame

local SF_Content = SelectFrame.Content
local SF_List = SF_Content.Grid

local SelectionMenu = {}

SelectionMenu.Selection_Types = {
	All = function(self)
		return PetInventory:GetPets()
	end,
	
	GetAmountsOfPets = function(self)
		
		local Amount = self.Amount
		
		local Pets = {}
		local List = PetInventory:GetPets()
		
		for i, Pet in List do
			Pets[Pet.Tier .. Pet.Name] = (Pets[Pet.Tier .. Pet.Name] or 0) + 1
		end
		
		local new_list = {}
		
		for i, Pet in List do
			if Pets[Pet.Tier .. Pet.Name] < 10 then
				continue
			end
			
			local is_found
			
			for a, b in new_list do
				if b[1].Name == Pet.Name and b[1].Tier == Pet.Tier and not Pet.Locked then
					is_found = true
					
					b[2] += 1
				end
			end
			
			if is_found then
				continue
			end
			
			table.insert(
				new_list,
				{Pet, 1}
			)
		end
		
		return new_list
	end,
}

function SelectionMenu:CreateTemplate(Pet)
	return GuiService.GuiUtil:CreatePet(Pet, SF_List)
end

function SelectionMenu:CreateList(_type, Selection_Callback)
	
	local Selection_Types = self.Selection_Types
	local Selection_Type = Selection_Types[_type.Type] or Selection_Types.All
	
	local Pets = Selection_Type(_type)

	if SelectFrame.Visible then
		return
	end
	
	if self.HoverRender then
		self.HoverRender:Destroy()
		self.HoverRender = nil
	end
	
	for i, v in SF_List:GetChildren() do
		if not v:IsA("GuiButton") then
			continue
		end
		
		v:Destroy()
	end
	
	GuiService:OpenFrame(SelectFrame)
	
	self.List = Pets
	
	self.HoverRender = HoverManager:Bind(
		SelectFrame,
		SF_List,
		{
			HelpLabel = "Select Pet"
		} 
	)
	
	for i, Pet in self.List do
		
		local pet_amt
		
		if _type.Type == "GetAmountsOfPets" then
			pet_amt = Pet[2]
			Pet = Pet[1]
		end
		
		local Template = self:CreateTemplate(Pet)
		
		if pet_amt then
			Template.Content.Info.Level.Text = ("x%d"):format(pet_amt)
		end
		
		AnimationService:CreateButton(
			Template,
			function()
				GuiService:CloseFrame(SelectFrame)
				
				return Selection_Callback(Pet)
			end
		)
		
	end
	
	self.HoverRender:LoadHoverInfo()
	
end

return SelectionMenu