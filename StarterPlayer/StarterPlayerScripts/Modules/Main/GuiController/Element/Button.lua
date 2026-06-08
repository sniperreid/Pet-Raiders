local Button = {}
Button.__index = Button

function Button:CreateContent()
	local Gui_Object = self.Object
	local Gui_Content = Instance.new("Frame", Gui_Object)
	Gui_Content.AnchorPoint = Vector2.one/2
	Gui_Content.Size = UDim2.fromScale(1, 1)
	Gui_Content.Position = UDim2.fromScale(.5, .5)
	Gui_Content.BackgroundTransparency = 1
	Gui_Content.Name = "Content"
	
	for i, Child in Gui_Object:GetChildren() do
		if Child == Gui_Content then
			continue
		end
		
		Child.Parent = Gui_Content
	end
	
	return Gui_Content
end

function Button:CreateUIScale()
	local Gui_Object = self.Object
	local Gui_Content = Gui_Object:FindFirstChild("Content")
	local Gui_Scale = Instance.new("UIScale", Gui_Content)
	Gui_Scale.Scale = 1
	
	return Gui_Scale
end

function Button:init()
	
	local Gui_Object = self.Object
	local Gui_Content = Gui_Object:FindFirstChild("Content") or self:CreateContent()
	local Gui_Scale = Gui_Content:FindFirstChild("UIScale") or self:CreateUIScale()
	
	local Controller = self.Controller
	local Fusion = Controller.Controller
	
	Controller.Content = Controller.new(Fusion, Gui_Content)
	Controller.UIScale = Controller.new(Fusion, Gui_Scale)
	
	Controller.Content:AttachTweenTheme(Controller.TweenTheme)
	Controller.UIScale:AttachTweenTheme(Controller.TweenTheme)
	
	for i, v in Gui_Content:GetChildren() do
		Controller.Content[v.Name] = Controller.new(Fusion, v)
		Controller.Content[v.Name]:AttachTweenTheme(Controller.TweenTheme)
	end
	
	local Maid = Controller.Maid
	
	Maid:GiveTask(Gui_Object.MouseEnter:Connect(function()
		Fusion:CallRoutine("EnterHover", Controller, true)
	end))
	
	Maid:GiveTask(Gui_Object.MouseLeave:Connect(function()
		Fusion:CallRoutine("ExitHover", Controller, true)
	end))
	
	Maid:GiveTask(Gui_Object.MouseButton1Down:Connect(function()
		Fusion:CallRoutine("MouseDown", Controller, true)
	end))
	
	Maid:GiveTask(Gui_Object.MouseButton1Up:Connect(function()
		local Callback = Controller.ElementCallback

		if not Callback then
			return
		end
		
		Fusion:CallRoutine("MouseUp", Controller, true)
		
		return Callback(Controller)
	end))
	
end

function Button.new(Controller, GUI_OBJECT)
	local self = setmetatable({
		Controller = Controller,
		Object = Controller.Object
	}, Button)
	
	self:init()

	return self
end

return Button