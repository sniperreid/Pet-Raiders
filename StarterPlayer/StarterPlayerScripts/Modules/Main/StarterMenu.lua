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

local Interface = GuiService.Interface
local Frames = Interface.Frames
local StarterFrame = Frames.StarterFrame

local SF_Content = StarterFrame.Content
local SF_List = SF_Content.Pets
local SF_Buttons = SF_Content.Buttons

local StarterMenu = {}

function StarterMenu:CreateTemplate(i, Starter)
	return GuiService.GuiUtil:CreatePet({
		ID = tostring(i),
		Name = Starter,
		Tier = "Normal",
		Exp = 0,
		Level = 1,
		Equipped = false
	}, SF_List)
end

function StarterMenu:CanSelect()
	return self.SelectedStarter > 0 and self.SelectedStarter <= #self.StartersList
end

function StarterMenu:UpdateSelection(new)
	self.SelectedStarter = new

	SF_Buttons.Choose.Blackout.Visible = not self:CanSelect()
	
	for i, v in SF_List:GetChildren() do
		if not v:IsA("GuiButton") then
			continue
		end

		v.Content.UIStroke.Color = tonumber(v.Name) == new and Color3.new(0, 1, 0) or Color3.fromRGB(7, 43, 86)
	end
end

function StarterMenu:CreateStarterList(Starters)
	
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
	
	StarterFrame.Visible = true
	
	self:UpdateSelection(0)
	self.StartersList = Starters
	
	self.HoverRender = HoverManager:Bind(
		StarterFrame,
		SF_List
	)
	
	for i, Starter in self.StartersList do
		
		self.HoverRender:SubscribeData(
			tostring(i),
			{
				Name = Starter,
				Tier = "Normal",
				Exp = 0,
				Level = 1,
				Locked = false,
				Equipped = false,
				Serial = 0
			}
		)
		
		local Template = self:CreateTemplate(i, Starter)
		
		AnimationService:CreateButton(
			Template,
			function()
				if self.SelectedStarter == i then
					return self:UpdateSelection(0)
				end
				
				self:UpdateSelection(i)
			end
		)
		
	end
	
	self.HoverRender:LoadHoverInfo()
	
end

function StarterMenu:init()
	AnimationService:CreateButton(
		SF_Buttons.Choose,
		function()
			if not self:CanSelect() then
				return
			end
			
			Network:Post(
				"SelectStarter",
				self.StartersList[self.SelectedStarter]
			)
			
			StarterFrame.Visible = false
		end
	)
	
	Network:Bind("OpenStarterMenu", function(...)
		self:CreateStarterList(...)
	end)
end

StarterMenu:init()

return StarterMenu