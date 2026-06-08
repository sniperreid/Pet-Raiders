local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage.Modules
local Utility = Modules.Util

local MaidClass = require(Utility.MaidClass)

local ClassIndex = {
	Button = "GuiButton",
	UIScale = "UIScale"
}

local Element = {}
Element.__index = Element

function Element:Destroy()
	if self.Maid then
		self.Maid:Clean()
	end

	table.clear(self)
end

function Element:CreateTween(Info, Properties, Object)
	
	local Object = Object or (self:is("Flipbook") and self.Content or self.Object)
	
	if not Object then
		return {Play = function(self) end}
	end
	
	if Info.Time == 0 then
		for i, v in Properties or {} do
			Object[i] = v
		end
	end
	
	return TweenService:Create(
		Object,
		Info or TweenInfo.new(),
		Properties or {}
	)
end

function Element:PlayTween(...)
	return self:CreateTween(...):Play()
end

function Element:Transform(Destination, Speed, TweenType)
	
	local TweenType = TweenType or self.TweenTheme or "Linear"
	local Speed = Speed or 1

	self:PlayTween(
		TweenInfo.new(Speed, Enum.EasingStyle[TweenType]),
		{Position = Destination}
	)
	
end

function Element:RotateTo(Rotation, Speed, TweenType)
	
	local TweenType = TweenType or self.TweenTheme or "Linear"
	local Speed = Speed or 1
	
	local Object = self.Object
	local CurrentRotation = Object.Rotation
	
	local DistanceFromRotation = math.abs(CurrentRotation - Rotation)
	
	self:PlayTween(
		TweenInfo.new(Speed, Enum.EasingStyle[TweenType]),
		{Rotation = Rotation}
	)
end

function Element:ChangeDisplayOrder(ZIndex)
	
	local Object = self.Object
	
	Object.ZIndex = ZIndex or 0
	
end

function Element:ChangeOpacity(Opacity, Speed, TweenType)
	
	local TweenType = TweenType or self.TweenTheme or "Linear"
	local Speed = Speed or 1
	
	local Opacity = (Opacity or 0) / 100

	local Object = self.Object
	
	local isImage = string.match(Object.ClassName, "Image")
	local Property = (isImage and "Image" or "Background") .. "Transparency"
	
	if Speed == 0 then
		Object[Property] = Opacity
		
		return
	end

	self:PlayTween(
		TweenInfo.new(Speed, Enum.EasingStyle[TweenType]),
		{[Property] = Opacity},
		Object
	)
	
end

function Element:Typewrite(Speed, TweenType)
	
	local TweenType = TweenType or self.TweenTheme or "Linear"
	local Speed = Speed or 1
	
	local Object = self.Object
	
	if not Object:IsA("TextLabel") then
		return
	end
	
	Object.MaxVisibleGraphemes = 0
	
	self:PlayTween(
		TweenInfo.new(Speed, Enum.EasingStyle[TweenType]),
		{MaxVisibleGraphemes = string.len(Object.Text)}
	)
	
end

function Element:AttachTweenTheme(TweenType)
	self.TweenTheme = TweenType
end

function Element:BindCallback(ElementCallback)
	self.ElementCallback = ElementCallback
end

function Element:GetAbstractClassname()
	for Abstract, Type in ClassIndex do
		if self.Object:IsA(Type) then
			return Abstract
		end
	end
	
	return ""
end

function Element:is(class)
	return self[class] == true
end

function Element:init()
	local AbstractClass = self:GetAbstractClassname()
	local AbstractModule = script:FindFirstChild(AbstractClass)
	
	if not self.ObjectOnDestroyed then
		self.Maid:GiveTask(self.Object)
	end
	
	if AbstractModule then
		self.Indexer = require(AbstractModule).new(self)
	end
end

function Element.new(Controller, GUI_OBJECT, ElementCallback, ObjectOnDestroyed)
	local self = setmetatable({
		Controller = Controller,
		Maid = MaidClass.new(),
		ElementCallback = ElementCallback,
		Object = GUI_OBJECT,
		ObjectOnDestroyed = ObjectOnDestroyed,
		[script.Name] = true
	}, Element)
	
	self:init()
	
	return self
end

return Element