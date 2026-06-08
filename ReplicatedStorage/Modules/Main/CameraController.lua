local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Class = Services.get "_class"
local EasyRender = Services.get("RenderUtil").Number
local math = Services.get("MathUtility")

Class.insert "CameraRender" {
	
	CameraObject = workspace.CurrentCamera,
	CameraPivot = CFrame.new(),
	CameraAngle = CFrame.new(),
	FOV = 70,
	
	get_id = function(self)
		return self.class .. self.camera_id
	end,
	
	init = function(self, id)
		local Camera = self.CameraObject
		
		self.OriginalFieldOfView = Camera.FieldOfView
		
		self.camera_id = id
		
		local idx = self:get_id()
		
		self.Maid:onCleanUp(function()
			RunService:UnbindFromRenderStep(idx)
			
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = self.OriginalFieldOfView
		end)
		
		Camera.CameraType = Enum.CameraType.Scriptable
		
		RunService:BindToRenderStep(
			idx,
			Enum.RenderPriority.Camera.Value + 2,
			function()
				self:Update()
			end
		)
	end,
	
	Update = function(self)
		
		local Camera = self.CameraObject
		
		Camera.FieldOfView = self.FOV or 70
		Camera.CFrame = self.CameraPivot * self.CameraAngle
	end,
	
	PivotTo = function(self, newPivot)
		self.CameraPivot = newPivot
	end,
	
	UpdateAngle = function(self, newAngle)
		self.CameraAngle = newAngle
	end,
	
	Transform = function(self, newPivot, easeTime, easeType, easeDirection, isAngle)
		if self.TransformRender and self.TransformRender.Disconnect then
			self.TransformRender:Disconnect()
		end
		
		local Origin = self.CameraPivot
		
		self.TransformRender = self.Maid:add(EasyRender.new({
			Min = 0,
			Max = 1,
			UpdateSpeed = easeTime
		}, function(t)
			local x = TweenService:GetValue(
				t,
				easeType,
				easeDirection
			)
			
			local currentPivot = Origin:Lerp(
				newPivot,
				x
			)
			
			if isAngle then
				return self:UpdateAngle(currentPivot)
			end
			
			return self:PivotTo(currentPivot)
		end))
	end,
	
	UpdateIntensity = function(self, new_field_of_view, easeTime, easeType, easeDirection)
		if self.IntensityRender and self.IntensityRender.Disconnect then
			self.IntensityRender:Disconnect()
		end
		
		local Origin = self.FOV
		
		if not new_field_of_view or new_field_of_view == Origin then
			return
		end
		
		self.IntensityRender = self.Maid:add(EasyRender.new({
			UpdateSpeed = easeTime or 0
		}, function(t)
			local x = TweenService:GetValue(
				t,
				easeType or Enum.EasingStyle.Sine,
				easeDirection or Enum.EasingDirection.Out
			)
			
			self.FOV = math.Lerp(
				Origin,
				new_field_of_view,
				x
			)
		end))
		
	end,
}

Class.insert "CameraController" {
	init = function(self)
		self.camera_id = HttpService:GenerateGUID(false)
		self.cam_render = Class.new("CameraRender", self.camera_id)
		
		self.Maid:onCleanUp(function()
			if not self.cam_render then
				return
			end
			
			self.cam_render.Maid:Clean()
		end)
	end,
	
	UpdateIntensity = function(self, new_intensity, ...)
		self.current_intensity = new_intensity
		
		return self.cam_render:UpdateIntensity(self[self.current_intensity .. "FieldOfView"], ...)
	end,
	
	PivotTo = function(self, ...)
		return self.cam_render:PivotTo(...)
	end,
	
	Transform = function(self, new_point, easeTime, easeType, easeDirection)
		assert(new_point, "new pivot not defined.")
		if not easeTime or easeTime == 0 then return self:PivotTo(new_point) end
		assert(easeType, "ease type necessary, default to Linear")
		assert(easeDirection, "ease direction necessary, default to InOut")
		
		return self.cam_render:Transform(new_point, easeTime, easeType, easeDirection)
	end,
	
	DefaultFieldOfView = 70,
	DramaticFieldOfView = 50,
}

return {}