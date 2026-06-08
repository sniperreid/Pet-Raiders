local Workspace = game:GetService("Workspace")
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local MaidClass = Services.get("MaidClass")
local RarityModule = Services.get("RarityModule")
local TitlesService = Services.get("TitlesService")

local TitleGradients = TitlesService.Gradients

local TextAnimationService = {}
TextAnimationService._LabelTasks = {}
TextAnimationService.Connections = {}

TextAnimationService.TextColors = {
	Common = Color3.fromRGB(255, 255, 255),
	Unique = Color3.fromRGB(255, 170, 90),
	Rare = Color3.fromRGB(255, 70, 70),
	Epic = Color3.fromRGB(110, 80, 230)
}

function TextAnimationService:GetShade(Color)
	local R, G, B = Color.R * 255, Color.G * 255, Color.B * 255
	
	local ShadeR = 60
	local ShadeG = 60
	local ShadeB = 60
	
	return Color3.fromRGB(
		math.clamp(R - ShadeR, 0, 255),
		math.clamp(G - ShadeG, 0, 255),
		math.clamp(B - ShadeB, 0, 255)
	)
end

function TextAnimationService:GetBlend(Colors, Offset)
	local Blend = (Offset * (#Colors - 1)) * 2
	local Index = math.floor(Blend) % #Colors + 1
	local NextIndex = (Index % #Colors) + 1
	local Alpha = Blend % 1
	
	return Colors[Index]:Lerp(Colors[NextIndex], Alpha)
end

TextAnimationService.Special = {
	Legendary = function(Offset)
		return Color3.fromHSV(
			Offset % 1,
			0.5,
			0.9
		)
	end,

	Secret = function(Offset)
		local Colors = {
			Color3.fromRGB(255, 0, 153),
			Color3.fromRGB(255, 92, 176),
			Color3.fromRGB(255, 60, 86)
		}

		local Blend = (Offset * (#Colors - 1)) * 2
		local Index = math.floor(Blend) % #Colors + 1
		local NextIndex = (Index % #Colors) + 1
		local Alpha = Blend % 1

		return Colors[Index]:Lerp(Colors[NextIndex], Alpha)
	end,
	
	Exclusive = function(Offset)
		return Color3.fromHSV(
			0.8 + math.sin(Offset * math.pi) / 10, 
			1, 
			1
		)
	end,
	
	Shiny = function(Offset)
		local Colors = {
			Color3.fromRGB(255, 171, 37),
			Color3.fromRGB(255, 211, 33),
			Color3.fromRGB(255, 134, 53)
		}
		
		return TextAnimationService:GetBlend(Colors, Offset)
	end
}

for i, v in RarityModule do
	if not v.Special then
		TextAnimationService.TextColors[i] = v.Color
		
		continue
	end
	
	TextAnimationService.Special[i] = v.Special
end

for Title, Data in TitleGradients do
	TextAnimationService.Special[Title] = Data
end

TextAnimationService.Random = Random.new()

local function Lerp(a, b, t)
	return a + (b - a) * t
end

function TextAnimationService:CalculateTextSize(TextLabel)
	return math.min(TextLabel.AbsoluteSize.X, TextLabel.AbsoluteSize.Y)
end

function TextAnimationService:RequestCleanup(TextLabel)
	if not self._LabelTasks[TextLabel] then
		return
	end

	local LabelTask = self._LabelTasks[TextLabel]
	local Object = LabelTask.Object

	if not Object then
		return
	end
	
	local _connections = self.Connections[TextLabel]

	if _connections then
		MaidClass:Destroy(_connections)
		MaidClass:Cancel(_connections)
		MaidClass:Disconnect(_connections)
	end

	if TextLabel:IsA("TextLabel") then
		TextLabel.TextScaled = true
	end

	local UIGradient = Object:FindFirstChildOfClass("UIGradient")

	if UIGradient then
		UIGradient:Destroy()
	end

	self._LabelTasks[TextLabel] = nil
end

function TextAnimationService:AnimateBackground(Background, Type)
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Settings = PlayerData.Settings or {}
	local isLowQuality = Settings["Low Quality"]
	
	self:RequestCleanup(Background)
	
	local RandomOffset = self.Random:NextNumber() / self.Random:NextNumber()
	
	local IsSpecial = self.Special[Type]
	local Gradient = Background:FindFirstChild("UIGradient") or Instance.new("UIGradient", Background)
	
	local function UpdateBackground()
		Background.BackgroundColor3 = Color3.new(1,1,1)
		
		if not IsSpecial then
			if not self.TextColors[Type] then
				if self.Connections[Background] then
					self.Connections[Background]:Disconnect()
					self.Connections[Background] = nil
				end
				
				return 
			end

			Gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(
					0,
					self.TextColors[Type]
				),
				
				ColorSequenceKeypoint.new(
					1,
					self.TextColors[Type]
				)
			})

			if self.Connections[Background] then
				self.Connections[Background]:Disconnect()
				self.Connections[Background] = nil
			end
			
			return 
		end
		
		if Background:IsA("ImageLabel") then
			Background.ImageColor3 = Color3.new(1,1,1)
		end

		local Sequence = {}

		for i = 0, 10 do
			table.insert(Sequence, ColorSequenceKeypoint.new(
				i / 10,
				self.Special[Type](
					(tick() + i / ((Background.Size.Y.Scale + Background.Size.Y.Scale) * 2)) / 2 + RandomOffset
				)
			))
		end

		Gradient.Color = ColorSequence.new(Sequence)

		table.clear(Sequence)
	end
	
	coroutine.wrap(function()
		local Type = RunService:IsServer() and "Heartbeat" or "RenderStepped"

		if IsSpecial and not isLowQuality then
			self.Connections[Background] = RunService[Type]:Connect(UpdateBackground)
		else
			for i = 1, 2 do
				RunService[Type]:Wait()

				UpdateBackground()
			end
		end
	end)()
	
	self._LabelTasks[Background] = {
		Object = Background
	}

	Background.AncestryChanged:Connect(function(Child, Parent)
		if not Parent then
			self:RequestCleanup(Background)
		end
	end)

	return {
		Destroy = function(self)
			self:RequestCleanup(Background)
		end,
	}
end

function TextAnimationService:AnimateText(TextLabel, Type, HighQuality)
	local PlayerData = Network.Call and Network:Fetch("GetClientData") or {}
	local Settings = PlayerData.Settings or {}
	local isLowQuality = Settings["Low Quality"]

	self:RequestCleanup(TextLabel)

	local OriginalText = TextLabel.Text
	local StringLength = #OriginalText

	local RandomOffset = self.Random:NextNumber() / self.Random:NextNumber()
	local TextSize = self:CalculateTextSize(TextLabel)

	local UIStroke = TextLabel:FindFirstChildOfClass("UIStroke")

	if UIStroke then
		--UIStroke:Destroy()
		--TextLabel.TextStrokeTransparency = 0
	end

	local IsSpecial = self.Special[Type]
	local Gradient = Instance.new("UIGradient", TextLabel)

	local function UpdateText()
		TextSize = self:CalculateTextSize(TextLabel)

		if not IsSpecial then
			if not self.TextColors[Type] then
				if self.Connections[TextLabel] then
					self.Connections[TextLabel]:Disconnect()
					self.Connections[TextLabel] = nil
				end

				return 
			end

			TextLabel.TextColor3 = self.TextColors[Type]

			if self.Connections[TextLabel] then
				self.Connections[TextLabel]:Disconnect()
				self.Connections[TextLabel] = nil
			end

			return 
		end

		if HighQuality then
			local GeneratedString = ""

			for i = 1, StringLength do
				local Letter = OriginalText:sub(i, i)

				local LetterColor = self.Special[Type](
					(tick() + i / StringLength) / 2 + RandomOffset
				):ToHex():upper()

				local LetterSize = math.floor(
					(TextSize * (5 / 6)) + (
					(
						math.sin(
							(tick() + i / StringLength + RandomOffset) * math.pi
						) + 0.75
					) / 2
					) * (TextSize / 6)
				)

				local Section = `<font size="{LetterSize}" color="#{LetterColor}">{Letter}</font>`

				if TextLabel.Name == "Pet_Name" then
					Section = `color="#{LetterColor}"`
				end

				GeneratedString = GeneratedString .. Section

				TextLabel.Text = GeneratedString
			end
		else
			TextLabel.TextColor3 = Color3.new(1,1,1)

			local Sequence = {}

			for i = 0, 15 do
				table.insert(Sequence, ColorSequenceKeypoint.new(
					i / 15,
					self.Special[Type](
						(tick() + i / StringLength) / 2 + RandomOffset
					)
				))
			end

			Gradient.Color = ColorSequence.new(Sequence)

			table.clear(Sequence)
		end	
	end

	coroutine.wrap(function()
		--coroutine.wrap(UpdateText)()

		local Type = RunService:IsServer() and "Heartbeat" or "RenderStepped"

		if IsSpecial and not isLowQuality then
			self.Connections[TextLabel] = RunService[Type]:Connect(UpdateText)
		else
			for i = 1, 2 do
				RunService[Type]:Wait()

				UpdateText()
			end
		end
	end)()

	self._LabelTasks[TextLabel] = {
		Object = TextLabel
	}
	
	TextLabel.AncestryChanged:Connect(function(Child, Parent)
		if not Parent then
			self:RequestCleanup(TextLabel)
		end
	end)

	return {
		Destroy = function(self)
			TextLabel.TextScaled = true
			
			self:RequestCleanup(TextLabel)
		end,
	}
end

function TextAnimationService:AnimateImage(ImageLabel, Type, HighQuality)
	self:RequestCleanup(ImageLabel)

	local RandomOffset = self.Random:NextNumber() / self.Random:NextNumber()

	local IsSpecial = self.Special[Type]
	local Gradient = Instance.new("UIGradient", ImageLabel)

	local function UpdateImage()
		if not IsSpecial then
			if not self.TextColors[Type] then
				if self.Connections[ImageLabel] then
					self.Connections[ImageLabel]:Disconnect()
					self.Connections[ImageLabel] = nil
				end

				return
			end

			ImageLabel.ImageColor3 = self.TextColors[Type]

			if self.Connections[ImageLabel] then
				self.Connections[ImageLabel]:Disconnect()
				self.Connections[ImageLabel] = nil
			end

			return
		end

		if HighQuality then
			local Sequence = {}

			for i = 0, 15 do
				table.insert(Sequence, ColorSequenceKeypoint.new(
					i / 15,
					self.Special[Type]((tick() + i / 15) / 2 + RandomOffset)
					))
			end

			Gradient.Color = ColorSequence.new(Sequence)
			table.clear(Sequence)
		else
			ImageLabel.ImageColor3 = Color3.new(1, 1, 1)

			local Sequence = {}

			for i = 0, 15 do
				table.insert(Sequence, ColorSequenceKeypoint.new(
					i / 15,
					self.Special[Type]((tick() + i / 15) / 2 + RandomOffset)
					))
			end

			Gradient.Color = ColorSequence.new(Sequence)
			table.clear(Sequence)
		end	
	end

	coroutine.wrap(function()
		local Type = RunService:IsServer() and "Heartbeat" or "RenderStepped"

		if IsSpecial then
			self.Connections[ImageLabel] = RunService[Type]:Connect(UpdateImage)
		else
			for i = 1, 2 do
				RunService[Type]:Wait()
				UpdateImage()
			end
		end
	end)()

	self._LabelTasks[ImageLabel] = {
		Object = ImageLabel
	}

	ImageLabel.AncestryChanged:Connect(function(Child, Parent)
		if not Parent then
			self:RequestCleanup(ImageLabel)
		end
	end)

	return {
		Destroy = function(self)
			self:RequestCleanup(ImageLabel)
		end,
	}
end

function TextAnimationService:RotateGradient(ImageLabel, Strength)
	self:RequestCleanup(ImageLabel)
	
	local Speed = 1/20
	local Strength = Strength or 3
	
	local Gradient = ImageLabel:FindFirstChildOfClass("UIGradient")
	local StartRotation = Gradient.Rotation
	
	local Start = tick()
	
	local Type = RunService:IsServer() and "Heartbeat" or "RenderStepped"
	
	self.Connections[Gradient] = RunService[Type]:Connect(function()
		local Next = ((tick() - Start) / Speed) * Strength
		local NextRotation = StartRotation + Next
		
		Gradient.Rotation = NextRotation
	end)
	
	self._LabelTasks[Gradient] = {
		Object = Gradient
	}
	
	Gradient.AncestryChanged:Connect(function(Child, Parent)
		if not Parent then
			self:RequestCleanup(ImageLabel)
		end
	end)
	
	return {
		Destroy = function(self)
			self:RequestCleanup(ImageLabel)
		end,
	}
end

return TextAnimationService